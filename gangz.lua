--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local Net = ReplicatedStorage:FindFirstChild("Net") -- used for Shooting.shotPlayer route

--// Toggles (exactly 3)
local Toggles = {
    PlayerESP   = false,
    StayBehind  = false,
    ShootNearby = false,
}

--// GUI
local function createGui()
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 200)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 16
    TitleLabel.Text = "Dreamz MiniHub"
    TitleLabel.Parent = MainFrame

    local function createButton(name, toggleKey, yPos)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, 0, yPos)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame

        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)
    end

    createButton("Player ESP", "PlayerESP", 40)
    createButton("Stay Behind Closest", "StayBehind", 75)
    createButton("Shoot Nearby", "ShootNearby", 110)
end

createGui()

--// Helpers
local function isPvpOn(p)
    -- require explicit true (adjust if your game treats nil as ON)
    local v = p:GetAttribute("PVP_ENABLED")
    if v ~= nil then return v == true end
    local c = p.Character
    if not c then return false end
    local cv = c:GetAttribute("PVP_ENABLED")
    if cv ~= nil then return cv == true end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        local hv = h:GetAttribute("PVP_ENABLED")
        if hv ~= nil then return hv == true end
    end
    return false
end

local function getClosestAliveOtherPlayer(myHRP)
    local closest, closestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and isPvpOn(p) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < closestDist then
                    closest = p
                    closestDist = d
                end
            end
        end
    end
    return closest, closestDist
end

-- Shooting wrapper (edit if your server expects different args)
local function fireShoot(myHRP, targetPlayer, tHRP)
    if Net then
        -- matches your earlier usage:
        Net:FireServer("Shooting.shotPlayer", myHRP.Position, tHRP.Position, targetPlayer.Name, tHRP.CFrame)
    else
        -- fallback: try to find a generic "shoot" RemoteEvent once (optional)
        -- (add your own route here if needed)
    end
end

--// ESP
local function updatePlayerESP()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = otherPlayer.Character.HumanoidRootPart
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            local health = humanoid and math.floor(humanoid.Health) or "?"
            local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)

            if Toggles.PlayerESP then
                if not hrp:FindFirstChild("Player_ESP") then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "Player_ESP"
                    billboard.Adornee = hrp
                    billboard.Size = UDim2.new(0, 150, 0, 40)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = hrp

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 0, 0)
                    label.TextStrokeTransparency = 0
                    label.TextScaled = true
                    label.Text = string.format("%s | HP: %s | %dm", otherPlayer.Name, health, dist)
                    label.Parent = billboard
                else
                    local label = hrp.Player_ESP:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm", otherPlayer.Name, health, dist)
                    end
                end
            else
                if hrp:FindFirstChild("Player_ESP") then
                    hrp.Player_ESP:Destroy()
                end
            end
        end
    end
end

--// Behavior constants
local BEHIND_DISTANCE = 3.5   -- studs behind target
local VERTICAL_OFFSET = 1.5   -- slight lift

local SHOOT_RADIUS = 30       -- studs; players within this range will be shot
local SHOOT_RATE = 0.15       -- seconds between "shoot sweeps"
local PER_TARGET_COOLDOWN = 0.4 -- per target, avoid overspam

local lastShootSweep = 0
local targetLastShotAt = {}   -- [player.UserId] = timestamp

--// Main loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then return end

        -- Player ESP
        if Toggles.PlayerESP then updatePlayerESP() end

        -- Stay Behind Closest (every-frame CFrame)
        if Toggles.StayBehind then
            local targetPlayer = nil
            local closestDist = nil
            do
                local p, d = getClosestAliveOtherPlayer(myHRP)
                targetPlayer, closestDist = p, d
            end

            if targetPlayer and targetPlayer.Character then
                local tHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tHum and tHRP and tHum.Health > 0 then
                    local desiredPos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
                    myHRP.CFrame = CFrame.new(desiredPos, desiredPos + tHRP.CFrame.LookVector)
                end
            end
        end

        -- Shoot Nearby (fires at all PvP-enabled players within radius, with a tiny per-target cooldown)
        if Toggles.ShootNearby and (now - lastShootSweep) >= SHOOT_RATE then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and isPvpOn(p) then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and tHRP and hum.Health > 0 then
                        local dist = (myHRP.Position - tHRP.Position).Magnitude
                        if dist <= SHOOT_RADIUS then
                            local last = targetLastShotAt[p.UserId] or 0
                            if (now - last) >= PER_TARGET_COOLDOWN then
                                fireShoot(myHRP, p, tHRP)
                                targetLastShotAt[p.UserId] = now
                            end
                        end
                    end
                end
            end
            lastShootSweep = now
        end
    end)
end)
