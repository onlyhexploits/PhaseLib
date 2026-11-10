local import = ...

local Constants = import("Core/Constants")
local Utility = import("Core/Utility")

local TextSizes = Constants.TextSizes

local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(section, config)
	config = Utility.Merge({ Title = "", Content = "", RichText = false }, config)
	local context = section:CreateContext()
	local scope = context.Scope

	local frame = Utility.Create("Frame", {
		Name = "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:NextOrder(),
		Parent = section.Container,
	})
	Utility.Padding(frame, 8, 0, 8, 0)

	local card = Utility.Create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		Parent = frame,
	})
	scope:Bind(card, { BackgroundColor3 = "Surface" })
	Utility.Corner(card, 10)
	scope:Bind(Utility.Stroke(card, 1, 0.5), { Color = "Border" })
	Utility.Padding(card, 14, 16, 14, 16)
	Utility.List(card, 6)

	local title = Utility.Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Title,
		FontFace = Constants.Fonts.Medium,
		TextSize = TextSizes.Body,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = config.Title ~= "",
		LayoutOrder = 1,
		Parent = card,
	})
	scope:Bind(title, { TextColor3 = "Text" })

	local content = Utility.Create("TextLabel", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Content,
		RichText = config.RichText,
		TextSize = TextSizes.Control,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		Parent = card,
	})
	scope:Bind(content, { TextColor3 = "TextSecondary" })

	section:AddEntry(frame, config.Title .. " " .. config.Content)

	local self = setmetatable({}, Paragraph)
	self.Frame = frame
	self._title = title
	self._content = content
	self._context = context
	return self
end

function Paragraph:SetTitle(text)
	self._title.Text = text
	self._title.Visible = text ~= ""
end

function Paragraph:SetContent(text)
	self._content.Text = text
end

function Paragraph:Destroy()
	self._context.Janitor:Destroy()
	self._context.Scope:Destroy()
	self.Frame:Destroy()
end

return Paragraph
