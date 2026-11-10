local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Row = import("UI/Row")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Input = {}
Input.__index = Input

local function build(section, config)
	local refs = Row.Build(section, {
		Name = config.Name,
		Description = config.Description,
		ControlWidth = config.Width,
	})
	refs.Box = Utility.Create("Frame", {
		Name = "Box",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(config.Width, Metrics.ControlHeight),
		BackgroundTransparency = 0,
		Parent = refs.Control,
	})
	Utility.Corner(refs.Box, Metrics.ControlRadius)
	refs.Stroke = Utility.Stroke(refs.Box, 1, 0.5)
	refs.TextBox = Utility.Create("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		PlaceholderText = config.Placeholder,
		ClearTextOnFocus = config.ClearOnFocus,
		Text = config.Default,
		TextSize = TextSizes.Control,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = refs.Box,
	})
	return refs
end

function Input.new(section, config)
	config = Utility.Merge({
		Name = "Input",
		Placeholder = "Enter text...",
		Default = "",
		ClearOnFocus = false,
		Width = 220,
		Live = false,
		Disabled = false,
	}, config)
	local refs = build(section, config)

	local self = setmetatable({}, Input)
	self.Frame = refs.Frame
	self.Value = config.Default
	self._refs = refs
	self._callback = config.Callback
	self._validate = config.Validate
	self._maxLength = config.MaxLength
	self._live = config.Live
	self._focused = false
	self._hover = false
	self._invalid = false

	Utility.Interact(refs.Box, refs.Janitor, {
		Hover = function(state)
			self._hover = state
			self:_render(true)
		end,
	})

	refs.Janitor:Add(refs.TextBox.Focused:Connect(function()
		self._focused = true
		self:_render(true)
	end))

	refs.Janitor:Add(refs.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = refs.TextBox.Text
		if self._maxLength and #text > self._maxLength then
			refs.TextBox.Text = string.sub(text, 1, self._maxLength)
			return
		end
		if self._live and self._focused then
			self:_commit(text, false)
		end
	end))

	refs.Janitor:Add(refs.TextBox.FocusLost:Connect(function(enterPressed)
		self._focused = false
		self:_commit(refs.TextBox.Text, enterPressed)
		self:_render(true)
	end))

	refs.Scope:Watch(function(_, animated)
		self:_render(animated)
	end)

	if config.Disabled then
		self:SetDisabled(true)
	end

	return self
end

function Input:_commit(text, enterPressed)
	if self._validate then
		local ok, result = pcall(self._validate, text)
		if not ok or result == false then
			self._refs.TextBox.Text = self.Value
			self:_flashInvalid()
			return
		end
	end
	if text == self.Value then
		return
	end
	self.Value = text
	Utility.SafeCall(self._callback, text, enterPressed)
end

function Input:_flashInvalid()
	self._invalid = true
	self:_render(true)
	task.delay(0.6, function()
		self._invalid = false
		if self._refs.Box.Parent then
			self:_render(true)
		end
	end)
end

function Input:_render(animated)
	local refs = self._refs
	local colors = refs.Scope:Colors()
	local strokeColor = colors.Border
	local strokeTransparency = 0.5
	local background = colors.Surface
	if self._invalid then
		strokeColor = colors.Error
		strokeTransparency = 0
	elseif self._focused then
		strokeColor = colors.TextMuted
		strokeTransparency = 0
	elseif self._hover then
		background = colors.Hover
	end
	Animation.Set(refs.Box, "Hover", { BackgroundColor3 = background }, animated)
	Animation.Set(refs.Stroke, "Hover", {
		Color = strokeColor,
		Transparency = strokeTransparency,
	}, animated)
	refs.TextBox.TextColor3 = colors.Text
	refs.TextBox.PlaceholderColor3 = colors.TextMuted
end

function Input:Set(text, silent)
	text = tostring(text)
	self._refs.TextBox.Text = text
	if text == self.Value then
		return
	end
	self.Value = text
	if not silent then
		Utility.SafeCall(self._callback, text, false)
	end
end

function Input:Get()
	return self.Value
end

function Input:Focus()
	self._refs.TextBox:CaptureFocus()
end

function Input:SetPlaceholder(text)
	self._refs.TextBox.PlaceholderText = text
end

function Input:SetDisabled(disabled)
	self._refs.TextBox.TextEditable = not disabled
	Row.SetDisabled(self._refs, disabled)
end

function Input:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Input:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Input
