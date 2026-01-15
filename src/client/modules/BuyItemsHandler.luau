local BuyItemsHandler = {}

local engine
function BuyItemsHandler.init(engineRef)
	engine = engineRef
end

BuyItemsHandler.activePurchase = nil
BuyItemsHandler.purchaseInFlight = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatVisuals = require(ReplicatedStorage.Shared.GameData.StatVisuals)

function BuyItemsHandler:setup()
	engine:await("PromptService")

	local PromptService = engine:get("PromptService")
	local Pickaxes = engine:get("Pickaxes")
	local Kits = engine:get("Kits")

	local UI = engine.PlayerGui.UI.EquipmentBuy

	for _, buyItem in pairs(workspace.Entities.BuyItems:GetChildren()) do
		local itemType = buyItem:GetAttribute("Type")
		local itemData = itemType == "Pickaxe" and Pickaxes[buyItem:GetAttribute("ItemName")]
			or itemType == "Kit" and Kits[buyItem:GetAttribute("ItemName")]
		local newPrompt = PromptService.new()
		newPrompt:set("ActionText", `View [<font color="rgb(255, 231, 94)">${itemData.price}</font>]`)
		newPrompt:set("ObjectText", itemData.name)
		newPrompt:set("Parent", buyItem)

		newPrompt.prompt.Triggered:Connect(function()
			PromptService:disableAll()
			self:openUI(buyItem, itemData, itemType)
		end)
	end

	UI.ConfirmNo.Activated:Connect(function()
		BuyItemsHandler:closeUI()
	end)
	UI.ConfirmYes.Activated:Connect(function()
		BuyItemsHandler:confirmPurchase()
	end)
end

function BuyItemsHandler:openUI(buyItem, itemData, itemType)
	local QuickTween = engine:get("QuickTween")
	local PlayerService = engine:get("PlayerService")
	local camera = workspace.CurrentCamera

	local blur = Instance.new("BlurEffect")
	local shopName = buyItem:GetAttribute("Shop") or "Shop"
	local UI = engine.PlayerGui.UI.EquipmentBuy
	local currentItemName = PlayerService.data.equipped[string.lower(itemType)]
	local currentItemData = itemType == "Pickaxe" and engine:get("Pickaxes")[currentItemName]
		or itemType == "Kit" and engine:get("Kits")[currentItemName]

	self.activePurchase = {
		itemType = itemType,
		itemName = buyItem:GetAttribute("ItemName"),
		itemData = itemData,
	}
	self.purchaseInFlight = false

	UI.Visible = false
	UI.UIScale.Scale = 0.25
	UI.Position = UDim2.fromScale(0.5, 0.8)
	blur.Size = 0
	blur.Parent = game:GetService("Lighting")

	UI.Header.Header.Text = shopName
	UI.Price.Text = `Price: <font color="rgb(255, 231, 94)">${itemData.price}</font>`
	UI.Description.Text = itemData.description
	UI.ConfirmText.Text = `Do you want to buy {itemData.name}?`

	for _, oldStat in pairs(UI.Stats:GetChildren()) do
		if oldStat.Name ~= "StatTemplate" and oldStat.Name ~= "UIListLayout" then
			oldStat:Destroy()
		end
	end

	local count = 0
	for name, value in pairs(itemData.stats) do
		local statData = StatVisuals[name]
		if statData then
			local statFrame = UI.Stats.StatTemplate:Clone()
			statFrame.Visible = true
			local secondaryColorRich = string.format(
				"rgb(%d, %d, %d)",
				math.floor(statData.secondaryColor.R * 255),
				math.floor(statData.secondaryColor.G * 255),
				math.floor(statData.secondaryColor.B * 255)
			)
			local maxStat = (typeof(statData.maxStat) == "table" and statData.maxStat.max) or statData.maxStat or 0
			local viewValue = value
			if typeof(viewValue) == "table" then
				viewValue = viewValue.max
			end
			if typeof(viewValue) ~= "number" then
				viewValue = 0
			end

			local currentValue = 0
			if currentItemData and currentItemData.stats then
				currentValue = currentItemData.stats[name]
			end
			if typeof(currentValue) == "table" then
				currentValue = currentValue.max
			end
			if typeof(currentValue) ~= "number" then
				currentValue = 0
			end

			statFrame.StatName.Text =
				`{statData.name}: {viewValue} <font color="{secondaryColorRich}">({currentValue})</font>`
			statFrame.StatName.TextColor3 = statData.color

			local denom = (typeof(maxStat) == "number" and maxStat > 0) and maxStat or math.max(viewValue, currentValue, 1)
			local desiredX = math.clamp(viewValue / denom, 0, 1)
			local secondaryDesiredX = math.clamp(currentValue / denom, 0, 1)
			statFrame.BarFrame.BarOverlayFill.Size = UDim2.fromScale(0, 1)
			statFrame.BarFrame.BarOverlayFill.BackgroundColor3 = statData.secondaryColor
			statFrame.BarFrame.BarFill.Size = UDim2.fromScale(0, 1)
			statFrame.BarFrame.BarFill.BackgroundColor3 = statData.color
			if currentValue > viewValue then
				statFrame.BarFrame.BarOverlayFill.ZIndex = 0
			else
				statFrame.BarFrame.BarOverlayFill.ZIndex = 2
			end
			task.delay(0.1 * count, function()
				QuickTween(statFrame.BarFrame.BarFill, 0.25, { Size = UDim2.fromScale(desiredX, 1) })
				QuickTween(statFrame.BarFrame.BarOverlayFill, 1, { Size = UDim2.fromScale(secondaryDesiredX, 1) })
			end)
			statFrame.Name = name
			count += 1
			statFrame.Parent = UI.Stats
		end
	end

	UI.Visible = true
	QuickTween(UI.UIScale, 0.15, { Scale = 1 })
	QuickTween(UI, 0.15, { Position = UDim2.fromScale(0.5, 0.5) })
	QuickTween(camera, 0.2, { FieldOfView = 50 })
	QuickTween(blur, 0.2, { Size = 9 })
end

function BuyItemsHandler:confirmPurchase()
	if self.purchaseInFlight then
		return
	end

	local purchase = self.activePurchase
	if not purchase then
		return
	end

	local PlayerService = engine:get("PlayerService")
	local NotificationService = engine:get("NotificationService")
	local typeKey = string.lower(purchase.itemType or "")

	if PlayerService.data.equipped[typeKey] == purchase.itemName then
		NotificationService.new(
			"You already have this equipped!",
			{ italic = true, textColor = Color3.fromRGB(230, 75, 77) }
		)
		return
	end

	local price = purchase.itemData and purchase.itemData.price or 0
	if PlayerService.data.coins < price then
		NotificationService.new("Not enough gold.", { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
		return
	end

	self.purchaseInFlight = true
	engine.events.Inventory:FireServer("buyItem", {
		itemType = purchase.itemType,
		itemName = purchase.itemName,
	})
end

function BuyItemsHandler:handlePurchaseResult(success, data)
	self.purchaseInFlight = false

	if not success then
		local NotificationService = engine:get("NotificationService")
		local reason = data and data.reason
		local message = "Purchase failed."

		if reason == "insufficientFunds" then
			message = "Not enough gold."
		elseif reason == "alreadyEquipped" then
			message = "You already have this equipped!"
		elseif reason == "invalidItem" then
			message = "That item isn't available."
		end

		NotificationService.new(message, { italic = true, textColor = Color3.fromRGB(230, 75, 77) })
		return
	end

	self.activePurchase = nil
	self:closeUI()
end

function BuyItemsHandler:closeUI()
	local QuickTween = engine:get("QuickTween")
	local PromptService = engine:get("PromptService")
	local camera = workspace.CurrentCamera

	local blur = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
	local UI = engine.PlayerGui.UI.EquipmentBuy

	QuickTween(UI.UIScale, 0.15, { Scale = 0.25 })
	QuickTween(UI, 0.15, { Position = UDim2.fromScale(0.5, 0.8) }).Completed:Wait()
	UI.Visible = false
	QuickTween(camera, 0.2, { FieldOfView = 70 })
	if blur then
		QuickTween(blur, 0.2, { Size = 0 }).Completed:Wait()
		blur:Destroy()
	end
	PromptService:reEnableAll()

	self.activePurchase = nil
	self.purchaseInFlight = false
end

return BuyItemsHandler
