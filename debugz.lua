local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50

local BOOSTED_WALK_SPEED = 32
local BOOSTED_JUMP_POWER = 100

local speedToggled = false
local jumpToggled = false

local humanoid = nil

local function InitializeHumanoid(h)
    humanoid = h
    humanoid.WalkSpeed = DEFAULT_WALK_SPEED
    humanoid.JumpPower = DEFAULT_JUMP_POWER
end

local function ApplyCurrentSettings()
    if not humanoid then return end
    humanoid.WalkSpeed = speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED
    humanoid.JumpPower = jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER
end

local function ToggleSpeed()
    speedToggled = not speedToggled
    ApplyCurrentSettings()
    print("Speed toggled. Now:", speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED)
end

local function ToggleJump()
    jumpToggled = not jumpToggled
    ApplyCurrentSettings()
    print("Jump toggled. Now:", jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER)
end

local function onCharacterAdded(character)
    local h = character:WaitForChild("Humanoid")
    InitializeHumanoid(h)
    ApplyCurrentSettings()
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.K then
        ToggleSpeed()
    elseif input.KeyCode == Enum.KeyCode.L then
        ToggleJump()
    end
end)
