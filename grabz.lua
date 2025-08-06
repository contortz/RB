local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load the Conch UI module
local conch = require(
    ReplicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Net")
        :WaitForChild("alicesaidhi+conch_ui")
        :WaitForChild("0.2.5-rc.1")
        :WaitForChild("conch_ui")
        :WaitForChild("src")
        :WaitForChild("lib")
)

-- Create a simple UI button to mount Conch
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ConchLauncher"
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 40)
button.Position = UDim2.new(0, 20, 0, 100)
button.Text = "🔧 Launch Conch"
button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Parent = screenGui

-- Bind click to mount Conch UI
button.MouseButton1Click:Connect(function()
	local success, err = pcall(function()
		conch.mount()
	end)

	if success then
		print("✅ Conch UI launched.")
	else
		warn("❌ Failed to mount Conch UI:", err)
	end
end)
