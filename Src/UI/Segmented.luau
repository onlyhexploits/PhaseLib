local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Icons = import("Core/Icons")

local TextSizes = Constants.TextSizes

local Segmented = {}
Segmented.__index = Segmented

local function normalizeOptions(options)
	local result = {}
	for _, option in ipairs(options) do
		if type(option) == "table" then
			table.insert(result, {
				Value = option.Value,
				Text = option.Text,
				Icon = option.Icon,
			})
		else
			table.insert(result, { Value = option, Text = tostring(option) })
		end
	end
	return result
end

local function build(tab, config, options)
	local padding = 4
	local segmentHeight = 32
	local segmentWidth = 44
	for _, option in ipairs(options) do
		if not option.Icon then
			segmentWidth = 76
		end
	end

	local refs = { Padding = padding, SegmentWidth = segmentWidth, SegmentHeight = segmentHeight, Segments = {} }

	refs.Frame = Utility.Create("Frame", {
		Name = "Segmented",
		Size = UDim2.fromOffset(#options * segmentWidth + padding * 2, segmentHeight + padding * 2),
		BackgroundTransparency = 0,
		LayoutOrder = tab:NextOrder(),
		Parent = tab.HeaderControls,
	})
	Utility.Corner(refs.Frame, 12)
	refs.Stroke = Utility.Stroke(refs.Frame, 1)

	refs.Indicator = Utility.Create("Frame", {
		Name = "Indicator",
		Position = UDim2.fromOffset(padding, padding),
		Size = UDim2.fromOffset(segmentWidth, segmentHeight),
		BackgroundTransparency = 0,
		Parent = refs.Frame,
	})
	Utility.Corner(refs.Indicator, 9)

	for index, option in ipairs(options) do
		local button = Utility.Create("TextButton", {
			Name = tostring(option.Value),
			Position = UDim2.fromOffset(padding + (index - 1) * segmentWidth, padding),
			Size = UDim2.fromOffset(segmentWidth, segmentHeight),
			Parent = refs.Frame,
		})
		local segment = { Button = button, Option = option, Hover = false }
		if option.Icon then
			segment.Icon = Icons.Create(button, option.Icon, 18, Color3.new(1, 1, 1))
			segment.Icon.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
			segment.Icon.Frame.Position = UDim2.fromScale(0.5, 0.5)
		else
			segment.Label = Utility.Create("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Text = option.Text or tostring(option.Value),
				TextSize = TextSizes.Control,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = button,
			})
		end
		refs.Segments[index] = segment
	end

	return refs
end

function Segmented.new(tab, config)
	config = Utility.Merge({ Options = {} }, config)
	local options = normalizeOptions(config.Options)
	local context = tab:CreateContext()
	local refs = build(tab, config, options)

	local self = setmetatable({}, Segmented)
	self.Frame = refs.Frame
	self.Options = options
	self.Value = config.Default
	self._refs = refs
	self._context = context
	self._callback = config.Callback

	if self.Value == nil and options[1] then
		self.Value = options[1].Value
	end

	context.Scope:Bind(refs.Frame, { BackgroundColor3 = "Surface" })
	context.Scope:Bind(refs.Stroke, { Color = "Border" })
	context.Scope:Bind(refs.Indicator, { BackgroundColor3 = "Selected" })

	for index, segment in ipairs(refs.Segments) do
		Utility.Interact(segment.Button, context.Janitor, {
			Hover = function(state)
				segment.Hover = state
				self:_renderSegments(true)
			end,
			Click = function()
				self:Set(options[index].Value)
			end,
		})
	end

	context.Scope:Watch(function(_, animated)
		self:_renderSegments(animated)
	end)
	self:_moveIndicator(false)

	return self
end

function Segmented:_indexOf(value)
	for index, option in ipairs(self.Options) do
		if option.Value == value then
			return index
		end
	end
	return nil
end

function Segmented:_moveIndicator(animated)
	local index = self:_indexOf(self.Value)
	if not index then
		self._refs.Indicator.Visible = false
		return
	end
	self._refs.Indicator.Visible = true
	local x = self._refs.Padding + (index - 1) * self._refs.SegmentWidth
	Animation.Set(self._refs.Indicator, "Toggle", { Position = UDim2.fromOffset(x, self._refs.Padding) }, animated)
end

function Segmented:_renderSegments(animated)
	local colors = self._context.Scope:Colors()
	for _, segment in ipairs(self._refs.Segments) do
		local selected = segment.Option.Value == self.Value
		local color = colors.TextSecondary
		if selected or segment.Hover then
			color = colors.Text
		end
		if segment.Icon then
			segment.Icon:SetColor(color, animated)
		else
			Animation.Set(segment.Label, "Hover", { TextColor3 = color }, animated)
		end
	end
end

function Segmented:Set(value, silent)
	if value == self.Value or not self:_indexOf(value) then
		return
	end
	self.Value = value
	self:_moveIndicator(true)
	self:_renderSegments(true)
	if not silent then
		Utility.SafeCall(self._callback, value)
	end
end

function Segmented:Get()
	return self.Value
end

function Segmented:Destroy()
	self._context.Janitor:Destroy()
	self._context.Scope:Destroy()
	self.Frame:Destroy()
end

return Segmented
