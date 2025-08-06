local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ Correct path to the conch_ui module
local conch = require(
    ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("Conch")
        :WaitForChild("roblox_packages")
        :WaitForChild(".pesde")
        :WaitForChild("alicesaidhi+conch_ui")
        :WaitForChild("0.2.5-rc.1")
        :WaitForChild("conch")
)

-- Create a simple UI to launch Conch
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "LaunchConch"

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 40)
button.Position = UDim2.new(0, 20, 0, 120)
button.Text = "Launch Conch"
button.TextColor3 = Color3.new(1, 1, 1)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
button.Parent = screenGui

button.MouseButton1Click:Connect(function()
    local success, result = pcall(function()
        return conch.mount()
    end)

    if success then
        print("✅ Conch UI launched")
    else
        warn("❌ Failed to mount Conch UI:", result)
    end
end)
