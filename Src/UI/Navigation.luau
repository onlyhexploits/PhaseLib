local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Icons = import("Core/Icons")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Navigation = {}
Navigation.__index = Navigation

function Navigation.new(window, parent, onSelect)
	local self = setmetatable({}, Navigation)
	self.Window = window
	self.Scope = window.Scope
	self.Janitor = window.Janitor
	self.Items = {}
	self.Groups = {}
	self.Selected = nil
	self._onSelect = onSelect
	self._focused = false

	local scope = self.Scope
	local janitor = self.Janitor
	local searchTop = 14
	local listTop = searchTop + Metrics.SearchHeight + 10

	self.SearchFrame = Utility.Create("Frame", {
		Name = "Search",
		Position = UDim2.fromOffset(12, searchTop),
		Size = UDim2.new(1, -24, 0, Metrics.SearchHeight),
		BackgroundTransparency = 0,
		Parent = parent,
	})
	scope:Bind(self.SearchFrame, { BackgroundColor3 = "Surface" })
	Utility.Corner(self.SearchFrame, 10)
	self._searchStroke = Utility.Stroke(self.SearchFrame, 1)

	self._searchIcon = Icons.Create(self.SearchFrame, "search", 16, Color3.new(1, 1, 1))
	self._searchIcon.Frame.AnchorPoint = Vector2.new(0, 0.5)
	self._searchIcon.Frame.Position = UDim2.new(0, 12, 0.5, 0)

	self.SearchBox = Utility.Create("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -50, 1, 0),
		PlaceholderText = "Search…",
		TextSize = TextSizes.Body,
		Parent = self.SearchFrame,
	})
	scope:Bind(self.SearchBox, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })

	self.Scroll = Utility.Create("ScrollingFrame", {
		Name = "Items",
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -listTop),
		ScrollBarThickness = 3,
		Parent = parent,
	})
	scope:Bind(self.Scroll, { ScrollBarImageColor3 = "Selected" })
	Utility.Padding(self.Scroll, 4, 12, 14, 12)
	Utility.List(self.Scroll, 2)

	self.Empty = Utility.Create("TextLabel", {
		Name = "Empty",
		Size = UDim2.new(1, 0, 0, 40),
		Text = "No results",
		TextSize = TextSizes.Control,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		LayoutOrder = 1000000,
		Parent = self.Scroll,
	})
	scope:Bind(self.Empty, { TextColor3 = "TextMuted" })

	local function renderSearch(animated)
		local colors = scope:Colors()
		local strokeColor = colors.Border
		local iconColor = colors.TextMuted
		if self._focused then
			strokeColor = colors.TextMuted
			iconColor = colors.TextSecondary
		end
		Animation.Set(self._searchStroke, "Hover", { Color = strokeColor }, animated)
		self._searchIcon:SetColor(iconColor, animated)
	end

	janitor:Add(self.SearchBox.Focused:Connect(function()
		self._focused = true
		renderSearch(true)
	end))

	janitor:Add(self.SearchBox.FocusLost:Connect(function(enterPressed)
		self._focused = false
		renderSearch(true)
		if enterPressed then
			self:_selectFirstVisible()
		end
	end))

	janitor:Add(self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:Search(self.SearchBox.Text)
	end))

	scope:Watch(function(_, animated)
		renderSearch(animated)
		for _, item in ipairs(self.Items) do
			self:_render(item, animated)
		end
	end)

	return self
end

function Navigation:_group(name)
	name = name or ""
	for _, group in ipairs(self.Groups) do
		if group.Name == name then
			return group
		end
	end

	local scope = self.Scope
	local index = #self.Groups + 1
	local group = { Name = name, Index = index, Items = {} }

	if index > 1 then
		local separator = Utility.Create("Frame", {
			Name = "Separator",
			Size = UDim2.new(1, 0, 0, 19),
			LayoutOrder = index * 1000 - 1,
			Parent = self.Scroll,
		})
		local lineFrame = Utility.Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.new(1, -12, 0, 1),
			BackgroundTransparency = 0,
			Parent = separator,
		})
		scope:Bind(lineFrame, { BackgroundColor3 = "Border" })
		group.Separator = separator
	end

	if name ~= "" then
		local header = Utility.Create("TextLabel", {
			Name = "Header_" .. name,
			Size = UDim2.new(1, 0, 0, Metrics.NavHeaderHeight),
			Text = name,
			FontFace = Constants.Fonts.Medium,
			TextSize = TextSizes.Control,
			LayoutOrder = index * 1000,
			Parent = self.Scroll,
		})
		Utility.Padding(header, 0, 0, 0, 6)
		scope:Bind(header, { TextColor3 = "TextMuted" })
		group.Header = header
	end

	self.Groups[index] = group
	return group
end

function Navigation:AddItem(config)
	local group = self:_group(config.Group)
	local order = group.Index * 1000 + #group.Items + 1
	local hasIcon = config.Icon ~= nil

	local button = Utility.Create("TextButton", {
		Name = config.Name,
		Size = UDim2.new(1, 0, 0, Metrics.NavItemHeight),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = self.Scroll,
	})
	Utility.Corner(button, Metrics.ControlRadius)

	local item = {
		Name = config.Name,
		Page = config.Page,
		Group = group,
		Button = button,
		Selected = false,
		Hovered = false,
		Pressed = false,
		Visible = true,
	}

	if hasIcon then
		item.Icon = Icons.Create(button, config.Icon, 18, Color3.new(1, 1, 1))
		item.Icon.Frame.AnchorPoint = Vector2.new(0, 0.5)
		item.Icon.Frame.Position = UDim2.new(0, 12, 0.5, 0)
	end

	local labelOffset = hasIcon and 42 or 14
	item.Label = Utility.Create("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(labelOffset, 0),
		Size = UDim2.new(1, -(labelOffset + 8), 1, 0),
		Text = config.Name,
		TextSize = TextSizes.Body,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	table.insert(group.Items, item)
	table.insert(self.Items, item)

	Utility.Interact(button, self.Janitor, {
		Hover = function(state)
			item.Hovered = state
			self:_render(item, true)
		end,
		Press = function(state)
			item.Pressed = state
			self:_render(item, true)
		end,
		Click = function()
			self:Select(item)
		end,
	})

	self:_render(item, false)
	return item
end

function Navigation:_render(item, animated)
	local colors = self.Scope:Colors()
	local background = colors.Hover
	local transparency = 1
	local foreground = colors.Text:Lerp(colors.TextSecondary, 0.4)

	if item.Selected then
		background = colors.Selected
		transparency = 0
		foreground = colors.Text
	elseif item.Pressed then
		background = colors.Hover:Lerp(colors.Selected, 0.5)
		transparency = 0
		foreground = colors.Text
	elseif item.Hovered then
		background = colors.Hover
		transparency = 0
		foreground = colors.Text
	end

	Animation.Set(item.Button, "Hover", {
		BackgroundColor3 = background,
		BackgroundTransparency = transparency,
	}, animated)
	Animation.Set(item.Label, "Hover", { TextColor3 = foreground }, animated)
	if item.Icon then
		item.Icon:SetColor(foreground, animated)
	end
end

function Navigation:Select(item)
	if self.Selected == item then
		return
	end
	local previous = self.Selected
	self.Selected = item
	if previous then
		previous.Selected = false
		self:_render(previous, true)
	end
	item.Selected = true
	self:_render(item, previous ~= nil)
	if self._onSelect then
		self._onSelect(item, previous)
	end
end

function Navigation:_selectFirstVisible()
	for _, group in ipairs(self.Groups) do
		for _, item in ipairs(group.Items) do
			if item.Visible then
				self:Select(item)
				return
			end
		end
	end
end

function Navigation:Search(rawQuery)
	local query = Utility.Normalize(rawQuery)
	local any = false

	for _, item in ipairs(self.Items) do
		local match = query == "" or Utility.Contains(item.Name, query) or item.Page:HasMatch(query)
		item.Visible = match
		item.Button.Visible = match
		item.Page:Filter(query)
		if match then
			any = true
		end
	end

	local shownBefore = false
	for _, group in ipairs(self.Groups) do
		local groupVisible = false
		for _, item in ipairs(group.Items) do
			if item.Visible then
				groupVisible = true
				break
			end
		end
		if group.Header then
			group.Header.Visible = groupVisible
		end
		if group.Separator then
			group.Separator.Visible = groupVisible and shownBefore
		end
		if groupVisible then
			shownBefore = true
		end
	end

	self.Empty.Visible = not any

	if self.Selected and not self.Selected.Visible then
		self:_selectFirstVisible()
	end
end

return Navigation
