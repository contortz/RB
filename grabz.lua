--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Remotes
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")
local serverTime = Workspace:GetServerTimeNow()

-- Your UUID (once identified from scan)
local yourUUID = nil
local victimUUID = nil

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0) -- High up
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true -- Draggable UI
Frame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🔍 Plot Scanner & Steal"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true

-- ScrollBox for Results
local Results = Instance.new("ScrollingFrame", Frame)
Results.Size = UDim2.new(1, -10, 0, 120)
Results.Position = UDim2.new(0, 5, 0, 30)
Results.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Results.CanvasSize = UDim2.new(0, 0, 0, 0)
Results.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

-- Scan Button
local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 155)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

-- Steal Button
local StealBtn = Instance.new("TextButton", Frame)
StealBtn.Size = UDim2.new(1, -10, 0, 25)
StealBtn.Position = UDim2.new(0, 5, 0, 180)
StealBtn.Text = "💸 Execute Steal (Podium 2)"
StealBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StealBtn.TextColor3 = Color3.new(1, 1, 1)

-- Function: Scan Plots
local function ScanPlots()
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
        local podium = plot:FindFirstChild("AnimalPodiums") and plot.AnimalPodiums:FindFirstChild("2")
        if podium and podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn") then
            local attach = podium.Base.Spawn:FindFirstChild("Attachment")
            if attach and attach:FindFirstChild("AnimalOverhead") then
                -- Search descendants for DisplayName
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
                        
                        -- Identify your UUID & victim UUID automatically
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


-- Function: Steal
local function Steal()
    if yourUUID and victimUUID then
        StealRemote:FireServer(serverTime + 71, yourUUID, victimUUID, 2)
    else
        warn("❌ UUIDs not set. Scan plots first!")
    end
end

-- Bind buttons
ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(Steal)
