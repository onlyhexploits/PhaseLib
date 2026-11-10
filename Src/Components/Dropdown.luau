local import = ...

local Constants = import("Core/Constants")
local Janitor = import("Core/Janitor")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Icons = import("Core/Icons")
local Row = import("UI/Row")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Dropdown = {}
Dropdown.__index = Dropdown

local function build(section, config)
	local refs = Row.Build(section, {
		Name = config.Name,
		Description = config.Description,
		ControlWidth = config.Width,
	})

	refs.Button = Utility.Create("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(config.Width, Metrics.ControlHeight),
		BackgroundTransparency = 0,
		Parent = refs.Control,
	})
	Utility.Corner(refs.Button, Metrics.ControlRadius)
	refs.ButtonStroke = Utility.Stroke(refs.Button, 1, 0.5)

	refs.Label = Utility.Create("TextLabel", {
		Name = "Value",
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -42, 1, 0),
		TextSize = TextSizes.Control,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = refs.Button,
	})

	refs.Chevron = Icons.Create(refs.Button, "chevron-down", 16, Color3.new(1, 1, 1))
	refs.Chevron.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	refs.Chevron.Frame.Position = UDim2.new(1, -18, 0.5, 0)

	refs.Popup = Utility.Create("Frame", {
		Name = "Dropdown",
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	})
	Utility.Corner(refs.Popup, Metrics.PopupRadius)
	refs.PopupStroke = Utility.Stroke(refs.Popup, 1)

	refs.List = Utility.Create("ScrollingFrame", {
		Name = "Options",
		ScrollBarThickness = 3,
		Parent = refs.Popup,
	})
	Utility.Padding(refs.List, Metrics.PopupPadding, Metrics.PopupPadding, Metrics.PopupPadding, Metrics.PopupPadding)
	Utility.List(refs.List, 2)

	return refs
end

function Dropdown.new(section, config)
	config = Utility.Merge({
		Name = "Dropdown",
		Options = {},
		Width = 148,
		Disabled = false,
	}, config)
	local refs = build(section, config)

	local self = setmetatable({}, Dropdown)
	self.Frame = refs.Frame
	self.Options = {}
	self.Value = nil
	self._refs = refs
	self._width = config.Width
	self._window = section.Window
	self._callback = config.Callback
	self._optionsJanitor = Janitor.new()
	refs.Janitor:Add(self._optionsJanitor)
	self._items = {}
	self._open = false
	self._hover = false
	self._press = false

	for _, option in ipairs(config.Options) do
		table.insert(self.Options, tostring(option))
	end
	if config.Default ~= nil and table.find(self.Options, tostring(config.Default)) then
		self.Value = tostring(config.Default)
	else
		self.Value = self.Options[1]
	end

	Utility.Interact(refs.Button, refs.Janitor, {
		Hover = function(state)
			self._hover = state
			self:_render(true)
		end,
		Press = function(state)
			self._press = state
			self:_render(true)
		end,
		Click = function()
			if self._open then
				self:Close()
			else
				self:Open()
			end
		end,
	})

	self:_buildOptions()
	refs.Scope:Watch(function(_, animated)
		self:_render(animated)
	end)

	if config.Disabled then
		self:SetDisabled(true)
	end

	return self
end

function Dropdown:_popupHeight()
	local count = #self.Options
	local visible = math.min(count, Metrics.PopupMaxOptions)
	return visible * Metrics.OptionHeight + math.max(visible - 1, 0) * 2 + Metrics.PopupPadding * 2
end

function Dropdown:_buildOptions()
	local refs = self._refs
	self._optionsJanitor:Cleanup()
	for _, child in ipairs(refs.List:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._items = {}

	for index, option in ipairs(self.Options) do
		local button = Utility.Create("TextButton", {
			Name = option,
			Size = UDim2.new(1, 0, 0, Metrics.OptionHeight),
			LayoutOrder = index,
			Parent = refs.List,
		})
		Utility.Corner(button, 6)

		local label = Utility.Create("TextLabel", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -36, 1, 0),
			Text = option,
			TextSize = TextSizes.Control,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = button,
		})

		local check = Icons.Create(button, "check", 14, Color3.new(1, 1, 1))
		check.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		check.Frame.Position = UDim2.new(1, -16, 0.5, 0)

		local item = { Button = button, Label = label, Check = check, Option = option, Hover = false }
		Utility.Interact(button, self._optionsJanitor, {
			Hover = function(state)
				item.Hover = state
				self:_renderItem(item, true)
			end,
			Click = function()
				self:Close()
				self:Set(option)
			end,
		})
		self._items[index] = item
		self:_renderItem(item, false)
	end
end

function Dropdown:_renderItem(item, animated)
	local colors = self._refs.Scope:Colors()
	local selected = item.Option == self.Value
	local background = colors.Hover
	local transparency = 1
	local foreground = colors.TextSecondary

	if item.Hover then
		transparency = 0
		foreground = colors.Text
	elseif selected then
		background = colors.Selected
		transparency = 0.35
		foreground = colors.Text
	end

	Animation.Set(item.Button, "Hover", {
		BackgroundColor3 = background,
		BackgroundTransparency = transparency,
	}, animated)
	Animation.Set(item.Label, "Hover", { TextColor3 = foreground }, animated)
	item.Check.Frame.Visible = selected
	item.Check:SetColor(colors.Text, false)
end

function Dropdown:_render(animated)
	local refs = self._refs
	local colors = refs.Scope:Colors()
	local background = colors.Surface
	if self._press then
		background = colors.Selected
	elseif self._hover or self._open then
		background = colors.Hover
	end

	Animation.Set(refs.Button, "Hover", { BackgroundColor3 = background }, animated)
	Animation.Set(refs.ButtonStroke, "Hover", { Color = colors.Border }, animated)
	Animation.Set(refs.Label, "Hover", { TextColor3 = colors.Text }, animated)
	refs.Chevron:SetColor(colors.TextSecondary, animated)
	refs.Label.Text = self.Value or ""

	refs.Popup.BackgroundColor3 = colors.Surface
	refs.PopupStroke.Color = colors.Border
	refs.List.ScrollBarImageColor3 = colors.Selected

	for _, item in ipairs(self._items) do
		self:_renderItem(item, animated)
	end
end

function Dropdown:Open()
	if self._open or self._refs.Disabled or #self.Options == 0 then
		return
	end
	self._open = true

	local refs = self._refs
	local width = math.max(self._width, 150)
	local height = self:_popupHeight()

	refs.Popup.Size = UDim2.fromOffset(width, 0)
	local direction, fittedHeight = self._window.Overlay:Open(self, refs.Button, refs.Popup, Vector2.new(width, height), 6)
	height = fittedHeight

	if direction == "Up" then
		refs.List.AnchorPoint = Vector2.new(0, 1)
		refs.List.Position = UDim2.fromScale(0, 1)
	else
		refs.List.AnchorPoint = Vector2.new(0, 0)
		refs.List.Position = UDim2.fromScale(0, 0)
	end
	refs.List.Size = UDim2.new(1, 0, 0, height)

	Animation.Tween(refs.Popup, "Dropdown", { Size = UDim2.fromOffset(width, height) })
	Animation.Tween(refs.Chevron.Frame, "Dropdown", { Rotation = 180 })
	self:_render(true)
end

function Dropdown:Close()
	if not self._open then
		return
	end
	self._open = false

	local refs = self._refs
	self._window.Overlay:Release(self)

	local tween = Animation.Tween(refs.Popup, "Dropdown", { Size = UDim2.fromOffset(refs.Popup.Size.X.Offset, 0) })
	tween.Completed:Once(function()
		if not self._open then
			refs.Popup.Parent = nil
		end
	end)
	Animation.Tween(refs.Chevron.Frame, "Dropdown", { Rotation = 0 })
	self:_render(true)
end

function Dropdown:Set(value, silent)
	value = tostring(value)
	if value == self.Value or not table.find(self.Options, value) then
		return
	end
	self.Value = value
	self:_render(true)
	if not silent then
		Utility.SafeCall(self._callback, value)
	end
end

function Dropdown:Get()
	return self.Value
end

function Dropdown:SetOptions(options, default)
	self.Options = {}
	for _, option in ipairs(options) do
		table.insert(self.Options, tostring(option))
	end
	if default ~= nil and table.find(self.Options, tostring(default)) then
		self.Value = tostring(default)
	elseif not (self.Value and table.find(self.Options, self.Value)) then
		self.Value = self.Options[1]
	end
	self:_buildOptions()
	self:_render(false)
end

function Dropdown:SetDisabled(disabled)
	if disabled then
		self:Close()
	end
	Row.SetDisabled(self._refs, disabled)
end

function Dropdown:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Dropdown:Destroy()
	self:Close()
	self._refs.Popup:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Dropdown
