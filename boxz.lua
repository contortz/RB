--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
while not player do task.wait() player = Players.LocalPlayer end

-- Optional Remote
local STOMPEVENT = ReplicatedStorage:FindFirstChild("STOMPEVENT") -- RemoteEvent (may be nil)

--// Toggles
local Toggles = {
    AutoPickCash = false,
    AutoPunch = false,
    AutoSwing = false,
    PlayerESP = false,
    ATMESP = false,
    SalonPunchTest = false,
    GiveDinero = false,
    StayBehind = false,     -- follow closest valid player (every frame CFrame)
    AutoStomper = false,    -- sweep map for low-HP players and stomp
}

-- =========================
-- UI PARENT (robust)
-- =========================
local UI_NAME = "StreetFightGui"

local function getHiddenUi()
    return (gethui and gethui())
        or (get_hidden_gui and get_hidden_gui())
        or (gethiddengui and gethiddengui())
        or nil
end

local function protectGui(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    pcall(function() if protect_gui then protect_gui(gui) end end)
end

-- kill any previous copies anywhere obvious
for _, root in ipairs({getHiddenUi(), CoreGui, player:FindFirstChild("PlayerGui")}) do
    if root and root:FindFirstChild(UI_NAME) then root[UI_NAME]:Destroy() end
end

-- forward decls (wired to buttons)
local teleportNextATM, refreshPlayerESP, clearPlayerESP, updateATMESP, clearATMESP

-- build UI (same style, more reliable parent + watchdog)
local function createGui()
    local parentRoot = getHiddenUi() or CoreGui or player:WaitForChild("PlayerGui")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = UI_NAME
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder = 999999
    protectGui(ScreenGui)
    ScreenGui.Parent = parentRoot

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 490)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -245) -- center to avoid offscreen
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
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 14
        button.Text = name .. ": OFF"
        button.Parent = MainFrame

        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)

            if toggleKey == "PlayerESP" then
                if Toggles.PlayerESP then refreshPlayerESP() else clearPlayerESP() end
            elseif toggleKey == "ATMESP" then
                if Toggles.ATMESP then updateATMESP() else clearATMESP() end
            end
        end)
    end

    createButton("Auto Pick Cash", "AutoPickCash", 40)
    createButton("Auto Punch", "AutoPunch", 75)
    createButton("Auto Swing", "AutoSwing", 110)
    createButton("Player ESP", "PlayerESP", 145)
    createButton("ATM ESP", "ATMESP", 180)
    createButton("Stay Behind Closest", "StayBehind", 215)
    createButton("Auto Stomper", "AutoStomper", 250)
    createButton("Salon Punch Test", "SalonPunchTest", 285)
    createButton("Give Dinero Test", "GiveDinero", 320)

    -- Teleport to next ATM
    local tpATMButton = Instance.new("TextButton")
    tpATMButton.Size = UDim2.new(0.9, 0, 0, 30)
    tpATMButton.Position = UDim2.new(0.05, 0, 0, 355)
    tpATMButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    tpATMButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpATMButton.Font = Enum.Font.SourceSansBold
    tpATMButton.TextSize = 14
    tpATMButton.Text = "Teleport Next ATM"
    tpATMButton.Parent = MainFrame
    tpATMButton.MouseButton1Click:Connect(function()
        if teleportNextATM then teleportNextATM() end
    end)

    -- watchdog: if UI is nuked, reparent back
    task.spawn(function()
        while task.wait(0.3) do
            if not ScreenGui.Parent then
                ScreenGui.Parent = getHiddenUi() or CoreGui or player:FindFirstChild("PlayerGui")
            end
        end
    end)

    print("[MiniHub] UI parent:", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "nil")
    return ScreenGui
end

local ScreenGui = createGui()

-- =========================
-- Helpers
-- =========================
local function isPvpOn(p)
    -- Require explicit true (checks Player, Character, or Humanoid attributes)
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
                if d < closestDist then closest, closestDist = p, d end
            end
        end
    end
    return closest, closestDist
end

-- Correct health: read from the **character model itself**
local function getHealthFromCharacter(char)
    if not char then return nil end

    -- Attribute first (your game stores it here)
    local attr = char:GetAttribute("Health")
    if attr ~= nil then
        local n = tonumber(attr)
        if n then return n end
    end

    -- NumberValue child named "Health"
    local nv = char:FindFirstChild("Health")
    if nv and nv:IsA("NumberValue") then
        local n = tonumber(nv.Value)
        if n then return n end
    end

    -- Fallback: Humanoid health
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end

    return nil
end

-- =========================
-- ESP (uses Character HRP for position, Character for Health)
-- =========================
local function ensureBillboard(parentPart, name)
    local bb = parentPart:FindFirstChild("Player_ESP")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "Player_ESP"
        bb.Adornee = parentPart
        bb.Size = UDim2.new(0, 180, 0, 40)
        bb.AlwaysOnTop = true
        bb.Parent = parentPart

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 0, 0)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Name = "Text"
        label.Text = name
        label.Parent = bb
    end
    return bb
end

function refreshPlayerESP()
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local char = other.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hp = getHealthFromCharacter(char) -- <<< HEALTH FROM CHARACTER MODEL
                local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                if Toggles.PlayerESP then
                    local bb = ensureBillboard(hrp, other.Name)
                    local label = bb:FindFirstChild("Text")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm",
                            other.Name, hp and math.floor(hp) or "?", dist)
                    end
                else
                    if hrp:FindFirstChild("Player_ESP") then hrp.Player_ESP:Destroy() end
                end
            end
        end
    end
end

function clearPlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("Player_ESP") then
                hrp.Player_ESP:Destroy()
            end
        end
    end
end

-- =========================
-- ATM ESP helpers
-- =========================
function updateATMESP()
    local dmgFolder = Workspace:FindFirstChild("Damageables")
    if not dmgFolder then return end
    for _, atm in ipairs(dmgFolder:GetChildren()) do
        if atm:IsA("Model") and atm.Name == "ATM" then
            local part = atm:FindFirstChildWhichIsA("BasePart")
            if part then
                if Toggles.ATMESP then
                    if not part:FindFirstChild("ATM_ESP") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "ATM_ESP"
                        billboard.Adornee = part
                        billboard.Size = UDim2.new(0, 100, 0, 30)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = part

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = "💰 ATM"
                        label.TextColor3 = Color3.fromRGB(0, 255, 0)
                        label.TextStrokeTransparency = 0
                        label.TextScaled = true
                        label.Parent = billboard
                    end
                else
                    if part:FindFirstChild("ATM_ESP") then part.ATM_ESP:Destroy() end
                end
            end
        end
    end
end

function clearATMESP()
    local dmgFolder = Workspace:FindFirstChild("Damageables")
    if not dmgFolder then return end
    for _, atm in ipairs(dmgFolder:GetChildren()) do
        if atm:IsA("Model") and atm.Name == "ATM" then
            local part = atm:FindFirstChildWhichIsA("BasePart")
            if part and part:FindFirstChild("ATM_ESP") then part.ATM_ESP:Destroy() end
        end
    end
end

-- =========================
-- Cash Teleport + Prompt
-- =========================
local lastTeleport, teleportCooldown, currentCashIndex = 0, 0.25, 1
local function purchasePromptActive()
    local pg = player:FindFirstChild("PlayerGui")
    local promptGui = pg and pg:FindFirstChild("ProximityPrompts")
    return promptGui and #promptGui:GetChildren() > 0
end
local function simulateKeyPress(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

function teleportNextATM()
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local dmgFolder = Workspace:FindFirstChild("Damageables")
    if not dmgFolder then return end
    local atms = {}
    for _, obj in ipairs(dmgFolder:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "ATM" then table.insert(atms, obj) end
    end
    if #atms == 0 then return end
    if currentCashIndex > #atms then currentCashIndex = 1 end
    local target = atms[currentCashIndex]
    local part = target:FindFirstChildWhichIsA("BasePart")
    if part then myHRP.CFrame = part.CFrame + Vector3.new(0, 4, 0) end
    currentCashIndex += 1
end

-- =========================
-- Main loop
-- =========================
local BEHIND_DISTANCE, VERTICAL_OFFSET = 3.5, 1.5
local STOMP_THRESHOLD, STOMP_TP_OFFSET = 3, Vector3.new(0, 2.5, 0)
local STOMP_SPAM_COUNT, STOMP_SPAM_DELAY, STOMP_COOLDOWN = 5, 0.05, 1
local lastStompSweep = 0

RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then return end

        -- Auto Pick Cash
        if Toggles.AutoPickCash and now - lastTeleport >= teleportCooldown then
            local cashFolder = Workspace:FindFirstChild("Cash")
            if cashFolder then
                local allCash = {}
                for _, obj in ipairs(cashFolder:GetChildren()) do
                    if obj:IsA("BasePart") and obj.Name == "Cash" then
                        table.insert(allCash, obj)
                    end
                end
                if #allCash > 0 then
                    if currentCashIndex > #allCash then currentCashIndex = 1 end
                    local targetCash = allCash[currentCashIndex]
                    if targetCash then
                        myHRP.CFrame = targetCash.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.05)
                        if purchasePromptActive() then simulateKeyPress(Enum.KeyCode.E) end
                    end
                    currentCashIndex += 1
                    lastTeleport = now
                end
            end
        end

        -- Auto Punch
        if Toggles.AutoPunch then
            local punchRemote = ReplicatedStorage:FindFirstChild("PUNCHEVENT")
            if punchRemote then punchRemote:FireServer(1) end
        end

        -- Auto Swing
        if Toggles.AutoSwing then
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            if modules then
                local net = modules:FindFirstChild("Net")
                if net then
                    local pipe = net:FindFirstChild("RE/PipeActivated"); if pipe then pipe:FireServer(1) end
                    local stopSign = net:FindFirstChild("RE/stopsignalHit"); if stopSign then stopSign:FireServer(1) end
                end
            end
        end

        -- Give Dinero (test)
        if Toggles.GiveDinero then
            local events = ReplicatedStorage:FindFirstChild("events")
            if events then
                local commandEvents = events:FindFirstChild("customer_command_events")
                if commandEvents then
                    local giveDinero = commandEvents:FindFirstChild("giveDinero")
                    if giveDinero and giveDinero:IsA("RemoteEvent") then
                        giveDinero:FireServer(999999)
                    end
                end
            end
        end

        -- Salon Punch Test
        if Toggles.SalonPunchTest then
            local remote = ReplicatedStorage:FindFirstChild("Roles")
            if remote then
                local tools = remote:FindFirstChild("Tools")
                if tools then
                    local default = tools:FindFirstChild("Default")
                    if default then
                        local remotes = default:FindFirstChild("Remotes")
                        if remotes then
                            local weapons = remotes:FindFirstChild("Weapons")
                            if weapons then
                                local salonPunch = weapons:FindFirstChild("SalonPunches")
                                if salonPunch and salonPunch:IsA("RemoteFunction") then
                                    local result = salonPunch:InvokeServer(1)
                                    print("🧪 SalonPunch result:", result)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Auto Stomper (uses character HP from attribute/NumberValue)
        local didStompThisSweep = false
        if Toggles.AutoStomper and (now - lastStompSweep) >= STOMP_COOLDOWN then
            local candidates = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and isPvpOn(p) then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hp = getHealthFromCharacter(p.Character)
                    if hrp and hp and hp > 0 and hp <= STOMP_THRESHOLD then
                        table.insert(candidates, {hrp = hrp, hp = hp})
                    end
                end
            end
            if #candidates > 0 then
                table.sort(candidates, function(a,b)
                    local myPos = myHRP.Position
                    return (myPos - a.hrp.Position).Magnitude < (myPos - b.hrp.Position).Magnitude
                end)
                for _, t in ipairs(candidates) do
                    myHRP.CFrame = t.hrp.CFrame + STOMP_TP_OFFSET
                    if STOMPEVENT and STOMPEVENT:IsA("RemoteEvent") then
                        for i = 1, STOMP_SPAM_COUNT do
                            STOMPEVENT:FireServer(); task.wait(STOMP_SPAM_DELAY)
                        end
                    end
                    didStompThisSweep = true
                end
            end
            lastStompSweep = now
        end

        -- Stay Behind Closest (skip if stomping)
        if Toggles.StayBehind and not didStompThisSweep then
            local targetPlayer, closestDist = nil, nil
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

        -- ESP updates
        if Toggles.PlayerESP then refreshPlayerESP() end
        if Toggles.ATMESP then updateATMESP() end
    end)
end)

-- Quick hotkeys if your UI parent is blocked:
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.P then
        Toggles.PlayerESP = not Toggles.PlayerESP
        if Toggles.PlayerESP then refreshPlayerESP() else clearPlayerESP() end
    elseif inp.KeyCode == Enum.KeyCode.O then
        Toggles.ATMESP = not Toggles.ATMESP
        if Toggles.ATMESP then updateATMESP() else clearATMESP() end
    end
end)
