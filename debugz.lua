--[[
    Place this in StarterPlayerScripts or StarterCharacterScripts as a LocalScript.
    It toggles between normal and boosted WalkSpeed/JumpPower when the H key is pressed.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Settings
local NORMAL_SPEED = 16
local BOOSTED_SPEED = 50

local NORMAL_JUMP = 50
local BOOSTED_JUMP = 100

-- State
local speedEnabled = false

-- Function to apply movement values
local function applyMovementSettings()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            if speedEnabled then
                humanoid.WalkSpeed = BOOSTED_SPEED
                humanoid.JumpPower = BOOSTED_JUMP
            else
                humanoid.WalkSpeed = NORMAL_SPEED
                humanoid.JumpPower = NORMAL_JUMP
            end
        end
    end
end

-- Toggle on key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        speedEnabled = not speedEnabled
        applyMovementSettings()
        if speedEnabled then
            print("✅ Speed Boost Enabled")
        else
            print("❌ Speed Boost Disabled")
        end
    end
end)

-- Enforce settings continuously in case ControlScript resets them
RunService.Heartbeat:Connect(function()
    if speedEnabled then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                if humanoid.WalkSpeed ~= BOOSTED_SPEED then
                    humanoid.WalkSpeed = BOOSTED_SPEED
                end
                if humanoid.JumpPower ~= BOOSTED_JUMP then
                    humanoid.JumpPower = BOOSTED_JUMP
                end
            end
        end
    end
end)

-- Reapply settings on character respawn
player.CharacterAdded:Connect(function()
    wait(1)
    applyMovementSettings()
end)
