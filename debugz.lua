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
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 500)
frame.Position = UDim2.new(0, 20, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Info Labels
local baseInfoLabel = Instance.new("TextLabel", frame)
baseInfoLabel.Size = UDim2.new(1, -10, 0, 25)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 40)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1, 1, 1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"

local slotInfoLabel = Instance.new("TextLabel", frame)
slotInfoLabel.Size = UDim2.new(1, -10, 0, 25)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 70)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"

-- Base + Slot Logic
local function findLocalPlayerBase()
    local playerName = player.Name
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, model in ipairs(plots:GetChildren()) do
        local sign = model:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local frame = gui and gui:FindFirstChild("Frame")
        local label = frame and frame:FindFirstChild("TextLabel")

        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == playerName then
                local tier = model:GetAttribute("Tier")
                baseInfoLabel.Text = "🏠 Base: " .. model.Name .. " | Tier: " .. tostring(tier or "?")
                local animalPodiums = model:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled, total = 0, 0
                    for _, podiumModule in ipairs(animalPodiums:GetChildren()) do
                        if podiumModule:IsA("Model") then
                            local base = podiumModule:FindFirstChild("Base")
                            local spawn = base and base:FindFirstChild("Spawn")
                            if spawn and spawn:IsA("BasePart") then
                                total += 1
                                if spawn:FindFirstChild("Attachment") then
                                    filled += 1
                                end
                            end
                        end
                    end
                    slotInfoLabel.Text = "Slots: " .. filled .. " / " .. total
                end
                break
            end
        end
    end
end

task.delay(1, findLocalPlayerBase)

-- Button Helper
local function makeButton(yOffset, text, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, yOffset)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextScaled = true
    callback(button)
end

-- Function to teleport player to clone (once when clicked)
local function teleportToCloneOnce()
    local net = getNet()
    if net then
        -- Fire the teleportation event once
        net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
    else
        warn("Net module or RemoteEvent not found.")
    end
end

-- Function to create a TP to Clone button on the right side
local function makeTPButton(yOffset, text, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0, 150, 0, 30)
    button.Position = UDim2.new(1, -160, 0, yOffset)  -- Position button to the right side
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextScaled = true
    callback(button)
end

-- Remotes + State
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)
local teleportLoop = false
local autoEquipQuantum = false
local autoActivateQuantum = false
local autoEquipBee = false
local autoActivateBee = false
local autoEquipBat = false
local autoSwingBat = false

-- Runtime Loops
RunService.Heartbeat:Connect(function()
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if autoEquipQuantum and backpack and character and not character:FindFirstChild("Quantum Cloner") then
        local tool = backpack:FindFirstChild("Quantum Cloner")
        if tool then tool.Parent = character end
    end

    if autoActivateQuantum and character then
        local tool = character:FindFirstChild("Quantum Cloner")
        if tool then tool:Activate() end
    end

    if teleportLoop then
        Net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
    end

    if autoEquipBee and backpack and character and not character:FindFirstChild("Bee Launcher") then
        local tool = backpack:FindFirstChild("Bee Launcher")
        if tool then tool.Parent = character end
    end

    if autoActivateBee and character then
        local tool = character:FindFirstChild("Bee Launcher")
        if tool then tool:Activate() end
    end

    if autoEquipBat and backpack and character and not character:FindFirstChild("Tung Bat") then
        local tool = backpack:FindFirstChild("Tung Bat")
        if tool then tool.Parent = character end
    end

    if autoSwingBat and character then
        local tool = character:FindFirstChild("Tung Bat")
        if tool then tool:Activate() end
    end
end)

-- Buttons
makeButton(110, "Loop Equip Quantum Cloner", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipQuantum = not autoEquipQuantum
        btn.BackgroundColor3 = autoEquipQuantum and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(140, "Loop Activate Quantum", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoActivateQuantum = not autoActivateQuantum
        btn.BackgroundColor3 = autoActivateQuantum and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(170, "Loop Teleport to Clone", function(btn)
    btn.MouseButton1Click:Connect(function()
        teleportLoop = not teleportLoop
        btn.BackgroundColor3 = teleportLoop and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

-- Add TP Button for "TP to Clone"
makeTPButton(200, "TP to Clone", function(btn)
    btn.MouseButton1Click:Connect(function()
        teleportToCloneOnce()  -- Teleports the player to the clone once
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)  -- Optionally change color after click
    end)
end)

makeButton(230, "Loop Equip Bee Launcher", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipBee = not autoEquipBee
        btn.BackgroundColor3 = autoEquipBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(260, "Loop Activate Bee Launcher", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoActivateBee = not autoActivateBee
        btn.BackgroundColor3 = autoActivateBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(290, "Loop Equip Tung Bat", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipBat = not autoEquipBat
        btn.BackgroundColor3 = autoEquipBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(320, "Auto Swing Bat", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoSwingBat = not autoSwingBat
        btn.BackgroundColor3 = autoSwingBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)
