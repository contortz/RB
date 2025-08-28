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

-- ===== Block Remote (uses your exact path) =====
-- If your game actually uses a different path, just change this one line:
local BlockEvent = ReplicatedStorage.CombatRemotesRemotes.BlockEvent  -- RemoteEvent

--// Toggles
local Toggles = {
    PlayerESP  = false,
    StayBehind = false,
    Blocking   = false, -- NEW
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
    Frame.Size = UDim2.new(0, 200, 0, 160)
    Frame.Position = UDim2.new(0.5, -100, 0.5, -80) -- center
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
                -- default behavior: flip toggle
                Toggles[key] = not Toggles[key]
                updateButtonVisual(key)
                -- extra cleanup for ESP when turning off
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

    makeToggle(40,  "Player ESP", "PlayerESP")
    makeToggle(75,  "Stay Behind", "StayBehind")

    -- === Blocking button ===
    local function setBlocking(on)
        if Toggles.Blocking == on then return end
        Toggles.Blocking = on
        updateButtonVisual("Blocking")
        if on then
            BlockEvent:FireServer("blockStart")
        else
            BlockEvent:FireServer("unblocking")
        end
    end

    makeToggle(110, "Blocking (Z/X)", "Blocking", function()
        setBlocking(not Toggles.Blocking)
    end)

    -- watchdog: re-parent if nuked
    task.spawn(function()
        while task.wait(0.3) do
            if not ScreenGui.Parent then
                ScreenGui.Parent = getHiddenUi() or CoreGui or player:FindFirstChild("PlayerGui")
            end
        end
    end)

    print("[MiniHub] UI parent:", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "nil")
    return ScreenGui, setBlocking
end

local ScreenGui, SetBlocking = createGui()

-- =========================
-- Health utils
-- =========================
local function getHealthFromCharacter(char)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    local attr = char:GetAttribute("Health")
    if attr ~= nil then
        local n = tonumber(attr)
        if n then return n end
    end
    local nv = char:FindFirstChild("Health")
    if nv and nv:IsA("NumberValue") then
        local n = tonumber(nv.Value)
        if n then return n end
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
        bb.Size = UDim2.new(0, 180, 0, 40)
        bb.AlwaysOnTop = true
        bb.Parent = hrp

        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255,0,0)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Parent = bb
    end
    return bb
end

local function updateESP(myHRP)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Toggles.PlayerESP then
                    local hp = getHealthFromCharacter(char)
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    local bb = ensureBillboard(hrp)
                    local label = bb:FindFirstChild("Text")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm", p.Name, hp and math.floor(hp) or "?", math.floor(dist))
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

-- =========================
-- Stay Behind Closest
-- =========================
local BEHIND_DISTANCE, VERTICAL_OFFSET = 5.0, 1.5

local function getClosestAliveOtherPlayer(myHRP)
    local closest, best = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hp = getHealthFromCharacter(char)
            if hrp and hp and hp > 0 then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < best then closest, best = p, d end
            end
        end
    end
    return closest, best
end

local function doStayBehind(myHRP)
    local target = getClosestAliveOtherPlayer(myHRP)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local desiredPos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
    local lookAt = desiredPos + tHRP.CFrame.LookVector
    myHRP.CFrame = CFrame.new(desiredPos, lookAt)
end

-- =========================
-- Keybinds: Z = blockStart, X = unblocking
-- =========================
local lastSend = 0
local SEND_COOLDOWN = 0.08 -- light debounce

local function canSend()
    local now = os.clock()
    if now - lastSend < SEND_COOLDOWN then return false end
    lastSend = now
    return true
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        Toggles.StayBehind = not Toggles.StayBehind
        updateButtonVisual("StayBehind")
    elseif input.KeyCode == Enum.KeyCode.Z then
        if canSend() then
            SetBlocking(true)  -- fires "blockStart" and updates UI
        end
    elseif input.KeyCode == Enum.KeyCode.X then
        if canSend() then
            SetBlocking(false) -- fires "unblocking" and updates UI
        end
    end
end)

-- ensure we clear block on respawn
player.CharacterAdded:Connect(function()
    SetBlocking(false)
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
    if Toggles.StayBehind then
        doStayBehind(myHRP)
    end
end)
