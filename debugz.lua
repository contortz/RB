-- === Speed Override Script ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Desired speed settings
local customWalkSpeed = 100 -- Default is 16
local customJumpPower = 100 -- Default is 50

-- Apply values and keep them enforced
local function applySpeedSettings()
    if humanoid then
        humanoid.WalkSpeed = customWalkSpeed
        humanoid.JumpPower = customJumpPower
    end
end

-- Monitor and reapply if something tries to change it
humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    if humanoid.WalkSpeed ~= customWalkSpeed then
        humanoid.WalkSpeed = customWalkSpeed
    end
end)

humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
    if humanoid.JumpPower ~= customJumpPower then
        humanoid.JumpPower = customJumpPower
    end
end)

-- Reapply on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    applySpeedSettings()
end)

-- Initial apply
applySpeedSettings()
