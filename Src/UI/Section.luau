local import = ...

local Constants = import("Core/Constants")
local Utility = import("Core/Utility")

local TextSizes = Constants.TextSizes

local Section = {}
Section.__index = Section

function Section.new(tab, config)
	config = Utility.Merge({ Name = "Section" }, config)

	local self = setmetatable({}, Section)
	self.Tab = tab
	self.Window = tab.Window
	self.Janitor = tab.Janitor
	self.Scope = tab.Scope
	self.Name = config.Name
	self._order = 0
	self._entries = {}
	self._searchName = string.lower(config.Name)

	local scope = self.Scope

	self.Frame = Utility.Create("Frame", {
		Name = "Section_" .. config.Name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = tab:NextOrder(),
		Parent = tab.Scroll,
	})
	Utility.List(self.Frame, 0)

	local header = Utility.Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = self.Frame,
	})
	Utility.Padding(header, 18, 0, 0, 0)
	Utility.List(header, 6)

	local title = Utility.Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		Text = config.Name,
		FontFace = Constants.Fonts.SemiBold,
		TextSize = TextSizes.Header,
		LayoutOrder = 1,
		Parent = header,
	})
	scope:Bind(title, { TextColor3 = "TextSecondary" })

	local hasDescription = config.Description ~= nil and config.Description ~= ""
	self.DescriptionLabel = Utility.Create("TextLabel", {
		Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Description or "",
		TextSize = TextSizes.Small,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = hasDescription,
		LayoutOrder = 2,
		Parent = header,
	})
	scope:Bind(self.DescriptionLabel, { TextColor3 = "TextMuted" })

	local line = Utility.Create("Frame", {
		Name = "Line",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0,
		LayoutOrder = 3,
		Parent = header,
	})
	scope:Bind(line, { BackgroundColor3 = "Border" })

	self.Container = Utility.Create("Frame", {
		Name = "Container",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = self.Frame,
	})
	Utility.List(self.Container, 0)

	return self
end

function Section.RegisterComponent(name, module)
	Section["Create" .. name] = function(self, config)
		return module.new(self, config or {})
	end
end

function Section:NextOrder()
	self._order = self._order + 1
	return self._order
end

function Section:CreateContext()
	return self.Tab:CreateContext()
end

function Section:AddEntry(frame, terms)
	table.insert(self._entries, { Frame = frame, Terms = string.lower(terms) })
end

function Section:HasMatch(query)
	if string.find(self._searchName, query, 1, true) then
		return true
	end
	for _, entry in ipairs(self._entries) do
		if string.find(entry.Terms, query, 1, true) then
			return true
		end
	end
	return false
end

function Section:Filter(query, forceShow)
	local sectionMatch = forceShow or query == "" or string.find(self._searchName, query, 1, true) ~= nil
	local any = false
	for _, entry in ipairs(self._entries) do
		local show = sectionMatch or string.find(entry.Terms, query, 1, true) ~= nil
		entry.Frame.Visible = show
		if show then
			any = true
		end
	end
	self.Frame.Visible = any or sectionMatch
end

function Section:SetDescription(text)
	self.DescriptionLabel.Text = text or ""
	self.DescriptionLabel.Visible = text ~= nil and text ~= ""
end

function Section:Destroy()
	self.Frame:Destroy()
end

return Section
