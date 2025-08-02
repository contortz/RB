--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NetLogger"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 400) -- Taller for extra buttons
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
title.Text = "📜 Net Logger"
title.Parent = mainFrame

-- Scroll Area
local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, -10, 1, -120) -- Leave space for buttons
logBox.Position = UDim2.new(0, 5, 0, 35)
logBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
logBox.ScrollBarThickness = 6
logBox.CanvasSize = UDim2.new(0,0,0,0)
logBox.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = logBox
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Add Log Function
local function addLog(method, remote, args)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 25)
    container.BackgroundTransparency = 1
    container.Parent = logBox

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.format("[%s] %s", method, remote.Name)
    label.Parent = container

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.3, 0, 1, 0)
    copyBtn.Position = UDim2.new(0.7, 0, 0, 0)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 14
    copyBtn.Text = "Copy Args"
    copyBtn.Parent = container

    copyBtn.MouseButton1Click:Connect(function()
        setclipboard(table.concat(args, ", "))
    end)

    logBox.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

-- Hook FireServer
local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
    local args = {...}
    pcall(addLog, "FireServer", self, args)
    return oldFireServer(self, ...)
end)

-- Hook InvokeServer
local oldInvokeServer
oldInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(self, ...)
    local args = {...}
    pcall(addLog, "InvokeServer", self, args)
    return oldInvokeServer(self, ...)
end)

--------------------------------------------------------------------
-- 🔵 Huge Hitbox Delivery
local hugeHitboxBtn = Instance.new("TextButton")
hugeHitboxBtn.Size = UDim2.new(1, -10, 0, 35)
hugeHitboxBtn.Position = UDim2.new(0, 5, 1, -80)
hugeHitboxBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
hugeHitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hugeHitboxBtn.TextSize = 16
hugeHitboxBtn.Text = "Huge Hitbox Delivery"
hugeHitboxBtn.Parent = mainFrame

hugeHitboxBtn.MouseButton1Click:Connect(function()
    local fuseHitbox = workspace:FindFirstChild("FuseMachine")
        and workspace.FuseMachine:FindFirstChild("Hitboxes")
        and workspace.FuseMachine.Hitboxes:FindFirstChild("Hitbox")

    if fuseHitbox and fuseHitbox:IsA("BasePart") and player.Character then
        fuseHitbox.Size = Vector3.new(9999, 9999, 9999)
        fuseHitbox.CFrame = player.Character:FindFirstChild("HumanoidRootPart").CFrame
        addLog("Modify", {Name="FuseMachine"}, {"Hitbox enlarged + moved"})
    else
        addLog("Error", {Name="FuseMachine"}, {"Hitbox not found"})
    end
end)

--------------------------------------------------------------------
-- 🔴 Direct Delivery Invoke
local directInvokeBtn = Instance.new("TextButton")
directInvokeBtn.Size = UDim2.new(1, -10, 0, 35)
directInvokeBtn.Position = UDim2.new(0, 5, 1, -40)
directInvokeBtn.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
directInvokeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
directInvokeBtn.TextSize = 16
directInvokeBtn.Text = "Direct Delivery Invoke"
directInvokeBtn.Parent = mainFrame

directInvokeBtn.MouseButton1Click:Connect(function()
    local rf = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("Net"):FindFirstChild("RF/FuseMachine/Delivery")

    if rf then
        local hitbox = workspace:FindFirstChild("FuseMachine")
            and workspace.FuseMachine:FindFirstChild("Hitboxes")
            and workspace.FuseMachine.Hitboxes:FindFirstChild("Hitbox")

        if hitbox then
            local success, err = pcall(function()
                rf:InvokeServer(hitbox)
            end)
            if success then
                addLog("InvokeServer", rf, {"Delivery invoked"})
            else
                addLog("InvokeServer", rf, {"Error: "..tostring(err)})
            end
        else
            addLog("Error", {Name="FuseMachine"}, {"Hitbox missing"})
        end
    else
        addLog("Error", {Name="RF/FuseMachine/Delivery"}, {"Remote not found"})
    end
end)
