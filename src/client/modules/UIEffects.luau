-- UIEffectsModule.luau
-- A module for UI text effects

local UIEffectsModule = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


-- Parameters:
--   textLabel: The TextLabel GUI object to apply the effect to
--   fullText: The complete text to be typed out
--   speed: Time delay between each character (in seconds, default: 0.05)
--   callback: Optional function to call when typing is complete
function UIEffectsModule.typewriterEffect(textLabel, fullText, speed, callback)
	if not textLabel or not textLabel:IsA("TextLabel") then
		warn("UIEffectsModule.typewriterEffect: First parameter must be a TextLabel")
		return
	end

	if type(fullText) ~= "string" then
		warn("UIEffectsModule.typewriterEffect: Second parameter must be a string")
		return
	end

	speed = speed or 0.05
	textLabel.Text = ""

	local currentIndex = 0
	local connection
	local lastUpdateTime = tick()

	connection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()

		if currentTime - lastUpdateTime >= speed then
			currentIndex = currentIndex + 1

			if currentIndex <= #fullText then
				textLabel.Text = string.sub(fullText, 1, currentIndex)
				lastUpdateTime = currentTime
			else
				connection:Disconnect()

				if callback and type(callback) == "function" then
					callback()
				end
			end
		end
	end)

	return connection
end


function UIEffectsModule.typewriterEffectWithCursor(textLabel, fullText, speed, cursorChar, callback)
	if not textLabel or not textLabel:IsA("TextLabel") then
		warn("UIEffectsModule.typewriterEffectWithCursor: First parameter must be a TextLabel")
		return
	end

	if type(fullText) ~= "string" then
		warn("UIEffectsModule.typewriterEffectWithCursor: Second parameter must be a string")
		return
	end

	speed = speed or 0.05
	cursorChar = cursorChar or "|"

	textLabel.Text = cursorChar

	local currentIndex = 0
	local connection
	local lastUpdateTime = tick()
	local cursorVisible = true
	local cursorBlinkTime = 0.5 
	local lastCursorBlink = tick()

	connection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()

		if currentTime - lastCursorBlink >= cursorBlinkTime then
			cursorVisible = not cursorVisible
			lastCursorBlink = currentTime
		end

		if currentTime - lastUpdateTime >= speed and currentIndex < #fullText then
			currentIndex = currentIndex + 1
			lastUpdateTime = currentTime
		end

		local displayText = string.sub(fullText, 1, currentIndex)

		if currentIndex < #fullText then
			if cursorVisible then
				displayText = displayText .. cursorChar
			end
			textLabel.Text = displayText
		else
			textLabel.Text = fullText
			connection:Disconnect()

			if callback and type(callback) == "function" then
				callback()
			end
		end
	end)

	return connection
end

function UIEffectsModule.fadeIn(guiObject, duration, callback)
	if not guiObject then
		warn("UIEffectsModule.fadeIn: GUI object is required")
		return
	end

	duration = duration or 1

	if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("ImageLabel") then
		guiObject.BackgroundTransparency = 1
		if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
			guiObject.TextTransparency = 1
		end
		if guiObject:IsA("ImageLabel") then
			guiObject.ImageTransparency = 1
		end
	end

	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local targetProperties = {}
	if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("ImageLabel") then
		targetProperties.BackgroundTransparency = 0
		if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
			targetProperties.TextTransparency = 0
		end
		if guiObject:IsA("ImageLabel") then
			targetProperties.ImageTransparency = 0
		end
	end

	local tween = TweenService:Create(guiObject, tweenInfo, targetProperties)
	tween:Play()

	if callback and type(callback) == "function" then
		tween.Completed:Connect(callback)
	end

	return tween
end

function UIEffectsModule.stopEffect(connection)
	if connection and connection.Connected then
		connection:Disconnect()
	end
end

return UIEffectsModule