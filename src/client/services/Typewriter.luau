local Typewriter = {
    activeWriters = {}
}

local CHAR_DELAYS = {
    ["."] = 0.2,
    [","] = 0.1,
    ["!"] = 0.2,
    ["?"] = 0.2,
    ["\n"] = 0.5,
}

local engine
function Typewriter.init(engineModule)
    engine = engineModule
end

function Typewriter.new(textLabel, text, speed)
    local self = setmetatable({
        textLabel = textLabel,
        goalText = text,
        speed = speed or 0.05,
        skipped = false
    }, { __index = Typewriter })

    if Typewriter.activeWriters[textLabel] then
        Typewriter.activeWriters[textLabel]:destroy()
    end

    self:type()

    Typewriter.activeWriters[textLabel] = self
    return self
end

function Typewriter:type()
    local RunService = game:GetService("RunService")
    
    self.textLabel.Text = self.goalText
    local visibleText = self.textLabel.ContentText

    local dtAcculumator = 0

    self.heartbeat = RunService.Heartbeat:Connect(function(dt)  
        dtAcculumator += dt
        if not self or self.skipped then
            self.heartbeat:Disconnect()
            return
        end

        while dtAcculumator >= self.speed do
            dtAcculumator -= self.speed

            if #visibleText < #self.goalText then
                local nextChar = self.goalText:sub(#visibleText + 1, #visibleText + 1)
                visibleText = visibleText .. nextChar
                self.textLabel.Text = visibleText

                local charDelay = CHAR_DELAYS[nextChar] or 0
                if charDelay > 0 then
                    dtAcculumator = -charDelay
                end
            else
                self.heartbeat:Disconnect()
                Typewriter.activeWriters[self.textLabel] = nil
                break
            end
        end
    end)
end

return Typewriter