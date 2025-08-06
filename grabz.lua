local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Net + Synchronizer
local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
local StealRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

local localUUID = "YOUR_UUID_HERE"

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PlotScanStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 230)
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
ScanBtn.Size = UDim2.new(1, -10, 0, 25)
ScanBtn.Position = UDim2.new(0, 5, 0, 200)
ScanBtn.Text = "🔍 Scan Plots"
ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ScanBtn.TextColor3 = Color3.new(1, 1, 1)

local function ScanPlots()
    -- Clear old results
    for _, child in ipairs(Results:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        -- ✅ Grab channel via Synchronizer
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local animalList = channel:Get("AnimalList")
            if animalList then
                for index, animalData in pairs(animalList) do
                    if animalData and animalData.Index then
                        local victimUUID = plot.Name
                        local displayName = animalData.DisplayName or ("Animal "..index)

                        -- Create button to trigger steal
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

ScanBtn.MouseButton1Click:Connect(ScanPlots)
