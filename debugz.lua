--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

--// Variables
local player = Players.LocalPlayer
local autoSwingEnabled = false
local toolName = "Tung Bat"

--// GUI Setup
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "BatTouchUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 60, 0, 220)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, -10, 0, 40)
button.Position = UDim2.new(0, 5, 0, 10)
button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Text = "Auto Swing: OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true

--// Equip the tool if unequipped
local function forceEquipTool()
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    if backpack and character and not character:FindFirstChild(toolName) then
        local tool = backpack:FindFirstChild(toolName)
        if tool then
            tool.Parent = character
        end
    end
end

--// Simulate a short mobile touch input
local function simulateTouch()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local touchX = screenSize.X / 2
    local touchY = screenSize.Y / 2

    VirtualInputManager:SendTouchEvent(touchX, touchY, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendTouchEvent(touchX, touchY, 0, false, game, 0)
end

--// Main loop
RunService.Heartbeat:Connect(function()
    if autoSwingEnabled then
        forceEquipTool()
        simulateTouch()
        task.wait(0.4)
    end
end)

--// Button click logic
button.MouseButton1Click:Connect(function()
    autoSwingEnabled = not autoSwingEnabled
    button.Text = "Auto Swing: " .. (autoSwingEnabled and "ON" or "OFF")
    button.BackgroundColor3 = autoSwingEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)
