local import = ...

local Constants = import("Core/Constants")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local Row = import("UI/Row")

local UserInputService = game:GetService("UserInputService")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Keybind = {}
Keybind.__index = Keybind

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
		TextSize = TextSizes.Control,
		Parent = refs.Control,
	})
	Utility.Corner(refs.Button, Metrics.ControlRadius)
	refs.Stroke = Utility.Stroke(refs.Button, 1, 0.5)
	return refs
end

function Keybind.new(section, config)
	config = Utility.Merge({
		Name = "Keybind",
		Default = Enum.KeyCode.Unknown,
		Width = 130,
		Disabled = false,
	}, config)
	local refs = build(section, config)

	local self = setmetatable({}, Keybind)
	self.Frame = refs.Frame
	self.Value = config.Default
	self._refs = refs
	self._window = section.Window
	self._callback = config.Callback
	self._onPressed = config.OnPressed
	self._listening = false
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
			if self._listening then
				self:_stopListening()
			else
				self:_startListening()
			end
		end,
	})

	refs.Janitor:Add(UserInputService.InputBegan:Connect(function(input, processed)
		if self._listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					self:_stopListening()
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					self:_stopListening()
					self:Set(Enum.KeyCode.Unknown)
				else
					self:_stopListening()
					self:Set(input.KeyCode)
				end
			end
			return
		end
		if processed or self._window._listening then
			return
		end
		if self._onPressed and self.Value ~= Enum.KeyCode.Unknown and input.KeyCode == self.Value then
			Utility.SafeCall(self._onPressed, self.Value)
		end
	end))

	refs.Janitor:Add(function()
		if self._listening then
			self._window:SetKeybindListening(false)
		end
	end)

	refs.Scope:Watch(function(_, animated)
		self:_render(animated)
	end)

	if config.Disabled then
		self:SetDisabled(true)
	end

	return self
end

function Keybind:_startListening()
	self._listening = true
	self._window:SetKeybindListening(true)
	self:_render(true)
end

function Keybind:_stopListening()
	if not self._listening then
		return
	end
	self._listening = false
	self._window:SetKeybindListening(false)
	self:_render(true)
end

function Keybind:_render(animated)
	local refs = self._refs
	local colors = refs.Scope:Colors()
	local background = colors.Surface
	if self._press then
		background = colors.Selected
	elseif self._hover or self._listening then
		background = colors.Hover
	end
	Animation.Set(refs.Button, "Hover", { BackgroundColor3 = background }, animated)
	Animation.Set(refs.Stroke, "Hover", {
		Color = self._listening and colors.TextMuted or colors.Border,
		Transparency = self._listening and 0 or 0.5,
	}, animated)
	refs.Button.TextColor3 = self._listening and colors.TextSecondary or colors.Text
	if self._listening then
		refs.Button.Text = "Press a key…"
	else
		refs.Button.Text = Utility.KeyName(self.Value)
	end
end

function Keybind:Set(keyCode, silent)
	if keyCode == self.Value then
		return
	end
	self.Value = keyCode
	self:_render(true)
	if not silent then
		Utility.SafeCall(self._callback, keyCode)
	end
end

function Keybind:Get()
	return self.Value
end

function Keybind:SetDisabled(disabled)
	if disabled then
		self:_stopListening()
	end
	Row.SetDisabled(self._refs, disabled)
end

function Keybind:SetName(text)
	Row.SetTitle(self._refs, text)
end

function Keybind:Destroy()
	self._refs.Janitor:Destroy()
	self._refs.Scope:Destroy()
	self._refs.Frame:Destroy()
end

return Keybind
