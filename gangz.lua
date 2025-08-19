-- Place as a LocalScript (StarterPlayerScripts or client executor)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Ensure we are client-side and game is ready
if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
if not player then return end

-- Wait for PlayerGui + character (use non-blocking pattern if already spawned)
local PlayerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

--// Toggles (exactly 3)
local Toggles = {
    PlayerESP    = false,
    StayBehind   = false,
    ShootClosest = false, -- visual-only: mark & aim
}

--// GUI
local function createGui()
    local old = PlayerGui:FindFirstChild("StreetFightGui")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 210, 0, 200)
    MainFrame.Position = UDim2.new(0.5, -105, 0.5, -100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1,0,0,30)
    Title.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Text = "Dreamz MiniHub"
    Title.Parent = MainFrame

    local function makeToggle(label, key, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.9,0,0,30)
        b.Position = UDim2.new(0.05,0,0,y)
        b.BackgroundColor3 = Color3.fromRGB(50,50,50)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Text = label .. ": OFF"
        b.Parent = MainFrame
        b.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            b.Text = label .. ": " .. (Toggles[key] and "ON" or "OFF")
            b.BackgroundColor3 = Toggles[key] and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
        end)
    end

    makeToggle("Player ESP", "PlayerESP", 40)
    makeToggle("Stay Behind Closest", "StayBehind", 75)
    makeToggle("Shoot Closest Players", "ShootClosest", 110) -- visual-only
end

createGui()

-- Recreate minimal state after respawn (UI persists because ResetOnSpawn=false)
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

--// ===== Target resolution (Workspace twin or Character) =====

local CONTAINER_CANDIDATES = { "Characters", "Players", "Alive", "Entities", "PlayerModels" }

local function validateModel(model)
    if not model or not model:IsA("Model") then return end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then
        return model, hrp, hum
    end
end

local function resolveActor(plr)
    -- 1) Direct child on Workspace with same name
    local twin = Workspace:FindFirstChild(plr.Name)
    if twin then
        local m, hrp, hum = validateModel(twin)
        if m then return m, hrp, hum end
    end

    -- 2) Common containers (Characters, Players, Alive, Entities, PlayerModels)
    for _, bucket in ipairs(CONTAINER_CANDIDATES) do
        local container = Workspace:FindFirstChild(bucket)
        if container then
            local inBucket = container:FindFirstChild(plr.Name)
            if inBucket then
                local m, hrp, hum = validateModel(inBucket)
                if m then return m, hrp, hum end
            end
        end
    end

    -- 3) Fallback: scan Workspace immediate children for a model with this name
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == plr.Name then
            local m, hrp, hum = validateModel(child)
            if m then return m, hrp, hum end
        end
    end

    -- 4) Final fallback: their Character
    local char = plr.Character
    if char then
        return validateModel(char)
    end
    return nil, nil, nil
end

local function getClosestAliveOtherPlayer(myHRP)
    local bestPlr, bestModel, bestHRP, bestHum, bestDist = nil, nil, nil, nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local model, hrp, hum = resolveActor(p)
            if model and hrp and hum then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestPlr, bestModel, bestHRP, bestHum, bestDist = p, model, hrp, hum, d
                end
            end
        end
    end
    return bestPlr, bestModel, bestHRP, bestHum, bestDist
end

--// ===== ESP =====
local function updatePlayerESP()
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local model, hrp, hum = resolveActor(p)
            if model and hrp and hum then
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
                        label.Text = string.format("%s | HP: %d | %dm",
                            p.Name, math.floor(hum.Health), math.floor((myHRP.Position - hrp.Position).Magnitude))
                        label.Parent = billboard
                    else
                        local label = hrp.Player_ESP:FindFirstChildOfClass("TextLabel")
                        if label then
                            label.Text = string.format("%s | HP: %d | %dm",
                                p.Name, math.floor(hum.Health), math.floor((myHRP.Position - hrp.Position).Magnitude))
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
end

--// ===== Behavior constants =====
local BEHIND_DISTANCE = 3.5  -- studs
local VERTICAL_OFFSET = 1.5  -- studs

-- Visual “shoot/aim”
local SHOOT_RADIUS = 30
local SHOOT_RATE = 0.15
local lastShootSweep = 0

local function flashHighlight(model, color)
    if not model then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = model
    hl.FillColor = color or Color3.fromRGB(255, 255, 0)
    hl.FillTransparency = 0.6
    hl.OutlineColor = hl.FillColor
    hl.OutlineTransparency = 0
    hl.Parent = model
    task.delay(0.15, function() if hl then hl:Destroy() end end)
end

--// ===== Main =====
RunService.Heartbeat:Connect(function()
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    -- Player ESP
    if Toggles.PlayerESP then updatePlayerESP() end

    -- Stay Behind Closest (every-frame CFrame)
    if Toggles.StayBehind then
        local tp, model, tHRP, tHum = getClosestAliveOtherPlayer(myHRP)
        if tp and tHRP and tHum then
            local desiredPos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
            myHRP.CFrame = CFrame.new(desiredPos, desiredPos + tHRP.CFrame.LookVector)
        end
    end

    -- Shoot Closest Players (visual-only)
    local now = tick()
    if Toggles.ShootClosest and (now - lastShootSweep) >= SHOOT_RATE then
        local near = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local model, tHRP, tHum = resolveActor(p)
                if model and tHRP and tHum then
                    local d = (myHRP.Position - tHRP.Position).Magnitude
                    if d <= SHOOT_RADIUS then
                        table.insert(near, {model = model, hrp = tHRP, hum = tHum, dist = d})
                    end
                end
            end
        end
        table.sort(near, function(a,b) return a.dist < b.dist end)
        for _, t in ipairs(near) do
            myHRP.CFrame = CFrame.new(myHRP.Position, t.hrp.Position) -- aim at target
            flashHighlight(t.model, Color3.fromRGB(255, 230, 0))
        end
        lastShootSweep = now
    end
end)
