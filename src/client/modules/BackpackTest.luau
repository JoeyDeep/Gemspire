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