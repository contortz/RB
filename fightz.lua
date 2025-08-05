--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Feature Toggles Table
local Toggles = {
    AutoFollow = false,
    AutoPunch = false,
    AutoThrow = false,
    AutoSwing = false,
    AutoPickMoney = false
}

-- Remotes (safe WaitForChild to avoid nil)
local PunchRemote = ReplicatedStorage:WaitForChild("Roles"):WaitForChild("Tools"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Weapons"):WaitForChild("Punch")
local ThrowRemote = ReplicatedStorage:WaitForChild("Utils"):WaitForChild("Throwables"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Throw")
local SwingRemote = ReplicatedStorage:WaitForChild("Roles"):WaitForChild("Tools"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Weapons"):WaitForChild("Swing")
local PickMoneyRemote = ReplicatedStorage:WaitForChild("Stats"):WaitForChild("Core"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("PickMoney")

-- Function to create GUI (persistent & draggable)
local function createGui()
    -- Remove old GUI if it exists
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 300)
    MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
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
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)

        yPos += 0.15
    end

    -- Buttons
    createButton("Auto Follow", "AutoFollow")
    createButton("Auto Punch", "AutoPunch")
    createButton("Auto Throw", "AutoThrow")
    createButton("Auto Swing", "AutoSwing")
    createButton("Auto PickMoney", "AutoPickMoney")
end

-- Create GUI initially
pcall(createGui)

-- Recreate GUI on respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(createGui)
end)

-- Cooldowns
local punchCooldown = 0.2
local swingCooldown = 0.2
local throwCooldown = 0.3
local pickMoneyCooldown = 0.5
local followInterval = 0.1

-- Last timestamps
local lastPunch, lastSwing, lastThrow, lastPick, lastFollow = 0, 0, 0, 0, 0

-- Main Loop
RunService.Heartbeat:Connect(function()
    local now = tick()
    local myChar = player.Character or Workspace:FindFirstChild(player.Name)

    -- Auto Punch
    if Toggles.AutoPunch and now - lastPunch >= punchCooldown then
        pcall(function()
            PunchRemote:InvokeServer()
            lastPunch = now
        end)
    end

    -- Auto Swing
    if Toggles.AutoSwing and now - lastSwing >= swingCooldown then
        pcall(function()
            SwingRemote:InvokeServer()
            lastSwing = now
        end)
    end

    -- Auto Throw
    if Toggles.AutoThrow and now - lastThrow >= throwCooldown and myChar and myChar:FindFirstChild("HumanoidRootPart") then
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
                lastThrow = now
            end
        end)
    end

    -- Auto Follow
    if Toggles.AutoFollow and now - lastFollow >= followInterval and myChar and myChar:FindFirstChild("HumanoidRootPart") then
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
                local targetPos = closestHRP.Position
                local direction = (targetPos - myHRP.Position).Unit * (closestDist - 5)
                myHumanoid.WalkToPoint = targetPos - direction
                lastFollow = now
            end
        end)
    end

    -- Auto PickMoney
    if Toggles.AutoPickMoney and now - lastPick >= pickMoneyCooldown and myChar and myChar:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            local myHRP = myChar.HumanoidRootPart
            local originalCFrame = myHRP.CFrame

            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("ProximityPrompt") then
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and prompt.Enabled then
                        local moneyPos
                        if obj.PrimaryPart then
                            moneyPos = obj.PrimaryPart.Position
                        elseif obj:FindFirstChild("Part") then
                            moneyPos = obj.Part.Position
                        else
                            moneyPos = obj:GetModelCFrame().Position
                        end
                        
                        myHRP.CFrame = CFrame.new(moneyPos + Vector3.new(0, 3, 0))
                        task.wait(0.05)
                        fireproximityprompt(prompt)
                    end
                end
            end

            myHRP.CFrame = originalCFrame
            lastPick = now
        end)
    end
end)
