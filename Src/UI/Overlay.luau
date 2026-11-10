local import = ...

local Utility = import("Core/Utility")

local UserInputService = game:GetService("UserInputService")

local Overlay = {}
Overlay.__index = Overlay

function Overlay.new(root, uiScale, janitor)
	local self = setmetatable({}, Overlay)
	self.Root = root
	self.Scale = uiScale
	self._current = nil

	self.Layer = Utility.Create("Frame", {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = root,
	})

	self.Blocker = Utility.Create("TextButton", {
		Name = "Blocker",
		Position = UDim2.fromOffset(-5000, -5000),
		Size = UDim2.fromOffset(10000, 10000),
		Visible = false,
		ZIndex = 1,
		Parent = self.Layer,
	})

	janitor:Add(self.Blocker.Activated:Connect(function()
		self:Dismiss()
	end))

	janitor:Add(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and self._current then
			self:Dismiss()
		end
	end))

	return self
end

function Overlay:IsOpen()
	return self._current ~= nil
end

function Overlay:Open(owner, anchor, popup, size, gap)
	self:Dismiss()

	local scale = math.max(self.Scale.Scale, 0.01)
	local rootPosition = self.Root.AbsolutePosition
	local bounds = self.Root.AbsoluteSize / scale
	local anchorPosition = (anchor.AbsolutePosition - rootPosition) / scale
	local anchorSize = anchor.AbsoluteSize / scale

	local x = anchorPosition.X + anchorSize.X - size.X
	x = math.clamp(x, 8, math.max(8, bounds.X - size.X - 8))

	local below = anchorPosition.Y + anchorSize.Y + gap
	local spaceDown = math.max(bounds.Y - 8 - below, 0)
	local spaceUp = math.max(anchorPosition.Y - gap - 8, 0)
	local fitsDown = size.Y <= spaceDown
	local fitsUp = size.Y <= spaceUp
	local opensDown = fitsDown or (not fitsUp and spaceDown >= spaceUp)
	local height = math.floor(math.min(size.Y, opensDown and spaceDown or spaceUp))

	if opensDown then
		popup.AnchorPoint = Vector2.new(0, 0)
		popup.Position = UDim2.fromOffset(x, below)
	else
		popup.AnchorPoint = Vector2.new(0, 1)
		popup.Position = UDim2.fromOffset(x, anchorPosition.Y - gap)
	end

	popup.Parent = self.Layer
	self.Blocker.Visible = true
	self._current = owner

	return opensDown and "Down" or "Up", height
end

function Overlay:Release(owner)
	if self._current == owner then
		self._current = nil
		self.Blocker.Visible = false
	end
end

function Overlay:Dismiss()
	local current = self._current
	if current then
		self._current = nil
		self.Blocker.Visible = false
		current:Close()
	end
end

return Overlay
