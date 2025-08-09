--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- UI Setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 500)
frame.Position = UDim2.new(0, 20, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Function to teleport player to clone (once when clicked)
local function teleportToCloneOnce()
    local net = getNet()
    if net then
        -- Fire the teleportation event once
        net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
    else
        warn("Net module or RemoteEvent not found.")
    end
end

-- Function to create TP to Clone button on the right side with specific style
local function makeTPButton(yOffset, text, callback)
    local button = Instance.new("TextButton", screenGui)
    button.Size = UDim2.new(0, 150, 0, 40)  -- Adjust the size
    button.Position = UDim2.new(1, -160, 0, yOffset)  -- Position button to the right side
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Black background with opacity
    button.BackgroundTransparency = 0.5  -- Set opacity
    button.TextColor3 = Color3.fromRGB(0, 0, 255)  -- Blue text
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextStrokeTransparency = 0.8  -- Black stroke for the letters
    button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)  -- Black stroke color
    button.MouseButton1Click:Connect(function()
        callback(button)
    end)
    button.ZIndex = 10  -- Ensures it is above other UI elements
end

-- Add the TP to Clone button
makeTPButton(200, "TP to Clone", function(btn)
    btn.MouseButton1Click:Connect(function()
        teleportToCloneOnce()  -- Teleports the player to the clone once
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)  -- Change color to indicate it's clicked
    end)
end)

