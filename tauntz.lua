--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Net = ReplicatedStorage:WaitForChild("Net")

--// Feature Toggles
local AutoTauntEnabled = false
local EquipMagicEnabled = false
local KillAllEnabled = false
local StayUnderKeepersEnabled = false
local StayBehindKeeperEnabled = false
local lastTauntTime = 0

-- Position offsets
local OffsetY = -10 -- Under Keepers
local BehindOffsetY = 0 -- Height when behind
local BehindDistance = 5 -- Default distance behind Keeper

--// GUI Creator
local function createGui()
    -- Remove old GUI if exists
    if player.PlayerGui:FindFirstChild("CustomGui") then
        player.PlayerGui.CustomGui:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player:WaitForChild("PlayerGui")

    local yPos = 0.05
    local function createButton(name, initialState, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 180, 0, 40)
        button.Position = UDim2.new(0.05, 0, yPos, 0)
        button.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": " .. (initialState and "ON" or "OFF")
        button.Parent = ScreenGui

        button.MouseButton1Click:Connect(function()
            local state = callback()
            button.Text = name .. ": " .. (state and "ON" or "OFF")
            button.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)

        yPos += 0.08
    end

    -- Toggle Buttons
    createButton("Auto Taunt", AutoTauntEnabled, function()
        AutoTauntEnabled = not AutoTauntEnabled
        return AutoTauntEnabled
    end)

    createButton("Equip Magic", EquipMagicEnabled, function()
        EquipMagicEnabled = not EquipMagicEnabled
        return EquipMagicEnabled
    end)

    createButton("Kill All Players", KillAllEnabled, function()
        KillAllEnabled = not KillAllEnabled
        return KillAllEnabled
    end)

    createButton("Stay Under Keepers", StayUnderKeepersEnabled, function()
        StayUnderKeepersEnabled = not StayUnderKeepersEnabled
        return StayUnderKeepersEnabled
    end)

    createButton("Stay Behind Keeper", StayBehindKeeperEnabled, function()
        StayBehindKeeperEnabled = not StayBehindKeeperEnabled
        return StayBehindKeeperEnabled
    end)

    -- Add extra spacing for slider
    yPos += 0.05

    -- Slider Label
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0, 180, 0, 20)
    sliderLabel.Position = UDim2.new(0.05, 0, yPos, 0)
    sliderLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.Text = "Behind Distance: " .. BehindDistance
    sliderLabel.Parent = ScreenGui
    yPos += 0.03

    -- Slider Bar
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 180, 0, 10)
    sliderFrame.Position = UDim2.new(0.05, 0, yPos, 0)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderFrame.Parent = ScreenGui

    -- Slider Handle
    local sliderHandle = Instance.new("Frame")
    sliderHandle.Size = UDim2.new(0, 10, 0, 20)
    sliderHandle.Position = UDim2.new(BehindDistance / 20, -5, -0.5, 0)
    sliderHandle.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    sliderHandle.Parent = sliderFrame
    sliderHandle.Active = true
    sliderHandle.Draggable = true

    -- Slider Logic
    sliderHandle.MouseMoved:Connect(function(x)
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local sliderX = math.clamp((x - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            sliderHandle.Position = UDim2.new(sliderX, -5, -0.5, 0)
            BehindDistance = math.floor(sliderX * 20)
            sliderLabel.Text = "Behind Distance: " .. BehindDistance
        end
    end)
end

--// Recreate GUI on respawn
player.CharacterAdded:Connect(function()
    pcall(createGui)
end)

-- Initial GUI
pcall(createGui)

--// Main Loop
RunService.Heartbeat:Connect(function(deltaTime)
    -- Auto Taunt
    if AutoTauntEnabled then
        lastTauntTime += deltaTime
        if lastTauntTime >= 1 then
            Net:FireServer("Taunt.play")
            lastTauntTime = 0
        end
    end

    -- Equip Magic
    if EquipMagicEnabled then
        Net:FireServer("Cosmetic.equip", "hatSkin", "default")
    end

    -- Kill All (skip Keepers / own team)
    if KillAllEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local myTeam = player.Team and player.Team.Name
        local myHRP = player.Character.HumanoidRootPart.Position
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= player
            and target.Team
            and target.Team.Name ~= "Keeper"
            and target.Team.Name ~= myTeam
            and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = target.Character.HumanoidRootPart
                Net:FireServer("Shooting.shotPlayer", myHRP, targetHRP.Position, target.Name, targetHRP.CFrame)
            end
        end
    end

    -- Stay Under Keepers
    if StayUnderKeepersEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local closestKeeper, closestDist = nil, math.huge
        for _, target in pairs(Players:GetPlayers()) do
            if target.Team and target.Team.Name == "Keeper"
            and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestKeeper = target
                end
            end
        end
        if closestKeeper then
            local keeperHRP = closestKeeper.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(keeperHRP.Position.X, keeperHRP.Position.Y + OffsetY, keeperHRP.Position.Z)
        end
    end

    -- Stay Behind Keeper
    if StayBehindKeeperEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local closestKeeper, closestDist = nil, math.huge
        for _, target in pairs(Players:GetPlayers()) do
            if target.Team and target.Team.Name == "Keeper"
            and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestKeeper = target
                end
            end
        end
        if closestKeeper then
            local keeperHRP = closestKeeper.Character.HumanoidRootPart
            local behindPos = keeperHRP.Position + keeperHRP.CFrame.LookVector * -math.abs(BehindDistance)
            hrp.CFrame = CFrame.new(behindPos.X, keeperHRP.Position.Y + BehindOffsetY, behindPos.Z)
        end
    end
end)
