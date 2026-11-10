local BaseUrl = "https://raw.githubusercontent.com/onlyhexploits/PhaseLib/main/Src/"

local cache = {}
local loading = {}

local function import(path)
	local cached = cache[path]
	if cached ~= nil then
		return cached
	end

	assert(not loading[path], "[PhaseLib] Circular import: " .. path)
	loading[path] = true

	local source = game:HttpGetAsync(BaseUrl .. path .. ".luau")
	local chunk, message = loadstring(source, "=" .. path)
	assert(chunk, "[PhaseLib] Failed to compile " .. path .. ": " .. tostring(message))

	local result = chunk(import)
	loading[path] = nil
	cache[path] = result
	return result
end

return import("Library")
