local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pipecutter = {
	transparencyCache = {},
}

local engine
function Pipecutter.init(engineModule)
	engine = engineModule
end

function Pipecutter:start(station, geodeTool)
	local QuickTween = engine:get("QuickTween")

	local returnEvent = Instance.new("BindableEvent")

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = station.CamPart.CFrame

	local placeholder = station.Placeholder
	for _, basePart in pairs(placeholder:GetDescendants()) do
		if basePart:IsA("BasePart") then
			Pipecutter.transparencyCache[basePart] = basePart.Transparency
			basePart.Transparency = 1
		end
	end

	local pipecutter = ReplicatedStorage.Storage.GeodeCutters.Pipecutter:Clone()
	pipecutter:PivotTo(placeholder:GetPivot())
	pipecutter.Parent = station

	pipecutter.GeodeOrigin.Material = geodeTool.Handle.Material
	pipecutter.GeodeOrigin.Color = geodeTool.Handle.Color
	pipecutter.GeodeOrigin.Transparency = 0

	task.spawn(function()
		local cfValue = Instance.new("CFrameValue")
		cfValue.Value = pipecutter:GetPivot()
		cfValue:GetPropertyChangedSignal("Value"):Connect(function()
			pipecutter:PivotTo(cfValue.Value)
		end)
		QuickTween(cfValue, 0.4, { Value = pipecutter.GeodeOrigin.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.5)) })
		QuickTween(camera, 0.3, { CFrame = station.CamPart.CFrame:ToWorldSpace(CFrame.new(0, 0, 0.25)) })
		task.wait(0.4)
		cfValue:Destroy()
	end)

	return returnEvent
end

function Pipecutter:cleanup()
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	for basePart, transparency in pairs(Pipecutter.transparencyCache) do
		basePart.Transparency = transparency
	end
end

return Pipecutter
