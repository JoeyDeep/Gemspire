local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

function bind(method, self)
    return function(...)
        return method(self, ...)
    end
end


local PlacedDrill = {
	activeClass = nil,
	spawnTime = nil,
	drillInfo = nil,
	timeUntilNextYield = nil,
}
PlacedDrill.__index = PlacedDrill

local engine
function PlacedDrill.init(engineModule)
	engine = engineModule
end

function PlacedDrill.new(drillObj)
	local self = setmetatable({}, PlacedDrill)

	local playerData = engine:get("PlayerService").data

	

	local Drills = engine:get("Drills")

	PlacedDrill.drillInfo = Drills[playerData.drill.type]

	self.drill = drillObj

	PlacedDrill.activeClass = self
	PlacedDrill.spawnTime = playerData.drill.spawnTime

	self:placementAnimation()
	-- decide an appropriate timing for this. 
	-- should we instead be listening for a server fired event? 
	-- probably. the important thing is start after client playerData is updated
	task.delay(2, bind(self.enableUI,self) )
		

	return self
end


function PlacedDrill:placementAnimation()

	local QuickTeen = engine:get("QuickTween")

	local animatedParts = self.drill.AnimatedParts:GetChildren()
	local goalParts = self.drill.GoalDrill.AnimatedParts
	local orginalPartPositions = {}
	local promiseList = {}

	for index, part in ipairs(animatedParts) do 
		orginalPartPositions[part.Name] = {
			CFrame = part.CFrame,
			Size = part.Size,
		}
		promiseList[index] = Promise.new(function(resolve, reject, onCancel)
			local tween = QuickTeen(part,2,{
				CFrame=goalParts["Goal_"..part.Name].CFrame,
				Size=goalParts["Goal_"..part.Name].Size
			})
			tween.Completed:Connect(resolve)
		end)
		
		
	end

	Promise.all(promiseList):andThen(function()
		
		for index, part in ipairs(animatedParts) do 
			local orginalPartInfo = orginalPartPositions[part.Name]

			local CFrameLerp = orginalPartInfo.CFrame:Lerp(goalParts["Goal_"..part.Name].CFrame,0.5)
			local SizeLerp = orginalPartInfo.Size:Lerp(goalParts["Goal_"..part.Name].Size,0.5)

			QuickTeen(part,2,{
				CFrame=CFrameLerp,
				Size=SizeLerp
			},
				TweenInfo.new(
					2,
					Enum.EasingStyle.Cubic,
					Enum.EasingDirection.InOut,
					-1,
					true,
					1
				)
			)
		end
	end)	

	

end

function PlacedDrill:enableUI()

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local storage = ReplicatedStorage.Storage

	-- Rename to "DrillProgressBar"
	local progressBar = storage.Billboards.ProgressBar:Clone()
	progressBar.Adornee = self.drill
	progressBar.Parent = playerGui

	self.progressBar = progressBar

	self:startProgressBar()
	self:enablePrompt()

end

function PlacedDrill:enablePrompt()
	local PromptService = engine:get("PromptService")

	local myPrompt = PromptService.new()
	myPrompt.prompt.ActionText = "Collect Loot"
	myPrompt.prompt.ObjectText = "Drill"
	myPrompt.prompt.Parent = self.drill
	-- myPrompt.Enabled = true
	-- myPrompt.prompt.MaxActivationDistance = 10

	myPrompt.prompt.Triggered:Connect(bind(self.collectLoot,self))

	self.prompt = myPrompt

end

function PlacedDrill:collectLoot()
	engine.events.Drill:FireServer("collectLoot")
end

function PlacedDrill:startProgressBar()

	
	local totalYield = self:calculateTotalYield()

	local fill = self.progressBar.Bar:WaitForChild("Fill")

	local lootText = self.progressBar:WaitForChild("LootText")

	lootText.Text = tostring(totalYield) .. "/" .. tostring(self.drillInfo.maxLoot)

	if totalYield >= self.drillInfo.maxLoot then
		fill.Size = UDim2.new(1, 0, 1, 0)
	else
		local progress = self:calculateProgressToNextYield() / (self.drillInfo.lootInterval * 60)


		fill.Size = UDim2.new(progress, 0, 1, 0)  -- Reset empty

		
		local tweenInfo = TweenInfo.new(
			self.drillInfo.lootInterval * 60,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut,
			0, false, 0
		)

		local goal = {Size = UDim2.new(1, 0, 1, 0)}

		local tween = TweenService:Create(fill, tweenInfo, goal)

		tween.Completed:Connect(bind(self.startProgressBar,self))

		tween:Play()
	end

	

end

function PlacedDrill:calculateProgressToNextYield()
	local playerData = engine:get("PlayerService").data
	local interval = self.drillInfo.lootInterval * 60
	local totalProgress = os.time() - playerData.drill.spawnTime
	local progressUntilNextLoot = totalProgress % interval

	return progressUntilNextLoot
end

function PlacedDrill:calculateTotalYield()
	local playerData = engine:get("PlayerService").data
	local interval = self.drillInfo.lootInterval * 60
	local totalProgress = os.time() - playerData.drill.spawnTime
	local totalYield = math.floor(totalProgress / interval)

	if totalYield > self.drillInfo.maxLoot then 
		totalYield = self.drillInfo.maxLoot
	end 

	return totalYield
end

return PlacedDrill