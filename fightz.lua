--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Toggles
local Toggles = {
    AutoFollow = false,
    AutoPunch = false,
    AutoThrow = false,
    AutoSwing = false,
    AutoPickMoney = false
}

-- GUI
local function createGui()
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 18
    TitleLabel.Text = "Street Fight by Dreamz"
    TitleLabel.Parent = MainFrame

    local yPos = 0.15
    local function createButton(name, toggleKey)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, yPos, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame
        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
        end)
        yPos += 0.15
    end

    createButton("Auto Follow", "AutoFollow")
    createButton("Auto Punch", "AutoPunch")
    createButton("Auto Throw", "AutoThrow")
    createButton("Auto Swing", "AutoSwing")
    createButton("Auto PickMoney", "AutoPickMoney")
end

createGui()
player.CharacterAdded:Connect(function() task.delay(1, createGui) end)

-- Remotes
local PunchRemote = ReplicatedStorage:FindFirstChild("Roles") and ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons:FindFirstChild("Punch")
local ThrowRemote = ReplicatedStorage:FindFirstChild("Utils") and ReplicatedStorage.Utils.Throwables.Default.Remotes:FindFirstChild("Throw")
local SwingRemote = ReplicatedStorage:FindFirstChild("Roles") and ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons:FindFirstChild("Swing")

-- Cooldowns
local punchCooldown, swingCooldown, throwCooldown, pickMoneyCooldown, followInterval = 0.2, 0.2, 0.3, 0.5, 0.1
local lastPunch, lastSwing, lastThrow, lastPick, lastFollow = 0, 0, 0, 0, 0

-- Main Loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character or Workspace:FindFirstChild(player.Name)
        if not myChar then return end

        -- Auto Punch
        if Toggles.AutoPunch and now - lastPunch >= punchCooldown then
            lastPunch = now
            pcall(function() PunchRemote:InvokeServer() end)
        end

        -- Auto Swing
        if Toggles.AutoSwing and now - lastSwing >= swingCooldown then
            lastSwing = now
            pcall(function() SwingRemote:InvokeServer() end)
        end

        -- Auto Throw
        if Toggles.AutoThrow and now - lastThrow >= throwCooldown and myChar:FindFirstChild("HumanoidRootPart") then
            lastThrow = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
                local closestHRP, closestDist = nil, math.huge
                for _, obj in pairs(searchFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
                        local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestHRP = obj.HumanoidRootPart
                        end
                    end
                end
                if closestHRP then
                    local direction = (closestHRP.Position - myHRP.Position).Unit
                    ThrowRemote:InvokeServer(direction)
                end
            end)
        end

        -- Auto Follow
        if Toggles.AutoFollow and now - lastFollow >= followInterval and myChar:FindFirstChild("HumanoidRootPart") then
            lastFollow = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local myHumanoid = myChar:FindFirstChild("Humanoid")
                local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
                local closestHRP, closestDist = nil, math.huge
                for _, obj in pairs(searchFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
                        local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestHRP = obj.HumanoidRootPart
                        end
                    end
                end
                if closestHRP and myHumanoid then
                    myHumanoid.WalkToPoint = closestHRP.Position
                end
            end)
        end

        -- Auto PickMoney
        if Toggles.AutoPickMoney and now - lastPick >= pickMoneyCooldown and myChar:FindFirstChild("HumanoidRootPart") then
            lastPick = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local moneyFolder = Workspace:FindFirstChild("Spawned") and Workspace.Spawned:FindFirstChild("Money")
                if moneyFolder then
                    for _, obj in pairs(moneyFolder:GetChildren()) do
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if part and prompt and prompt.Enabled then
                            myHRP.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                            task.wait(0.05)
                            fireproximityprompt(prompt)
                            break -- pick one at a time
                        end
                    end
                end
            end)
        end
    end)
end)
