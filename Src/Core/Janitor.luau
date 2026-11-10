local import = ...

local Janitor = {}
Janitor.__index = Janitor

local function cleanItem(item)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "function" then
		item()
	elseif kind == "thread" then
		pcall(task.cancel, item)
	elseif kind == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Janitor.new()
	return setmetatable({ _items = {}, _destroyed = false }, Janitor)
end

function Janitor:Add(item)
	if self._destroyed then
		cleanItem(item)
		return item
	end
	table.insert(self._items, item)
	return item
end

function Janitor:Connect(signal, callback)
	return self:Add(signal:Connect(callback))
end

function Janitor:Cleanup()
	local items = self._items
	self._items = {}
	for index = #items, 1, -1 do
		cleanItem(items[index])
	end
end

function Janitor:Destroy()
	self._destroyed = true
	self:Cleanup()
end

return Janitor
