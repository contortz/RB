--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Settings
local AutoFollowEnabled = false
local FollowDistance = 5 -- studs away from target

-- GUI Toggle (simple)
local player = Players.LocalPlayer
if player.PlayerGui:FindFirstChild("FollowGui") then
    player.PlayerGui.FollowGui:Destroy()
end
local ScreenGui = Instance.new("ScreenGui", player.PlayerGui)
ScreenGui.Name = "FollowGui"

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0.05, 0, 0.05, 0)
ToggleButton.Text = "Auto Follow: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)

ToggleButton.MouseButton1Click:Connect(function()
    AutoFollowEnabled = not AutoFollowEnabled
    ToggleButton.Text = "Auto Follow: " .. (AutoFollowEnabled and "ON" or "OFF")
    ToggleButton.BackgroundColor3 = AutoFollowEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
end)

-- Main Follow Logic
RunService.Heartbeat:Connect(function()
    if AutoFollowEnabled then
        local liveFolder = Workspace:FindFirstChild("Live")
        if liveFolder then
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

                -- Set WalkToPoint if a target is found
                if closestPlayer and closestHRP then
                    local targetPos = closestHRP.Position
                    -- Keep a small distance
                    local direction = (targetPos - myHRP.Position).Unit * (closestDist - FollowDistance)
                    myHumanoid.WalkToPoint = targetPos - direction
                end
            end
        end
    end
end)
