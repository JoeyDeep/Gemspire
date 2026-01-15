--[[
PURPOSE: 
	Engine module to manage and provide access to other modules and services.

USAGE:
	```lua
	local engine = require(path.to.Engine) -- OR... (below, & most common):
	local engine
	function someModule.init(engineModule)
		engine = engineModule
	end

	local someModule = engine:get("SomeModuleName")

	someModule:doSomeging() -- called to singleton
	someModule.classCache[classIndex]:doSomething() -- called as instance of the class
	```
]]

local engine = {
	modules = {},
	events = game:GetService("ReplicatedStorage").Events,
	player = game:GetService("Players").LocalPlayer,
	PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
}
engine.__index = engine

function engine:get(moduleName)
	if engine.modules[moduleName] then
		return engine.modules[moduleName]
	else
		warn("Module '" .. moduleName .. "' not found in engine.")
		return nil
	end
end

function engine:await(moduleName, timeout)
	local module = engine.modules[moduleName]
	if not module then
		warn("Module '" .. moduleName .. "' not found in engine.")
		return nil
	end

	if typeof(module) == "table" and module.init and not module.___loaded then
		if not module.___initializing then
			module.___initializing = true
			local ok, err = pcall(function()
				module.init(engine)
			end)
			module.___initializing = nil
			if ok then
				module.___loaded = true
			else
				warn("Failed to init module '" .. moduleName .. "': " .. tostring(err))
				return nil
			end
		end
	end

	if typeof(module) == "table" and module.init and not module.___loaded then
		local start = os.clock()
		while not module.___loaded do
			if timeout and os.clock() - start > timeout then
				warn("Timed out waiting for module '" .. moduleName .. "'.")
				return nil
			end
			task.wait()
		end
	end

	return module
end

-- ordered first to last to be loaded
local foldersToLoad = {
	"modules",
	"services",
}

local function loadModule(module)
	if module:IsA("ModuleScript") then
		local success, err = pcall(function()
			local loadedModule = require(module)
			engine.modules[module.Name] = loadedModule
		end)
		if not success then
			warn("Failed to load module '" .. module.Name .. "': " .. tostring(err))
		end
	end
end
local function initModules()
	for name, module in pairs(engine.modules) do
		if typeof(module) == "table" and module.init and not module.___loaded then
			-- Call the init function if it exists
			local start = tick()

			module.init(engine)
			module.___loaded = true

			if tick() - start > 0.1 then
				warn(`[!!!] {name} took {tick() - start} seconds to load`)
			end
		end
	end
end

for _, module in pairs(game:GetService("ReplicatedStorage").Shared:GetDescendants()) do
	loadModule(module)
end
initModules()
for _, folderName in ipairs(foldersToLoad) do
	for _, module in pairs(script.Parent.Parent[folderName]:GetDescendants()) do
		loadModule(module)
	end
end
initModules()
print(`[Engine] Client Loaded`)

return engine
