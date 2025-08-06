--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Remote
local grabRemote = ReplicatedStorage.Packages.Net["RE/StealService/Grab"]

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrabAllBasesGui"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 60)
Frame.Position = UDim2.new(0.5, -90, 0.5, -30)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Parent = ScreenGui

local GrabAllBtn = Instance.new("TextButton")
GrabAllBtn.Size = UDim2.new(1, -10, 0, 40)
GrabAllBtn.Position = UDim2.new(0, 5, 0, 10)
GrabAllBtn.Text = "💸 Grab All Bases"
GrabAllBtn.TextColor3 = Color3.new(1, 1, 1)
GrabAllBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GrabAllBtn.Parent = Frame

-- Function: Grab all UUIDs
local function GrabAllBases()
    for _, floor in ipairs(ReplicatedStorage.Bases:GetChildren()) do
        for _, obj in ipairs(floor:GetDescendants()) do
            if obj:IsA("StringValue") and string.match(obj.Value, "%-") then
                -- Found UUID
                print("Grabbing from base:", obj.Value)
                grabRemote:FireServer("Grab", obj.Value)
            end
        end
    end
end

GrabAllBtn.MouseButton1Click:Connect(GrabAllBases)
