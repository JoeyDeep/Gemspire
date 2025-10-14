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
	for _, module in pairs(engine.modules) do
		if typeof(module) == "table" and module.init and not module.___loaded then
			-- Call the init function if it exists
			local start = tick()

			module.init(engine)
			module.___loaded = true

			if tick() - start > 0.1 then
				warn(`[!!!] {module.Name} took {tick() - start} seconds to load`)
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
