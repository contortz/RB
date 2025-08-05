--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Feature Toggles
local AutoFollowEnabled = false
local AutoPunchEnabled = false
local AutoThrowEnabled = false
local AutoSwingEnabled = false
local AutoPickMoneyEnabled = false

-- Remotes
local PunchRemote = ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons.Punch
local ThrowRemote = ReplicatedStorage.Utils.Throwables.Default.Remotes.Throw
local SwingRemote = ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons.Swing
local PickMoneyRemote = ReplicatedStorage.Stats.Core.Default.Remotes.PickMoney

-- Function to create GUI (persistent & draggable)
local function createGui()
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("StreetFightGui") then
        playerGui.StreetFightGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

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
    local function createButton(name, stateVarName)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, yPos, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame

        button.MouseButton1Click:Connect(function()
            _G[stateVarName] = not _G[stateVarName]
            button.Text = name .. ": " .. (_G[stateVarName] and "ON" or "OFF")
            button.BackgroundColor3 = _G[stateVarName] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)

        yPos += 0.15
    end

    -- Buttons
    _G.AutoFollowEnabled = AutoFollowEnabled
    _G.AutoPunchEnabled = AutoPunchEnabled
    _G.AutoThrowEnabled = AutoThrowEnabled
    _G.AutoSwingEnabled = AutoSwingEnabled
    _G.AutoPickMoneyEnabled = AutoPickMoneyEnabled

    createButton("Auto Follow", "AutoFollowEnabled")
    createButton("Auto Punch", "AutoPunchEnabled")
    createButton("Auto Throw", "AutoThrowEnabled")
    createButton("Auto Swing", "AutoSwingEnabled")
    createButton("Auto PickMoney", "AutoPickMoneyEnabled")
end

-- Create GUI initially
createGui()

-- Recreate GUI on respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    createGui()
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Cooldown values (in seconds)
    local punchCooldown = 0.2
    local swingCooldown = 0.2
    local throwCooldown = 0.3
    local pickMoneyCooldown = 0.5
    local followInterval = 0.1

    -- Last-used timestamps
    _G._lastPunch = _G._lastPunch or 0
    _G._lastSwing = _G._lastSwing or 0
    _G._lastThrow = _G._lastThrow or 0
    _G._lastPick = _G._lastPick or 0
    _G._lastFollow = _G._lastFollow or 0

    -- Auto Punch
    if _G.AutoPunchEnabled and now - _G._lastPunch >= punchCooldown then
        PunchRemote:InvokeServer()
        _G._lastPunch = now
    end

    -- Auto Swing
    if _G.AutoSwingEnabled and now - _G._lastSwing >= swingCooldown then
        SwingRemote:InvokeServer()
        _G._lastSwing = now
    end

-- Auto Throw (aimed at closest)
if _G.AutoThrowEnabled and now - _G._lastThrow >= throwCooldown then
    local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
    local myChar = searchFolder:FindFirstChild(player.Name)

    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local myHRP = myChar.HumanoidRootPart
        local closestHRP, closestDist = nil, math.huge

        for _, obj in pairs(searchFolder:GetChildren()) do
            if obj:IsA("Model")
            and obj.Name ~= player.Name
            and obj:FindFirstChild("HumanoidRootPart") then
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
            _G._lastThrow = now
        end
    end
end


-- Auto Follow (smooth with offset using CFrame logic)
if _G.AutoFollowEnabled and now - _G._lastFollow >= followInterval then
    local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
    local myChar = searchFolder:FindFirstChild(player.Name)

    if myChar and myChar:FindFirstChild("Humanoid") and myChar:FindFirstChild("HumanoidRootPart") then
        local myHRP = myChar.HumanoidRootPart
        local myHumanoid = myChar.Humanoid

        local closestHRP, closestDist = nil, math.huge

        -- Find closest target
        for _, obj in pairs(searchFolder:GetChildren()) do
            if obj:IsA("Model")
            and obj.Name ~= player.Name
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart") then
                local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestHRP = obj.HumanoidRootPart
                end
            end
        end

        -- Move toward target with spacing
        if closestHRP then
            local targetPos = closestHRP.Position
            local direction = (targetPos - myHRP.Position).Unit * (closestDist - 5)
            myHumanoid.WalkToPoint = targetPos - direction
        end

        _G._lastFollow = now
    end
end



    -- Auto PickMoney
    if _G.AutoPickMoneyEnabled and now - _G._lastPick >= pickMoneyCooldown then
        local spawnedFolder = Workspace:FindFirstChild("Spawned")
        if spawnedFolder then
            for _, obj in pairs(spawnedFolder:GetChildren()) do
                if obj.Name:lower():find("money") then
                    PickMoneyRemote:InvokeServer(obj.Name)
                end
            end
        end
        _G._lastPick = now
    end
end)
