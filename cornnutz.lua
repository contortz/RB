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

-- Enabled rarities (default only Brainrot God & Secret ON)
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Avoid In Machine toggle
local AvoidInMachine = true

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
frame.Size = UDim2.new(0, 200, 0, 280)
frame.Position = UDim2.new(0, 20, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Rarity ESP"
title.TextSize = 16

-- Avoid In Machine toggle button
local avoidBtn = Instance.new("TextButton", frame)
avoidBtn.Size = UDim2.new(1, -10, 0, 25)
avoidBtn.Position = UDim2.new(0, 5, 0, 30)
avoidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
avoidBtn.TextColor3 = Color3.new(1, 1, 1)
avoidBtn.Text = "Avoid In Machine: ON"

avoidBtn.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    avoidBtn.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
end)

local y = 60
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

-- UI Highlight
local function highlightViewportFrame(vpf, rarity, inMachine)
    if not EnabledRarities[rarity] then return end
    if AvoidInMachine and inMachine then return end

    local stroke = vpf:FindFirstChild("Highlight")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "Highlight"
        stroke.Thickness = 2
        stroke.Transparency = 0
        stroke.Color = RarityColors[rarity]
        stroke.Parent = vpf
    else
        stroke.Color = RarityColors[rarity]
    end
end

-- Workspace Highlight
local function highlightWorldModel(model, rarity)
    if not EnabledRarities[rarity] or not model:IsA("Model") or not model.PrimaryPart then return end
    if AvoidInMachine and model:GetAttribute("InMachine") then return end

    local tag = "WorldESP_" .. model:GetDebugId()
    if worldESPFolder:FindFirstChild(tag) then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = tag
    box.Adornee = model.PrimaryPart
    box.Size = model:GetExtentsSize()
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = RarityColors[rarity]
    box.Transparency = 0.5
    box.Parent = worldESPFolder
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
                            local inMachine = (uiRoot.Name == "FuseMachine")
                            highlightViewportFrame(vpf, data.Rarity, inMachine)
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
                highlightWorldModel(model, data.Rarity)
            end
        end
    end
end)
