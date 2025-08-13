local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- GUI references
local playerGui = player:WaitForChild("PlayerGui")
local toggleGui = playerGui:WaitForChild("ToggleStatusGui")
local speedLabel = toggleGui:WaitForChild("SpeedStatus")
local jumpLabel = toggleGui:WaitForChild("JumpStatus")

-- Default values
local DEFAULT_WALK_SPEED = 16
local BOOSTED_WALK_SPEED = 50

local DEFAULT_JUMP_POWER = 50
local BOOSTED_JUMP_POWER = 100

local speedToggled = false
local jumpToggled = false

local function ApplyCurrentSettings()
    if humanoid then
        humanoid.WalkSpeed = speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED
        humanoid.JumpPower = jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER
    end
end

local function UpdateGui()
    speedLabel.Text = "Speed: " .. (speedToggled and "Boosted" or "Normal")
    jumpLabel.Text = "Jump: " .. (jumpToggled and "Boosted" or "Normal")
end

local function ToggleSpeed()
    speedToggled = not speedToggled
    ApplyCurrentSettings()
    UpdateGui()
    print("Speed toggled. Now:", speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED)
end

local function ToggleJump()
    jumpToggled = not jumpToggled
    ApplyCurrentSettings()
    UpdateGui()
    print("Jump toggled. Now:", jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.K then
            ToggleSpeed()
        elseif input.KeyCode == Enum.KeyCode.L then
            ToggleJump()
        end
    end
end)

-- Reapply settings when character respawns
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    ApplyCurrentSettings()
    UpdateGui()
end)

-- Apply on script start (in case player already spawned)
ApplyCurrentSettings()
UpdateGui()
