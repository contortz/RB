--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Settings
local player = Players.LocalPlayer
local AutoFollowEnabled = false
local FollowDistance = 5 -- studs away from target

--// Create UI (persistent)
if player.PlayerGui:FindFirstChild("FollowGui") then
    player.PlayerGui.FollowGui:Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FollowGui"
ScreenGui.ResetOnSpawn = false -- 🔹 keeps UI on respawn
ScreenGui.Parent = player.PlayerGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0.05, 0, 0.05, 0)
ToggleButton.Text = "Auto Follow: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Parent = ScreenGui

ToggleButton.MouseButton1Click:Connect(function()
    AutoFollowEnabled = not AutoFollowEnabled
    ToggleButton.Text = "Auto Follow: " .. (AutoFollowEnabled and "ON" or "OFF")
    ToggleButton.BackgroundColor3 = AutoFollowEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
end)

--// Function to follow closest player
local function followClosest()
    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return end

    local myCharacter = liveFolder:FindFirstChild(player.Name)
    if myCharacter and myCharacter:FindFirstChild("Humanoid") and myCharacter:FindFirstChild("HumanoidRootPart") then
        local myHumanoid = myCharacter.Humanoid
        local myHRP = myCharacter.HumanoidRootPart

        -- Find closest other player
        local closestPlayer, closestDist, closestHRP = nil, math.huge, nil
        for _, otherChar in pairs(liveFolder:GetChildren()) do
            if otherChar.Name ~= player.Name and otherChar:FindFirstChild("HumanoidRootPart") then
                local dist = (myHRP.Position - otherChar.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = otherChar
                    closestHRP = otherChar.HumanoidRootPart
                end
            end
        end

        -- Walk towards closest player
        if closestPlayer and closestHRP then
            local targetPos = closestHRP.Position
            local direction = (targetPos - myHRP.Position).Unit * (closestDist - FollowDistance)
            myHumanoid.WalkToPoint = targetPos - direction
        end
    end
end

--// Update loop
RunService.Heartbeat:Connect(function()
    if AutoFollowEnabled then
        followClosest()
    end
end)

--// Re-hook after respawn
player.CharacterAdded:Connect(function()
    -- Character respawned, keep following if enabled
    if AutoFollowEnabled then
        RunService.Heartbeat:Connect(function()
            if AutoFollowEnabled then
                followClosest()
            end
        end)
    end
end)
