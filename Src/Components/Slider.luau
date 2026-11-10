local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Row = import("UI/Row")

local TextSizes = Constants.TextSizes

local Slider = {}
Slider.__index = Slider

local function build(section, config)
	local refs = Row.Build(section, {
		Name = config.Name,
		Description = config.Description,
		ControlWidth = 300,
	})

	refs.ValueLabel = Utility.Create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(60, 20),
		TextSize = TextSizes.Control,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = refs.Control,
	})

	refs.Hit = Utility.Create("TextButton", {
		Name = "Hit",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, -72, 0, 28),
		Parent = refs.Control,
	})

	refs.Track = Utility.Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(1, -16, 0, 4),
		BackgroundTransparency = 0,
		Parent = refs.Hit,
	})
	Utility.Corner(refs.Track, 2)

	refs.Fill = Utility.Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 0,
		Parent = refs.Track,
	})
	Utility.Corner(refs.Fill, 2)

	refs.Thumb = Utility.Create("Frame", {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 0,
		Parent = refs.Track,
	})
	Utility.Corner(refs.Thumb, 8)

	return refs
end

function Slider.new(section, config)
	config = Utility.Merge({
		Name = "Slider",
		Min = 0,
		Max = 100,
		Increment = 1,
		Suffix = "",
		Disabled = false,
	}, config)
	if config.Max <= config.Min then
		config.Max = config.Min + 1
	end
	local refs = build(section, config)

	local self = setmetatable({}, Slider)
	self.Frame = refs.Frame
	self.Min = config.Min
	self.Max = config.Max
	self.Increment = config.Increment
	self.Suffix = config.Suffix
	self._refs = refs
	self._section = section
	self._callback = config.Callback
	self._hover = false
	self._dragging = false
	self.Value = self:_normalize(config.Default or config.Min)

	Utility.Interact(refs.Hit, refs.Janitor, {
		Hover = function(state)
			self._hover = state
			self:_render(true)
		end,
	})

	Utility.Drag(refs.Hit, refs.Janitor, {
		Began = function(position)
			self._dragging = true
			self._section.Tab.Scroll.ScrollingEnabled = false
			self:_fromPosition(position)
			self:_render(true)
		end,
		Changed = function(position)
			self:_fromPosition(position)
		end,
		Ended = function()
			self._dragging = false
			self._section.Tab.Scroll.ScrollingEnabled = true
			self:_render(true)
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

function Slider:_normalize(value)
	local rounded = Utility.Round(value - self.Min, self.Increment) + self.Min
	return math.clamp(rounded, self.Min, self.Max)
end

function Slider:_alpha()
	return (self.Value - self.Min) / (self.Max - self.Min)
end

function Slider:_fromPosition(position)
	local track = self._refs.Track
	local alpha = math.clamp((position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
	self:Set(self.Min + (self.Max - self.Min) * alpha, false, true)
end

function Slider:_render(animated)
	local refs = self._refs
	local colors = refs.Scope:Colors()
	local alpha = self:_alpha()
	local thumbSize = (self._dragging or self._hover) and 16 or 14

	refs.Track.BackgroundColor3 = colors.Hover
	refs.Fill.BackgroundColor3 = colors.Accent
	refs.Thumb.BackgroundColor3 = colors.Accent
	refs.ValueLabel.TextColor3 = self._dragging and colors.Text or colors.TextSecondary
	refs.ValueLabel.Text = Utility.FormatNumber(self.Value) .. self.Suffix

	Animation.Set(refs.Fill, "Hover", { Size = UDim2.fromScale(alpha, 1) }, animated and not self._dragging)
	Animation.Set(refs.Thumb, "Hover", {
		Position = UDim2.fromScale(alpha, 0.5),
		Size = UDim2.fromOffset(thumbSize, thumbSize),
	}, animated and not self._dragging)
	if self._dragging then
		refs.Thumb.Position = UDim2.fromScale(alpha, 0.5)
		refs.Thumb.Size = UDim2.fromOffset(thumbSize, thumbSize)
		refs.Fill.Size = UDim2.fromScale(alpha, 1)
	end
end

function Slider:Set(value, silent, instant)
	local normalized = self:_normalize(value)
	if normalized == self.Value then
		return
	end
	self.Value = normalized
	self:_render(not instant)
	if not silent then
		Utility.SafeCall(self._callback, normalized)
	end
end

function Slider:Get()
	return self.Value
end

function Slider:SetRange(min, max)
	self.Min = min
	self.Max = math.max(max, min + 1)
	self.Value = self:_normalize(self.Value)
	self:_render(true)
end

function Slider:SetDisabled(disabled)
	Row.SetDisabled(self._refs, disabled)
end

function Slider:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Slider:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Slider
