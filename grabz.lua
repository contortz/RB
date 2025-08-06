--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Your UUID (thief)
local thiefUUID = "42fcba24-5876-45f8-aad5-e2513f445fe7"
local serverTime = Workspace:GetServerTimeNow()

-- Remote
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

-- GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MassStealGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 60)
Frame.Position = UDim2.new(0.5, -100, 0.5, -30)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local StealBtn = Instance.new("TextButton", Frame)
StealBtn.Size = UDim2.new(1, -10, 0, 40)
StealBtn.Position = UDim2.new(0, 5, 0, 10)
StealBtn.Text = "💸 Mass Steal All Bases"
StealBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StealBtn.TextColor3 = Color3.new(1, 1, 1)

-- Function: Mass Steal
local function MassSteal()
    for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
        local victimUUID = plot.Name
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for i = 1, 10 do
                StealRemote:FireServer(serverTime + 71, thiefUUID, victimUUID, i)
            end
        end
    end
end

StealBtn.MouseButton1Click:Connect(MassSteal)
