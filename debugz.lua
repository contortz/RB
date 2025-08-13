local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToggleStatusGui"
screenGui.Parent = playerGui

-- Helper to create labels
local function createLabel(name, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(0, 150, 0, 30)
    label.Position = position
    label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 20
    label.Text = name .. ": Normal"
    label.Parent = screenGui
    return label
end

local speedLabel = createLabel("Speed", UDim2.new(0, 10, 0, 10))
local jumpLabel = createLabel("Jump", UDim2.new(0, 10, 0, 50))

local DEFAULT_WALK_SPEED = 16
local BOOSTED_WALK_SPEED = 50

local DEFAULT_JUMP_POWER = 50
local BOOSTED_JUMP_POWER = 100

local speedToggled = false
local jumpToggled = false

local humanoid

local function updateHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED
        humanoid.JumpPower = jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER
    end
end

local function updateGui()
    speedLabel.Text = "Speed: " .. (speedToggled and "Boosted" or "Normal")
    jumpLabel.Text = "Jump: " .. (jumpToggled and "Boosted" or "Normal")
end

local function toggleSpeed()
    speedToggled = not speedToggled
    updateHumanoid()
    updateGui()
    print("Speed toggled:", speedToggled)
end

local function toggleJump()
    jumpToggled = not jumpToggled
    updateHumanoid()
    updateGui()
    print("Jump toggled:", jumpToggled)
end

-- Detect key presses
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.K then
            toggleSpeed()
        elseif input.KeyCode == Enum.KeyCode.L then
            toggleJump()
        end
    end
end)

local function onCharacterAdded(char)
    humanoid = char:WaitForChild("Humanoid")
    updateHumanoid()
    updateGui()
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
