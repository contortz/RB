local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local customWalkSpeed = 16
local customJumpPower = 50

-- === Apply Settings ===
local function applySettings()
    if humanoid then
        humanoid.WalkSpeed = customWalkSpeed
        humanoid.JumpPower = customJumpPower
    end
end

-- === Monitor Reset ===
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

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    applySettings()
end)

applySettings()

-- === UI Setup ===
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "SpeedControlGui"
ScreenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0, 200, 0, 120)
frame.Position = UDim2.new(0, 20, 0, 250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "Speed Control"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local currentSpeed = Instance.new("TextLabel", frame)
currentSpeed.Position = UDim2.new(0, 0, 0, 28)
currentSpeed.Size = UDim2.new(1, 0, 0, 20)
currentSpeed.Text = "WalkSpeed: " .. customWalkSpeed
currentSpeed.TextColor3 = Color3.new(1,1,1)
currentSpeed.BackgroundTransparency = 1
currentSpeed.Font = Enum.Font.Gotham
currentSpeed.TextSize = 14

local increase = Instance.new("TextButton", frame)
increase.Size = UDim2.new(0.5, -5, 0, 30)
increase.Position = UDim2.new(0, 5, 0, 55)
increase.Text = "Faster"
increase.Font = Enum.Font.Gotham
increase.TextSize = 14
increase.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
increase.TextColor3 = Color3.new(1, 1, 1)

local decrease = Instance.new("TextButton", frame)
decrease.Size = UDim2.new(0.5, -5, 0, 30)
decrease.Position = UDim2.new(0.5, 5, 0, 55)
decrease.Text = "Slower"
decrease.Font = Enum.Font.Gotham
decrease.TextSize = 14
decrease.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
decrease.TextColor3 = Color3.new(1, 1, 1)

-- === Button Behavior ===
local function updateSpeedLabel()
    currentSpeed.Text = "WalkSpeed: " .. customWalkSpeed
end

increase.MouseButton1Click:Connect(function()
    customWalkSpeed += 10
    customJumpPower += 5
    applySettings()
    updateSpeedLabel()
end)

decrease.MouseButton1Click:Connect(function()
    customWalkSpeed = math.max(16, customWalkSpeed - 10)
    customJumpPower = math.max(50, customJumpPower - 5)
    applySettings()
    updateSpeedLabel()
end)

updateSpeedLabel()
