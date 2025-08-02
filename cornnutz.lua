-- Create ScreenGui
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StellarTestUI"
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Visible = true
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 0, 30) -- leave space for minimize
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "⭐ BrainRotz by Dreamz ⭐"
titleLabel.Parent = mainFrame

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Text = "-"
minimizeBtn.Parent = mainFrame

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

--------------------------------------------------------------------
-- Instant Proximity
local instantEnabled = false
local proxTog = Instance.new("TextButton")
proxTog.Size = UDim2.new(1, -20, 0, 30)
proxTog.Position = UDim2.new(0, 10, 0, 50)
proxTog.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
proxTog.TextColor3 = Color3.fromRGB(255, 255, 255)
proxTog.Text = "Instant Proximity (OFF)"
proxTog.Parent = mainFrame

proxTog.MouseButton1Click:Connect(function()
    instantEnabled = not instantEnabled
    proxTog.Text = "Instant Proximity (" .. (instantEnabled and "ON" or "OFF") .. ")"
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v.HoldDuration = instantEnabled and 0 or 1
        end
    end
end)

--------------------------------------------------------------------
-- Teleport to Base
local function findBase()
    for _, plot in pairs(workspace:WaitForChild("Plots"):GetChildren()) do
        local yourBase = plot:FindFirstChild("YourBase", true)
        if yourBase and yourBase.Enabled then
            return plot:FindFirstChild("DeliveryHitbox", true)
        end
    end
    return nil
end

local tpBaseBtn = Instance.new("TextButton")
tpBaseBtn.Size = UDim2.new(1, -20, 0, 30)
tpBaseBtn.Position = UDim2.new(0, 10, 0, 90)
tpBaseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tpBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBaseBtn.Text = "Teleport to Base"
tpBaseBtn.Parent = mainFrame

tpBaseBtn.MouseButton1Click:Connect(function()
    local base = findBase()
    if base and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = base.CFrame
    end
end)

--------------------------------------------------------------------
-- Noclip (Brute Force Loop)
local noclipEnabled = false
local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(1, -20, 0, 30)
noclipBtn.Position = UDim2.new(0, 10, 0, 130)
noclipBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipBtn.Text = "Noclip (OFF)"
noclipBtn.Parent = mainFrame

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = "Noclip (" .. (noclipEnabled and "ON" or "OFF") .. ")"
end)

game:GetService("RunService").Stepped:Connect(function()
    if noclipEnabled and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

--------------------------------------------------------------------
-- Infinite Jump
local infJumpEnabled = false
local infJumpBtn = Instance.new("TextButton")
infJumpBtn.Size = UDim2.new(1, -20, 0, 30)
infJumpBtn.Position = UDim2.new(0, 10, 0, 170)
infJumpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
infJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
infJumpBtn.Text = "Infinite Jump (OFF)"
infJumpBtn.Parent = mainFrame

infJumpBtn.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    infJumpBtn.Text = "Infinite Jump (" .. (infJumpEnabled and "ON" or "OFF") .. ")"
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)
