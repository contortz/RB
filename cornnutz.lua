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
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "⭐ BrainRotz by Dreamz ⭐"
titleLabel.Parent = mainFrame

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
-- Tween to Base
local tweenBaseBtn = Instance.new("TextButton")
tweenBaseBtn.Size = UDim2.new(1, -20, 0, 30)
tweenBaseBtn.Position = UDim2.new(0, 10, 0, 130)
tweenBaseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tweenBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tweenBaseBtn.Text = "Tween to Base"
tweenBaseBtn.Parent = mainFrame

tweenBaseBtn.MouseButton1Click:Connect(function()
    local base = findBase()
    if base and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local dist = (base.Position - hrp.Position).Magnitude
        local tweenInfo = TweenInfo.new(dist / 16, Enum.EasingStyle.Linear)
        game:GetService("TweenService"):Create(hrp, tweenInfo, {CFrame = base.CFrame}):Play()
    end
end)

--------------------------------------------------------------------
-- WalkSpeed
local wsBtn = Instance.new("TextButton")
wsBtn.Size = UDim2.new(1, -20, 0, 30)
wsBtn.Position = UDim2.new(0, 10, 0, 170)
wsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
wsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
wsBtn.Text = "WalkSpeed (50)"
wsBtn.Parent = mainFrame

wsBtn.MouseButton1Click:Connect(function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 50 end
end)

--------------------------------------------------------------------
-- Noclip
local noclipEnabled = false
local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(1, -20, 0, 30)
noclipBtn.Position = UDim2.new(0, 10, 0, 210)
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
        for _, part in ipairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
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
infJumpBtn.Position = UDim2.new(0, 10, 0, 250)
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

--------------------------------------------------------------------
-- God Mode
local godEnabled = false
local godBtn = Instance.new("TextButton")
godBtn.Size = UDim2.new(1, -20, 0, 30)
godBtn.Position = UDim2.new(0, 10, 0, 290)
godBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
godBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
godBtn.Text = "God Mode (OFF)"
godBtn.Parent = mainFrame

godBtn.MouseButton1Click:Connect(function()
    godEnabled = not godEnabled
    godBtn.Text = "God Mode (" .. (godEnabled and "ON" or "OFF") .. ")"
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if godEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        hum.Health = hum.MaxHealth
    end
end)

--------------------------------------------------------------------
-- ESP
local espEnabled = false
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -20, 0, 30)
espBtn.Position = UDim2.new(0, 10, 0, 330)
espBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espBtn.Text = "ESP (OFF)"
espBtn.Parent = mainFrame

local function createESP(plr)
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = plr.Character.HumanoidRootPart
    box.Size = Vector3.new(4,6,1)
    box.Color3 = Color3.fromRGB(255,0,0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.Parent = espFolder
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = "ESP (" .. (espEnabled and "ON" or "OFF") .. ")"
    espFolder:ClearAllChildren()
    if espEnabled then
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player then createESP(plr) end
        end
    end
end)

--------------------------------------------------------------------
-- Minimize Icon
local minimizeIcon = Instance.new("TextButton")
minimizeIcon.Size = UDim2.new(0, 30, 0, 30)
minimizeIcon.Position = UDim2.new(1, -40, 0, 10)
minimizeIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minimizeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeIcon.Text = "-"
minimizeIcon.Parent = screenGui

local dragging = false
local dragInput, dragStart, startPos
minimizeIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = minimizeIcon.Position
    end
end)
minimizeIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        minimizeIcon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                          startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
minimizeIcon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

minimizeIcon.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    minimizeIcon.Text = mainFrame.Visible and "-" or "+"
end)
