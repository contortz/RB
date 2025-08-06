local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Modules
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

-- Replace this with your actual UUID
local localUUID = "5519c13b-957e-4210-8cbb-cc9244cd48fc"

local allStealPayloads = {}

-- UI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotStealer"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 260)
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
Results.Size = UDim2.new(1, -10, 0, 160)
Results.Position = UDim2.new(0, 5, 0, 30)
Results.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Results.CanvasSize = UDim2.new(0, 0, 0, 0)
Results.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

local function UpdateCanvasSize()
    Results.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
end

-- Buttons
local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 195)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

local CopyBtn = Instance.new("TextButton", Frame)
CopyBtn.Size = UDim2.new(0.5, -7, 0, 25)
CopyBtn.Position = UDim2.new(0, 5, 0, 225)
CopyBtn.Text = "📋 Copy All"
CopyBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 30)
CopyBtn.TextColor3 = Color3.new(1, 1, 1)

local StealAllBtn = Instance.new("TextButton", Frame)
StealAllBtn.Size = UDim2.new(0.5, -7, 0, 25)
StealAllBtn.Position = UDim2.new(0.5, 2, 0, 225)
StealAllBtn.Text = "💸 Steal All"
StealAllBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 30)
StealAllBtn.TextColor3 = Color3.new(1, 1, 1)

-- Scan Function
local function ScanPlots()
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    allStealPayloads = {}

    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList then
                for index, animalData in pairs(animalList) do
                    if animalData and animalData.Index then
                        local victimUUID = plot.Name
                        local displayName = animalData.DisplayName or ("Animal " .. index)

                        -- Store payload
                        table.insert(allStealPayloads, {
                            victim = victimUUID,
                            index = index,
                        })

                        -- GUI button
                        local Btn = Instance.new("TextButton", Results)
                        Btn.Size = UDim2.new(1, -5, 0, 22)
                        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        Btn.TextColor3 = Color3.new(1, 1, 1)
                        Btn.TextScaled = true
                        Btn.Text = victimUUID .. " ➡️ " .. displayName

                        Btn.MouseButton1Click:Connect(function()
                            local serverTime = Workspace:GetServerTimeNow()
                            StealRemote:FireServer(serverTime + 60, localUUID, victimUUID, index)
                        end)
                    end
                end
            end
        end
    end

    UpdateCanvasSize()
end

-- Copy to Clipboard
local function CopyAllPayloads()
    local serverTime = Workspace:GetServerTimeNow()
    local lines = {}
    for _, data in ipairs(allStealPayloads) do
        local line = `StealRemote:FireServer({serverTime + 60}, "{localUUID}", "{data.victim}", {data.index})`
        table.insert(lines, line)
    end
    setclipboard(table.concat(lines, "\n"))
end

-- Mass Steal
local function StealAll()
    local serverTime = Workspace:GetServerTimeNow()
    for _, data in ipairs(allStealPayloads) do
        StealRemote:FireServer(serverTime + 60, localUUID, data.victim, data.index)
    end
end

-- Button Connections
ScanBtn.MouseButton1Click:Connect(ScanPlots)
CopyBtn.MouseButton1Click:Connect(CopyAllPayloads)
StealAllBtn.MouseButton1Click:Connect(StealAll)
