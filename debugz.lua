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
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 20, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz Base Viewer"
title.TextSize = 10

-- Scrollable list for player base info
local scrollFrame = Instance.new("ScrollingFrame", frame)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", scrollFrame)
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Get all player base data
local function updateAllPlayerBaseInfo()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    scrollFrame:ClearAllChildren()
    UIListLayout.Parent = scrollFrame

    for _, model in ipairs(plots:GetChildren()) do
        local sign = model:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local frame = gui and gui:FindFirstChild("Frame")
        local label = frame and frame:FindFirstChild("TextLabel")

        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            local tier = model:GetAttribute("Tier") or "?"
            local filled, total = 0, 0

            local animalPodiums = model:FindFirstChild("AnimalPodiums")
            if animalPodiums then
                for _, podium in ipairs(animalPodiums:GetChildren()) do
                    if podium:IsA("Model") then
                        local base = podium:FindFirstChild("Base")
                        local spawn = base and base:FindFirstChild("Spawn")
                        if spawn and spawn:IsA("BasePart") then
                            total += 1
                            if spawn:FindFirstChild("Attachment") then
                                filled += 1
                            end
                        end
                    end
                end
            end

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, 0, 0, 25)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = Color3.new(1, 1, 1)
            infoLabel.Font = Enum.Font.GothamBold
            infoLabel.TextScaled = true
            infoLabel.Text = "👤 " .. owner .. " | 🏠 " .. model.Name .. " | Tier: " .. tostring(tier) .. " | Slots: " .. filled .. "/" .. total
            infoLabel.Parent = scrollFrame
        end
    end

    -- Resize scroll canvas
    task.wait()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end

-- Initial update
task.delay(1, updateAllPlayerBaseInfo)
