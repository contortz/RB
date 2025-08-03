--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Animal data (name to rarity mapping)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

-- Rarity Colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255)
}

-- Enabled rarities (toggles)
local EnabledRarities = {
    Common = true,
    Rare = true,
    Epic = true,
    Legendary = true,
    Mythic = true,
    ["Brainrot God"] = true,
    Secret = true
}

--// UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RarityESPUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 250)
mainFrame.Position = UDim2.new(0, 20, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Rarity ESP"
title.Parent = mainFrame

-- Create rarity checkboxes
local yPos = 30
for rarity, _ in pairs(RarityColors) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = rarity .. ": ON"
    button.Parent = mainFrame

    button.MouseButton1Click:Connect(function()
        EnabledRarities[rarity] = not EnabledRarities[rarity]
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    end)

    yPos = yPos + 28
end

--// Highlight for ViewportFrames
local function highlightViewportFrame(vpf, rarity)
    if not EnabledRarities[rarity] then return end
    local highlight = vpf:FindFirstChild("Highlight")
    if not highlight then
        highlight = Instance.new("UIStroke")
        highlight.Name = "Highlight"
        highlight.Thickness = 2
        highlight.Parent = vpf
    end
    highlight.Color = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

--// Highlight for 3D animals
local espFolder = Instance.new("Folder")
espFolder.Name = "AnimalESPFolder"
espFolder.Parent = CoreGui

local function create3DESP(model, rarity)
    if not EnabledRarities[rarity] then return end
    if not model or not model.PrimaryPart then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = model.Name .. "_ESP"
    box.Adornee = model.PrimaryPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = model:GetExtentsSize()
    box.Color3 = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
    box.Transparency = 0.5
    box.Parent = espFolder
end

--// Update Loop
RunService.Heartbeat:Connect(function()
    espFolder:ClearAllChildren()

    -- Check FuseMachine + Index UI
    for _, container in ipairs({playerGui:FindFirstChild("FuseMachine"), playerGui:FindFirstChild("Index")}) do
        if container then
            for _, descendant in ipairs(container:GetDescendants()) do
                if descendant:IsA("ViewportFrame") and descendant:FindFirstChild("WorldModel") then
                    local worldModel = descendant.WorldModel:GetChildren()[1]
                    if worldModel then
                        local animalName = worldModel.Name
                        local animalData = AnimalsData[animalName]
                        if animalData and animalData.Rarity then
                            highlightViewportFrame(descendant, animalData.Rarity)
                        end
                    end
                end
            end
        end
    end

    -- Check live Workspace animals
    for _, plot in ipairs(Workspace:FindFirstChild("Plots"):GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                if base then
                    for _, model in ipairs(base:GetChildren()) do
                        if model:IsA("Model") and model.PrimaryPart then
                            local animalData = AnimalsData[model.Name]
                            if animalData and animalData.Rarity then
                                create3DESP(model, animalData.Rarity)
                            end
                        end
                    end
                end
            end
        end
    end
end)
