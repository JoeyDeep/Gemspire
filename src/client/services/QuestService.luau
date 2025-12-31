local QuestService = {}

local engine
function QuestService.init(engineModule)
    engine = engineModule

    local QuickTween = engine:get("QuickTween")
    local Sound = engine:get("Sound")
    local questTabOpen = true
    task.spawn(function()
        engine.PlayerGui:WaitForChild("UI"):WaitForChild("Quests"):WaitForChild("HideToggle").Activated:Connect(function()
            questTabOpen = not questTabOpen
            Sound:playGlobal("Click")
            if questTabOpen then
                QuickTween(engine.PlayerGui.UI.Quests.Content, 0.15, { Position = UDim2.fromScale(0.006, 0.245) })
                QuickTween(engine.PlayerGui.UI.Quests.HideToggle, 0.15, {Position = UDim2.fromScale(0.159, 0.245), Rotation = 0})
            else
                QuickTween(engine.PlayerGui.UI.Quests.Content, 0.15, { Position = UDim2.fromScale(-0.152, 0.245) })
                QuickTween(engine.PlayerGui.UI.Quests.HideToggle, 0.15, {Position = UDim2.fromScale(0.004, 0.245), Rotation = 180})
            end
        end)
        engine.PlayerGui:WaitForChild("UI"):WaitForChild("Quests"):WaitForChild("HideToggle").MouseEnter:Connect(function()
            QuickTween(engine.PlayerGui.UI.Quests.HideToggle.UIScale, 0.15, {Scale = 1.1})
            Sound:playGlobal("Hover")
        end)
        engine.PlayerGui:WaitForChild("UI"):WaitForChild("Quests"):WaitForChild("HideToggle").MouseLeave:Connect(function()
            QuickTween(engine.PlayerGui.UI.Quests.HideToggle.UIScale, 0.3, {Scale = 1})
        end)
    end)
end

function QuestService:drawQuestList(playerQuestData)
    local UI = engine.PlayerGui:WaitForChild("UI"):WaitForChild("Quests")
    local content = UI:WaitForChild("Content")

    local layoutOrder = 1

    for _, oldChild in pairs(content:GetChildren()) do
        if oldChild:IsA("GuiObject") and not (oldChild.Name == "HeaderTemplate" or oldChild.Name == "TaskTemplate" or oldChild.Name == "DividerTemplate" or oldChild.Name == "UIListLayout") then
            oldChild:Destroy()
        end
    end

    if next(playerQuestData.active) == nil then
        local noQuestsLabel = content.TaskTemplate:Clone()
        noQuestsLabel.Name = "NoActiveQuests"
        noQuestsLabel.Text = "No Active Quests"
        noQuestsLabel.LayoutOrder = layoutOrder
        noQuestsLabel.Visible = true
        noQuestsLabel.Parent = content
        return
    end

    for questID, questData in pairs(playerQuestData.active) do
        local questInfo = engine:get(`Quest_{questID}`) 
        if questInfo then
            local questName = questInfo.questData.title
            local nodeData = questInfo.questData.nodes[questData.currentNode]

            local titleLabel = content.HeaderTemplate:Clone()
            titleLabel.Name = questName
            titleLabel.Text = questName
            titleLabel.LayoutOrder = layoutOrder
            titleLabel.Visible = true
            titleLabel.Parent = content
            layoutOrder += 1

            for taskIndex, taskData in ipairs(nodeData.tasks or {}) do
                local taskLabel = content.TaskTemplate:Clone()
                taskLabel.Name = `Task_{taskIndex}`
                local progress = questData.currentTasks[taskIndex]
                taskLabel.Text =
                --
                    `{taskData.description} [<font color="rgb(255, 230, 0)">{progress.current}</font>/<font color="rgb(255, 230, 0)">{progress.goal}</font>]`
                taskLabel.LayoutOrder = layoutOrder
                taskLabel.Visible = true
                taskLabel.Parent = content
                layoutOrder += 1
            end
            local divider = content.DividerTemplate:Clone()
            divider.Name = `Divider_{questID}`
            divider.LayoutOrder = layoutOrder
            divider.Visible = true
            divider.Parent = content
        end
    end
end

return QuestService