--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

-- Steal Remote (Proper Grab remote)
local StealRemote = Net:RemoteEvent("StealService/Grab")

-- UUID storage
local myUUID, plot2UUID = nil, nil

--// UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Plot2StealUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 230)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "📦 Plot 2 Steal Control"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -10, 0, 20)
Status.Position = UDim2.new(0, 5, 0, 30)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.new(1, 1, 1)
Status.Text = "🔍 Scan for Plot 2..."
Status.Parent = Frame

-- Buttons
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 60)
ScanBtn.Text = "🔍 Scan Plot 2"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.Parent = Frame

local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 90)
StealBtn.Text = "💸 Steal Plot 2"
StealBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Parent = Frame

local ReverseBtn = Instance.new("TextButton")
ReverseBtn.Size = UDim2.new(1, -10, 0, 25)
ReverseBtn.Position = UDim2.new(0, 5, 0, 120)
ReverseBtn.Text = "🔄 Reverse Plot 2"
ReverseBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ReverseBtn.TextColor3 = Color3.new(1, 1, 1)
ReverseBtn.Parent = Frame

--// Functions
local function ScanPlot2()
    myUUID, plot2UUID = nil, nil
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner then
                if plot.Name:find("2") then plot2UUID = plot.Name end
                if owner == game.Players.LocalPlayer then myUUID = plot.Name end
            end
        end
    end
    Status.Text = plot2UUID and ("✅ Plot 2: " .. plot2UUID) or "⚠️ Plot 2 not found"
end

local function StealPlot2()
    if myUUID and plot2UUID then
        StealRemote:FireServer(Workspace:GetServerTimeNow() + 71, myUUID, plot2UUID, 2)
        Status.Text = "✅ Steal fired (Grab)"
    else
        Status.Text = "⚠️ Scan first!"
    end
end

local function ReversePlot2()
    if myUUID and plot2UUID then
        StealRemote:FireServer(Workspace:GetServerTimeNow() + 71, plot2UUID, myUUID, 2)
        Status.Text = "✅ Reverse fired (Grab)"
    else
        Status.Text = "⚠️ Scan first!"
    end
end

-- Button bindings
ScanBtn.MouseButton1Click:Connect(ScanPlot2)
StealBtn.MouseButton1Click:Connect(StealPlot2)
ReverseBtn.MouseButton1Click:Connect(ReversePlot2)
