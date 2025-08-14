return function(object, time, properties, tweenInfo)
	if not object or not time or not properties then
		error("QuickTween: Missing required parameters")
	end

	local tweenService = game:GetService("TweenService")
	local tween = tweenService:Create(object, tweenInfo or TweenInfo.new(time, Enum.EasingStyle.Linear), properties)

	tween:Play()

	return tween
end
