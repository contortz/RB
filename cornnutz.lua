-- Create ScreenGui
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestUI"
screenGui.Parent = playerGui

-- Create Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Parent = screenGui

-- Create Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "⭐ Premium Test UI ⭐"
titleLabel.Parent = mainFrame

-- Create Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "Toggle Premium (OFF)"
toggleButton.Parent = mainFrame

-- Toggle Logic
local premiumEnabled = false
toggleButton.MouseButton1Click:Connect(function()
    premiumEnabled = not premiumEnabled
    toggleButton.Text = "Toggle Premium (" .. (premiumEnabled and "ON" or "OFF") .. ")"
    print("Premium is now", premiumEnabled and "ENABLED" or "DISABLED")
end)
