local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Row = import("UI/Row")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Button = {}
Button.__index = Button

local function build(section, config)
	local refs = Row.Build(section, {
		Name = config.Name,
		Description = config.Description,
		ControlWidth = config.Width,
	})
	refs.Button = Utility.Create("TextButton", {
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(config.Width, Metrics.ControlHeight),
		BackgroundTransparency = 0,
		Text = config.ButtonText,
		TextSize = TextSizes.Control,
		FontFace = Constants.Fonts.Medium,
		Parent = refs.Control,
	})
	Utility.Corner(refs.Button, Metrics.ControlRadius)
	refs.Stroke = Utility.Stroke(refs.Button, 1, 0.5)
	refs.Scale = Utility.Create("UIScale", { Parent = refs.Button })
	return refs
end

function Button.new(section, config)
	config = Utility.Merge({
		Name = "Button",
		ButtonText = "Run",
		Width = 100,
		Disabled = false,
	}, config)
	local refs = build(section, config)

	local self = setmetatable({}, Button)
	self.Frame = refs.Frame
	self._refs = refs
	self._callback = config.Callback
	self._hover = false
	self._press = false

	Utility.Interact(refs.Button, refs.Janitor, {
		Hover = function(state)
			self._hover = state
			self:_render(true)
		end,
		Press = function(state)
			self._press = state
			self:_render(true)
		end,
		Click = function()
			self:Fire()
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

function Button:_render(animated)
	local refs = self._refs
	local colors = refs.Scope:Colors()
	local background = colors.Surface
	if self._press then
		background = colors.Selected
	elseif self._hover then
		background = colors.Hover
	end
	Animation.Set(refs.Button, "Hover", {
		BackgroundColor3 = background,
		TextColor3 = colors.Text,
	}, animated)
	Animation.Set(refs.Stroke, "Hover", { Color = colors.Border }, animated)
	Animation.Set(refs.Scale, "Press", { Scale = self._press and 0.96 or 1 }, animated)
end

function Button:Fire()
	if self._refs.Disabled then
		return
	end
	Utility.SafeCall(self._callback)
end

function Button:SetText(text)
	self._refs.Button.Text = text
end

function Button:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Button:SetDescription(text)
	Row.SetDescription(self._refs, text)
end

function Button:SetDisabled(disabled)
	Row.SetDisabled(self._refs, disabled)
end

function Button:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Button
