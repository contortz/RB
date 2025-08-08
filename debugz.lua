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
screenGui.Name = "BeeLauncherUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0, 20, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "🐝 Bee Launcher Control"
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
local loopEquipBee = false
local loopActivateBee = false

-- Buttons
local equipBtn = makeButton(40, "🔁 Loop Equip Bee Launcher", function()
    loopEquipBee = not loopEquipBee
    equipBtn.BackgroundColor3 = loopEquipBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

local activateBtn = makeButton(80, "🔁 Loop Activate Bee Launcher", function()
    loopActivateBee = not loopActivateBee
    activateBtn.BackgroundColor3 = loopActivateBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Loop logic
RunService.RenderStepped:Connect(function()
    if loopEquipBee then
        local tool = player.Backpack:FindFirstChild("Bee Launcher")
        if tool then
            tool.Parent = player.Character
        end
    end

    if loopActivateBee then
        local tool = player.Character and player.Character:FindFirstChild("Bee Launcher")
        if tool then
            tool:Activate()
        end
    end
end)
