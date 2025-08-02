--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tweenService = game:GetService("TweenService")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetLogger"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 400) -- Taller to fit 3 buttons
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "📜 Net Logger + Fuse Test"
title.Parent = mainFrame

-- Scroll Area
local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, -10, 1, -120) -- Leave space for 3 buttons
logBox.Position = UDim2.new(0, 5, 0, 35)
logBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
logBox.ScrollBarThickness = 6
logBox.CanvasSize = UDim2.new(0,0,0,0)
logBox.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = logBox
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Add Log Function
local function addLog(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 25)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = logBox
    logBox.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

-- Utility to get FuseMachine Hitbox
local function getFuseHitbox()
    return workspace:FindFirstChild("FuseMachine")
        and workspace.FuseMachine:FindFirstChild("Hitboxes")
        and workspace.FuseMachine.Hitboxes:FindFirstChild("Hitbox")
end

--------------------------------------------------------------------
-- 🔵 Huge Box Auto Trigger
local bigBoxBtn = Instance.new("TextButton")
bigBoxBtn.Size = UDim2.new(1, -10, 0, 35)
bigBoxBtn.Position = UDim2.new(0, 5, 1, -105)
bigBoxBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
bigBoxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bigBoxBtn.TextSize = 16
bigBoxBtn.Text = "⚡ Huge Box Auto-Trigger"
bigBoxBtn.Parent = mainFrame

bigBoxBtn.MouseButton1Click:Connect(function()
    local fuseHitbox = getFuseHitbox()
    if fuseHitbox and fuseHitbox:IsA("BasePart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        fuseHitbox.Size = Vector3.new(50, 50, 50) -- Large but safe
        fuseHitbox.CFrame = player.Character.HumanoidRootPart.CFrame
        addLog("✅ Enlarged & moved FuseMachine hitbox to player.")

        local rf = game.ReplicatedStorage.Packages.Net:FindFirstChild("RF/FuseMachine/Delivery")
        if rf then
            pcall(function()
                rf:InvokeServer(fuseHitbox)
                addLog("⚡ Invoked Delivery after Huge Box resize.")
            end)
        else
            addLog("❌ Delivery Remote not found.")
        end
    else
        addLog("❌ FuseMachine Hitbox or Player not found.")
    end
end)

--------------------------------------------------------------------
-- 🔴 Player to FuseMachine Teleport
local tpToFuseBtn = Instance.new("TextButton")
tpToFuseBtn.Size = UDim2.new(1, -10, 0, 35)
tpToFuseBtn.Position = UDim2.new(0, 5, 1, -70)
tpToFuseBtn.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
tpToFuseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpToFuseBtn.TextSize = 16
tpToFuseBtn.Text = "🚀 Teleport Player to FuseMachine"
tpToFuseBtn.Parent = mainFrame

tpToFuseBtn.MouseButton1Click:Connect(function()
    local fuseHitbox = getFuseHitbox()
    if fuseHitbox and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = fuseHitbox.CFrame
        addLog("🚀 Teleported player to FuseMachine.")

        local rf = game.ReplicatedStorage.Packages.Net:FindFirstChild("RF/FuseMachine/Delivery")
        if rf then
            pcall(function()
                rf:InvokeServer(fuseHitbox)
                addLog("⚡ Invoked Delivery after teleport.")
            end)
        else
            addLog("❌ Delivery Remote not found.")
        end
    else
        addLog("❌ FuseMachine Hitbox or Player not found.")
    end
end)

--------------------------------------------------------------------
-- 🌀 Tween to FuseMachine
local tweenBtn = Instance.new("TextButton")
tweenBtn.Size = UDim2.new(1, -10, 0, 35)
tweenBtn.Position = UDim2.new(0, 5, 1, -35)
tweenBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
tweenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tweenBtn.TextSize = 16
tweenBtn.Text = "🌀 Tween to FuseMachine"
tweenBtn.Parent = mainFrame

tweenBtn.MouseButton1Click:Connect(function()
    local fuseHitbox = getFuseHitbox()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if fuseHitbox and hrp and humanoid then
        local dist = (fuseHitbox.Position - hrp.Position).Magnitude
        local tweenInfo = TweenInfo.new(dist / humanoid.WalkSpeed, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(hrp, tweenInfo, {
            CFrame = CFrame.new(fuseHitbox.Position)
        })
        tween:Play()
        addLog("🌀 Tweening player to FuseMachine...")

        tween.Completed:Connect(function()
            addLog("✅ Arrived at FuseMachine. Invoking Delivery.")
            local rf = game.ReplicatedStorage.Packages.Net:FindFirstChild("RF/FuseMachine/Delivery")
            if rf then
                pcall(function()
                    rf:InvokeServer(fuseHitbox)
                    addLog("⚡ Invoked Delivery after tween.")
                end)
            else
                addLog("❌ Delivery Remote not found.")
            end
        end)
    else
        addLog("❌ Cannot tween - missing HRP or FuseMachine.")
    end
end)
