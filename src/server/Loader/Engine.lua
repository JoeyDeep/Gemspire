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
	moduleOrder = {},
	events = game:GetService("ReplicatedStorage").Events,
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

-- ordered first to last to be loaded
local foldersToLoad = {
	"modules",
	"services",
}

local function loadModule(module)
	if module:IsA("ModuleScript") then
		local success, err = pcall(function()
			local loadedModule = require(module)
			if engine.modules[module.Name] == nil then
				table.insert(engine.moduleOrder, module.Name)
			end
			engine.modules[module.Name] = loadedModule
		end)
		if not success then
			warn("Failed to load module '" .. module.Name .. "': " .. tostring(err))
		end
	end
end
local function initModules()
	for _, name in ipairs(engine.moduleOrder) do
		local module = engine.modules[name]
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

local function getSortedModules(container)
	local modules = {}
	for _, module in ipairs(container:GetDescendants()) do
		if module:IsA("ModuleScript") then
			table.insert(modules, module)
		end
	end
	table.sort(modules, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)
	return modules
end

for _, module in ipairs(getSortedModules(game:GetService("ReplicatedStorage").Shared)) do
	loadModule(module)
end
initModules()
for _, folderName in ipairs(foldersToLoad) do
	for _, module in ipairs(getSortedModules(script.Parent.Parent[folderName])) do
		loadModule(module)
	end
end
initModules()
print(`[Engine] Server Loaded`)

return engine
