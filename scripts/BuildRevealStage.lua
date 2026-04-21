-- Paste into Studio's Command Bar (View > Command Bar)
-- Replaces the "Stage" part in Workspace with the RevealStage model

local stagePart = workspace:FindFirstChild("Stage")
assert(stagePart, "No part named 'Stage' found in Workspace")

local origin = stagePart.CFrame

-- Model
local model = Instance.new("Model")
model.Name = "RevealStage"

-- GeodeAnchor: the world origin used as (0,0,0) for geode model positioning
local anchor = Instance.new("Part")
anchor.Name = "GeodeAnchor"
anchor.Size = Vector3.new(1, 1, 1)
anchor.CFrame = origin
anchor.Anchored = true
anchor.CanCollide = false
anchor.CastShadow = false
anchor.Transparency = 1
anchor.Parent = model

-- CamPart: where the camera sits during the reveal (8 studs in front of anchor)
local camPart = Instance.new("Part")
camPart.Name = "CamPart"
camPart.Size = Vector3.new(0.5, 0.5, 0.5)
camPart.CFrame = origin * CFrame.new(0, 0, 8)
camPart.Anchored = true
camPart.CanCollide = false
camPart.CastShadow = false
camPart.Transparency = 1
camPart.Parent = model

model.PrimaryPart = anchor
model.Parent = workspace

stagePart:Destroy()

print("[BuildRevealStage] Done — RevealStage created at", origin.Position)
