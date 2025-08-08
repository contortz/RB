--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--// UI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "BrainRotzUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 280, 0, 560)
frame.Position = UDim2.new(0, 20, 0.5, -280)
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

--// State toggles
local loopEquipQC, loopActQC, loopTeleport = false, false, false
local loopEquipBee, loopActBee = false, false
local loopEquipBat, loopActBat = false, false
local loopEquipCoil, loopActCoil = false, false

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

-- Note: if constant activation freezes movement, we’ll tick-gate it below
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
        if coil then
            coil.Parent = char
            print("[Speed Coil] Equipped once.")
        else
            warn("[Speed Coil] Not found in Backpack.")
        end
    end
end); y = y + 30

local coilEquipBtn = makeButton(y, "🔁 Loop Equip Speed Coil", function(btn)
    loopEquipCoil = not loopEquipCoil
    btn.BackgroundColor3 = loopEquipCoil and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

local coilActBtn = makeButton(y, "🔁 Loop Activate Speed Coil", function(btn)
    loopActCoil = not loopActCoil
    btn.BackgroundColor3 = loopActCoil and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end); y = y + 30

--// Small helper
local function equipIfInBackpack(toolName)
    local char = player.Character
    local bag = player:FindFirstChild("Backpack")
    if not (char and bag) then return end
    if char:FindFirstChild(toolName) then return end
    local t = bag:FindFirstChild(toolName)
    if t then t.Parent = char end
end

--// Timers to avoid spamming Activate every frame (helps with movement)
local lastBat = 0
local lastQC  = 0
local lastBee = 0
local lastCoil = 0

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
        if net then
            net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
        end
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

    -- Tung Bat (gate activation to reduce movement lock)
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
            if coil then coil:Activate() end -- may be noop in some games
        end
    end
end)
