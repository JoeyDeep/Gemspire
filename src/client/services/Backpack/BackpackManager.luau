-- ReplicatedStorage/Shared/Inventory/BackpackManager.luau
-- Core inventory state + rendering + mouse/touch drag. Gamepad carry integrates via a provider hook.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Input = require(ReplicatedStorage.Packages.Input)

export type ToolClass = {
	name: string,
	type: string,
	ui: Frame,
	equipped: boolean,
	equip: (self: any) -> (),
	unequip: (self: any) -> (),
	setIndexLabel: (self: any, idxText: string?) -> (),
}

local lastBackpackOpen = tick()
local KEY_MAP = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.Zero] = 10,
}

-- Config
local MAX_TOOLBAR = 10
local HOLD_TO_DRAG_TIME = 0.12

-- State
local toolbar: { ToolClass? } = table.create(MAX_TOOLBAR)
local backpack: { ToolClass } = {}

local BackpackManager = {
	uiVisible = false,
}
BackpackManager.__index = BackpackManager

local engine
function BackpackManager.init(engineModule)
	engine = engineModule

	local InputData = engine:get("InputData")

	Input.PreferredInput.Observe(function(inputType: "Gamepad" | "MouseKeyboard" | "Touch")
		local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
		local inventoryUI = ui:WaitForChild("Inventory")
		if inputType == "Touch" then
			inventoryUI.Tip.Keybinded.Visible = false
			inventoryUI.Tip.Mobile.Visible = true
		else
			inventoryUI.Tip.Keybinded.Visible = true
			inventoryUI.Tip.Mobile.Visible = false
			if inputType == "Gamepad" then
				inventoryUI.Tip.Keybinded.KeybindIcon.Image = InputData.Icons[InputData.Inputs.Backpack.Gamepad.Input]
			else
				inventoryUI.Tip.Keybinded.KeybindIcon.Image =
					InputData.Icons[InputData.Inputs.Backpack.MouseKeyboard.Input]
			end
		end
	end)

	Input.Gamepad.new().ButtonDown:Connect(function(button, processed)
		if processed then
			return
		end
		if button == InputData.Inputs.Backpack.Gamepad.Input then
			BackpackManager:toggleVisible()
		end
	end)

	Input.Keyboard.new().KeyDown:Connect(function(key, processed)
		if processed then
			return
		end

		if key == InputData.Inputs.Backpack.MouseKeyboard.Input then
			BackpackManager:toggleVisible()
		elseif KEY_MAP[key] then
			BackpackManager.equipSlot(KEY_MAP[key])
		end
	end)

	task.spawn(function()
		local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
		local inventoryUI = ui:WaitForChild("Inventory")

		inventoryUI.Tip.Mobile.Activated:Connect(function()
			engine:get("Sound"):playGlobal("Click")
			BackpackManager:toggleVisible()
		end)
	end)
end

function BackpackManager:toggleVisible()
	if tick() - lastBackpackOpen < 0.25 then
		return
	end
	local equipped = false
	for _, tool in pairs(toolbar) do
		if tool.equipped then
			equipped = true
			break
		end
	end
	if equipped then
		return
	end
	local uiVisible = not BackpackManager.uiVisible
	BackpackManager.uiVisible = uiVisible

	local ui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI")
	local inventoryUI = ui:WaitForChild("Inventory")
	inventoryUI.Backpack.Visible = uiVisible
	inventoryUI.BackpackBackground.Visible = uiVisible

	if uiVisible then
		inventoryUI.Tip.Visible = false
	else
		inventoryUI.Tip.Visible = true
	end
	lastBackpackOpen = tick()
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UI = PlayerGui:WaitForChild("UI")
local InventoryGui = UI:WaitForChild("Inventory")
local ToolbarGui = InventoryGui:WaitForChild("Toolbar")
local BackpackGui = InventoryGui:WaitForChild("Backpack")

local ToolbarTemplate = ToolbarGui:WaitForChild("Template") :: Frame
local BackpackTemplate = BackpackGui:WaitForChild("Template") :: Frame

-- Drag (mouse/touch)
local dragging = false
local dragTool: ToolClass? = nil
local dragClone: Frame? = nil
local dragFrom: "Toolbar" | "Backpack" | nil = nil
local dragFromIndex: number? = nil
local mousePos: Vector2 = Vector2.zero

-- External "is carrying" provider (from gamepad controller)
local _externalIsCarrying: (() -> boolean)? = nil

-- ======== Utils ========
local function clearChildrenExceptTemplate(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if
			child ~= container:FindFirstChild("Template")
			and not child:IsA("UIListLayout")
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIAspectRatioConstraint")
			and not child:IsA("UIPadding")
		then
			child:Destroy()
		end
	end
end

local function removeToolEverywhere(t: ToolClass)
	for i = 1, MAX_TOOLBAR do
		if toolbar[i] == t then
			toolbar[i] = nil
		end
	end
	for i = #backpack, 1, -1 do
		if backpack[i] == t then
			table.remove(backpack, i)
		end
	end
end

local function compactToolbar()
	local new = table.create(MAX_TOOLBAR)
	local idx = 1
	for i = 1, MAX_TOOLBAR do
		if toolbar[i] ~= nil then
			new[idx] = toolbar[i]
			idx += 1
		end
	end
	for i = 1, MAX_TOOLBAR do
		toolbar[i] = new[i]
	end
end

local function rectHit(frame: GuiObject, pos: Vector2): boolean
	local p = frame.AbsolutePosition
	local s = frame.AbsoluteSize
	print(frame.Name, ":", pos.X >= p.X, pos.X <= p.X + s.X, pos.Y >= p.Y, pos.Y <= p.Y + s.Y)
	return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

local function getToolbarInsertIndex(pos: Vector2): number
	local list = {}
	for _, child in ipairs(ToolbarGui:GetChildren()) do
		if child:IsA("Frame") and child ~= ToolbarTemplate then
			table.insert(list, child)
		end
	end
	table.sort(list, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i, child in ipairs(list) do
		if rectHit(child, pos) then
			return i
		end
	end
	return #list + 1
end

local function getBackpackInsertIndex(pos: Vector2): number
	local grid = {}
	for _, child in ipairs(BackpackGui:GetChildren()) do
		if child:IsA("Frame") and child ~= BackpackTemplate then
			table.insert(grid, child)
		end
	end
	for i, child in ipairs(grid) do
		if rectHit(child, pos) then
			return i
		end
	end
	return #grid + 1
end

-- ======== Rendering ========
local function render()
	clearChildrenExceptTemplate(ToolbarGui)
	clearChildrenExceptTemplate(BackpackGui)

	for i = 1, MAX_TOOLBAR do
		local t = toolbar[i]
		if t then
			t.ui.Parent = ToolbarGui
			t.setIndexLabel(t, tostring(i))
			t.ui.Visible = true
		end
	end

	for _, t in ipairs(backpack) do
		t.ui.Parent = BackpackGui
		t.setIndexLabel(t, nil)
		t.ui.Visible = true
	end
end

-- ======== Insert helpers ========
local function insertToolbar(t: ToolClass, index: number)
	if index < 1 then
		index = 1
	end
	if index > MAX_TOOLBAR then
		index = MAX_TOOLBAR
	end

	local count = 0
	for i = 1, MAX_TOOLBAR do
		if toolbar[i] ~= nil then
			count += 1
		end
	end

	if count >= MAX_TOOLBAR then
		local last = toolbar[MAX_TOOLBAR]
		if last then
			toolbar[MAX_TOOLBAR] = nil
			table.insert(backpack, last)
		end
	end

	for i = MAX_TOOLBAR, index, -1 do
		toolbar[i] = toolbar[i - 1]
	end
	toolbar[index] = t
end

local function insertBackpack(t: ToolClass, index: number)
	if index < 1 then
		index = 1
	end
	if index > #backpack + 1 then
		index = #backpack + 1
	end
	table.insert(backpack, index, t)
end

-- ======== Drag (mouse/touch) ========
local function beginDrag(t: ToolClass, from: "Toolbar" | "Backpack", fromIndex: number, startPos: Vector2)
	if dragging then
		return
	end
	dragging = true
	dragTool = t
	dragFrom = from
	dragFromIndex = fromIndex

	dragClone = t.ui:Clone() --(from == "Toolbar" and ToolbarTemplate or BackpackTemplate):Clone()
	if dragClone then
		dragClone.Name = "DragGhost"
		dragClone.Visible = true
		dragClone.AnchorPoint = Vector2.new(0.5, 0.5)
		dragClone.Size = UDim2.fromOffset(t.ui.AbsoluteSize.X, t.ui.AbsoluteSize.Y)
		dragClone.Parent = UI
		-- for _, child in ipairs(t.ui:GetChildren()) do
		-- 	child:Clone().Parent = dragClone
		-- end
	end

	t.ui.Parent = UI
	t.ui.Visible = false

	mousePos = startPos
	if dragClone then
		dragClone.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
	end
end

local function updateDrag(pos: Vector2)
	if not dragging or not dragClone then
		return
	end
	mousePos = pos
	dragClone.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
end

local function cancelDrag()
	if not dragging then
		return
	end
	local t = dragTool
	if not t then
		return
	end

	if dragFrom == "Toolbar" and dragFromIndex then
		insertToolbar(t, dragFromIndex)
		compactToolbar()
	else
		insertBackpack(t, (dragFromIndex or (#backpack + 1)))
	end
	render()

	if dragClone then
		dragClone:Destroy()
	end
	dragging = false
	dragTool = nil
	dragClone = nil
	dragFrom = nil
	dragFromIndex = nil
end

local function getDropTarget(pos: Vector2): { target: "Toolbar" | "Backpack", index: number }?
	if rectHit(ToolbarGui, pos) then
		return { target = "Toolbar", index = getToolbarInsertIndex(pos) }
	elseif BackpackGui.Visible and rectHit(BackpackGui, pos) then
		return { target = "Backpack", index = getBackpackInsertIndex(pos) }
	end
	return nil
end

local function finishDrag()
	if not dragging then
		return
	end
	local t = dragTool :: ToolClass
	local drop = getDropTarget(mousePos)
	if not drop then
		cancelDrag()
		return
	end

	removeToolEverywhere(t)
	if drop.target == "Toolbar" then
		insertToolbar(t, drop.index)
		compactToolbar()
	else
		insertBackpack(t, drop.index)
	end

	if t.equipped then
		local stillToolbar = false
		for i = 1, MAX_TOOLBAR do
			if toolbar[i] == t then
				stillToolbar = true
				break
			end
		end
		if not stillToolbar then
			t:unequip()
		end
	end

	if dragClone then
		dragClone:Destroy()
	end
	dragging = false
	dragTool = nil
	dragClone = nil
	dragFrom = nil
	dragFromIndex = nil
	render()
end

local function attachDragHandlers(t: ToolClass)
	local button = t.ui:FindFirstChild("Button")
	if not button or not button:IsA("GuiButton") then
		return
	end

	local pressed = false
	local pressedAt = 0
	local moveConn: RBXScriptConnection? = nil

	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			pressed = true
			pressedAt = time()

			-- determine origin
			local parentName = if t.ui.Parent == ToolbarGui
				then "Toolbar"
				elseif t.ui.Parent == BackpackGui then "Backpack"
				else nil
			local from = parentName :: "Toolbar" | "Backpack" | nil
			local idx = 0
			if from == "Toolbar" then
				for i = 1, MAX_TOOLBAR do
					if toolbar[i] == t then
						idx = i
						break
					end
				end
			elseif from == "Backpack" then
				for i = 1, #backpack do
					if backpack[i] == t then
						idx = i
						break
					end
				end
			end

			moveConn = UserInputService.InputChanged:Connect(function(chg)
				if not pressed then
					return
				end
				if
					chg.UserInputType ~= Enum.UserInputType.MouseMovement
					and chg.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end
				local pos = UserInputService:GetMouseLocation()
				if (time() - pressedAt) >= HOLD_TO_DRAG_TIME and not dragging then
					if from and idx > 0 then
						beginDrag(t, from, idx, pos)
					end
				end
				if dragging then
					print(pos)
					updateDrag(pos)
				end
			end)
		end
	end)

	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local shortClick = (time() - pressedAt) < HOLD_TO_DRAG_TIME
			pressed = false
			if dragging then
				finishDrag()
			elseif shortClick then
				if t.equipped then
					t:unequip()
				else
					t:equip()
				end
			end
			if moveConn then
				moveConn:Disconnect()
				moveConn = nil
			end
		end
	end)
end

-- ======== Public API ========
function BackpackManager.addTool(t: ToolClass)
	removeToolEverywhere(t)
	local placed = false
	for i = 1, MAX_TOOLBAR do
		if toolbar[i] == nil then
			toolbar[i] = t
			placed = true
			break
		end
	end
	if not placed then
		table.insert(backpack, t)
	end
	t.ui.Visible = true
	-- Make gamepad-selectable by default
	local btn = t.ui:FindFirstChild("Button")
	if btn and btn:IsA("GuiButton") then
		btn.Selectable = true
	end
	attachDragHandlers(t)
	render()
end

function BackpackManager.removeToolByRef(t: ToolClass)
	removeToolEverywhere(t)
	if t.equipped then
		t:unequip()
	end
	render()
end

function BackpackManager.getToolbar(): { ToolClass? }
	return toolbar
end
function BackpackManager.getBackpack(): { ToolClass }
	return backpack
end

function BackpackManager.moveToolToToolbar(t: ToolClass, index: number?)
	removeToolEverywhere(t)
	insertToolbar(t, index or MAX_TOOLBAR)
	compactToolbar()
	render()
end

function BackpackManager.moveToolToBackpack(t: ToolClass, index: number?)
	removeToolEverywhere(t)
	insertBackpack(t, index or (#backpack + 1))
	render()
end

function BackpackManager.equipSlot(slotIndex: number)
	if slotIndex < 1 or slotIndex > MAX_TOOLBAR then
		return
	end
	local t = toolbar[slotIndex]
	if not t then
		return
	end
	if t.equipped then
		t:unequip()
	else
		t:equip()
	end
end

function BackpackManager.refresh()
	render()
end

-- Gamepad integration hooks
function BackpackManager._setIsCarryingProvider(fn: () -> boolean)
	_externalIsCarrying = fn
end
function BackpackManager.isCarrying(): boolean
	return dragging or (_externalIsCarrying and _externalIsCarrying()) or false
end

return BackpackManager
