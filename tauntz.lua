-- Auto Taunt Script (Persists After Respawn)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local AutoTauntEnabled = false
local TauntEvent = ReplicatedStorage:WaitForChild("Net")
local args = {"Taunt.play"}
local lastFireTime = 0

-- Function to create the GUI
local function createGui()
    -- Remove old GUI if it exists
    if player.PlayerGui:FindFirstChild("AutoTauntGui") then
        player.PlayerGui:FindFirstChild("AutoTauntGui"):Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoTauntGui"
    ScreenGui.Parent = player:WaitForChild("PlayerGui")

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 150, 0, 40)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.05, 0)
    ToggleButton.BackgroundColor3 = AutoTauntEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Text = "Auto Taunt: " .. (AutoTauntEnabled and "ON" or "OFF")
    ToggleButton.Parent = ScreenGui

    -- Toggle function
    ToggleButton.MouseButton1Click:Connect(function()
        AutoTauntEnabled = not AutoTauntEnabled
        ToggleButton.Text = "Auto Taunt: " .. (AutoTauntEnabled and "ON" or "OFF")
        ToggleButton.BackgroundColor3 = AutoTauntEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
    end)
end

-- Recreate GUI on spawn
player.CharacterAdded:Connect(function()
    createGui()
end)

-- Create GUI initially
createGui()

-- Loop (fires once per second)
RunService.Heartbeat:Connect(function(deltaTime)
    if AutoTauntEnabled then
        lastFireTime = lastFireTime + deltaTime
        if lastFireTime >= 1 then
            TauntEvent:FireServer(unpack(args))
            lastFireTime = 0
        end
    end
end)
