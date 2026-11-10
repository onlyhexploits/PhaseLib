local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Row = import("UI/Row")

local Metrics = Constants.Metrics

local Toggle = {}
Toggle.__index = Toggle

local function build(section, config)
	local refs = Row.Build(section, {
		Name = config.Name,
		Description = config.Description,
		ControlWidth = Metrics.ToggleWidth + 8,
	})
	refs.Track = Utility.Create("TextButton", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(Metrics.ToggleWidth, Metrics.ToggleHeight),
		BackgroundTransparency = 0,
		Parent = refs.Control,
	})
	Utility.Corner(refs.Track, Metrics.ToggleHeight / 2)
	refs.Knob = Utility.Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 0,
		Parent = refs.Track,
	})
	Utility.Corner(refs.Knob, 10)
	return refs
end

function Toggle.new(section, config)
	config = Utility.Merge({ Name = "Toggle", Default = false, Disabled = false }, config)
	local refs = build(section, config)

	local self = setmetatable({}, Toggle)
	self.Frame = refs.Frame
	self.Value = config.Default == true
	self._refs = refs
	self._callback = config.Callback
	self._hover = false
	self._press = false

	Utility.Interact(refs.Track, refs.Janitor, {
		Hover = function(state)
			self._hover = state
			self:_render(true)
		end,
		Press = function(state)
			self._press = state
			self:_render(true)
		end,
		Click = function()
			self:Set(not self.Value)
		end,
	})

	refs.Scope:Watch(function(_, animated)
		self:_render(animated)
	end)

	if config.Disabled then
		self:SetDisabled(true)
	end

	return self
end

function Toggle:_render(animated)
	local colors = self._refs.Scope:Colors()
	local on = self.Value
	local track = on and colors.ToggleOn or colors.ToggleOff
	if self._hover then
		track = track:Lerp(colors.Text, 0.1)
	end
	local width = self._press and 24 or 20
	local x = on and (Metrics.ToggleWidth - 3 - width) or 3
	Animation.Set(self._refs.Track, "Toggle", { BackgroundColor3 = track }, animated)
	Animation.Set(self._refs.Knob, "Toggle", {
		BackgroundColor3 = on and colors.KnobOn or colors.KnobOff,
		Position = UDim2.new(0, x, 0.5, 0),
		Size = UDim2.fromOffset(width, 20),
	}, animated)
end

function Toggle:Set(value, silent)
	value = value == true
	if value == self.Value then
		return
	end
	self.Value = value
	self:_render(true)
	if not silent then
		Utility.SafeCall(self._callback, value)
	end
end

function Toggle:Get()
	return self.Value
end

function Toggle:SetDisabled(disabled)
	Row.SetDisabled(self._refs, disabled)
end

function Toggle:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Toggle:SetDescription(text)
	Row.SetDescription(self._refs, text)
end

function Toggle:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Toggle
