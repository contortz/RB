--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Dependencies
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Synchronizer = require(Packages:WaitForChild("Synchronizer"))

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FuseMachineESP"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🔍 Machine ESP"
title.Parent = mainFrame

-- Toggle Button
local espEnabled = false
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, -10, 0, 35)
espButton.Position = UDim2.new(0, 5, 0, 40)
espButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.Text = "ESP: OFF"
espButton.Parent = mainFrame

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

-- ESP Folder in CoreGui
local espFolder = Instance.new("Folder")
espFolder.Name = "MachineESPFolder"
espFolder.Parent = game:GetService("CoreGui")

-- Function to create ESP Box
local function createESP(model)
    if not model or not model.PrimaryPart then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = model.PrimaryPart
    box.Size = model:GetExtentsSize()
    box.Color3 = Color3.fromRGB(0, 140, 255)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Parent = espFolder
end

-- Update ESP loop
RunService.RenderStepped:Connect(function()
    espFolder:ClearAllChildren()
    if not espEnabled then return end

    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        if plot:FindFirstChild("UID") then
            local channel = Synchronizer:Wait(plot.UID.Value)
            local animals = channel:Get("AnimalList")
            if type(animals) == "table" then
                for index, data in pairs(animals) do
                    if data.Steal == "FuseMachine" then
                        local podium = plot.PlotModel.AnimalPodiums:FindFirstChild(index)
                        if podium and podium:FindFirstChild("Base") then
                            local animalModel = podium.Base:FindFirstChildWhichIsA("Model")
                            if animalModel then
                                createESP(animalModel)
                            end
                        end
                    end
                end
            end
        end
    end
end)
