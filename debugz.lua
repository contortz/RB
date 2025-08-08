--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- UI
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "TungBatUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0, 250, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Tung Bat Controller"
title.Font = Enum.Font.GothamBold
title.TextScaled = true

-- Button Utility
local function makeButton(yOffset, text, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Toggles
local loopEquip = false
local loopActivate = false

-- Buttons
local equipBtn = makeButton(40, "Loop Equip: OFF", function()
    loopEquip = not loopEquip
    equipBtn.Text = "Loop Equip: " .. (loopEquip and "ON" or "OFF")
    equipBtn.BackgroundColor3 = loopEquip and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

local activateBtn = makeButton(80, "Loop Activate: OFF", function()
    loopActivate = not loopActivate
    activateBtn.Text = "Loop Activate: " .. (loopActivate and "ON" or "OFF")
    activateBtn.BackgroundColor3 = loopActivate and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Loop Logic
RunService.RenderStepped:Connect(function()
    if loopEquip then
        local tool = player.Backpack:FindFirstChild("Tung Bat")
        if tool then
            print("[Equip] Moving 'Tung Bat' to Character")
            tool.Parent = player.Character
        end
    end

    if loopActivate then
        local tool = player.Character and player.Character:FindFirstChild("Tung Bat")
        if tool then
            tool:Activate()
            print("[Activate] Called Activate() on Tung Bat")
        end
    end
end)
