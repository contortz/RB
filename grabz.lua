--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

-- Steal Remote (auto resolves RE/StealService/Grab)
local StealRemote = Net:RemoteEvent("StealService/Grab")

-- Local player UUID (your plot’s UUID will be scanned dynamically, so this is optional unless you own plot 2)
local myUUID = nil
local plot2UUID = nil

--// UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Plot2StealUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 160)
Frame.Position = UDim2.new(0.5, -120, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 8)

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 0, 25)
Label.BackgroundTransparency = 1
Label.Text = "📦 Plot 2 Steal Control"
Label.TextColor3 = Color3.new(1, 1, 1)
Label.Font = Enum.Font.GothamBold
Label.TextSize = 16
Label.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -10, 0, 20)
Status.Position = UDim2.new(0, 5, 0, 30)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.new(1, 1, 1)
Status.Font = Enum.Font.Code
Status.TextSize = 14
Status.Text = "Scan to find Plot 2..."
Status.Parent = Frame

-- Buttons
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 55)
ScanBtn.Text = "🔍 Scan for Plot 2"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.Font = Enum.Font.Gotham
ScanBtn.TextSize = 14
ScanBtn.Parent = Frame

local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 85)
StealBtn.Text = "💸 Steal Plot 2"
StealBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Font = Enum.Font.Gotham
StealBtn.TextSize = 14
StealBtn.Parent = Frame

local ReverseBtn = Instance.new("TextButton")
ReverseBtn.Size = UDim2.new(1, -10, 0, 25)
ReverseBtn.Position = UDim2.new(0, 5, 0, 115)
ReverseBtn.Text = "🔄 Reverse Steal Plot 2"
ReverseBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ReverseBtn.TextColor3 = Color3.new(1, 1, 1)
ReverseBtn.Font = Enum.Font.Gotham
ReverseBtn.TextSize = 14
ReverseBtn.Parent = Frame

--// Functions
local function ScanPlot2()
    plot2UUID = nil
    myUUID = nil
    
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner then
                -- Detect Plot 2 by attribute or name match
                if plot.Name:find("2") or (plot:GetAttribute("Tier") == 2) then
                    plot2UUID = plot.Name
                end
                -- Capture your UUID
                if owner == game.Players.LocalPlayer then
                    myUUID = plot.Name
                end
            end
        end
    end
    
    if plot2UUID then
        Status.Text = "✅ Plot 2 UUID: " .. plot2UUID
    else
        Status.Text = "⚠️ Plot 2 not found!"
    end
end

local function StealPlot2()
    if myUUID and plot2UUID then
        StealRemote:FireServer(Workspace:GetServerTimeNow() + 71, myUUID, plot2UUID, 2)
        Status.Text = "✅ Steal fired."
    else
        Status.Text = "⚠️ Scan first!"
    end
end

local function ReverseStealPlot2()
    if myUUID and plot2UUID then
        StealRemote:FireServer(Workspace:GetServerTimeNow() + 71, plot2UUID, myUUID, 2)
        Status.Text = "✅ Reverse steal fired."
    else
        Status.Text = "⚠️ Scan first!"
    end
end

--// Bind buttons
ScanBtn.MouseButton1Click:Connect(ScanPlot2)
StealBtn.MouseButton1Click:Connect(StealPlot2)
ReverseBtn.MouseButton1Click:Connect(ReverseStealPlot2)
