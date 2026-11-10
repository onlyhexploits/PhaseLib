local import = ...

local Constants = import("Core/Constants")
local Janitor = import("Core/Janitor")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Segmented = import("UI/Segmented")
local Section = import("UI/Section")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Tab = {}
Tab.__index = Tab

function Tab.new(window, config)
	config = Utility.Merge({ Name = "Tab" }, config)

	local self = setmetatable({}, Tab)
	self.Window = window
	self.Janitor = window.Janitor
	self.Scope = window.Scope
	self.Name = config.Name
	self.Sections = {}
	self._order = 0
	self._searchName = string.lower(config.Name)

	local scope = self.Scope
	local padding = Metrics.PagePadding
	local hasDescription = config.Description ~= nil and config.Description ~= ""

	self.Page = Utility.Create("CanvasGroup", {
		Name = "Page_" .. config.Name,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		Visible = false,
		Parent = window.Content,
	})

	self.Header = Utility.Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Metrics.PageHeaderHeight),
		Parent = self.Page,
	})

	self.TitleLabel = Utility.Create("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, padding, 0.5, hasDescription and -10 or 0),
		Size = UDim2.new(1, -(padding * 2 + 180), 0, 28),
		Text = config.Title or config.Name,
		FontFace = Constants.Fonts.SemiBold,
		TextSize = TextSizes.PageTitle,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Header,
	})
	scope:Bind(self.TitleLabel, { TextColor3 = "Text" })

	self.DescriptionLabel = Utility.Create("TextLabel", {
		Name = "Description",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, padding, 0.5, 14),
		Size = UDim2.new(1, -(padding * 2 + 180), 0, 18),
		Text = config.Description or "",
		TextSize = TextSizes.Small,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = hasDescription,
		Parent = self.Header,
	})
	scope:Bind(self.DescriptionLabel, { TextColor3 = "TextSecondary" })

	self.HeaderControls = Utility.Create("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -padding, 0.5, 0),
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		Parent = self.Header,
	})
	Utility.List(self.HeaderControls, 8, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})

	self.Scroll = Utility.Create("ScrollingFrame", {
		Name = "Scroll",
		Position = UDim2.fromOffset(0, Metrics.PageHeaderHeight),
		Size = UDim2.new(1, 0, 1, -Metrics.PageHeaderHeight),
		Parent = self.Page,
	})
	scope:Bind(self.Scroll, { ScrollBarImageColor3 = "Selected" })
	Utility.Padding(self.Scroll, 0, padding, 24, padding)
	Utility.List(self.Scroll, 0)

	self.Item = window.Navigation:AddItem({
		Name = config.Name,
		Icon = config.Icon,
		Group = config.Group,
		Page = self,
	})

	return self
end

function Tab:NextOrder()
	self._order = self._order + 1
	return self._order
end

function Tab:CreateContext()
	local janitor = Janitor.new()
	local scope = self.Scope:Child()
	self.Janitor:Add(janitor)
	janitor:Add(scope)
	return { Janitor = janitor, Scope = scope }
end

function Tab:CreateSection(config)
	local section = Section.new(self, config)
	table.insert(self.Sections, section)
	return section
end

function Tab:CreateSegmented(config)
	return Segmented.new(self, config or {})
end

function Tab:SetTitle(text)
	self.TitleLabel.Text = text
end

function Tab:SetDescription(text)
	self.DescriptionLabel.Text = text or ""
	self.DescriptionLabel.Visible = text ~= nil and text ~= ""
	self.TitleLabel.Position = UDim2.new(0, Metrics.PagePadding, 0.5, self.DescriptionLabel.Visible and -10 or 0)
end

function Tab:Select()
	self.Window:SelectTab(self)
end

function Tab:Show(animated)
	self.Page.Visible = true
	if animated then
		self.Page.GroupTransparency = 1
		self.Page.Position = UDim2.fromOffset(0, 8)
		Animation.Tween(self.Page, "Tab", {
			GroupTransparency = 0,
			Position = UDim2.fromOffset(0, 0),
		})
	else
		self.Page.GroupTransparency = 0
		self.Page.Position = UDim2.fromOffset(0, 0)
	end
end

function Tab:Hide()
	self.Page.Visible = false
end

function Tab:HasMatch(query)
	if string.find(self._searchName, query, 1, true) then
		return true
	end
	for _, section in ipairs(self.Sections) do
		if section:HasMatch(query) then
			return true
		end
	end
	return false
end

function Tab:Filter(query)
	local tabMatch = query == "" or string.find(self._searchName, query, 1, true) ~= nil
	for _, section in ipairs(self.Sections) do
		section:Filter(query, tabMatch)
	end
end

return Tab
