local import = ...

local Constants = import("Core/Constants")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Utility = {}

local textClasses = {
	TextLabel = true,
	TextButton = true,
	TextBox = true,
}

local defaults = {
	Frame = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	},
	CanvasGroup = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	},
	TextLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Text = "",
		TextSize = Constants.TextSizes.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	TextButton = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		TextSize = Constants.TextSizes.Body,
	},
	TextBox = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Text = "",
		ClearTextOnFocus = false,
		TextSize = Constants.TextSizes.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	ImageLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	},
	ImageButton = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
	},
	ScrollingFrame = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
	},
}

function Utility.Create(className, properties, children)
	local instance = Instance.new(className)
	local classDefaults = defaults[className]
	if classDefaults then
		for property, value in pairs(classDefaults) do
			instance[property] = value
		end
	end
	if textClasses[className] then
		instance.FontFace = Constants.Fonts.Regular
	end
	local parent = nil
	if properties then
		for property, value in pairs(properties) do
			if property == "Parent" then
				parent = value
			else
				instance[property] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Utility.Corner(parent, radius)
	return Utility.Create("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

function Utility.Stroke(parent, thickness, transparency)
	return Utility.Create("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Utility.Padding(parent, top, right, bottom, left)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

function Utility.List(parent, padding, options)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 0)
	if options then
		for property, value in pairs(options) do
			layout[property] = value
		end
	end
	layout.Parent = parent
	return layout
end

function Utility.Merge(base, overrides)
	local result = {}
	for key, value in pairs(base) do
		result[key] = value
	end
	if overrides then
		for key, value in pairs(overrides) do
			result[key] = value
		end
	end
	return result
end

function Utility.Round(value, step)
	step = step or 1
	if step <= 0 then
		return value
	end
	local rounded = math.floor(value / step + 0.5) * step
	return tonumber(string.format("%.6f", rounded))
end

function Utility.FormatNumber(value)
	local text = string.format("%.4f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

function Utility.Normalize(text)
	local lowered = string.lower(tostring(text or ""))
	lowered = string.gsub(lowered, "^%s+", "")
	lowered = string.gsub(lowered, "%s+$", "")
	return lowered
end

function Utility.Contains(haystack, needle)
	return string.find(string.lower(tostring(haystack or "")), needle, 1, true) ~= nil
end

function Utility.KeyName(keyCode)
	if keyCode == nil or keyCode == Enum.KeyCode.Unknown then
		return "None"
	end
	local spaced = string.gsub(keyCode.Name, "(%l)(%u)", "%1 %2")
	return spaced
end

function Utility.SafeCall(callback, ...)
	if type(callback) == "function" then
		task.spawn(callback, ...)
	end
end

function Utility.GetGuiParent()
	local player = Players.LocalPlayer
	assert(player, "RobloxUI must be required from a client script")
	return player:WaitForChild("PlayerGui")
end

function Utility.IsPrimaryInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.Interact(button, janitor, handlers)
	local pressing = false

	janitor:Add(button.MouseEnter:Connect(function()
		if handlers.Hover then
			handlers.Hover(true)
		end
	end))

	janitor:Add(button.MouseLeave:Connect(function()
		if handlers.Hover then
			handlers.Hover(false)
		end
		if pressing then
			pressing = false
			if handlers.Press then
				handlers.Press(false)
			end
		end
	end))

	janitor:Add(button.InputBegan:Connect(function(input)
		if Utility.IsPrimaryInput(input) then
			pressing = true
			if handlers.Press then
				handlers.Press(true)
			end
		end
	end))

	janitor:Add(button.InputEnded:Connect(function(input)
		if not Utility.IsPrimaryInput(input) then
			return
		end
		if pressing then
			pressing = false
			if handlers.Press then
				handlers.Press(false)
			end
		end
		if input.UserInputType == Enum.UserInputType.Touch and handlers.Hover then
			handlers.Hover(false)
		end
	end))

	if handlers.Click then
		janitor:Add(button.Activated:Connect(function()
			handlers.Click()
		end))
	end
end

function Utility.Drag(handle, janitor, callbacks)
	local active = false
	local origin = Vector2.zero

	janitor:Add(handle.InputBegan:Connect(function(input)
		if active or not Utility.IsPrimaryInput(input) then
			return
		end
		active = true
		origin = Vector2.new(input.Position.X, input.Position.Y)
		if callbacks.Began then
			callbacks.Began(origin)
		end
	end))

	janitor:Add(UserInputService.InputChanged:Connect(function(input)
		if not active then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local position = Vector2.new(input.Position.X, input.Position.Y)
		if callbacks.Changed then
			callbacks.Changed(position, position - origin)
		end
	end))

	janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if not active or not Utility.IsPrimaryInput(input) then
			return
		end
		active = false
		if callbacks.Ended then
			callbacks.Ended()
		end
	end))
end

return Utility
