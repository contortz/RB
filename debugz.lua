--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

--// UI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "BrainRotzUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 280, 0, 680)
frame.Position = UDim2.new(0, 20, 0.5, -340)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Text = "BrainRotz by Dreamz"

-- helper to make buttons (returns button so we can recolor)
local function makeButton(y, label, onClick)
    local b = Instance.new("TextButton", frame)
    b.Position = UDim2.new(0, 8, 0, y)
    b.Size = UDim2.new(1, -16, 0, 28)
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextScaled = true
    b.Text = label
    b.AutoButtonColor = true
    b.MouseButton1Click:Connect(function() onClick(b) end)
    return b
end

-- Fast require for Net (only once)
local Net
local function getNet()
    if not Net then
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        if pkg then
            local ok, mod = pcall(require, pkg:WaitForChild("Net"))
            if ok then Net = mod end
        end
    end
    return Net
end

-- Fallback direct RemoteEvent fetch for "RE/UseItem"
local function getUseItemRemote()
    local pkg = ReplicatedStorage:FindFirstChild("Packages")
    if not pkg then return nil end
    local netFolder = pkg:FindFirstChild("Net")
    if not netFolder then return nil end
    -- Some setups store this as a direct child RemoteEvent named "RE/UseItem"
    local direct = netFolder:FindFirstChild("RE/UseItem")
    if direct and direct.FireServer then return direct end
    -- Or exposed via Net:RemoteEvent(...)
    local net = getNet()
    if net and net.RemoteEvent then
        local ok, re = pcall(function() return net:RemoteEvent("RE/UseItem") end)
        if ok and re and re.FireServer then return re end
    end
    return nil
end

--// State toggles
local loopEquipQC, loopActQC, loopTeleport = false, false, false
local loopEquipBee, loopActBee = false, false
local loopEquipBat, loopActBat = false, false
local loopEquipCoil, loopActCoil = false, false

-- Laser Cape
local loopEquipCape, loopFireCape = false, false        -- (fire uses camera point)
local loopFireCapeClosest = false                       -- fire at closest player's position every 3.5s

-- small helper
local function equipIfInBackpack(toolName)
    local char = player.Character
    local bag = player:FindFirstChild("Backpack")
    if not (char and bag) then return end
    if char:FindFirstChild(toolName) then return end
    local t = bag:FindFirstChild(toolName)
    if t then t.Parent = char end
end

-- find Laser Cape Handle in character (tries common names)
local function getCapeHandle()
    local char = player.Character
    if not char then return nil end
    -- 1) accessories with "cape" in name or the specific toon shaded name
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("Accessory") then
            local n = inst.Name:lower()
            if n:find("cape") or inst.Name == "Accessory (Toon_Shaded_Black_on_White)" then
                local h = inst:FindFirstChild("Handle")
                if h then return h end
            end
        end
    end
    -- 2) if Laser Cape is a tool inside character, try any Handle under it
    local tool = char:FindFirstChild("Laser Cape")
    if tool then
        local h = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
        if h then return h end
    end
    return nil
end

-- point straight ahead of camera (raycast if possible)
local function getAimPoint(maxDist)
    maxDist = maxDist or 500
    local cam = Workspace.CurrentCamera
    if not cam then return Vector3.new() end
    local origin = cam.CFrame.Position
    local dir = cam.CFrame.LookVector * maxDist
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {player.Character}
    local result = Workspace:Raycast(origin, dir, params)
    return result and result.Position or (origin + dir)
end

-- closest other player's HRP position
local function getClosestPlayerPos(maxRange)
    maxRange = maxRange or math.huge
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local closestPos, closestDist = nil, maxRange
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local c = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestPos = hrp.Position
                end
            end
        end
    end
    return closestPos
end

-- timers to avoid spamming Activate every frame (helps movement)
local lastBat, lastQC, lastBee, lastCoil, lastCape = 0, 0, 0, 0, 0
local lastCapeClosest = 0

--// Main loop
RunService.Heartbeat:Connect(function()
    local char = player.Character

    -- Quantum Cloner
    if loopEquipQC then equipIfInBackpack("Quantum Cloner") end
    if loopActQC and char then
        if tick() - lastQC > 0.25 then
            lastQC = tick()
            local qc = char:FindFirstChild("Quantum Cloner")
            if qc then qc:Activate() end
        end
    end
    if loopTeleport then
        local net = getNet()
        if net then net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer() end
    end

    -- Bee Launcher
    if loopEquipBee then equipIfInBackpack("Bee Launcher") end
    if loopActBee and char then
        if tick() - lastBee > 0.25 then
            lastBee = tick()
            local bee = char:FindFirstChild("Bee Launcher")
            if bee then bee:Activate() end
        end
    end

    -- Tung Bat
    if loopEquipBat then equipIfInBackpack("Tung Bat") end
    if loopActBat and char then
        if tick() - lastBat > 1.2 then
            lastBat = tick()
            local bat = char:FindFirstChild("Tung Bat")
            if bat then bat:Activate() end
        end
    end

    -- Speed Coil
    if loopEquipCoil then equipIfInBackpack("Speed Coil") end
    if loopActCoil and char then
        if tick() - lastCoil > 0.5 then
            lastCoil = tick()
            local coil = char:FindFirstChild("Speed Coil")
            if coil then coil:Activate() end -- may be no-op in some games
        end
    end

    -- Laser Cape (equip)
    if loopEquipCape then equipIfInBackpack("Laser Cape") end

    -- Laser Cape (fire forward every 3.5s)
    if loopFireCape then
        if tick() - lastCape > 3.5 then
            lastCape = tick()
            local handle = getCapeHandle()
            local useItem = getUseItemRemote()
            if handle and useItem then
                local target = getAimPoint(600)
                useItem:FireServer(target, handle) -- (Vector3, Handle)
            end
        end
    end

-- Laser Cape (fire at closest player every 3.5s) — NEVER self
if loopFireCapeClosest and (tick() - lastCapeClosest > 3.5) then
    local handle = getCapeHandle()
    local useItem = getUseItemRemote()
    local targetPlr, targetHRP = getClosestTarget(1000, 5)
    if not useItem then
        warn("RE/UseItem remote not found")
    end
    if handle and useItem and targetPlr and targetHRP and targetPlr ~= player then
        lastCapeClosest = tick()
        useItem:FireServer(targetHRP.Position, handle) -- (Vector3, Handle)
    end
end


--// Buttons
local y = 40
makeButton(y, "Quantum Cloner", function() end).BackgroundColor3 = Color3.fromRGB(40,40,40)
y = y + 34

local qcEquipBtn = makeButton(y, "🔁 Loop Equip Quantum Cloner", function(btn)
    loopEquipQC = not loopEquipQC
    btn.BackgroundColor3 = loopEquipQC and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local qcActBtn = makeButton(y, "🔁 Loop Activate Quantum Cloner", function(btn)
    loopActQC = not loopActQC
    btn.BackgroundColor3 = loopActQC and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local qcTpBtn = makeButton(y, "🔁 Loop Teleport to Clone", function(btn)
    loopTeleport = not loopTeleport
    btn.BackgroundColor3 = loopTeleport and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 40

makeButton(y, "Bee Launcher", function() end).BackgroundColor3 = Color3.fromRGB(40,40,40)
y = y + 34

local beeEquipBtn = makeButton(y, "🔁 Loop Equip Bee Launcher", function(btn)
    loopEquipBee = not loopEquipBee
    btn.BackgroundColor3 = loopEquipBee and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local beeActBtn = makeButton(y, "🔁 Loop Activate Bee Launcher", function(btn)
    loopActBee = not loopActBee
    btn.BackgroundColor3 = loopActBee and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 40

makeButton(y, "Tung Bat", function() end).BackgroundColor3 = Color3.fromRGB(40,40,40)
y = y + 34

local batEquipBtn = makeButton(y, "🔁 Loop Equip Tung Bat", function(btn)
    loopEquipBat = not loopEquipBat
    btn.BackgroundColor3 = loopEquipBat and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local batActBtn = makeButton(y, "🔁 Loop Activate Tung Bat", function(btn)
    loopActBat = not loopActBat
    btn.BackgroundColor3 = loopActBat and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 40

makeButton(y, "Speed Coil", function() end).BackgroundColor3 = Color3.fromRGB(40,40,40)
y = y + 34

local coilEquipOnceBtn = makeButton(y, "Equip Speed Coil (once)", function()
    local char = player.Character
    local bag = player:FindFirstChild("Backpack")
    if bag and char then
        local coil = bag:FindFirstChild("Speed Coil")
        if coil then coil.Parent = char else warn("[Speed Coil] Not found in Backpack.") end
    end
end); y = y + 30

local coilEquipBtn = makeButton(y, "🔁 Loop Equip Speed Coil", function(btn)
    loopEquipCoil = not loopEquipCoil
    btn.BackgroundColor3 = loopEquipCoil and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local coilActBtn = makeButton(y, "🔁 Loop Activate Speed Coil", function(btn)
    loopActCoil = not loopActCoil
    btn.BackgroundColor3 = loopActCoil and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 40

-- Laser Cape controls
makeButton(y, "Laser Cape", function() end).BackgroundColor3 = Color3.fromRGB(40,40,40)
y = y + 34

makeButton(y, "Equip Laser Cape (once)", function()
    equipIfInBackpack("Laser Cape")
end); y = y + 30

local capeEquipBtn = makeButton(y, "🔁 Loop Equip Laser Cape", function(btn)
    loopEquipCape = not loopEquipCape
    btn.BackgroundColor3 = loopEquipCape and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local capeFireBtn = makeButton(y, "🔁 Loop Fire Laser (Ahead, 3.5s)", function(btn)
    loopFireCape = not loopFireCape
    btn.BackgroundColor3 = loopFireCape and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local capeFireClosestBtn = makeButton(y, "🔁 Loop Fire Laser (Closest, 3.5s)", function(btn)
    loopFireCapeClosest = not loopFireCapeClosest
    btn.BackgroundColor3 = loopFireCapeClosest and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30
