--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Animal data (for Lucky Blocks)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255)
}

-- Enabled rarities
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Toggles
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = false
local AutoPurchaseThresholdEnabled = false
local PurchaseThreshold = 20000 -- default 20k
local ThresholdOptions = {0, 5000, 10000, 20000, 50000, 100000, 300000}
local ThresholdIndex = 4

-- Price formatting
local function formatPrice(value)
    if value >= 1e9 then
        return string.format("%.1fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.1fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fK", value / 1e3)
    else
        return tostring(value)
    end
end

-- ESP Folders
local worldESPFolder = Instance.new("Folder", CoreGui)
worldESPFolder.Name = "WorldRarityESP"
local playerESPFolder = Instance.new("Folder", CoreGui)
playerESPFolder.Name = "PlayerESPFolder"

-- UI
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 450)
frame.Position = UDim2.new(0, 20, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

-- Minimize Button
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Text = "-"
minimizeBtn.ZIndex = 999

-- Corn Icon
local cornIcon = Instance.new("ImageButton", screenGui)
cornIcon.Size = UDim2.new(0, 60, 0, 60)
cornIcon.Position = UDim2.new(0, 15, 0.27, 0)
cornIcon.BackgroundTransparency = 1
cornIcon.Image = "rbxassetid://76154122039576"
cornIcon.ZIndex = 999
cornIcon.Visible = false

-- Dragging for Corn Icon
local dragging, dragInput, dragStart, startPos
cornIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = cornIcon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
cornIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        cornIcon.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Toggle Minimize
minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    cornIcon.Visible = true
end)
cornIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    cornIcon.Visible = false
end)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Avoid In Machine Toggle
local toggleAvoidBtn = Instance.new("TextButton", frame)
toggleAvoidBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAvoidBtn.Position = UDim2.new(0, 5, 0, 30)
toggleAvoidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAvoidBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAvoidBtn.Text = "Avoid In Machine: ON"
toggleAvoidBtn.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    toggleAvoidBtn.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
end)

-- Player ESP Toggle
local togglePlayerESPBtn = Instance.new("TextButton", frame)
togglePlayerESPBtn.Size = UDim2.new(1, -10, 0, 25)
togglePlayerESPBtn.Position = UDim2.new(0, 5, 0, 60)
togglePlayerESPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
togglePlayerESPBtn.TextColor3 = Color3.new(1, 1, 1)
togglePlayerESPBtn.Text = "Player ESP: OFF"
togglePlayerESPBtn.MouseButton1Click:Connect(function()
    PlayerESPEnabled = not PlayerESPEnabled
    togglePlayerESPBtn.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
end)

-- Most Expensive Only Toggle
local toggleMostExpBtn = Instance.new("TextButton", frame)
toggleMostExpBtn.Size = UDim2.new(1, -10, 0, 25)
toggleMostExpBtn.Position = UDim2.new(0, 5, 0, 90)
toggleMostExpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleMostExpBtn.TextColor3 = Color3.new(1, 1, 1)
toggleMostExpBtn.Text = "Most Expensive: OFF"
toggleMostExpBtn.MouseButton1Click:Connect(function()
    MostExpensiveOnly = not MostExpensiveOnly
    toggleMostExpBtn.Text = "Most Expensive: " .. (MostExpensiveOnly and "ON" or "OFF")
end)

-- Auto Purchase Toggle
local toggleAutoPurchaseBtn = Instance.new("TextButton", frame)
toggleAutoPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoPurchaseBtn.Position = UDim2.new(0, 5, 0, 120)
toggleAutoPurchaseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAutoPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoPurchaseBtn.Text = "Auto Purchase: OFF"
toggleAutoPurchaseBtn.MouseButton1Click:Connect(function()
    AutoPurchaseEnabled = not AutoPurchaseEnabled
    toggleAutoPurchaseBtn.Text = "Auto Purchase: " .. (AutoPurchaseEnabled and "ON" or "OFF")
end)

-- Auto Purchase Threshold Toggle
local toggleAutoPurchaseThresholdBtn = Instance.new("TextButton", frame)
toggleAutoPurchaseThresholdBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoPurchaseThresholdBtn.Position = UDim2.new(0, 5, 0, 150)
toggleAutoPurchaseThresholdBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAutoPurchaseThresholdBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoPurchaseThresholdBtn.Text = "Auto Purchase ≥ $" .. (PurchaseThreshold/1000) .. "k: OFF"

toggleAutoPurchaseThresholdBtn.MouseButton1Click:Connect(function()
    AutoPurchaseThresholdEnabled = not AutoPurchaseThresholdEnabled
    toggleAutoPurchaseThresholdBtn.Text = "Auto Purchase ≥ $" .. (PurchaseThreshold/1000) .. "k: " .. (AutoPurchaseThresholdEnabled and "ON" or "OFF")
end)

-- Change Threshold Dropdown
local changeThresholdBtn = Instance.new("TextButton", frame)
changeThresholdBtn.Size = UDim2.new(1, -10, 0, 25)
changeThresholdBtn.Position = UDim2.new(0, 5, 0, 180)
changeThresholdBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
changeThresholdBtn.TextColor3 = Color3.new(1, 1, 1)
changeThresholdBtn.Text = "Change Threshold"

changeThresholdBtn.MouseButton1Click:Connect(function()
    ThresholdIndex = ThresholdIndex + 1
    if ThresholdIndex > #ThresholdOptions then
        ThresholdIndex = 1
    end
    PurchaseThreshold = ThresholdOptions[ThresholdIndex]
    toggleAutoPurchaseThresholdBtn.Text = "Auto Purchase ≥ $" .. (PurchaseThreshold/1000) .. "k: " .. (AutoPurchaseThresholdEnabled and "ON" or "OFF")
end)

-- Proximity Prompt Auto Purchase Logic
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    local function triggerPurchase()
        task.wait(0.05)
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0.25)
        prompt:InputHoldEnd()
    end

    if AutoPurchaseThresholdEnabled and prompt.ActionText and string.find(prompt.ActionText:lower(), "purchase") then
        local objectText = prompt.Parent:FindFirstChild("ObjectText")
        if objectText and objectText:IsA("TextLabel") then
            local priceText = objectText.Text:gsub("%$", ""):upper()
            priceText = priceText:gsub("K", "000"):gsub("M", "000000")
            local priceValue = tonumber(priceText) or 0
            if priceValue >= PurchaseThreshold then
                triggerPurchase()
            end
        end
    elseif AutoPurchaseEnabled and not AutoPurchaseThresholdEnabled and prompt.ActionText and string.find(prompt.ActionText:lower(), "purchase") then
        triggerPurchase()
    end
end)

-- Rarity Toggles
local y = 210
for rarity in pairs(RarityColors) do
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    button.MouseButton1Click:Connect(function()
        EnabledRarities[rarity] = not EnabledRarities[rarity]
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    end)
    y += 28
end
