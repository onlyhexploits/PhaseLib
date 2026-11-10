local import = ...

local Animation = import("Core/Animation")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

local Scope = {}
Scope.__index = Scope

local palettes = {
	Dark = {
		Background = "#17181B",
		Window = "#1C1D21",
		Sidebar = "#191A1E",
		Surface = "#25262B",
		Hover = "#303137",
		Selected = "#3A3B41",
		Border = "#35363B",
		Text = "#F2F2F3",
		TextSecondary = "#A3A4AA",
		TextMuted = "#777980",
		Accent = "#FFFFFF",
		AccentText = "#17181B",
		ToggleOn = "#5A5B62",
		ToggleOff = "#303137",
		KnobOn = "#FFFFFF",
		KnobOff = "#9A9BA2",
		Success = "#5CC98A",
		Warning = "#E6B450",
		Error = "#E86464",
		Info = "#78A0E6",
	},
	Light = {
		Background = "#F2F2F5",
		Window = "#FFFFFF",
		Sidebar = "#F6F6F8",
		Surface = "#F0F0F3",
		Hover = "#E8E8EC",
		Selected = "#DFDFE5",
		Border = "#E2E2E7",
		Text = "#17181B",
		TextSecondary = "#5E5F67",
		TextMuted = "#8C8D95",
		Accent = "#17181B",
		AccentText = "#FFFFFF",
		ToggleOn = "#2C2D32",
		ToggleOff = "#D5D5DB",
		KnobOn = "#FFFFFF",
		KnobOff = "#FFFFFF",
		Success = "#2E9E62",
		Warning = "#C48A1A",
		Error = "#D04444",
		Info = "#3E6FD0",
	},
	Midnight = {
		Background = "#08090C",
		Window = "#0D0E13",
		Sidebar = "#0A0B0F",
		Surface = "#161820",
		Hover = "#1F212B",
		Selected = "#292C38",
		Border = "#242733",
		Text = "#EDEEF3",
		TextSecondary = "#9799A6",
		TextMuted = "#666878",
		Accent = "#FFFFFF",
		AccentText = "#0D0E13",
		ToggleOn = "#4A4F6A",
		ToggleOff = "#1F212B",
		KnobOn = "#FFFFFF",
		KnobOff = "#8C8EA0",
		Success = "#5CC98A",
		Warning = "#E6B450",
		Error = "#E86464",
		Info = "#78A0E6",
	},
}

local function normalize(colors)
	local result = {}
	for key, value in pairs(colors) do
		if typeof(value) == "string" then
			result[key] = Color3.fromHex(value)
		elseif typeof(value) == "Color3" then
			result[key] = value
		end
	end
	return result
end

local function copy(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

function Scope.new(manager, parent)
	local self = setmetatable({}, Scope)
	self._manager = manager
	self._parent = parent
	self._bindings = {}
	self._watchers = {}
	self._children = {}
	self._destroyed = false
	manager._scopes[self] = true
	return self
end

function Scope:Colors()
	return self._manager._colors
end

function Scope:Get(key)
	return self._manager._colors[key]
end

function Scope:Bind(instance, properties)
	if self._destroyed then
		return instance
	end
	local colors = self._manager._colors
	for property, key in pairs(properties) do
		local color = colors[key]
		assert(color, "Unknown theme key: " .. tostring(key))
		instance[property] = color
	end
	table.insert(self._bindings, { Instance = instance, Properties = properties })
	return instance
end

function Scope:Watch(callback)
	if self._destroyed then
		return function() end
	end
	table.insert(self._watchers, callback)
	callback(self._manager._colors, false)
	return function()
		local index = table.find(self._watchers, callback)
		if index then
			table.remove(self._watchers, index)
		end
	end
end

function Scope:Child()
	local child = Scope.new(self._manager, self)
	self._children[child] = true
	return child
end

function Scope:_apply(colors, animated)
	for _, binding in ipairs(self._bindings) do
		local goals = {}
		for property, key in pairs(binding.Properties) do
			goals[property] = colors[key]
		end
		Animation.Set(binding.Instance, "Theme", goals, animated)
	end
	for _, watcher in ipairs(self._watchers) do
		watcher(colors, animated)
	end
end

function Scope:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for child in pairs(self._children) do
		child:Destroy()
	end
	self._children = {}
	self._bindings = {}
	self._watchers = {}
	self._manager._scopes[self] = nil
	if self._parent then
		self._parent._children[self] = nil
	end
end

function ThemeManager.new()
	local self = setmetatable({}, ThemeManager)
	self._themes = {}
	for name, palette in pairs(palettes) do
		self._themes[name] = normalize(palette)
	end
	self._themes.Custom = copy(self._themes.Dark)
	self._name = "Dark"
	self._colors = self._themes.Dark
	self._scopes = {}
	self._listeners = {}
	return self
end

function ThemeManager:GetName()
	return self._name
end

function ThemeManager:GetColors()
	return self._colors
end

function ThemeManager:GetNames()
	local names = {}
	for name in pairs(self._themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ThemeManager:RegisterTheme(name, colors)
	local theme = copy(self._themes.Dark)
	for key, value in pairs(normalize(colors)) do
		theme[key] = value
	end
	self._themes[name] = theme
	return theme
end

function ThemeManager:Set(theme)
	local name
	local colors
	if type(theme) == "string" then
		colors = self._themes[theme]
		assert(colors, "Unknown theme: " .. theme)
		name = theme
	elseif type(theme) == "table" then
		colors = copy(self._colors)
		for key, value in pairs(normalize(theme)) do
			colors[key] = value
		end
		self._themes.Custom = colors
		name = "Custom"
	else
		error("Theme must be a theme name or a table of colors")
	end
	self._name = name
	self._colors = colors
	local snapshot = {}
	for scope in pairs(self._scopes) do
		table.insert(snapshot, scope)
	end
	for _, scope in ipairs(snapshot) do
		if not scope._destroyed then
			scope:_apply(colors, true)
		end
	end
	for _, listener in ipairs(self._listeners) do
		task.spawn(listener, name, colors)
	end
end

function ThemeManager:OnChanged(callback)
	table.insert(self._listeners, callback)
	return function()
		local index = table.find(self._listeners, callback)
		if index then
			table.remove(self._listeners, index)
		end
	end
end

function ThemeManager:CreateScope()
	return Scope.new(self, nil)
end

return ThemeManager
