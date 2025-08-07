--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- GUI Setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "CommandMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 200)
frame.Position = UDim2.new(0, 20, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "⚙️ Server Commands"
title.Font = Enum.Font.GothamBold
title.TextSize = 12

-- Helper function
local function createButton(text, yOffset, command)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yOffset)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.MouseButton1Click:Connect(function()
        ReplicatedStorage.conch_networking.invoke_server_command:FireServer(command)
        print("Fired command:", command)
    end)
end

-- Buttons
createButton("Spawn Brainrot", 40, 'spawnbrainrot "La Grande Combinasion" Rainbow 20')
createButton("Execute Candy Event", 80, "executeevent Candy 5000000")
createButton("Add Luck", 120, "addluck 9999999")
