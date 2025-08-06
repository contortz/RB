--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

--// Setup Remotes
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

--// Your UUID
local localUUID = "YOUR_UUID_HERE" -- Replace this with your Cocofanto plot UUID

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlotStealUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 300)
Frame.Position = UDim2.new(0.3, 0, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "🔍 Plot Scanner + Stealer"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true

local Results = Instance.new("ScrollingFrame", Frame)
Results.Size = UDim2.new(1, -10, 0, 220)
Results.Position = UDim2.new(0, 5, 0, 30)
Results.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Results.ScrollBarThickness = 6
Results.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIList = Instance.new("UIListLayout", Results)
UIList.Padding = UDim.new(0, 2)

local ScanBtn = Instance.new("TextButton", Frame)
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 260)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

-- Store victim data
local plotData = {}

-- Scan Plots
local function ScanPlots()
    -- Clear old
    for _, c in ipairs(Results:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    table.clear(plotData)

    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = rawget(plot, "Channel")
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList then
                for index, animal in pairs(animalList) do
                    if animal and animal.Index then
                        local victimUUID = plot.Name
                        local displayName = animal.DisplayName or ("Animal "..index)

                        local Btn = Instance.new("TextButton", Results)
                        Btn.Size = UDim2.new(1, -5, 0, 20)
                        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        Btn.TextColor3 = Color3.new(1, 1, 1)
                        Btn.TextScaled = true
                        Btn.Text = victimUUID.." ➡️ "..displayName

                        plotData[Btn] = {
                            victimUUID = victimUUID,
                            index = index
                        }

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

ScanBtn.MouseButton1Click:Connect(ScanPlots)
