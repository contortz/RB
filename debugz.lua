--// Setup
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Function to teleport player to clone (once when clicked)
local function teleportToCloneOnce()
    local net = getNet()  -- Ensure you have the function to get the Net module
    if net then
        -- Fire the teleportation event once
        net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
    else
        warn("Net module or RemoteEvent not found.")
    end
end

-- Create the TP to Clone button on the right side with specific style
local function createTPButton()
    local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screenGui.Name = "TPToCloneButton"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    -- Button Setup
    local button = Instance.new("TextButton", screenGui)
    button.Size = UDim2.new(0, 150, 0, 40)  -- Set the size
    button.Position = UDim2.new(1, -160, 0, 20)  -- Position the button to the right side
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Black background with opacity
    button.BackgroundTransparency = 0.5  -- 50% opacity
    button.TextColor3 = Color3.fromRGB(0, 0, 255)  -- Blue text color
    button.Text = "TP to Clone"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextStrokeTransparency = 0.8  -- Black stroke for the letters
    button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)  -- Black stroke color

    -- Action when clicked
    button.MouseButton1Click:Connect(function()
        teleportToCloneOnce()  -- Trigger teleportation once
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)  -- Change color to indicate click
    end)
end

-- Create the button
createTPButton()
