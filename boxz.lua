--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not game:IsLoaded() then game.Loaded:Wait() end

--// Toggles
local Toggles = {
    LockPunchMeter = false,
    PlayerESP      = false,
}

--// ---------- UI (same style you showed) ----------
local function createGui()
    local old = CoreGui:FindFirstChild("StreetFightGui")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 220, 0, 210)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -105)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.new(1, 1, 1)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 16
    TitleLabel.Text = "Dreamz MiniHub (Workspace)"
    TitleLabel.Parent = MainFrame

    local function makeBtn(text, key, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.9, 0, 0, 30)
        b.Position = UDim2.new(0.05, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 15
        b.Text = text .. ": OFF"
        b.Parent = MainFrame
        b.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            b.Text = text .. ": " .. (Toggles[key] and "ON" or "OFF")
            b.BackgroundColor3 = Toggles[key] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)
    end

    makeBtn("Lock PunchMeter = 100", "LockPunchMeter", 45)
    makeBtn("Player ESP (Workspace)", "PlayerESP", 80)

    -- Small tip text
    local tip = Instance.new("TextLabel")
    tip.BackgroundTransparency = 1
    tip.Size = UDim2.new(0.9, 0, 0, 60)
    tip.Position = UDim2.new(0.05, 0, 0, 120)
    tip.Font = Enum.Font.SourceSans
    tip.TextSize = 14
    tip.TextColor3 = Color3.fromRGB(200, 200, 200)
    tip.TextWrapped = true
    tip.Text = "Looks for models by your username in Workspace / BrookMap / BoxingRing paths."
    tip.Parent = MainFrame
end

createGui()

--// ---------- Model discovery for THIS game ----------
local localName = player.Name

local function findModelByName(name)
    local w = Workspace

    -- 1) Direct child
    local direct = w:FindFirstChild(name)
    if direct and direct:IsA("Model") then return direct end

    -- 2) BrookMap child
    local brook = w:FindFirstChild("BrookMap")
    if brook then
        local m = brook:FindFirstChild(name)
        if m and m:IsA("Model") then return m end
    end

    -- 3) Anything like .../BoxingRing/.../Players/Player1|Player2/<Name>
    for _, d in ipairs(w:GetDescendants()) do
        if d:IsA("Folder") and d.Name == "Players" then
            local m = d:FindFirstChild(name)
            if m and m:IsA("Model") then return m end
        elseif d:IsA("Model") and (d.Name == "Player1" or d.Name == "Player2") then
            local m2 = d:FindFirstChild(name)
            if m2 and m2:IsA("Model") then return m2 end
        end
    end

    return nil
end

local function getPrimary(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("FakeRootPart")
end

local function getHealth(model)
    if not model then return nil end
    -- Health attribute (preferred in your map notes)
    local attr = model:GetAttribute("Health")
    if attr ~= nil then return tonumber(attr) end

    -- Health child NumberValue
    local hv = model:FindFirstChild("Health")
    if hv and hv.Value ~= nil then return tonumber(hv.Value) end

    -- Fallback: Humanoid
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end

    return nil
end

--// ---------- PunchMeter lock ----------
local function lockPunchMeter100()
    local myModel = findModelByName(localName)
    if not myModel then return end
    local pm = myModel:FindFirstChild("PunchMeter")
    if pm and pm:IsA("NumberValue") and pm.Value ~= 100 then
        pm.Value = 100
    end
end

--// ---------- Player ESP (Workspace models) ----------
local ESP_TAG = "__WS_PLAYER_ESP__"

local function clearESP()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BillboardGui") and d.Name == ESP_TAG then
            d:Destroy()
        end
    end
end

local function addESPFor(name, model)
    local head = getPrimary(model)
    if not head then return end

    -- delete old
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BillboardGui") and c.Name == ESP_TAG then c:Destroy() end
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = ESP_TAG
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 0, 0, 0)
    bb.ExtentsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    bb.Adornee = head
    bb.Parent = model

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0, 220, 0, 28)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0.5
    lbl.Text = name
    lbl.Parent = bb

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not bb.Parent or not head.Parent then
            if conn then conn:Disconnect() end
            if bb then bb:Destroy() end
            return
        end
        local cam = Workspace.CurrentCamera
        local dist = (cam.CFrame.Position - head.Position).Magnitude
        local hp = getHealth(model)
        local hpStr = hp and (" | HP: " .. math.floor(hp)) or ""
        local meTag = (name == localName) and " (YOU)" or ""
        lbl.Text = string.format("%s%s | %.1fm%s", name, meTag, dist, hpStr)
    end)

    bb:GetPropertyChangedSignal("Parent"):Connect(function()
        if not bb.Parent and conn then conn:Disconnect() end
    end)
end

local function refreshESP()
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        local mdl = findModelByName(plr.Name)
        if mdl then
            addESPFor(plr.Name, mdl)
        end
    end
end

-- gentle refresh cadence (players move between containers)
local espTicker = 0

--// ---------- Main loops ----------
RunService.RenderStepped:Connect(function(dt)
    if Toggles.PlayerESP then
        espTicker += dt
        if espTicker >= 0.75 then
            espTicker = 0
            refreshESP()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Toggles.LockPunchMeter then
        lockPunchMeter100()
    end
end)
