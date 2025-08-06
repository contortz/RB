--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

--// Your UUID
local myUUID = "YOUR_UUID_HERE"
local plot2UUIDLive = nil -- will be updated from scanner

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "Plot2StealUI"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 140)
Frame.Position = UDim2.new(0.4, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🎯 Plot 2 Steal Controls"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true

-- Scan Button
local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 30)
ScanBtn.Text = "🔍 Scan Plot 2 UUID"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.Parent = Frame

-- Steal Button
local StealBtn = Instance.new("TextButton", Frame)
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 60)
StealBtn.Text = "💸 Steal Plot 2 Animals"
StealBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Parent = Frame

-- Reverse Steal Button
local ReverseBtn = Instance.new("TextButton", Frame)
ReverseBtn.Size = UDim2.new(1, -10, 0, 25)
ReverseBtn.Position = UDim2.new(0, 5, 0, 90)
ReverseBtn.Text = "🔄 Reverse Steal Plot 2"
ReverseBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 20)
ReverseBtn.TextColor3 = Color3.new(1, 1, 1)
ReverseBtn.Parent = Frame

-- Scanner Logic for Plot 2
local function scanPlot2()
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList and plot.Name:find("2") then -- crude match for plot 2
                plot2UUIDLive = plot.Name
                print("✅ Plot 2 UUID updated:", plot2UUIDLive)
                break
            end
        end
    end
    if not plot2UUIDLive then
        warn("⚠️ Plot 2 UUID not found!")
    end
end

-- Steal Logic
local function stealPlot2()
    if not plot2UUIDLive then
        warn("⚠️ Scan first to get Plot 2 UUID")
        return
    end
    local serverTime = Workspace:GetServerTimeNow()
    for idx = 1, 20 do
        StealRemote:FireServer(serverTime + 71, myUUID, plot2UUIDLive, idx)
        task.wait(0.2)
    end
end

-- Reverse Steal Logic
local function reverseStealPlot2()
    if not plot2UUIDLive then
        warn("⚠️ Scan first to get Plot 2 UUID")
        return
    end
    local serverTime = Workspace:GetServerTimeNow()
    for idx = 1, 20 do
        StealRemote:FireServer(serverTime + 71, plot2UUIDLive, myUUID, idx)
        task.wait(0.2)
    end
end

-- Connect Buttons
ScanBtn.MouseButton1Click:Connect(scanPlot2)
StealBtn.MouseButton1Click:Connect(stealPlot2)
ReverseBtn.MouseButton1Click:Connect(reverseStealPlot2)
