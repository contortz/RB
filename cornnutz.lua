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

-- Storage for ESP tracking
local activePlots = {} -- [PlotClient] = true
local espFolder = Instance.new("Folder")
espFolder.Name = "MachineESPFolder"
espFolder.Parent = CoreGui

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachineESPUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 100)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🔍 FuseMachine ESP"
title.Parent = mainFrame

local toggleESPBtn = Instance.new("TextButton")
toggleESPBtn.Size = UDim2.new(1, -10, 0, 35)
toggleESPBtn.Position = UDim2.new(0, 5, 0, 40)
toggleESPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPBtn.Text = "ESP: OFF"
toggleESPBtn.Parent = mainFrame

local ESPEnabled = false
toggleESPBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    toggleESPBtn.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
    if not ESPEnabled then
        espFolder:ClearAllChildren()
    end
end)

-- Create ESP Box + Name
local function createESPBox(model)
    if not model or not model.PrimaryPart then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "MachineESPBox"
    box.Adornee = model.PrimaryPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = model:GetExtentsSize()
    box.Color3 = Color3.fromRGB(0, 140, 255)
    box.Transparency = 0.5
    box.Parent = espFolder

    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "MachineESPName"
    nameTag.Adornee = model.PrimaryPart
    nameTag.Size = UDim2.new(0, 100, 0, 40)
    nameTag.AlwaysOnTop = true
    nameTag.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.new(0, 0.6, 1)
    label.TextStrokeTransparency = 0.5
    label.Text = "IN MACHINE"
    label.Parent = nameTag
end

-- Hook when plots appear (Observers.observeTag like in decomp)
Observers.observeTag("Plot", function(plotModel)
    -- PlotClient is created in PlotController when tag fires
    task.spawn(function()
        -- Wait until it has a Channel
        while not plotModel:GetAttribute("Loaded") do
            task.wait()
        end
        -- Get UID and synchronizer channel
        local UID = plotModel.Name
        local plotClient = {
            PlotModel = plotModel,
            Channel = require(Packages.Synchronizer):Wait(UID)
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
                if data.Steal == "FuseMachine" then
                    local podium = plotClient.PlotModel.AnimalPodiums:FindFirstChild(index)
                    if podium and podium.Base then
                        local animalModel = podium.Base:FindFirstChildWhichIsA("Model")
                        if animalModel and animalModel.PrimaryPart then
                            createESPBox(animalModel)
                        end
                    end
                end
            end
        end
    end
end)
