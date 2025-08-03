--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Animal data
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

local EnabledRarities = {}
for rarity in pairs(RarityColors) do EnabledRarities[rarity] = true end

-- ESP folders
local uiESPFolder = Instance.new("Folder", CoreGui)
uiESPFolder.Name = "UIRarityESP"

local worldESPFolder = Instance.new("Folder", CoreGui)
worldESPFolder.Name = "WorldRarityESP"

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RarityESPUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0, 20, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Rarity ESP"
title.TextSize = 16

local y = 30
for rarity in pairs(RarityColors) do
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = rarity .. ": ON"

    button.MouseButton1Click:Connect(function()
        EnabledRarities[rarity] = not EnabledRarities[rarity]
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    end)

    y += 28
end

-- Add floating label
local function addBillboard(model, text, color)
    if not model or not model.PrimaryPart then return end
    local tag = "Billboard_" .. model:GetDebugId()
    if worldESPFolder:FindFirstChild(tag) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = tag
    billboard.Adornee = model.PrimaryPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, model:GetExtentsSize().Y + 1, 0)
    billboard.Parent = worldESPFolder

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Text = text
end

-- UI Highlight
local function highlightViewportFrame(vpf, rarity, name, price, inMachine)
    if not EnabledRarities[rarity] then return end
    local stroke = vpf:FindFirstChild("Highlight")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "Highlight"
        stroke.Thickness = 2
        stroke.Transparency = 0
        stroke.Parent = vpf
    end
    stroke.Color = inMachine and Color3.new(0, 0, 0) or RarityColors[rarity]

    -- Add label overlay in UI
    local overlay = vpf:FindFirstChild("ESPOverlay") or Instance.new("TextLabel")
    overlay.Name = "ESPOverlay"
    overlay.Size = UDim2.new(1, 0, 0, 20)
    overlay.Position = UDim2.new(0, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.TextScaled = true
    overlay.TextColor3 = Color3.new(1, 1, 1)
    overlay.TextStrokeTransparency = 0
    overlay.Text = name .. " - $" .. tostring(price)
    overlay.Parent = vpf
end

-- Workspace Highlight
local function highlightWorldModel(model, rarity, name, price, inMachine)
    if not EnabledRarities[rarity] or not model:IsA("Model") or not model.PrimaryPart then return end
    local tag = "WorldESP_" .. model:GetDebugId()
    if not worldESPFolder:FindFirstChild(tag) then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = tag
        box.Adornee = model.PrimaryPart
        box.Size = model:GetExtentsSize()
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Color3 = inMachine and Color3.new(0, 0, 0) or RarityColors[rarity]
        box.Transparency = 0.5
        box.Parent = worldESPFolder
    end

    addBillboard(model, name .. " - $" .. tostring(price), inMachine and Color3.new(0, 0, 0) or RarityColors[rarity])
end

-- Heartbeat loop
RunService.Heartbeat:Connect(function()
    uiESPFolder:ClearAllChildren()
    worldESPFolder:ClearAllChildren()

    -- Check FuseMachine + Index ViewportFrames
    for _, uiRoot in ipairs({playerGui:FindFirstChild("FuseMachine"), playerGui:FindFirstChild("Index")}) do
        if uiRoot then
            for _, vpf in ipairs(uiRoot:GetDescendants()) do
                if vpf:IsA("ViewportFrame") and vpf:FindFirstChild("WorldModel") then
                    local model = vpf.WorldModel:FindFirstChildWhichIsA("Model")
                    if model then
                        local data = AnimalsData[model.Name]
                        if data and data.Rarity then
                            local inMachine = uiRoot.Name == "FuseMachine"
                            highlightViewportFrame(vpf, data.Rarity, data.DisplayName or model.Name, data.Price or "?", inMachine)
                        end
                    end
                end
            end
        end
    end

    -- Check Workspace for known animal models
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model.PrimaryPart then
            local data = AnimalsData[model.Name]
            if data and data.Rarity then
                highlightWorldModel(model, data.Rarity, data.DisplayName or model.Name, data.Price or "?", false)
            end
        end
    end
end)
