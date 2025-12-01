-- Typewriter.lua — RichText-safe typewriter using MaxVisibleGraphemes (time-based CPS)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DEFAULTS = {
	cps = 30, -- characters (visible graphemes) per second
	punctuationSlowdown = true,
	puncExtra = 0.08, -- extra seconds after . , ! ? ; :
	immediateOnSkip = true,
	skipInputs = { Enum.KeyCode.Space, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter },
}

local liveTypers = {}

local function isPunc(ch)
	return ch == "." or ch == "!" or ch == "?" or ch == "," or ch == ";" or ch == ":"
end

-- utf8-safe substring to get codepoint at index
local function utf8_char_at(s, idx)
	local i = utf8.offset(s, idx)
	if not i then
		return nil
	end
	local j = utf8.offset(s, idx + 1)
	if not j then
		return string.sub(s, i)
	end
	return string.sub(s, i, j - 1)
end

local function connectSkip(skipInputs, onSkip)
	local conns = {}
	table.insert(
		conns,
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				for _, code in ipairs(skipInputs) do
					if input.KeyCode == code then
						onSkip()
						return
					end
				end
			elseif
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				onSkip()
			end
		end)
	)
	return conns
end

local function disconnectAll(conns)
	for _, c in ipairs(conns) do
		if c.Connected then
			c:Disconnect()
		end
	end
end

-- Compute total visible graphemes WITHOUT flashing text:
-- clone an invisible copy, let it render once, read ContentText length.
local function measureVisibleLen(guiObject, fullText)
	local ghost = guiObject:Clone()
	ghost.Visible = false
	ghost.Text = fullText
	ghost.MaxVisibleGraphemes = math.huge
	ghost.Parent = guiObject.Parent
	RunService.Heartbeat:Wait() -- allow render step
	local content = ghost.ContentText ~= "" and ghost.ContentText or ghost.Text
	local total = utf8.len(content) or #content
	ghost:Destroy()
	return total, content
end

local Typewriter = {}

local engine
function Typewriter.init(engineModule)
	engine = engineModule
end

-- guiObject: TextLabel/TextButton/TextBox (RichText supported)
-- fullText: string (may include <b>, <i>, <font>, etc.)
-- opts: { cps, punctuationSlowdown, puncExtra, immediateOnSkip, skipInputs, onChar }
function Typewriter.Play(guiObject, fullText, opts)
	opts = opts or {}
	local cps = opts.cps or DEFAULTS.cps
	local punctuationSlowdown = (opts.punctuationSlowdown ~= nil) and opts.punctuationSlowdown
		or DEFAULTS.punctuationSlowdown
	local puncExtra = (opts.puncExtra ~= nil) and opts.puncExtra or DEFAULTS.puncExtra
	local immediateOnSkip = (opts.immediateOnSkip ~= nil) and opts.immediateOnSkip or DEFAULTS.immediateOnSkip
	local skipInputs = opts.skipInputs or DEFAULTS.skipInputs
	local onChar = opts.onChar

	if liveTypers[guiObject] then
		liveTypers[guiObject]()
		liveTypers[guiObject] = nil
	end

	guiObject.RichText = true
	guiObject.Text = fullText
	guiObject.MaxVisibleGraphemes = 0

	-- Determine target length and plain content for punctuation checks
	local totalVisible, plainContent = measureVisibleLen(guiObject, fullText)

	local cancelled = false
	local skipped = false
	local running = true
	local conns = connectSkip(skipInputs, function()
		skipped = true
	end)

	local function finish()
		disconnectAll(conns)
		running = false
		liveTypers[guiObject] = nil
	end

	liveTypers[guiObject] = finish

	--task.spawn(function()
	local shown = 0 -- how many graphemes currently visible
	local acc = 0 -- accumulator of "graphemes to reveal"
	local hold = 0 -- extra pause timer (punctuation)
	local lastTime = os.clock()

	while not cancelled do
		if skipped and immediateOnSkip then
			guiObject.MaxVisibleGraphemes = math.huge -- reveal all safely
			break
		end

		local now = os.clock()
		local dt = now - lastTime
		lastTime = now

		-- burn down any punctuation hold first
		if hold > 0 then
			hold = math.max(0, hold - dt)
			RunService.Heartbeat:Wait()
			continue
		end

		-- accumulate graphemes to show based on CPS
		acc = acc + (dt * cps)

		-- reveal as many full graphemes as we have budget for this frame
		local stepCount = math.floor(acc)
		if stepCount > 0 then
			acc = acc - stepCount
			local target = math.min(totalVisible, shown + stepCount)

			if opts.sound then
				engine:get("Sound"):playLocal(opts.sound, opts.soundParent)
			end

			while shown < target do
				shown = shown + 1
				guiObject.MaxVisibleGraphemes = shown
				if onChar then
					pcall(onChar, shown)
				end

				-- If the just-revealed visible char is punctuation, add an extra hold
				if punctuationSlowdown then
					local ch = utf8_char_at(plainContent, shown)
					if ch and isPunc(ch) then
						hold = hold + puncExtra
					end
				end
			end
		end

		if shown >= totalVisible then
			break
		end

		RunService.Heartbeat:Wait() -- next frame
	end

	-- final reveal if skipped late
	if skipped and immediateOnSkip then
		guiObject.MaxVisibleGraphemes = math.huge
	end

	finish()

	return {
		cancel = function()
			cancelled = true
			finish()
		end,
		skip = function()
			skipped = true
			if immediateOnSkip then
				guiObject.MaxVisibleGraphemes = math.huge
			end
		end,
		isRunning = function()
			return running
		end,
	}
end

return Typewriter
