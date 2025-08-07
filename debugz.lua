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
frame.Size = UDim2.new(0, 250, 0, 250)
frame.Position = UDim2.new(0, 20, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Base Info Display
local baseInfoLabel = Instance.new("TextLabel", frame)
baseInfoLabel.Size = UDim2.new(1, -10, 0, 25)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 40)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1, 1, 1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"

-- Slot Info Display
local slotInfoLabel = Instance.new("TextLabel", frame)
slotInfoLabel.Size = UDim2.new(1, -10, 0, 25)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 70)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"

-- Logic to find local player's base and tier
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

                -- Count filled and total slots
                local animalPodiums = model:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled = 0
                    local total = 0

                    for _, podium in ipairs(animalPodiums:GetChildren()) do
                        local spawn = podium:FindFirstChild("Spawn")
                        if spawn and spawn:IsA("BasePart") then
                            total += 1
                            if spawn:FindFirstChild("Attachment") then
                                filled += 1
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

-- Wait to ensure Workspace.Plots is available
task.delay(1, findLocalPlayerBase)
