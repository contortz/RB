--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Modules
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
local AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brain Rot Gods"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255)
}

-- Enabled rarities
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brain Rot Gods" or rarity == "Secret") -- Default ON for these
end

-- ESP Folders
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

-- Rarity toggles
local y = 30
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

-- Helper: Find PrimaryPart safely
local function getPrimary(model)
    return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Base")
end

-- Helper: Create ESP Billboard
local function addBillboard(model, text, color)
    local primary = getPrimary(model)
    if not primary then return end

    local tag = "Billboard_" .. model:GetDebugId()
    if worldESPFolder:FindFirstChild(tag) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = tag
    billboard.Adornee = primary
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

-- ESP Loop
RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()

    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        if plot:FindFirstChild("UID") then
            local channel = Synchronizer:Wait(plot.UID.Value)
            local animals = channel:Get("AnimalList")

            if type(animals) == "table" then
                for index, data in pairs(animals) do
                    local animalInfo = AnimalsData[data.Index]
                    if animalInfo and EnabledRarities[animalInfo.Rarity] then
                        if data.Steal == "FuseMachine" then continue end -- Avoid In Machine
                        
                        local podium = plot.PlotModel.AnimalPodiums:FindFirstChild(index)
                        if podium and podium.Base then
                            local model = podium.Base:FindFirstChildWhichIsA("Model")
                            if model then
                                local price = NumberUtils:ToString(
                                    AnimalsShared:GetPrice(data.Index, plot:GetOwner() or player)
                                )
                                addBillboard(model, animalInfo.DisplayName .. " - $" .. price, RarityColors[animalInfo.Rarity])
                            end
                        end
                    end
                end
            end
        end
    end
end)
