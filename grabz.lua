--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

--// Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

local localPlayer = Players.LocalPlayer
local localUUID
local scannedData = {} -- { {uuid="...", index=#}, ... }

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 290)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Results = Instance.new("ScrollingFrame", Frame)
Results.Size = UDim2.new(1, -10, 0, 180)
Results.Position = UDim2.new(0, 5, 0, 5)
Results.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Results.CanvasSize = UDim2.new(0, 0, 0, 0)
Results.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(0.5, -7, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 210)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

local CopyBtn = Instance.new("TextButton", Frame)
CopyBtn.Size = UDim2.new(0.5, -7, 0, 25)
CopyBtn.Position = UDim2.new(0.5, 2, 0, 210)
CopyBtn.Text = "📋 Copy All"
CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CopyBtn.TextColor3 = Color3.new(1, 1, 1)

local StealAllBtn = Instance.new("TextButton", Frame)
StealAllBtn.Size = UDim2.new(1, -10, 0, 25)
StealAllBtn.Position = UDim2.new(0, 5, 0, 240)
StealAllBtn.Text = "💸 Steal ALL"
StealAllBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StealAllBtn.TextColor3 = Color3.new(1, 1, 1)

--// Auto-find your UUID
local function FindLocalUUID()
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner == localPlayer then
                localUUID = plot.Name
                break
            end
        end
    end
end

--// Scan Function
local function ScanPlots()
    scannedData = {}
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    FindLocalUUID()
    if not localUUID then
        warn("⚠️ Local UUID not found! Is your plot loaded?")
        return
    end

    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList then
                for index, animalData in pairs(animalList) do
                    if animalData and animalData.Index then
                        local victimUUID = plot.Name
                        local displayName = animalData.DisplayName or ("Animal "..index)

                        table.insert(scannedData, {uuid=victimUUID, index=index})

                        local Btn = Instance.new("TextButton", Results)
                        Btn.Size = UDim2.new(1, -5, 0, 20)
                        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        Btn.TextColor3 = Color3.new(1, 1, 1)
                        Btn.TextScaled = true
                        Btn.Text = victimUUID.." ➡️ "..displayName

                        Btn.MouseButton1Click:Connect(function()
                            local serverTime = Workspace:GetServerTimeNow()
                            StealRemote:FireServer(serverTime + 60, localUUID, victimUUID, index)
                        end)
                    end
                end
            end
        end
    end
    Results.CanvasSize = UDim2.new(0, 0, 0, #Results:GetChildren() * 22)
end

--// Copy All
local function CopyAll()
    if #scannedData > 0 then
        local output = {}
        for _, v in ipairs(scannedData) do
            table.insert(output, v.uuid.." ➡️ Animal "..v.index)
        end
        setclipboard(table.concat(output, "\n"))
    else
        warn("⚠️ Nothing scanned to copy.")
    end
end

--// Steal All
local function StealAll()
    if not localUUID then
        FindLocalUUID()
    end
    if not localUUID then
        warn("⚠️ Local UUID not found!")
        return
    end
    local serverTime = Workspace:GetServerTimeNow()
    for _, v in ipairs(scannedData) do
        StealRemote:FireServer(serverTime + 60, localUUID, v.uuid, v.index)
    end
end

--// Connect Buttons
ScanBtn.MouseButton1Click:Connect(ScanPlots)
CopyBtn.MouseButton1Click:Connect(CopyAll)
StealAllBtn.MouseButton1Click:Connect(StealAll)
