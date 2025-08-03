--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Dependencies
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages.Observers)
local Synchronizer = require(Packages.Synchronizer)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas").Animals)

-- Storage
local activePlots = {} -- Tracks all plots
local espFolder = Instance.new("Folder")
espFolder.Name = "AnimalESPFolder"
espFolder.Parent = CoreGui

-- Colors per rarity
local rarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(180, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 128)
}

-- Toggle table
local rarityToggles = {
    Common = false,
    Rare = true,
    Epic = true,
    Legendary = true,
    Mythic = true,
    ["Brainrot God"] = true,
    Secret = true
}

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachineESPUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 200)
mainFrame.Position = UDim2.new(0, 50, 0, 200)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Rarity ESP"
title.Parent = mainFrame

-- ESP Enable Toggle
local ESPEnabled = false
local toggleESPBtn = Instance.new("TextButton")
toggleESPBtn.Size = UDim2.new(1, -10, 0, 25)
toggleESPBtn.Position = UDim2.new(0, 5, 0, 30)
toggleESPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPBtn.Text = "ESP: OFF"
toggleESPBtn.Parent = mainFrame

toggleESPBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    toggleESPBtn.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
    if not ESPEnabled then espFolder:ClearAllChildren() end
end)

-- Rarity Toggles
local yPos = 60
for rarity in pairs(rarityToggles) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 20)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = rarity .. ": " .. (rarityToggles[rarity] and "ON" or "OFF")
    btn.Parent = mainFrame

    btn.MouseButton1Click:Connect(function()
        rarityToggles[rarity] = not rarityToggles[rarity]
        btn.Text = rarity .. ": " .. (rarityToggles[rarity] and "ON" or "OFF")
    end)

    yPos += 22
end

-- ESP Create
local function createESPBox(model, rarity, name)
    if not model or not model.PrimaryPart then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = model.PrimaryPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = model:GetExtentsSize()
    box.Color3 = rarityColors[rarity] or Color3.new(1,1,1)
    box.Transparency = 0.5
    box.Parent = espFolder

    local tag = Instance.new("BillboardGui")
    tag.Adornee = model.PrimaryPart
    tag.Size = UDim2.new(0, 200, 0, 50)
    tag.AlwaysOnTop = true
    tag.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = rarityColors[rarity] or Color3.new(1,1,1)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Text = string.format("[%s] %s", rarity, name or "Unknown")
    label.Parent = tag
end

-- Observe plots
Observers.observeTag("Plot", function(plotModel)
    task.spawn(function()
        while not plotModel:GetAttribute("Loaded") do task.wait() end
        local UID = plotModel.Name
        local plotClient = {
            PlotModel = plotModel,
            Channel = Synchronizer:Wait(UID)
        }
        activePlots[plotClient] = true
    end)
end)

-- Update ESP
RunService.Heartbeat:Connect(function()
    if not ESPEnabled then return end
    espFolder:ClearAllChildren()

    for plotClient in pairs(activePlots) do
        local animals = plotClient.Channel:Get("AnimalList")
        if type(animals) == "table" then
            for index, data in pairs(animals) do
                if data.Index then
                    local info = AnimalsData[data.Index]
                    if info and rarityToggles[info.Rarity] then
                        local podium = plotClient.PlotModel.AnimalPodiums:FindFirstChild(index)
                        if podium and podium.Base then
                            local model = podium.Base:FindFirstChildWhichIsA("Model")
                            if model then
                                createESPBox(model, info.Rarity, info.DisplayName)
                            end
                        end
                    end
                end
            end
        end
    end
end)
