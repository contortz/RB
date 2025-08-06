--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- UUIDs
local thiefUUID = "5519c13b-957e-4210-8cbb-cc9244cd48fc"
local victimUUID = "42fcba24-5876-45f8-aad5-e2513f445fe7"
local serverTime = Workspace:GetServerTimeNow()

-- Remote
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e")

-- GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TargetStealGui"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 60)
Frame.Position = UDim2.new(0.5, -100, 0.2, -30) -- much higher on screen
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Parent = ScreenGui

local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(1, -10, 0, 40)
StealBtn.Position = UDim2.new(0, 5, 0, 10)
StealBtn.Text = "💸 Steal From Victim"
StealBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Parent = Frame

-- Function: Steal from specific victim
local function StealFromVictim()
    for i = 1, 10 do
        StealRemote:FireServer(serverTime + 71, thiefUUID, victimUUID, i)
    end
end

StealBtn.MouseButton1Click:Connect(StealFromVictim)
