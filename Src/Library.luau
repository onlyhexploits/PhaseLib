local import = ...

local Constants = import("Core/Constants")
local Janitor = import("Core/Janitor")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")
local ThemeManager = import("Core/ThemeManager")
local Icons = import("Core/Icons")
local Row = import("UI/Row")
local Section = import("UI/Section")
local Window = import("UI/Window")
local Notification = import("UI/Notification")
local Toggle = import("Components/Toggle")
local Dropdown = import("Components/Dropdown")
local Slider = import("Components/Slider")
local Button = import("Components/Button")
local Input = import("Components/Input")
local Keybind = import("Components/Keybind")
local Paragraph = import("Components/Paragraph")
local Label = import("Components/Label")

local Library = {}
Library.Version = Constants.Version
Library.Theme = ThemeManager.new()
Library.Windows = {}
Library.Core = {
	Constants = Constants,
	Utility = Utility,
	Animation = Animation,
	Icons = Icons,
	Row = Row,
	Janitor = Janitor,
	ThemeManager = ThemeManager,
}
Library._notifications = nil

Section.RegisterComponent("Toggle", Toggle)
Section.RegisterComponent("Dropdown", Dropdown)
Section.RegisterComponent("Slider", Slider)
Section.RegisterComponent("Button", Button)
Section.RegisterComponent("Input", Input)
Section.RegisterComponent("Keybind", Keybind)
Section.RegisterComponent("Paragraph", Paragraph)
Section.RegisterComponent("Label", Label)

function Library:CreateWindow(config)
	local window = Window.new(self, config or {})
	table.insert(self.Windows, window)
	return window
end

function Library:_removeWindow(window)
	local index = table.find(self.Windows, window)
	if index then
		table.remove(self.Windows, index)
	end
end

function Library:SetTheme(theme)
	self.Theme:Set(theme)
end

function Library:GetTheme()
	return self.Theme:GetName(), self.Theme:GetColors()
end

function Library:GetThemeNames()
	return self.Theme:GetNames()
end

function Library:RegisterTheme(name, colors)
	return self.Theme:RegisterTheme(name, colors)
end

function Library:OnThemeChanged(callback)
	return self.Theme:OnChanged(callback)
end

function Library:Notify(config)
	if not self._notifications then
		self._notifications = Notification.new(self.Theme)
	end
	return self._notifications:Push(config or {})
end

function Library:RegisterIcon(name, icon)
	Icons.Register(name, icon)
end

function Library:SetIconsType(iconType)
	return Icons.SetType(iconType)
end

function Library:RegisterComponent(name, module)
	assert(type(module) == "table" and type(module.new) == "function", "Component modules must expose a new(section, config) function")
	Section.RegisterComponent(name, module)
end

function Library:SetFonts(fonts)
	for key, font in pairs(fonts) do
		Constants.Fonts[key] = font
	end
end

function Library:Destroy()
	for index = #self.Windows, 1, -1 do
		self.Windows[index]:Destroy()
	end
	if self._notifications then
		self._notifications:Destroy()
		self._notifications = nil
	end
end

return Library
