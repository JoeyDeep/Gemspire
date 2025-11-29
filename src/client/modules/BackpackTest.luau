--[[
    PURPOSE:
        Handle tool equipping and unequipping events for tools in the player's backpack.
        !!! This module is in testing. The idea behind this backpack method is utilizing native Roblox backpack
            features, and simply listening to tool equip/unequip and add/destroy events to trigger any additional
            functionality as needed.

        As it stands, this module is the only one listening for tool equip/unequip events, and handles all such actions.
    USAGE:
        ```lua
        local BackpackTest = require(engine:get("BackpackTest"))
        
]]

local BackpackTest = {
    setupTools = {}
}
local engine

function BackpackTest.init(engineModule)
    engine = engineModule

    local players = game:GetService("Players")
    local backpack = players.LocalPlayer.Backpack

    players.LocalPlayer.CharacterAdded:Connect(function()
        backpack = players.LocalPlayer.Backpack
        players.LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                BackpackTest:setup(child)
            end
        end)
        for _, tool in pairs(players.LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                BackpackTest:setup(tool)
            end
        end
    end)
end

function BackpackTest:setup(toolObject)
    if BackpackTest.setupTools[toolObject] then
        return
    end
    BackpackTest.setupTools[toolObject] = true
    toolObject.Equipped:Connect(function()
        print("Equipped", toolObject.Name)
    end)
    toolObject.Unequipped:Connect(function()
        print("Unequipped", toolObject.Name)
    end)
end

return BackpackTest