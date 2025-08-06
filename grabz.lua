--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

-- Remotes (Prep + Grab)
local PrepRemote = Net:RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52")
local GrabRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

-- UUIDs
local myUUID = nil
local victimUUID = nil

--// UI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "Plot2StealUI"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 170)
Frame.Position = UDim2.new(0.5, -130, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "📦 Plot 2 Steal Control"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, -10, 0, 35)
Status.Position = UDim2.new(0, 5, 0, 30)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.new(1, 1, 1)
Status.Font = Enum.Font.Code
Status.TextSize = 14
Status.TextWrapped = true
Status.Text = "Scan to detect UUIDs..."
Status.Parent = Frame

Title.Parent = Frame

-- Helper to make buttons
local function createButton(text, position, color)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = position
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    return btn
end

local ScanBtn = createButton("🔍 Scan for UUIDs", UDim2.new(0, 5, 0, 70), Color3.fromRGB(60, 60, 60))
local StealBtn = createButton("💸 Steal Plot 2", UDim2.new(0, 5, 0, 100), Color3.fromRGB(150, 50, 50))
local ReverseBtn = createButton("🔄 Reverse Steal", UDim2.new(0, 5, 0, 130), Color3.fromRGB(50, 150, 50))

--// Scan Logic
local function ScanPlots()
    myUUID = nil
    victimUUID = nil
    
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner then
                -- Detect my UUID
                if owner == game.Players.LocalPlayer then
                    myUUID = plot.Name
                else
                    -- Grab first non-owned plot as victim
                    if not victimUUID then
                        victimUUID = plot.Name
                    end
                end
            end
        end
    end
    
    if myUUID and victimUUID then
        Status.Text = "✅ MyUUID: " .. myUUID .. "\n🎯 VictimUUID: " .. victimUUID
    elseif myUUID then
        Status.Text = "⚠️ Victim not found!"
    else
        Status.Text = "⚠️ Couldn’t detect my plot!"
    end
end

--// Grab Logic
local function DoGrab(fromUUID, toUUID)
    local serverTime = Workspace:GetServerTimeNow()
    PrepRemote:FireServer(serverTime, fromUUID)
    PrepRemote:FireServer(serverTime, toUUID)
    GrabRemote:FireServer(serverTime, fromUUID, toUUID, 2)
end

--// Button Events
ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(function()
    if myUUID and victimUUID then
        DoGrab(myUUID, victimUUID)
        Status.Text = "✅ Steal sent!"
    else
        Status.Text = "⚠️ Scan first!"
    end
end)
ReverseBtn.MouseButton1Click:Connect(function()
    if myUUID and victimUUID then
        DoGrab(victimUUID, myUUID)
        Status.Text = "✅ Reverse steal sent!"
    else
        Status.Text = "⚠️ Scan first!"
    end
end)
