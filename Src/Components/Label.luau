local import = ...

local Constants = import("Core/Constants")
local Utility = import("Core/Utility")

local TextSizes = Constants.TextSizes

local Label = {}
Label.__index = Label

local alignments = {
	Left = Enum.TextXAlignment.Left,
	Center = Enum.TextXAlignment.Center,
	Right = Enum.TextXAlignment.Right,
}

function Label.new(section, config)
	config = Utility.Merge({
		Text = "Label",
		TextSize = TextSizes.Body,
		Weight = "Regular",
		Color = "TextSecondary",
		Alignment = "Left",
	}, config)
	local context = section:CreateContext()
	local scope = context.Scope

	local frame = Utility.Create("Frame", {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = section:NextOrder(),
		Parent = section.Container,
	})
	Utility.Padding(frame, 10, 0, 10, 0)

	local label = Utility.Create("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Text,
		FontFace = Constants.Fonts[config.Weight] or Constants.Fonts.Regular,
		TextSize = config.TextSize,
		TextWrapped = true,
		TextXAlignment = alignments[config.Alignment] or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = frame,
	})

	local self = setmetatable({}, Label)
	self.Frame = frame
	self._label = label
	self._context = context
	self:SetColor(config.Color)

	section:AddEntry(frame, config.Text)
	return self
end

function Label:SetColor(color)
	if typeof(color) == "Color3" then
		self._label.TextColor3 = color
	else
		self._context.Scope:Bind(self._label, { TextColor3 = color })
	end
end

function Label:SetText(text)
	self._label.Text = text
end

function Label:Destroy()
	self._context.Janitor:Destroy()
	self._context.Scope:Destroy()
	self.Frame:Destroy()
end

return Label
