--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- UI setup ...
-- (Keep your UI creation and helper functions as before)

local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)

-- State toggles
local autoSpamGrapple = false
local lastSpamTime = 0
local spamInterval = 0.2

-- Main loop
RunService.Heartbeat:Connect(function()
    -- Your existing toggles (autoEquip, etc.) here...

    if autoSpamGrapple then
        local now = os.clock()
        if now - lastSpamTime >= spamInterval then
            lastSpamTime = now
            print("[SpamGrapple] Attempting to fire UseItem remote...")

            local args = { 0.3190609614054362 }
            local ok, err = pcall(function()
                Net:RemoteEvent("UseItem"):FireServer(unpack(args))
            end)
            if not ok then
                warn("[SpamGrapple] Couldn't fire remote:", err)
            end
        end
    end
end)

-- Button UI (spam toggle) ...
makeButton(380, "Spam Grapple Hook", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoSpamGrapple = not autoSpamGrapple
        btn.BackgroundColor3 = autoSpamGrapple and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
    end)
end)
