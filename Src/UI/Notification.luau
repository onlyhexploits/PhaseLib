local import = ...

local Constants = import("Core/Constants")
local Janitor = import("Core/Janitor")
local Animation = import("Core/Animation")
local Utility = import("Core/Utility")

local Metrics = Constants.Metrics
local TextSizes = Constants.TextSizes

local Notification = {}
Notification.__index = Notification

local typeKeys = {
	info = "Info",
	success = "Success",
	warning = "Warning",
	error = "Error",
}

function Notification.new(theme)
	local self = setmetatable({}, Notification)
	self.Theme = theme
	self.Janitor = Janitor.new()
	self.Scope = theme:CreateScope()
	self.Janitor:Add(self.Scope)
	self._active = {}
	self._counter = 0

	self.Gui = Utility.Create("ScreenGui", {
		Name = "RobloxUI_Notifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
		Parent = Utility.GetGuiParent(),
	})
	self.Janitor:Add(self.Gui)

	self.Holder = Utility.Create("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, Metrics.NotificationWidth, 1, -40),
		Parent = self.Gui,
	})
	Utility.List(self.Holder, 0, { VerticalAlignment = Enum.VerticalAlignment.Bottom })

	return self
end

function Notification:Push(config)
	config = Utility.Merge({
		Title = "Notification",
		Content = "",
		Duration = 4,
		Type = "Info",
	}, config)

	self._counter = self._counter + 1
	local scope = self.Theme:CreateScope()
	local typeKey = typeKeys[string.lower(tostring(config.Type))] or "Info"
	local offscreen = UDim2.fromOffset(Metrics.NotificationWidth + 40, 0)

	local wrapper = Utility.Create("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._counter,
		Parent = self.Holder,
	})
	Utility.Padding(wrapper, 0, 0, 8, 0)

	local toast = Utility.Create("Frame", {
		Name = "Body",
		Position = offscreen,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		Parent = wrapper,
	})
	scope:Bind(toast, { BackgroundColor3 = "Surface" })
	Utility.Corner(toast, 12)
	scope:Bind(Utility.Stroke(toast, 1), { Color = "Border" })
	Utility.Padding(toast, 14, 16, 14, 16)
	Utility.List(toast, 4)

	local header = Utility.Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = toast,
	})

	local dot = Utility.Create("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 0,
		Parent = header,
	})
	Utility.Corner(dot, 4)
	scope:Bind(dot, { BackgroundColor3 = typeKey })

	local title = Utility.Create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Text = tostring(config.Title),
		FontFace = Constants.Fonts.SemiBold,
		TextSize = TextSizes.Body,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	scope:Bind(title, { TextColor3 = "Text" })

	local hasContent = config.Content ~= nil and config.Content ~= ""
	local content = Utility.Create("TextLabel", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(config.Content or ""),
		TextSize = TextSizes.Control,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = hasContent,
		LayoutOrder = 2,
		Parent = toast,
	})
	scope:Bind(content, { TextColor3 = "TextSecondary" })

	local dismissed = false
	local handle = {}

	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		local height = wrapper.AbsoluteSize.Y
		local slide = Animation.Tween(toast, "Notification", { Position = offscreen })
		slide.Completed:Once(function()
			wrapper.AutomaticSize = Enum.AutomaticSize.None
			wrapper.Size = UDim2.new(1, 0, 0, height)
			wrapper.ClipsDescendants = true
			local collapse = Animation.Tween(wrapper, "Notification", { Size = UDim2.new(1, 0, 0, 0) })
			collapse.Completed:Once(function()
				scope:Destroy()
				wrapper:Destroy()
				local index = table.find(self._active, handle)
				if index then
					table.remove(self._active, index)
				end
			end)
		end)
	end

	handle.Dismiss = dismiss
	table.insert(self._active, handle)

	toast.InputBegan:Connect(function(input)
		if Utility.IsPrimaryInput(input) then
			Utility.SafeCall(config.Callback)
			dismiss()
		end
	end)

	Animation.Tween(toast, "Notification", { Position = UDim2.fromOffset(0, 0) })

	local duration = tonumber(config.Duration)
	if duration and duration > 0 and duration < math.huge then
		task.delay(duration, dismiss)
	end

	while #self._active > Metrics.NotificationMax do
		local oldest = table.remove(self._active, 1)
		oldest.Dismiss()
	end

	return handle
end

function Notification:Destroy()
	self.Janitor:Destroy()
end

return Notification
