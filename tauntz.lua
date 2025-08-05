--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Net = ReplicatedStorage:WaitForChild("Net")

--// Feature Toggles
local AutoTauntEnabled = false
local EquipMagicEnabled = false
local ShootPlayerEnabled = false
local lastTauntTime = 0

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

    -- Equip Magic Button
    createButton("Equip Magic", EquipMagicEnabled, function()
        EquipMagicEnabled = not EquipMagicEnabled
        return EquipMagicEnabled
    end)

    -- Shoot Player Button
    createButton("Shoot Player", ShootPlayerEnabled, function()
        ShootPlayerEnabled = not ShootPlayerEnabled
        return ShootPlayerEnabled
    end)
end

--// Recreate GUI on respawn
player.CharacterAdded:Connect(function()
    createGui()
end)

-- Initial GUI
createGui()

--// Loop: Auto Taunt + Equip Magic + Auto Shoot Player
RunService.Heartbeat:Connect(function(deltaTime)
    -- Auto Taunt once per second
    if AutoTauntEnabled then
        lastTauntTime += deltaTime
        if lastTauntTime >= 1 then
            Net:FireServer("Taunt.play")
            lastTauntTime = 0
        end
    end

    -- Keep Magic equipped
    if EquipMagicEnabled then
        Net:FireServer("Cosmetic.equip", "hatSkin", "Magic")
    end

    -- Force shooting hit (kills)
    if ShootPlayerEnabled then
        -- Dummy target data, server may override with real target
        local pos1 = Vector3.new(1, 10, -44)
        local pos2 = Vector3.new(-5, 9, -45)
        Net:FireServer("Shooting.shotPlayer", pos1, pos2, "AnyTarget", CFrame.new())
    end
end)
