local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

local Utility = {}

function Utility:ModelTween(Model, TweenEnd, TweenInfo)
	local TweenService = game:GetService("TweenService")
    local CFValue = Instance.new("CFrameValue")

	return Promise.new(function(resolve, reject, onCancel)
	
		CFValue.Value = Model:GetPivot()
    	local tween = TweenService:Create(CFValue, TweenInfo, {Value = TweenEnd})

		tween:Play()

		local Changed = CFValue.Changed:Connect(function()
			Model:PivotTo(CFValue.Value)
		end)


		tween.Completed:Connect(function()
			Changed:Disconnect()
            CFValue:Destroy()
			resolve()
		end)
	end)
    

    

    
end

return Utility