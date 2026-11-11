local import = ...

local Constants = import("Core/Constants")
local Janitor = import("Core/Janitor")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Icons = import("Core/Icons")
local Overlay = import("UI/Overlay")
local Navigation = import("UI/Navigation")
local Tab = import("UI/Tab")

local UserInputService = game:GetService("UserInputService")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Window = {}
Window.__index = Window

function Window.new(library, config)
	config = Utility.Merge({
		Title = "Application",
		Size = UDim2.fromOffset(1100, 760),
		Draggable = true,
		ClampToScreen = false,
		FitToScreen = true,
		Resizable = false,
		ToggleKey = Enum.KeyCode.RightControl,
		DestroyOnClose = false,
		Visible = true,
		SearchBarPosition = "Top",
		AutoScale = true,
		MinScale = 0.4,
	}, config)

	assert(
		config.SearchBarPosition == "Top" or config.SearchBarPosition == "Below",
		"SearchBarPosition must be \"Top\" or \"Below\""
	)

	local theme = library.Theme
	if config.Theme ~= nil then
		if type(config.Theme) == "table" or theme:GetName() ~= config.Theme then
			theme:Set(config.Theme)
		end
	end

	local self = setmetatable({}, Window)
	self.Library = library
	self.Janitor = Janitor.new()
	self.Scope = theme:CreateScope()
	self.Janitor:Add(self.Scope)
	self.Tabs = {}
	self.ActiveTab = nil
	self._open = false
	self._token = 0
	self._offset = Vector2.zero
	self._listening = false
	self._compact = nil
	self._fitScale = 1
	self._toggleKey = config.ToggleKey
	self._config = config

	local scope = self.Scope
	local janitor = self.Janitor

	self.Gui = Utility.Create("ScreenGui", {
		Name = "RobloxUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = config.Parent or Utility.GetGuiParent(),
	})
	janitor:Add(self.Gui)

	local viewport = self:_viewport()
	local requested = config.Size
	self._size = Vector2.new(
		requested.X.Scale * viewport.X + requested.X.Offset,
		requested.Y.Scale * viewport.Y + requested.Y.Offset
	)
	self._current = self._size

	self.Root = Utility.Create("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self._size.X, self._size.Y),
		Visible = false,
		Parent = self.Gui,
	})
	self._scale = Utility.Create("UIScale", { Scale = 0.96, Parent = self.Root })

	self.Frame = Utility.Create("CanvasGroup", {
		Name = "Window",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		GroupTransparency = 1,
		ZIndex = 1,
		Parent = self.Root,
	})
	scope:Bind(self.Frame, { BackgroundColor3 = "Window" })
	Utility.Corner(self.Frame, Metrics.WindowRadius)

	local outline = Utility.Create("Frame", {
		Name = "Outline",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = self.Root,
	})
	Utility.Corner(outline, Metrics.WindowRadius)
	self._outlineStroke = Utility.Stroke(outline, 1, 1)
	scope:Bind(self._outlineStroke, { Color = "Border" })

	self.Overlay = Overlay.new(self.Root, self._scale, janitor)

	local topBar = Utility.Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, Metrics.TopBarHeight),
		Parent = self.Frame,
	})

	local titleX = Metrics.PagePadding
	if config.Icon ~= nil then
		local logo = Icons.Create(topBar, config.Icon, 22, Color3.new(1, 1, 1))
		logo.Frame.AnchorPoint = Vector2.new(0, 0.5)
		logo.Frame.Position = UDim2.new(0, Metrics.PagePadding, 0.5, 0)
		titleX = Metrics.PagePadding + 32
		scope:Watch(function(colors, animated)
			logo:SetColor(colors.Text, animated)
		end)
	end

	self.TitleLabel = Utility.Create("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, titleX, 0.5, 0),
		Size = UDim2.new(1, -(titleX + 70), 0, 28),
		Text = config.Title,
		FontFace = Constants.Fonts.SemiBold,
		TextSize = TextSizes.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = topBar,
	})
	scope:Bind(self.TitleLabel, { TextColor3 = "Text" })

	local topLine = Utility.Create("Frame", {
		Name = "Line",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0,
		Parent = topBar,
	})
	scope:Bind(topLine, { BackgroundColor3 = "Border" })

	local closeButton = Utility.Create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		Parent = topBar,
	})
	Utility.Corner(closeButton, Metrics.ControlRadius)
	local closeScale = Utility.Create("UIScale", { Parent = closeButton })
	local closeIcon = Icons.Create(closeButton, "close", 18, Color3.new(1, 1, 1))
	closeIcon.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Frame.Position = UDim2.fromScale(0.5, 0.5)

	local closeState = { Hover = false, Press = false }
	local function renderClose(animated)
		local colors = scope:Colors()
		local background = colors.Hover
		if closeState.Press then
			background = colors.Selected
		end
		local active = closeState.Hover or closeState.Press
		Animation.Set(closeButton, "Hover", {
			BackgroundColor3 = background,
			BackgroundTransparency = active and 0 or 1,
		}, animated)
		closeIcon:SetColor(active and colors.Text or colors.TextSecondary, animated)
		Animation.Set(closeScale, "Press", { Scale = closeState.Press and 0.9 or 1 }, animated)
	end
	Utility.Interact(closeButton, janitor, {
		Hover = function(state)
			closeState.Hover = state
			renderClose(true)
		end,
		Press = function(state)
			closeState.Press = state
			renderClose(true)
		end,
		Click = function()
			self:Close()
		end,
	})
	scope:Watch(function(_, animated)
		renderClose(animated)
	end)

	local body = Utility.Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, Metrics.TopBarHeight),
		Size = UDim2.new(1, 0, 1, -Metrics.TopBarHeight),
		Parent = self.Frame,
	})

	self.Sidebar = Utility.Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, Metrics.SidebarWidth, 1, 0),
		BackgroundTransparency = 0,
		Parent = body,
	})
	scope:Bind(self.Sidebar, { BackgroundColor3 = "Sidebar" })

	self.Divider = Utility.Create("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, Metrics.SidebarWidth, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundTransparency = 0,
		Parent = body,
	})
	scope:Bind(self.Divider, { BackgroundColor3 = "Border" })

	self.Content = Utility.Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, Metrics.SidebarWidth + 1, 0, 0),
		Size = UDim2.new(1, -(Metrics.SidebarWidth + 1), 1, 0),
		ClipsDescendants = true,
		Parent = body,
	})

	self.Navigation = Navigation.new(self, self.Sidebar, function(item, previous)
		self.Overlay:Dismiss()
		if previous and previous.Page then
			previous.Page:Hide()
		end
		item.Page:Show(previous ~= nil)
		self.ActiveTab = item.Page
	end)

	if config.SearchBarPosition == "Below" then
		local search = self.Navigation.SearchFrame
		local list = self.Navigation.Scroll
		local margin = search.Position.Y.Offset
		local reserved = list.Position.Y.Offset
		list.Position = UDim2.fromOffset(0, 0)
		list.Size = UDim2.new(1, 0, 1, -reserved)
		search.AnchorPoint = Vector2.new(0, 1)
		search.Position = UDim2.new(0, search.Position.X.Offset, 1, -margin)
	end

	if config.Draggable then
		local startOffset = Vector2.zero
		Utility.Drag(topBar, janitor, {
			Began = function()
				self.Overlay:Dismiss()
				startOffset = self._offset
			end,
			Changed = function(_, delta)
				self._offset = startOffset + delta
				self:_clamp()
			end,
		})
	end

	if config.Resizable then
		local grip = Utility.Create("TextButton", {
			Name = "Resize",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(22, 22),
			ZIndex = 10,
			Parent = self.Frame,
		})
		local gripIcon = Icons.Create(grip, "grip", 16, Color3.new(1, 1, 1))
		gripIcon.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		gripIcon.Frame.Position = UDim2.fromScale(0.5, 0.5)
		scope:Watch(function(colors, animated)
			gripIcon:SetColor(colors.TextMuted, animated)
		end)

		local startSize = Vector2.zero
		local startOffset = Vector2.zero
		local startFit = 1
		Utility.Drag(grip, janitor, {
			Began = function()
				self.Overlay:Dismiss()
				startSize = self._current
				startOffset = self._offset
				startFit = self._fitScale
			end,
			Changed = function(_, delta)
				local localDelta = delta / startFit
				local newSize = Vector2.new(
					math.max(startSize.X + localDelta.X, Metrics.MinWindowSize.X),
					math.max(startSize.Y + localDelta.Y, Metrics.MinWindowSize.Y)
				)
				self._size = newSize
				self._offset = startOffset + (newSize - startSize) * startFit / 2
				self:_fit()
			end,
		})
	end

	local launcher = config.Launcher
	if launcher == nil then
		launcher = UserInputService.TouchEnabled
	end
	if launcher then
		self:_buildLauncher()
	end

	janitor:Add(self.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_fit()
	end))

	janitor:Add(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or self._listening then
			return
		end
		if self._toggleKey ~= Enum.KeyCode.Unknown and input.KeyCode == self._toggleKey then
			self:Toggle()
		end
	end))

	self:_fit()
	if config.Visible then
		self:Open()
	end

	return self
end

function Window:_viewport()
	local size = self.Gui.AbsoluteSize
	if size.X < 1 or size.Y < 1 then
		local camera = workspace.CurrentCamera
		size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	end
	return size
end

function Window:_buildLauncher()
	local scope = self.Scope
	self._launcher = Utility.Create("TextButton", {
		Name = "Launcher",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 0,
		Visible = false,
		Parent = self.Gui,
	})
	scope:Bind(self._launcher, { BackgroundColor3 = "Surface" })
	Utility.Corner(self._launcher, 12)
	scope:Bind(Utility.Stroke(self._launcher, 1), { Color = "Border" })

	local icon = Icons.Create(self._launcher, "settings", 22, Color3.new(1, 1, 1))
	icon.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Frame.Position = UDim2.fromScale(0.5, 0.5)
	scope:Watch(function(colors, animated)
		icon:SetColor(colors.Text, animated)
	end)

	local moved = false
	local startPosition = Vector2.zero
	Utility.Drag(self._launcher, self.Janitor, {
		Began = function()
			moved = false
			local launcher = self._launcher
			startPosition = launcher.AbsolutePosition - self.Gui.AbsolutePosition
			launcher.AnchorPoint = Vector2.zero
			launcher.Position = UDim2.fromOffset(startPosition.X, startPosition.Y)
		end,
		Changed = function(_, delta)
			if not moved and delta.Magnitude < 6 then
				return
			end
			moved = true
			local viewport = self.Gui.AbsoluteSize
			local launcher = self._launcher
			local x = math.clamp(startPosition.X + delta.X, 0, math.max(viewport.X - launcher.AbsoluteSize.X, 0))
			local y = math.clamp(startPosition.Y + delta.Y, 0, math.max(viewport.Y - launcher.AbsoluteSize.Y, 0))
			launcher.Position = UDim2.fromOffset(x, y)
		end,
	})

	self.Janitor:Add(self._launcher.Activated:Connect(function()
		if moved then
			return
		end
		self:Open()
	end))
end

function Window:_applyLayout()
	local compact = self._current.X < Metrics.CompactBreakpoint
	if compact == self._compact then
		return
	end
	self._compact = compact
	local width = compact and Metrics.SidebarCompactWidth or Metrics.SidebarWidth
	self.Sidebar.Size = UDim2.new(0, width, 1, 0)
	self.Divider.Position = UDim2.new(0, width, 0, 0)
	self.Content.Position = UDim2.new(0, width + 1, 0, 0)
	self.Content.Size = UDim2.new(1, -(width + 1), 1, 0)
end

function Window:_fit()
	local config = self._config
	local viewport = self:_viewport()
	local limitX = viewport.X * Metrics.ScreenFraction
	local limitY = viewport.Y * Metrics.ScreenFraction
	local wantX = math.max(self._size.X, Metrics.MinWindowSize.X)
	local wantY = math.max(self._size.Y, Metrics.MinWindowSize.Y)

	local fit = 1
	if config.AutoScale then
		fit = math.clamp(math.min(limitX / wantX, limitY / wantY, 1), config.MinScale, 1)
	end
	self._fitScale = fit
	self._scale.Scale = self._open and fit or 0.96 * fit

	local maxX = math.huge
	local maxY = math.huge
	if config.FitToScreen then
		maxX = limitX / fit
		maxY = limitY / fit
	end
	local width = math.min(wantX, maxX)
	local height = math.min(wantY, maxY)
	self._current = Vector2.new(math.floor(width), math.floor(height))
	self.Root.Size = UDim2.fromOffset(self._current.X, self._current.Y)
	self:_applyLayout()
	self:_clamp()
end

function Window:_clamp()
	if self._config.ClampToScreen then
		local viewport = self:_viewport()
		local halfWidth = self._current.X * self._fitScale / 2
		local halfHeight = self._current.Y * self._fitScale / 2
		local limitX = math.max(viewport.X / 2 + halfWidth - 96, 1)
		local minY = -viewport.Y / 2 + halfHeight
		local maxY = math.max(viewport.Y / 2 - Metrics.TopBarHeight + halfHeight, minY)
		self._offset = Vector2.new(
			math.clamp(self._offset.X, -limitX, limitX),
			math.clamp(self._offset.Y, minY, maxY)
		)
	end
	self.Root.Position = UDim2.new(0.5, self._offset.X, 0.5, self._offset.Y)
end

function Window:ResetPosition()
	self._offset = Vector2.zero
	self:_clamp()
end

function Window:CreateTab(config)
	local tab = Tab.new(self, config or {})
	table.insert(self.Tabs, tab)
	if not self.Navigation.Selected then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	self.Navigation:Select(tab.Item)
end

function Window:Open()
	if self._open then
		return
	end
	self._open = true
	self._token = self._token + 1
	if not self.Root.Visible then
		self._scale.Scale = 0.96 * self._fitScale
		self.Frame.GroupTransparency = 1
		self._outlineStroke.Transparency = 1
		self.Root.Visible = true
	end
	if self._launcher then
		self._launcher.Visible = false
	end
	Animation.Tween(self._scale, "Window", { Scale = self._fitScale })
	Animation.Tween(self.Frame, "Window", { GroupTransparency = 0 })
	Animation.Tween(self._outlineStroke, "Window", { Transparency = 0 })
end

function Window:Close()
	if not self._open then
		return
	end
	self._open = false
	self.Overlay:Dismiss()
	self._token = self._token + 1
	local token = self._token
	Animation.Tween(self._scale, "Window", { Scale = 0.96 * self._fitScale })
	Animation.Tween(self._outlineStroke, "Window", { Transparency = 1 })
	local fade = Animation.Tween(self.Frame, "Window", { GroupTransparency = 1 })
	fade.Completed:Once(function()
		if token == self._token then
			self.Root.Visible = false
		end
	end)
	if self._launcher then
		self._launcher.Visible = true
	end
	Utility.SafeCall(self._config.OnClose)
	if self._config.DestroyOnClose then
		task.delay(Constants.Durations.Window + 0.05, function()
			if token == self._token then
				self:Destroy()
			end
		end)
	end
end

function Window:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

function Window:IsOpen()
	return self._open
end

function Window:SetTitle(text)
	self.TitleLabel.Text = text
end

function Window:SetToggleKey(keyCode)
	self._toggleKey = keyCode
end

function Window:GetToggleKey()
	return self._toggleKey
end

function Window:SetKeybindListening(state)
	if state then
		self._listening = true
	else
		task.defer(function()
			self._listening = false
		end)
	end
end

function Window:Notify(config)
	return self.Library:Notify(config)
end

function Window:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self.Janitor:Destroy()
	self.Library:_removeWindow(self)
end

return Window
