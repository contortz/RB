--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

-- Remotes
local PrepRemote = Net:RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52")
local GrabRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

-- UUIDs
local myUUID = nil
local plot2UUID = nil

--// UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Plot2StealUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") -- ✅ Works reliably

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 160)
Frame.Position = UDim2.new(0.5, -120, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Label = Instance.new("TextLabel", Frame)
Label.Size = UDim2.new(1, 0, 0, 25)
Label.BackgroundTransparency = 1
Label.Text = "📦 Plot 2 Steal Control"
Label.TextColor3 = Color3.new(1, 1, 1)
Label.Font = Enum.Font.GothamBold
Label.TextSize = 16
Label.Parent = Frame

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, -10, 0, 20)
Status.Position = UDim2.new(0, 5, 0, 30)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.new(1, 1, 1)
Status.Font = Enum.Font.Code
Status.TextSize = 14
Status.Text = "Scan to find Plot 2..."
Status.Parent = Frame

-- Helper to create buttons
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

local ScanBtn = createButton("🔍 Scan for Plot 2", UDim2.new(0, 5, 0, 55), Color3.fromRGB(60, 60, 60))
local StealBtn = createButton("💸 Steal Plot 2", UDim2.new(0, 5, 0, 85), Color3.fromRGB(150, 50, 50))
local ReverseBtn = createButton("🔄 Reverse Steal Plot 2", UDim2.new(0, 5, 0, 115), Color3.fromRGB(50, 150, 50))

--// Scan Logic
local function ScanPlot2()
    plot2UUID = nil
    myUUID = nil
    
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner then
                if plot.Name:find("2") or plot:GetAttribute("Tier") == 2 then
                    plot2UUID = plot.Name
                end
                if owner == Players.LocalPlayer then
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

--// Grab Logic (Auto Delay)
local function DoGrab(fromUUID, toUUID)
    local prepTime = Workspace:GetServerTimeNow()
    local holdTime = 2.5 -- Hold duration from proximity prompt
    local extraDelay = 68.5 -- Remaining delay to match ~71 total
    
    -- Step 1: Prep both sides
    PrepRemote:FireServer(prepTime, fromUUID)
    PrepRemote:FireServer(prepTime, toUUID)
    Status.Text = "⏳ Prep fired at " .. prepTime
    
    -- Step 2: Auto grab after full duration
    task.delay(holdTime + extraDelay, function()
        local grabTime = Workspace:GetServerTimeNow()
        GrabRemote:FireServer(grabTime, fromUUID, toUUID, 2)
        Status.Text = "✅ Grab fired at " .. grabTime
    end)
end

-- Button Actions
ScanBtn.MouseButton1Click:Connect(ScanPlot2)
StealBtn.MouseButton1Click:Connect(function()
    if myUUID and plot2UUID then
        DoGrab(myUUID, plot2UUID)
    else
        Status.Text = "⚠️ Scan first!"
    end
end)
ReverseBtn.MouseButton1Click:Connect(function()
    if myUUID and plot2UUID then
        DoGrab(plot2UUID, myUUID)
    else
        Status.Text = "⚠️ Scan first!"
    end
end)
