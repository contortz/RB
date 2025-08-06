--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Net + Remotes
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local PrepRemote = Net:RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52") -- Prep handshake
local GrabRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e") -- Final grab
local DeliveryRemote = Net:RemoteEvent("de34c182-de89-4c83-a3a4-7e76a719e789") -- Delivery

--// Conch UI
local ConchUI = require(ReplicatedStorage.Packages.Conch["alicesaidhi+conch_ui"].conch_ui)

--// UUIDs
local yourUUID = nil
local victimUUID = nil

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 285) -- Added height for Console button
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
Results.ScrollBarThickness = 6
Results.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

-- Utility to make buttons
local function createButton(text, yPos, color)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    return btn
end

-- Buttons
local ScanBtn    = createButton("🔍 Scan Plots", 155, Color3.fromRGB(60,60,60))
local StealBtn   = createButton("💸 Steal from Victim", 180, Color3.fromRGB(80,20,20))
local ReverseBtn = createButton("🔄 Reverse Steal", 205, Color3.fromRGB(20,80,20))
local DeliverBtn = createButton("📦 Simulate Delivery", 230, Color3.fromRGB(20,20,80))
local ConsoleBtn = createButton("🖥 Launch Conch Console", 255, Color3.fromRGB(50,50,100))

--// Scan Function
local function ScanPlots()
    yourUUID, victimUUID = nil, nil
    for _, c in ipairs(Results:GetChildren()) do 
        if c:IsA("TextLabel") then c:Destroy() end 
    end
    
    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        local podium = plot:FindFirstChild("AnimalPodiums") and plot.AnimalPodiums:FindFirstChild("2")
        if podium and podium.Base and podium.Base:FindFirstChild("Spawn") then
            local attach = podium.Base.Spawn:FindFirstChild("Attachment")
            if attach and attach:FindFirstChild("AnimalOverhead") then
                for _, desc in ipairs(attach.AnimalOverhead:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name == "DisplayName" then
                        local name = desc.Text
                        local uuid = plot.Name
                        
                        local lbl = Instance.new("TextLabel", Results)
                        lbl.Size = UDim2.new(1, -5, 0, 20)
                        lbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        lbl.Text = uuid .. " ➡️ " .. name
                        lbl.TextColor3 = Color3.new(1, 1, 1)
                        lbl.TextScaled = true
                        
                        Results.CanvasSize = UDim2.new(0, 0, 0, #Results:GetChildren()*22)
                        
                        if name == "Cocofanto Elefanto" then yourUUID = uuid end
                        if name == "Fluriflura" then victimUUID = uuid end
                    end
                end
            end
        end
    end
end

--// Steal Function
local function DoSteal(fromUUID, toUUID)
    if not (fromUUID and toUUID) then 
        warn("❌ Scan first!") 
        return 
    end
    
    local serverTime = Workspace:GetServerTimeNow()
    PrepRemote:FireServer(serverTime, fromUUID)
    PrepRemote:FireServer(serverTime, toUUID)
    task.wait(2.5)
    GrabRemote:FireServer(serverTime + 2.5, fromUUID, toUUID, 2)
end

--// Delivery Function
local function DoDelivery()
    local deliveryUUID = "128ed252-43ef-423b-8d83-bcbc692628b7"
    for repeatIndex = 1, 20 do
        DeliveryRemote:FireServer(deliveryUUID)
        task.wait(0.05)
    end
end

--// Launch Console
local function LaunchConsole()
    if ConchUI.Init then
        ConchUI:Init()
    elseif ConchUI.Launch then
        ConchUI:Launch()
    elseif ConchUI.Start then
        ConchUI:Start()
    else
        warn("⚠ No obvious start function found in ConchUI")
    end
end

-- Button Events
ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(function() DoSteal(yourUUID, victimUUID) end)
ReverseBtn.MouseButton1Click:Connect(function() DoSteal(victimUUID, yourUUID) end)
DeliverBtn.MouseButton1Click:Connect(DoDelivery)
ConsoleBtn.MouseButton1Click:Connect(LaunchConsole)
