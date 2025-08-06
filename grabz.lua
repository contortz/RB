--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// GUI parent fallback
local CoreGui = game:GetService("CoreGui")
local GuiParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
if not GuiParent then GuiParent = LocalPlayer:WaitForChild("PlayerGui") end

--// Wait for Plots
local Plots = Workspace:WaitForChild("Plots", 10)
if not Plots then warn("⚠️ Plots not found") return end

--// Modules
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local StealRemote = Net:RemoteEvent("StealService/Grab")

--// Your UUID (replace this with your actual UUID)
local myUUID = "YOUR-UUID-HERE"
local plot2UUID = nil

--// UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealPlotUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 140)
Frame.Position = UDim2.new(0.4, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🎯 Plot 2 Steal Menu"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true

-- Button factory
local function makeButton(yOffset, text, color)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, yOffset)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    return btn
end

local ScanBtn = makeButton(30, "🔍 Scan Plot 2 UUID", Color3.fromRGB(60, 60, 60))
local StealBtn = makeButton(60, "💸 Steal Plot 2", Color3.fromRGB(80, 20, 20))
local ReverseBtn = makeButton(90, "🔄 Reverse Steal", Color3.fromRGB(20, 80, 20))

-- Scan Logic
local function scanPlot2()
    plot2UUID = nil
    for _, plot in ipairs(Plots:GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner and plot.Name:find("2") then
                plot2UUID = plot.Name
                print("✅ Found Plot 2 UUID:", plot2UUID)
                break
            end
        end
    end
    if not plot2UUID then warn("⚠️ Plot 2 not found.") end
end

-- Steal Logic
local function stealFromPlot2()
    if not plot2UUID then warn("⚠️ Scan first") return end
    local serverTime = Workspace:GetServerTimeNow()
    StealRemote:FireServer(serverTime + 71, myUUID, plot2UUID, 2) -- '2' = steal
end

-- Reverse Logic
local function reverseSteal()
    if not plot2UUID then warn("⚠️ Scan first") return end
    local serverTime = Workspace:GetServerTimeNow()
    StealRemote:FireServer(serverTime + 71, plot2UUID, myUUID, 2) -- Reverse steal
end

-- Hook buttons
ScanBtn.MouseButton1Click:Connect(scanPlot2)
StealBtn.MouseButton1Click:Connect(stealFromPlot2)
ReverseBtn.MouseButton1Click:Connect(reverseSteal)

print("✅ Steal UI loaded.")
