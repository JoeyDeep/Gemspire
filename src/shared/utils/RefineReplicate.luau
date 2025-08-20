local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RefineRep = {}

local engine
function RefineRep.init(engineModule)
	engine = engineModule
end

function RefineRep:setProgress(hostClient, equippedKit, progress, targetRubble)
	local QuickTween = engine:get("QuickTween")
	local Kits = engine:get("Kits")
	local Loot = engine:get("Loot")

	local kitData = Kits[equippedKit]
	local equippedTray = Kits[equippedKit].tray
	local hostCharacter = hostClient.Character

	if
		not hostCharacter
		or not hostCharacter:FindFirstChild(`{equippedTray}_Tray`)
		or not hostCharacter[`{equippedTray}_Tray`]:FindFirstChild("Handle")
	then
		return
	end

	progress = 1 - progress

	local trayModel = hostCharacter[`{equippedTray}_Tray`]

	for _, lootObj in pairs(trayModel.Loot:GetChildren()) do
		local largestAxis = math.max(lootObj.Size.X, lootObj.Size.Y, lootObj.Size.Z)
		if
			lootObj.Position.Y - largestAxis / 2 < trayModel.RefineEntities.FillPlane.Position.Y
			or not lootObj:FindFirstChild("WeldConstraint")
		then
			continue
		end

		local lootData = Loot[lootObj.Name]
		lootObj.CollisionGroup = "Loot"
		lootObj.CanCollide = true
		lootObj.WeldConstraint:Destroy()

		if hostClient.Name == hostCharacter.Name then
			local billboard = ReplicatedStorage.Storage.Billboards.Loot:Clone()
			billboard.TextLabel.Text = lootData.name
			billboard.TextLabel.TextColor3 = lootData.color
			billboard.StudsOffset = Vector3.new(0, largestAxis / 1.5, 0)
			billboard.Parent = lootObj
		end
	end

	if progress > 0.75 then
		trayModel.RefineEntities.FillPlane.Motor6D.C0 = kitData.rubbleMotorData.Min
		targetRubble.Size *= Vector3.new(0.5, 0.5, 0.5)
	else
		local alpha = progress
		local goalC0 = kitData.rubbleMotorData.Max:Lerp(kitData.rubbleMotorData.Min, alpha)
		QuickTween(trayModel.RefineEntities.FillPlane.Motor6D, 0.35, { C0 = goalC0 })
		targetRubble.Size *= Vector3.new(0.9, 0.9, 0.9)
	end
end

return RefineRep
