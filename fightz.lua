--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Settings
local player = Players.LocalPlayer
local AutoFollowEnabled = false
local FollowDistance = 5 -- studs away

--// Create UI (persistent)
if player.PlayerGui:FindFirstChild("FollowGui") then
    player.PlayerGui.FollowGui:Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FollowGui"
ScreenGui.ResetOnSpawn = false
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

--// Follow Closest Player from Workspace root
local function followClosest()
    -- Find our character
    local myCharacter = Workspace:FindFirstChild(player.Name)
    if not myCharacter or not myCharacter:FindFirstChild("Humanoid") or not myCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end

    local myHumanoid = myCharacter.Humanoid
    local myHRP = myCharacter.HumanoidRootPart

    -- Find closest character with HumanoidRootPart
    local closestHRP
    local closestDist = math.huge
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model")
        and obj.Name ~= player.Name
        and obj:FindFirstChild("Humanoid")
        and obj:FindFirstChild("HumanoidRootPart") then
            
            local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestHRP = obj.HumanoidRootPart
            end
        end
    end

    -- Walk to closest player
    if closestHRP then
        local targetPos = closestHRP.Position
        local direction = (targetPos - myHRP.Position).Unit * (closestDist - FollowDistance)
        myHumanoid.WalkToPoint = targetPos - direction
    end
end

--// Run every frame
RunService.Heartbeat:Connect(function()
    if AutoFollowEnabled then
        followClosest()
    end
end)

-- Keep working after respawn
player.CharacterAdded:Connect(function()
    if AutoFollowEnabled then
        RunService.Heartbeat:Connect(function()
            if AutoFollowEnabled then
                followClosest()
            end
        end)
    end
end)
