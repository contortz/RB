--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Parent = ScreenGui

--// Create Buttons
local ClaimCoinsBtn = Instance.new("TextButton")
ClaimCoinsBtn.Size = UDim2.new(1, -10, 0, 40)
ClaimCoinsBtn.Position = UDim2.new(0, 5, 0, 5)
ClaimCoinsBtn.Text = "Claim Coins"
ClaimCoinsBtn.TextColor3 = Color3.new(1, 1, 1)
ClaimCoinsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ClaimCoinsBtn.Parent = Frame

local GrabBtn = Instance.new("TextButton")
GrabBtn.Size = UDim2.new(1, -10, 0, 40)
GrabBtn.Position = UDim2.new(0, 5, 0, 50)
GrabBtn.Text = "Grab"
GrabBtn.TextColor3 = Color3.new(1, 1, 1)
GrabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GrabBtn.Parent = Frame

--// Functions
ClaimCoinsBtn.MouseButton1Click:Connect(function()
    local args = { 2 }
    ReplicatedStorage.Packages.Net["RE/PlotService/ClaimCoins"]:FireServer(unpack(args))
end)

GrabBtn.MouseButton1Click:Connect(function()
    local args = { "Grab", 2 }
    ReplicatedStorage.Packages.Net["RE/StealService/Grab"]:FireServer(unpack(args))
end)
