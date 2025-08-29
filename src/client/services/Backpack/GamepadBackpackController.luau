-- GamepadInventoryController.luau
-- Console-friendly inventory controls:
--  A = Pick up / Place (emulates drag)
--  X = Equip / Unequip
--  Y = Quick-move between Toolbar <-> Backpack
--  B = Cancel carry (return to origin)
-- LB / RB = Jump focus between Toolbar and Backpack (keeps nearest index)
-- D-pad / LeftStick = navigate items (Roblox handles via Selection)

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Controller = {}
Controller.__index = Controller

local engine

type ToolClass = typeof(engine:get("BackpackManager").getToolbar()[1]) -- Tool type from manager
type ContainerName = "Toolbar" | "Backpack"

-- Carry state (gamepad "drag")
local carrying: ToolClass? = nil
local carryFrom: ContainerName | nil = nil
local carryFromIndex: number? = nil

-- ===== Helpers: reading UI & state =====

local function getInventoryRoots()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ui = playerGui:WaitForChild("UI")
	local inv = ui:WaitForChild("Inventory")
	local toolbarGui = inv:WaitForChild("Toolbar")
	local backpackGui = inv:WaitForChild("Backpack")
	return toolbarGui, backpackGui
end

local function collectButtons(containerGui: Instance): { GuiButton }
	local buttons = {}
	for _, child in ipairs(containerGui:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("Button") and child.Name ~= "Template" then
			local btn = child.Button
			if btn:IsA("GuiButton") then
				table.insert(buttons, btn)
			end
		end
	end
	-- Roblox respects LayoutOrder for selection movement; we keep array order natural
	table.sort(buttons, function(a, b)
		return (a.Parent :: Frame).LayoutOrder < (b.Parent :: Frame).LayoutOrder
	end)
	return buttons
end

-- local function getToolFromCard(card: Frame): ToolClass?
-- 	local tb = BackpackManager.getToolbar()
-- 	for _, t in ipairs(tb) do
-- 		if t and t.ui == card then
-- 			return t
-- 		end
-- 	end
-- 	for _, t in ipairs(BackpackManager.getBackpack()) do
-- 		if t and t.ui == card then
-- 			return t
-- 		end
-- 	end
-- 	return nil
-- end

local function getToolFromSelected(): (ToolClass?, ContainerName | nil, number?)
	local selected = GuiService.SelectedObject
	if not selected or not selected:IsA("GuiButton") then
		return nil, nil, nil
	end
	local card = selected:FindFirstAncestorOfClass("Frame")
	if not card then
		return nil, nil, nil
	end

	local BackpackManager = engine:get("BackpackManager")

	-- Determine container and index by matching UI
	local toolbar = BackpackManager.getToolbar()
	for i = 1, #toolbar do
		local t = toolbar[i]
		if t and t.ui == card then
			return t, "Toolbar", i
		end
	end
	local backpack = BackpackManager.getBackpack()
	for i = 1, #backpack do
		local t = backpack[i]
		if t and t.ui == card then
			return t, "Backpack", i
		end
	end
	return nil, nil, nil
end

local function focusContainer(container: ContainerName, preferredIndex: number?)
	local toolbarGui, backpackGui = getInventoryRoots()
	local buttons = (container == "Toolbar") and collectButtons(toolbarGui) or collectButtons(backpackGui)
	if #buttons == 0 then
		-- No items there; keep current focus unchanged
		return
	end
	local idx = math.clamp(preferredIndex or 1, 1, #buttons)
	GuiService.SelectedObject = buttons[idx]
end

-- Map the current selection's index to the "same" index in the other container
local function jumpFocus(toContainer: ContainerName)
	local _t, fromContainer, fromIndex = getToolFromSelected()
	if fromContainer == toContainer then
		-- already focused there; just keep it
		return
	end
	-- Try to retain the same index; clamp if shorter
	focusContainer(toContainer, fromIndex or 1)
end

-- ===== Carrying logic (A / place & quick moves) =====

local function placeCarryAtSelection()
	if not carrying then
		return
	end
	local _, targetContainer, targetIndex = getToolFromSelected()
	local BackpackManager = engine:get("BackpackManager")

	if targetContainer == "Toolbar" then
		BackpackManager.moveToolToToolbar(carrying, targetIndex)
	else
		-- fallback to backpack if selection isn't on a card
		BackpackManager.moveToolToBackpack(carrying, targetIndex)
	end

	carrying = nil
	carryFrom = nil
	carryFromIndex = nil
end

local function quickMove(t: ToolClass?, from: ContainerName | nil)
	if not t or not from then
		return
	end
	local BackpackManager = engine:get("BackpackManager")

	if from == "Toolbar" then
		BackpackManager.moveToolToBackpack(t)
	else
		BackpackManager.moveToolToToolbar(t)
	end
end

-- ====== Actions ======

-- A: pick up / place
local function onPickPlace(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local t, where, idx = getToolFromSelected()
	if not carrying then
		if t and where and idx then
			carrying = t
			carryFrom = where
			carryFromIndex = idx
			-- Optional: visual feedback could be applied here (outline, pulse, etc.)
		end
	else
		placeCarryAtSelection()
	end
	return Enum.ContextActionResult.Sink
end

-- X: equip / unequip (works on carried tool too)
local function onEquipToggle(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local t = carrying or select(1, getToolFromSelected())
	if not t then
		return Enum.ContextActionResult.Pass
	end
	if t.equipped then
		t:unequip()
	else
		t:equip()
	end
	return Enum.ContextActionResult.Sink
end

-- Y: quick move to other container
local function onQuickMove(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if carrying then
		quickMove(carrying, carryFrom)
		carrying = nil
		carryFrom = nil
		carryFromIndex = nil
	else
		local t, where = getToolFromSelected()
		quickMove(t, where)
	end
	return Enum.ContextActionResult.Sink
end

-- B: cancel carry
local function onCancel(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if carrying then
		local BackpackManager = engine:get("BackpackManager")
		-- return to original position
		if carryFrom == "Toolbar" and carryFromIndex then
			BackpackManager.moveToolToToolbar(carrying, carryFromIndex)
		elseif carryFrom == "Backpack" and carryFromIndex then
			BackpackManager.moveToolToBackpack(carrying, carryFromIndex)
		end
		carrying = nil
		carryFrom = nil
		carryFromIndex = nil
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

-- RB: jump focus to Backpack
local function onJumpRight(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	jumpFocus("Backpack")
	return Enum.ContextActionResult.Sink
end

-- LB: jump focus to Toolbar
local function onJumpLeft(_actionName, inputState, _inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	jumpFocus("Toolbar")
	return Enum.ContextActionResult.Sink
end

-- ====== Public API ======

function Controller.init(engineModule)
	engine = engineModule
	-- Bind common console layout
	ContextActionService:BindAction("INV_A_PickPlace", onPickPlace, false, Enum.KeyCode.ButtonA)
	ContextActionService:BindAction("INV_X_Equip", onEquipToggle, false, Enum.KeyCode.ButtonX)
	ContextActionService:BindAction("INV_Y_QuickMove", onQuickMove, false, Enum.KeyCode.ButtonY)
	ContextActionService:BindAction("INV_B_Cancel", onCancel, false, Enum.KeyCode.ButtonB)
	ContextActionService:BindAction("INV_LB_JumpToolbar", onJumpLeft, false, Enum.KeyCode.ButtonL1)
	ContextActionService:BindAction("INV_RB_JumpBackpack", onJumpRight, false, Enum.KeyCode.ButtonR1)

	-- Ensure at least some selection exists to start
	task.defer(function()
		local toolbarGui, backpackGui = getInventoryRoots()
		local tbButtons = collectButtons(toolbarGui)
		local bpButtons = collectButtons(backpackGui)

		if GuiService.SelectedObject == nil then
			if #tbButtons > 0 then
				GuiService.SelectedObject = tbButtons[1]
			elseif #bpButtons > 0 then
				GuiService.SelectedObject = bpButtons[1]
			end
		end

		-- Make sure all cards are selectable (defensive; you can also set this in Tool:setup())
		for _, btn in ipairs(tbButtons) do
			btn.Selectable = true
		end
		for _, btn in ipairs(bpButtons) do
			btn.Selectable = true
		end
	end)
end

-- Optional hook for UI buttons to check if a carry is active (so they can ignore Activated)
function Controller.isCarrying(): boolean
	return carrying ~= nil
end

return Controller
