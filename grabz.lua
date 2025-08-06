--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Setup Remotes
local Net = require(ReplicatedStorage.Packages.Net)
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAnywhereUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 200)
Frame.Position = UDim2.new(0.5, -140, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 8)

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 0, 30)
Label.BackgroundTransparency = 1
Label.Text = "🐘 Cocofanto Steal Menu"
Label.TextColor3 = Color3.new(1, 1, 1)
Label.Font = Enum.Font.GothamBold
Label.TextSize = 16
Label.Parent = Frame

local LogBox = Instance.new("TextLabel")
LogBox.Size = UDim2.new(1, -10, 0, 100)
LogBox.Position = UDim2.new(0, 5, 0, 35)
LogBox.BackgroundTransparency = 1
LogBox.TextColor3 = Color3.new(1, 1, 1)
LogBox.TextXAlignment = Enum.TextXAlignment.Left
LogBox.TextYAlignment = Enum.TextYAlignment.Top
LogBox.Font = Enum.Font.Code
LogBox.TextSize = 14
LogBox.TextWrapped = true
LogBox.Text = "Press Scan Plots..."
LogBox.Parent = Frame

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0.5, -7, 0, 30)
ScanBtn.Position = UDim2.new(0, 5, 0, 150)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.Font = Enum.Font.Gotham
ScanBtn.TextSize = 14
ScanBtn.Parent = Frame

local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(0.5, -7, 0, 30)
StealBtn.Position = UDim2.new(0.5, 2, 0, 150)
StealBtn.Text = "💸 Steal Anywhere"
StealBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Font = Enum.Font.Gotham
StealBtn.TextSize = 14
StealBtn.Parent = Frame

--// Vars
local yourUUID
local victimList = {}

--// Scan Function
local function ScanPlots()
    yourUUID = nil
    table.clear(victimList)
    
    local channelFolder = ReplicatedStorage:WaitForChild("Synchronizer"):WaitForChild("Channel")
    for _, ch in ipairs(channelFolder:GetChildren()) do
        local channel = rawget(ch, "Channel") or ch
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList then
                for index, animalData in pairs(animalList) do
                    if animalData and animalData.Index then
                        if animalData.DisplayName == "Cocofanto Elefanto" then
                            yourUUID = ch.Name
                        else
                            table.insert(victimList, {uuid = ch.Name, index = index})
                        end
                    end
                end
            end
        end
    end
    
    if yourUUID then
        LogBox.Text = "✅ Cocofanto UUID: " .. yourUUID .. "\nVictims: " .. tostring(#victimList)
    else
        LogBox.Text = "⚠️ Cocofanto not found!"
    end
end

--// Steal Function
local function StealAnywhere()
    if not yourUUID then
        LogBox.Text = "⚠️ Scan first!"
        return
    end
    local serverTime = Workspace:GetServerTimeNow()
    for _, victim in ipairs(victimList) do
        StealRemote:FireServer(serverTime + 60, yourUUID, victim.uuid, victim.index)
    end
    LogBox.Text = "💸 Steal attempts sent to " .. tostring(#victimList) .. " plots."
end

--// Bind Buttons
ScanBtn.MouseButton1Click:Connect(ScanPlots)
StealBtn.MouseButton1Click:Connect(StealAnywhere)
