--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Remotes
local HandshakeRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52")
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("39c0ed9f-fd96-4f29-a89e-403bdb02eb6b")
local serverTime = Workspace:GetServerTimeNow()

-- UUIDs
local yourUUID = nil
local victimUUID = nil

-- GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 230)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🔍 Plot Scanner & Steal"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true

local Results = Instance.new("ScrollingFrame", Frame)
Results.Size = UDim2.new(1, -10, 0, 120)
Results.Position = UDim2.new(0, 5, 0, 30)
Results.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Results.CanvasSize = UDim2.new(0, 0, 0, 0)
Results.ScrollBarThickness = 6
local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 155)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

local StealBtn = Instance.new("TextButton", Frame)
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 180)
StealBtn.Text = "💸 Steal from Victim"
StealBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StealBtn.TextColor3 = Color3.new(1, 1, 1)

-- Scan Function
local function ScanPlots()
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
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
                        
                        if name == "Cocofanto Elefanto" then
                            yourUUID = uuid
                        elseif name == "Fluriflura" then
                            victimUUID = uuid
                        end
                    end
                end
            end
        end
    end
end

-- Full 4-Packet Steal
local function StealFromVictim()
    if yourUUID and victimUUID then
        for podiumIndex = 1, 10 do
            -- Packet 1
            HandshakeRemote:FireServer(serverTime + 71, "e48572ed-dadc-4d9b-9124-315d813815db")
            -- Packet 2
            HandshakeRemote:FireServer(serverTime + 71, "614ca939-6c52-4dab-b3ab-5cde12e0a5f2")
            -- Packet 3
            StealRemote:FireServer(serverTime + 71, "cf9ebf62-6040-4485-b600-8c3d51818629", victimUUID, podiumIndex)
            -- Packet 4
            StealRemote:FireServer(serverTime + 71, "e8ecef56-8247-419b-8909-383adc32f434", victimUUID, podiumIndex)
        end
    else
        warn("❌ Scan first to detect UUIDs!")
    end
end

ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(StealFromVictim)
