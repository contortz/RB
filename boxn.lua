--// Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
while not player do task.wait() player = Players.LocalPlayer end

-- ===== Remotes (your exact paths; change if needed) =====
local BlockEvent = ReplicatedStorage.CombatRemotesRemotes.BlockEvent  -- RemoteEvent
local DodgeEvent = ReplicatedStorage.CombatRemotesRemotes.DodgeEvent  -- RemoteEvent

--// Toggles
local Toggles = {
    PlayerESP   = false,
    Blocking    = false,
    AutoDodgeOnCombat = false, -- NEW
}

-- =========================
-- UI (robust parent + watchdog)
-- =========================
local UI_NAME = "MiniTwoToggleGui"

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
    if root and root:FindFirstChild(UI_NAME) then
        root[UI_NAME]:Destroy()
    end
end

local Buttons = {} -- key -> {btn=Instance, label=string}
local function updateButtonVisual(key)
    local info = Buttons[key]; if not info then return end
    local on = Toggles[key]
    info.btn.Text = ("%s: %s"):format(info.label, on and "ON" or "OFF")
    info.btn.BackgroundColor3 = on and Color3.fromRGB(0,200,0) or Color3.fromRGB(60,60,60)
end

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

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 220, 0, 170)
    Frame.Position = UDim2.new(0.5, -110, 0.5, -85)
    Frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 28)
    Title.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Text = "MiniHub"
    Title.Parent = Frame

    local function makeToggle(y, label, key, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.9, 0, 0, 30)
        b.Position = UDim2.new(0.05, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 14
        b.Parent = Frame

        Buttons[key] = { btn = b, label = label }
        updateButtonVisual(key)

        b.MouseButton1Click:Connect(function()
            if onClick then
                onClick()
            else
                Toggles[key] = not Toggles[key]
                updateButtonVisual(key)
                if key == "PlayerESP" and not Toggles.PlayerESP then
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
            end
        end)
    end

    makeToggle(40,  "Player ESP",            "PlayerESP")
    makeToggle(75,  "Blocking (Z/X)",        "Blocking", function()
        Toggles.Blocking = not Toggles.Blocking
        updateButtonVisual("Blocking")
        if Toggles.Blocking then
            BlockEvent:FireServer("blockStart")
        else
            BlockEvent:FireServer("unblocking")
        end
    end)
    makeToggle(110, "Auto Dodge (closest combat)", "AutoDodgeOnCombat")

    -- watchdog: re-parent if nuked
    task.spawn(function()
        while task.wait(0.3) do
            if not ScreenGui.Parent then
                ScreenGui.Parent = getHiddenUi() or CoreGui or player:FindFirstChild("PlayerGui")
            end
        end
    end)

    return ScreenGui
end

createGui()

-- =========================
-- Attribute sources (Model named exactly like the player)
-- =========================

local function findStatsModelForPlayer(targetPlayer)
    local candidates = {}

    if targetPlayer.Character then
        table.insert(candidates, targetPlayer.Character)
    end
    local wsNamed = Workspace:FindFirstChild(targetPlayer.Name)
    if wsNamed and wsNamed:IsA("Model") then
        table.insert(candidates, wsNamed)
    end
    local repNamed = ReplicatedStorage:FindFirstChild(targetPlayer.Name)
    if repNamed and repNamed:IsA("Model") then
        table.insert(candidates, repNamed)
    end

    local containerNames = { "Players", "PlayerData", "Profiles", "Stats", "Data", "ProfilesByName" }
    for _, containerName in ipairs(containerNames) do
        for _, parent in ipairs({ ReplicatedStorage, Workspace }) do
            local container = parent:FindFirstChild(containerName)
            if container then
                local model = container:FindFirstChild(targetPlayer.Name)
                if model and model:IsA("Model") then
                    table.insert(candidates, model)
                end
            end
        end
    end

    for _, model in ipairs(candidates) do
        if model:GetAttribute("Health") ~= nil
        or model:GetAttribute("UltimateLevel") ~= nil
        or model:GetAttribute("combat") ~= nil then
            return model
        end
    end

    return candidates[1]
end

local function getPlayerAttribute(targetPlayer, attributeName)
    local statsModel = findStatsModelForPlayer(targetPlayer)
    if statsModel then
        local val = statsModel:GetAttribute(attributeName)
        if val ~= nil then return val end
    end
    if attributeName == "Health" and targetPlayer.Character then
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then return humanoid.Health end
    end
    return nil
end

-- =========================
-- Player ESP (Billboard)
-- =========================

local function ensureBillboard(hrp)
    local bb = hrp:FindFirstChild("Player_ESP")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "Player_ESP"
        bb.Adornee = hrp
        bb.Size = UDim2.new(0, 240, 0, 46)
        bb.AlwaysOnTop = true
        bb.Parent = hrp

        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 200, 50)
        label.TextStrokeTransparency = 0.15
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = bb
    end
    return bb
end

local function updateESP(myHRP)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            if otherHRP then
                if Toggles.PlayerESP then
                    local health = getPlayerAttribute(otherPlayer, "Health")
                    local ultimateLevel = getPlayerAttribute(otherPlayer, "UltimateLevel")
                    local distance = (myHRP.Position - otherHRP.Position).Magnitude

                    local bb = ensureBillboard(otherHRP)
                    local label = bb:FindFirstChild("Text")
                    if label then
                        label.Text = string.format(
                            "%s | HP: %s | UL: %s | %dm",
                            otherPlayer.Name,
                            (health and math.floor(tonumber(health) or 0) or "?"),
                            (ultimateLevel ~= nil and tostring(ultimateLevel) or "?"),
                            math.floor(distance)
                        )
                    end
                else
                    if otherHRP:FindFirstChild("Player_ESP") then
                        otherHRP.Player_ESP:Destroy()
                    end
                end
            end
        end
    end
end

-- =========================
-- Auto Dodge on closest player's combat = true
-- =========================

local lastCombatStateByUserId = {}  -- userId -> boolean
local lastDodgeTime = 0
local DODGE_COOLDOWN = 0.25 -- small safety cooldown

local function getClosestOtherPlayer(myHRP)
    local closest, best = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < best then
                    closest, best = p, d
                end
            end
        end
    end
    return closest, best
end

local function maybeAutoDodge(myHRP)
    if not Toggles.AutoDodgeOnCombat then return end
    local target = getClosestOtherPlayer(myHRP)
    if not target then return end

    local combat = getPlayerAttribute(target, "combat")
    local uid = target.UserId
    local prev = lastCombatStateByUserId[uid]

    if combat == true and prev ~= true then
        local now = os.clock()
        if now - lastDodgeTime >= DODGE_COOLDOWN then
            lastDodgeTime = now
            -- fire exactly when it flips true
            DodgeEvent:FireServer("left")
        end
    end

    lastCombatStateByUserId[uid] = combat == true
end

-- =========================
-- Keybinds: Z = blockStart, X = unblocking
-- =========================
local lastSend = 0
local SEND_COOLDOWN = 0.08
local function canSend()
    local now = os.clock()
    if now - lastSend < SEND_COOLDOWN then return false end
    lastSend = now
    return true
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z then
        if canSend() then
            Toggles.Blocking = true
            updateButtonVisual("Blocking")
            BlockEvent:FireServer("blockStart")
        end
    elseif input.KeyCode == Enum.KeyCode.X then
        if canSend() then
            Toggles.Blocking = false
            updateButtonVisual("Blocking")
            BlockEvent:FireServer("unblocking")
        end
    end
end)

-- clear block on respawn
player.CharacterAdded:Connect(function()
    Toggles.Blocking = false
    updateButtonVisual("Blocking")
end)

-- =========================
-- Main loop
-- =========================
RunService.Heartbeat:Connect(function()
    local myChar = player.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    if Toggles.PlayerESP then
        updateESP(myHRP)
    end

    -- Auto Dodge watcher
    maybeAutoDodge(myHRP)
end)
