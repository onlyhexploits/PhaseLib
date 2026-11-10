local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Row = {}

function Row.Build(section, config)
	local context = section:CreateContext()
	local scope = context.Scope
	local janitor = context.Janitor
	local name = config.Name or "Row"
	local description = config.Description
	local controlWidth = config.ControlWidth or 0

	local frame = Utility.Create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, Metrics.RowHeight),
		LayoutOrder = section:NextOrder(),
		Parent = section.Container,
	})

	local reserve = 0
	if controlWidth > 0 then
		reserve = controlWidth + 20
	end

	local column = Utility.Create("Frame", {
		Name = "Text",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, -reserve, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	Utility.List(column, 2)

	local title = Utility.Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = name,
		TextSize = TextSizes.Body,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		Parent = column,
	})
	scope:Bind(title, { TextColor3 = "Text" })

	local descriptionLabel = Utility.Create("TextLabel", {
		Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = description or "",
		TextSize = TextSizes.Small,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = description ~= nil and description ~= "",
		LayoutOrder = 2,
		Parent = column,
	})
	scope:Bind(descriptionLabel, { TextColor3 = "TextSecondary" })

	local control = nil
	if controlWidth > 0 then
		control = Utility.Create("Frame", {
			Name = "Control",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0, controlWidth, 1, 0),
			Parent = frame,
		})
	end

	local separator = Utility.Create("Frame", {
		Name = "Separator",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.3,
		Parent = frame,
	})
	scope:Bind(separator, { BackgroundColor3 = "Border" })

	local shield = Utility.Create("TextButton", {
		Name = "Shield",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = frame,
	})
	scope:Bind(shield, { BackgroundColor3 = "Window" })

	local function measure()
		local needed = column.AbsoluteSize.Y + Metrics.RowPadding * 2
		frame.Size = UDim2.new(1, 0, 0, math.max(Metrics.RowHeight, needed))
	end
	janitor:Add(column:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure))
	task.defer(measure)

	section:AddEntry(frame, name .. " " .. (description or ""))

	return {
		Frame = frame,
		Title = title,
		Description = descriptionLabel,
		Control = control,
		Separator = separator,
		Shield = shield,
		Janitor = janitor,
		Scope = scope,
		Disabled = false,
	}
end

function Row.SetDisabled(refs, disabled)
	refs.Disabled = disabled
	local shield = refs.Shield
	if disabled then
		shield.Visible = true
		Animation.Tween(shield, "Hover", { BackgroundTransparency = 0.45 })
	else
		local tween = Animation.Tween(shield, "Hover", { BackgroundTransparency = 1 })
		tween.Completed:Once(function()
			if not refs.Disabled then
				shield.Visible = false
			end
		end)
	end
end

function Row.SetTitle(refs, text)
	refs.Title.Text = text
end

function Row.SetDescription(refs, text)
	refs.Description.Text = text or ""
	refs.Description.Visible = text ~= nil and text ~= ""
end

return Row
