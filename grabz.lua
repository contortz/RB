--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Remote
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")
local serverTime = Workspace:GetServerTimeNow()

-- Victim UUID
local victimUUID = nil

-- GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 190)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🔍 Plot Scanner & Steal"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true

-- ScrollBox
local Results = Instance.new("ScrollingFrame", Frame)
Results.Size = UDim2.new(1, -10, 0, 90)
Results.Position = UDim2.new(0, 5, 0, 30)
Results.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Results.CanvasSize = UDim2.new(0, 0, 0, 0)
Results.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

-- Buttons
local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 125)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

local StealBtn = Instance.new("TextButton", Frame)
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 155)
StealBtn.Text = "💸 Steal from Victim"
StealBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StealBtn.TextColor3 = Color3.new(1, 1, 1)

-- Scan Function
local function ScanPlots()
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

    victimUUID = nil
    
    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        local podium = plot:FindFirstChild("AnimalPodiums") and plot.AnimalPodiums:FindFirstChild("2")
        if podium and podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn") then
            local attach = podium.Base.Spawn:FindFirstChild("Attachment")
            if attach and attach:FindFirstChild("AnimalOverhead") then
                for _, desc in ipairs(attach.AnimalOverhead:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name == "DisplayName" then
                        local name = desc.Text
                        local uuid = plot.Name
                        
                        local Label = Instance.new("TextLabel", Results)
                        Label.Size = UDim2.new(1, -5, 0, 20)
                        Label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        Label.Text = uuid .. " ➡️ " .. name
                        Label.TextColor3 = Color3.new(1, 1, 1)
                        Label.TextScaled = true
                        
                        Results.CanvasSize = UDim2.new(0, 0, 0, #Results:GetChildren() * 22)
                        
                        if name == "Fluriflura" then
                            victimUUID = uuid
                        end
                    end
                end
            end
        end
    end
end

-- Steal Function
local function Steal()
    if victimUUID then
        for i = 1, 10 do
            StealRemote:FireServer(serverTime + 71, victimUUID, i)
        end
    else
        warn("❌ Scan first to get victim UUID!")
    end
end

-- Button Actions
ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(Steal)
