local import = ...

local Constants = import("Core/Constants")

local TweenService = game:GetService("TweenService")

local Animation = {}

local styles = {
	Toggle = Enum.EasingStyle.Quart,
	Dropdown = Enum.EasingStyle.Quart,
	Window = Enum.EasingStyle.Quart,
	Notification = Enum.EasingStyle.Quart,
}

local infos = {}
for name, duration in pairs(Constants.Durations) do
	infos[name] = TweenInfo.new(duration, styles[name] or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animation.Info(preset)
	if typeof(preset) == "TweenInfo" then
		return preset
	end
	return infos[preset] or infos.Hover
end

function Animation.Tween(instance, preset, properties)
	local tween = TweenService:Create(instance, Animation.Info(preset), properties)
	tween:Play()
	return tween
end

function Animation.Set(instance, preset, properties, animated)
	if animated then
		return Animation.Tween(instance, preset, properties)
	end
	for property, value in pairs(properties) do
		instance[property] = value
	end
	return nil
end

return Animation
