local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")

local Purse = require(ReplicatedStorage.Packages.Purse)

local PurseService = {
	_purse = Purse,
	_hiddenCount = 0,
}
PurseService.__index = PurseService

local engine

local function setCoreBackpackDisabled()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end

local function getBackpackGui()
	local playerGui = engine and engine.PlayerGui
	if not playerGui then
		return nil
	end
	return playerGui:FindFirstChild("BackpackGui")
end

local function setBackpackGuiEnabled(enabled)
	local backpackGui = getBackpackGui()
	if backpackGui then
		backpackGui.Enabled = enabled
	end
end

local function removeLegacyInventoryFrame()
	local playerGui = engine and engine.PlayerGui
	local uiRoot = playerGui and playerGui:FindFirstChild("UI")
	local legacyInventory = uiRoot and uiRoot:FindFirstChild("Inventory")
	if legacyInventory then
		legacyInventory:Destroy()
	end
end

local function bindLegacyInventoryCleanup()
	local playerGui = engine and engine.PlayerGui
	if not playerGui then
		return
	end

	local function bindUiRoot(uiRoot)
		if not uiRoot then
			return
		end
		removeLegacyInventoryFrame()
		uiRoot.ChildAdded:Connect(function(child)
			if child.Name == "Inventory" then
				child:Destroy()
			end
		end)
	end

	bindUiRoot(playerGui:FindFirstChild("UI"))
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "UI" then
			bindUiRoot(child)
		end
	end)
end

function PurseService.init(engineModule)
	engine = engineModule
	bindLegacyInventoryCleanup()
	setCoreBackpackDisabled()
	setBackpackGuiEnabled(true)

	local InputData = engine:get("InputData")
	local backpackInputs = InputData and InputData.Inputs and InputData.Inputs.Backpack
	local keyCodes = {}
	if backpackInputs then
		for _, inputData in pairs(backpackInputs) do
			if inputData.Type == "KeyCode" and inputData.Input then
				table.insert(keyCodes, inputData.Input)
			end
		end
	end

	if #keyCodes > 0 then
		ContextActionService:BindAction("PurseToggle", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				PurseService:toggle()
			end
		end, false, table.unpack(keyCodes))
	end
end

function PurseService:getPurse()
	return self._purse
end

function PurseService:isOpen()
	return self._purse.IsOpen == true
end

function PurseService:open()
	if self._hiddenCount > 0 then
		return
	end
	if self._purse.OpenClose and not self:isOpen() then
		self._purse.OpenClose()
	end
end

function PurseService:close()
	if self._purse.OpenClose and self:isOpen() then
		self._purse.OpenClose()
	end
end

function PurseService:toggle()
	if self._hiddenCount > 0 then
		return
	end
	if self._purse.OpenClose then
		self._purse.OpenClose()
	end
end

function PurseService:setVisible(visible)
	setCoreBackpackDisabled()
	if visible then
		self._hiddenCount = 0
		setBackpackGuiEnabled(true)
	else
		self._hiddenCount = 1
		self:close()
		setBackpackGuiEnabled(false)
	end
end

function PurseService:pushHidden()
	self._hiddenCount += 1
	self:close()
	setBackpackGuiEnabled(false)
	setCoreBackpackDisabled()
end

function PurseService:popHidden()
	if self._hiddenCount > 0 then
		self._hiddenCount -= 1
	end
	setCoreBackpackDisabled()
	if self._hiddenCount == 0 then
		setBackpackGuiEnabled(true)
	end
end

function PurseService:bindStateChanged(callback)
	return self._purse.StateChanged.Event:Connect(callback)
end

return PurseService
