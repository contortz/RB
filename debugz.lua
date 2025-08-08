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
screenGui.Name = "TungBatUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0, 250, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "🦇 Tung Bat Control"
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
local loopEquip = false
local loopActivate = false

-- Buttons
local equipBtn = makeButton(40, "🔁 Loop Equip Tung Bat", function()
    loopEquip = not loopEquip
    equipBtn.BackgroundColor3 = loopEquip and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

local activateBtn = makeButton(80, "🔁 Loop Activate (Click)", function()
    loopActivate = not loopActivate
    activateBtn.BackgroundColor3 = loopActivate and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Frame-based logic
RunService.RenderStepped:Connect(function()
    if loopEquip then
        local tool = player.Backpack:FindFirstChild("Tung Bat")
        if tool then
            tool.Parent = player.Character
        end
    end

    if loopActivate then
        local tool = player.Character and player.Character:FindFirstChild("Tung Bat")
        if tool then
            tool:Activate()
        end
    end
end)
