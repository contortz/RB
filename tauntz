-- Auto Taunt Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Variables
local AutoTauntEnabled = false
local TauntEvent = ReplicatedStorage:WaitForChild("Net")
local args = {"Taunt.play"}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0.05, 0, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "Auto Taunt: OFF"
ToggleButton.Parent = ScreenGui

-- Toggle Function
ToggleButton.MouseButton1Click:Connect(function()
    AutoTauntEnabled = not AutoTauntEnabled
    ToggleButton.Text = "Auto Taunt: " .. (AutoTauntEnabled and "ON" or "OFF")
    ToggleButton.BackgroundColor3 = AutoTauntEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Loop
RunService.Heartbeat:Connect(function()
    if AutoTauntEnabled then
        for count = 1, 1000 do
            TauntEvent:FireServer(unpack(args))
        end
    end
end)
