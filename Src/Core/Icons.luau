local import = ...

local Animation = import("Core/Animation")
local Utility = import("Core/Utility")

local Icons = {}

local Icon = {}
Icon.__index = Icon

local registry = {}
local aliases = {
	close = "x",
}
local provider = nil

local loaded, result = pcall(function()
	return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
end)
if loaded and type(result) == "table" then
	provider = result
	pcall(function()
		provider.SetIconsType("lucide")
	end)
else
	warn("[PhaseLib] Failed to load IconsV2: " .. tostring(result))
end

local function isDirect(value)
	return string.find(value, "^rbxasset") ~= nil or string.find(value, "^https?://") ~= nil
end

local function resolve(name)
	if not provider then
		return nil
	end
	local success, icon = pcall(provider.GetIcon, aliases[name] or name)
	if success and icon ~= nil then
		return icon
	end
	return nil
end

function Icons.SetType(iconType)
	if not provider then
		return false
	end
	return (pcall(provider.SetIconsType, iconType))
end

function Icons.Register(name, value)
	registry[name] = value
end

function Icons.Has(name)
	if registry[name] ~= nil then
		return true
	end
	return resolve(name) ~= nil
end

function Icons.Create(parent, icon, size, color)
	size = size or 18
	color = color or Color3.new(1, 1, 1)

	local container = Utility.Create("Frame", {
		Name = "Icon",
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
	local self = setmetatable({ Frame = container, _parts = {} }, Icon)

	local value = icon
	if type(value) == "string" and registry[value] ~= nil then
		value = registry[value]
	end
	if type(value) == "number" then
		value = "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" and not isDirect(value) then
		value = resolve(value)
	end

	local properties = nil
	if type(value) == "string" then
		properties = { Image = value }
	elseif type(value) == "table" and value.Image then
		properties = {
			Image = value.Image,
			ImageRectOffset = value.ImageRectOffset or Vector2.zero,
			ImageRectSize = value.ImageRectSize or Vector2.zero,
		}
	end

	if properties then
		properties.Name = "Image"
		properties.Size = UDim2.fromScale(1, 1)
		properties.ImageColor3 = color
		properties.ScaleType = Enum.ScaleType.Fit
		properties.Parent = container
		local image = Utility.Create("ImageLabel", properties)
		table.insert(self._parts, { Instance = image, Property = "ImageColor3" })
	end

	return self
end

function Icon:SetColor(color, animated)
	for _, part in ipairs(self._parts) do
		Animation.Set(part.Instance, "Hover", { [part.Property] = color }, animated)
	end
end

function Icon:Destroy()
	self.Frame:Destroy()
end

return Icons
