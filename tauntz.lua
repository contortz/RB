--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Net = ReplicatedStorage:WaitForChild("Net")

--// Feature Toggles
local AutoTauntEnabled = false
local EquipMagicEnabled = false
local KillAllEnabled = false
local StayUnderKeepersEnabled = false
local StayBehindKeeperEnabled = false
local lastTauntTime = 0
local OffsetY = -10 -- How far under Keepers you want to stay
local BehindOffsetY = 0 -- Height when behind
local BehindDistance = -5 -- Distance behind Keeper

--// GUI Creator
local function createGui()
    -- Remove old GUI if exists
    if player.PlayerGui:FindFirstChild("CustomGui") then
        player.PlayerGui.CustomGui:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomGui"
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

    -- Auto Taunt Button
    createButton("Auto Taunt", AutoTauntEnabled, function()
        AutoTauntEnabled = not AutoTauntEnabled
        return AutoTauntEnabled
    end)

    -- Equip Magic (Default Hat) Button
    createButton("Equip Magic", EquipMagicEnabled, function()
        EquipMagicEnabled = not EquipMagicEnabled
        return EquipMagicEnabled
    end)

    -- Kill All Players Button
    createButton("Kill All Players", KillAllEnabled, function()
        KillAllEnabled = not KillAllEnabled
        return KillAllEnabled
    end)

    -- Stay Under Keepers Button
    createButton("Stay Under Keepers", StayUnderKeepersEnabled, function()
        StayUnderKeepersEnabled = not StayUnderKeepersEnabled
        return StayUnderKeepersEnabled
    end)

    -- Stay Behind Keeper Button
    createButton("Stay Behind Keeper", StayBehindKeeperEnabled, function()
        StayBehindKeeperEnabled = not StayBehindKeeperEnabled
        return StayBehindKeeperEnabled
    end)
end

--// Recreate GUI on respawn
player.CharacterAdded:Connect(function()
    createGui()
end)

-- Initial GUI
createGui()

--// Main Loop
RunService.Heartbeat:Connect(function(deltaTime)
    -- Auto Taunt once per second
    if AutoTauntEnabled then
        lastTauntTime += deltaTime
        if lastTauntTime >= 1 then
            Net:FireServer("Taunt.play")
            lastTauntTime = 0
        end
    end

    -- Keep Magic equipped (default hat)
    if EquipMagicEnabled then
        Net:FireServer("Cosmetic.equip", "hatSkin", "default")
    end

    -- Kill all players by shooting them at HRP (Skip Keepers / Own Team)
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
                Net:FireServer(
                    "Shooting.shotPlayer",
                    myHRP,                           -- Origin
                    targetHRP.Position,              -- Target position
                    target.Name,                     -- Target name
                    targetHRP.CFrame                 -- Target CFrame
                )
            end
        end
    end

    -- Stay Under Keepers
    if StayUnderKeepersEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local closestKeeper = nil
        local closestDist = math.huge
        
        for _, target in pairs(Players:GetPlayers()) do
            if target.Team and target.Team.Name == "Keeper" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestKeeper = target
                end
            end
        end

        if closestKeeper and closestKeeper.Character and closestKeeper.Character:FindFirstChild("HumanoidRootPart") then
            local keeperHRP = closestKeeper.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(keeperHRP.Position.X, keeperHRP.Position.Y + OffsetY, keeperHRP.Position.Z)
        end
    end

    -- Stay Behind Keeper
    if StayBehindKeeperEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local closestKeeper = nil
        local closestDist = math.huge
        
        for _, target in pairs(Players:GetPlayers()) do
            if target.Team and target.Team.Name == "Keeper" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - target.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestKeeper = target
                end
            end
        end

        if closestKeeper and closestKeeper.Character and closestKeeper.Character:FindFirstChild("HumanoidRootPart") then
            local keeperHRP = closestKeeper.Character.HumanoidRootPart
            hrp.CFrame = keeperHRP.CFrame * CFrame.new(0, BehindOffsetY, BehindDistance)
        end
    end
end)
