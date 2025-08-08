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
screenGui.Name = "BatControlUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0, 250, 0.5, -70) -- moved over to avoid overlap
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "🦇 Bat Control"
title.TextScaled = true
title.Font = Enum.Font.GothamBold

-- Utility to create buttons
local function makeButton(yOffset, text, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, yOffset)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.TextScaled = true
    button.Font = Enum.Font.Gotham
    button.MouseButton1Click:Connect(callback)
    return button
end

-- Toggles
local loopEquipBat = false
local loopActivateBat = false

-- Buttons
local equipBtn = makeButton(40, "🔁 Loop Equip Bat", function()
    loopEquipBat = not loopEquipBat
    equipBtn.BackgroundColor3 = loopEquipBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

local activateBtn = makeButton(80, "🔁 Loop Activate Bat", function()
    loopActivateBat = not loopActivateBat
    activateBtn.BackgroundColor3 = loopActivateBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Loop logic
RunService.RenderStepped:Connect(function()
    if loopEquipBat then
        local tool = player.Backpack:FindFirstChild("Tung Bat")
        if tool then
            tool.Parent = player.Character
        end
    end

    if loopActivateBat then
        local tool = player.Character and player.Character:FindFirstChild("Bat")
        if tool then
            tool:Activate()
        end
    end
end)
