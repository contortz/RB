--// Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")

--// Locals
local localPlayer        = Players.LocalPlayer
local localName          = localPlayer and localPlayer.Name or ""
local ESP_TAG_NAME       = "__BR_ESP__"
local UI_NAME            = "BrainRotzToggleUI"

--// Toggles
local Toggles = {
    LockPunchMeter = false,
    PlayerESP      = false,
}

--// ===== Utilities: model discovery across weird hierarchies =====
local function isPlayerName(name)
    -- Fast check against Players service
    local p = Players:FindFirstChild(name)
    return p ~= nil
end

local function findModelByExactNameUnder(root, name)
    if not root then return nil end
    local found = root:FindFirstChild(name)
    if found and found:IsA("Model") then return found end
    return nil
end

local function findRingPlayerModelAnywhere(name)
    -- Look for any "Players" container under rings, then a child model with our name
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Folder") or desc:IsA("Model") then
            if desc.Name == "Players" then
                local m = desc:FindFirstChild(name)
                if m and m:IsA("Model") then
                    return m
                end
            elseif desc:IsA("Model") and (desc.Name == "Player1" or desc.Name == "Player2") then
                -- Some maps use Player1/Player2 models that contain the actual name model
                local m2 = desc:FindFirstChild(name)
                if m2 and m2:IsA("Model") then
                    return m2
                end
            end
        end
    end
    return nil
end

local function findPlayerModelByName(name)
    -- 1) Directly under Workspace
    local direct = findModelByExactNameUnder(Workspace, name)
    if direct then return direct end

    -- 2) Under BrookMap
    local brook = Workspace:FindFirstChild("BrookMap")
    if brook then
        local nested = findModelByExactNameUnder(brook, name)
        if nested then return nested end
    end

    -- 3) In any ring "Players" folder or Player1/Player2 holder
    local ringHit = findRingPlayerModelAnywhere(name)
    if ringHit then return ringHit end

    return nil
end

local function getAllDetectedPlayerModels()
    -- Returns a list of {name=model}
    local results = {}

    -- Scan all known players
    for _, plr in ipairs(Players:GetPlayers()) do
        local m = findPlayerModelByName(plr.Name)
        if m then
            results[plr.Name] = m
        end
    end

    -- Also catch any loose models named like players (if they exist before Players service sees them)
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and isPlayerName(child.Name) then
            results[child.Name] = results[child.Name] or child
        end
    end

    -- Check BrookMap top-level (some maps duplicate there)
    local brook = Workspace:FindFirstChild("BrookMap")
    if brook then
        for _, child in ipairs(brook:GetChildren()) do
            if child:IsA("Model") and isPlayerName(child.Name) then
                results[child.Name] = results[child.Name] or child
            end
        end
    end

    return results
end

local function getPrimary(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model:FindFirstChild("FakeRootPart")
    return hrp
end

local function getHealthFromModel(model)
    -- You said “has a Health attribute” (NumberValue/Attribute). Try Attribute first, then ObjectValue/NumberValue child.
    if not model then return nil end
    if model:GetAttribute("Health") then
        return tonumber(model:GetAttribute("Health"))
    end
    local healthVal = model:FindFirstChild("Health")
    if healthVal and healthVal.Value ~= nil then
        return tonumber(healthVal.Value)
    end
    -- Also try Humanoid if present
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    return nil
end

--// ===== PunchMeter locker =====
local function lockPunchMeter100()
    local myModel = findPlayerModelByName(localName)
    if not myModel then return end
    local pm = myModel:FindFirstChild("PunchMeter")
    if pm and pm:IsA("NumberValue") then
        if pm.Value ~= 100 then
            pm.Value = 100
        end
    end
end

--// ===== ESP =====
local function makeBillboard(nameText, parentPart)
    local gui = Instance.new("BillboardGui")
    gui.Name = ESP_TAG_NAME
    gui.Size = UDim2.new(0, 0, 0, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.ExtentsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    gui.Adornee = parentPart
    gui.ResetOnSpawn = false

    local text = Instance.new("TextLabel")
    text.Name = "Tag"
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(0, 240, 0, 28)
    text.AnchorPoint = Vector2.new(0.5, 0.5)
    text.Position = UDim2.new(0.5, 0, 0.5, 0)
    text.Text = nameText
    text.Font = Enum.Font.SourceSansBold
    text.TextScaled = true
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0.5
    text.Parent = gui

    return gui, text
end

local function ensureESPForModel(model, ownerName)
    if not model then return end
    local pp = getPrimary(model)
    if not pp then return end

    -- Remove stale duplicates on model
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BillboardGui") and c.Name == ESP_TAG_NAME then
            c:Destroy()
        end
    end

    local gui, text = makeBillboard(ownerName, pp)
    gui.Parent = model

    -- live updater for line (distance/health)
    local con
    con = RunService.RenderStepped:Connect(function()
        if not gui or not gui.Parent or not pp.Parent then
            if con then con:Disconnect(); con = nil end
            if gui then gui:Destroy() end
            return
        end
        local cam = Workspace.CurrentCamera
        local dist = (cam.CFrame.Position - pp.Position).Magnitude
        local hp = getHealthFromModel(model)
        local hpStr = hp and string.format(" | HP: %s", math.floor(hp)) or ""
        local me = (ownerName == localName) and " (YOU)" or ""
        text.Text = string.format("%s%s | %.1fm%s", ownerName, me, dist, hpStr)
    end)

    -- Store cleanup connector on the GUI
    gui:GetPropertyChangedSignal("Parent"):Connect(function()
        if not gui.Parent and con then
            con:Disconnect()
            con = nil
        end
    end)
end

local function clearAllESP()
    -- Remove all billboards we created
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Name == ESP_TAG_NAME then
            desc:Destroy()
        end
    end
end

local function refreshAllESP()
    clearAllESP()
    local models = getAllDetectedPlayerModels()
    for name, model in pairs(models) do
        local pp = getPrimary(model)
        if pp then
            ensureESPForModel(model, name)
        end
    end
end

-- Continuous updater for ESP while toggle is on
local lastESPRefresh = 0
RunService.RenderStepped:Connect(function(dt)
    if Toggles.PlayerESP then
        lastESPRefresh = lastESPRefresh + dt
        -- Refresh every ~0.75s to catch spawns/moves between odd parents
        if lastESPRefresh >= 0.75 then
            lastESPRefresh = 0
            refreshAllESP()
        end
    end
end)

--// ===== Master heartbeat =====
RunService.Heartbeat:Connect(function()
    if Toggles.LockPunchMeter then
        lockPunchMeter100()
    end
end)

--// ===== Minimal GUI =====
do
    -- Avoid duplicates
    local old = (localPlayer.PlayerGui and localPlayer.PlayerGui:FindFirstChild(UI_NAME)) or nil
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = UI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = localPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 120)
    frame.Position = UDim2.new(0, 20, 0, 140)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -8, 0, 28)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BrainRotz – Tools"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local function makeToggle(parent, y, label, initial, onChanged)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 30)
        btn.Position = UDim2.new(0, 8, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(42,42,42)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16
        btn.Text = ""
        btn.Parent = parent

        local function render(state)
            btn.Text = string.format("[%s]  %s", state and "ON" or "OFF", label)
            btn.BackgroundColor3 = state and Color3.fromRGB(35, 120, 60) or Color3.fromRGB(60, 60, 60)
        end

        local state = initial
        render(state)
        btn.MouseButton1Click:Connect(function()
            state = not state
            render(state)
            onChanged(state)
        end)

        -- expose a setter
        return function(setTo)
            state = setTo and true or false
            render(state)
            onChanged(state)
        end
    end

    local setPunch = makeToggle(frame, 36, "Lock PunchMeter = 100", Toggles.LockPunchMeter, function(v)
        Toggles.LockPunchMeter = v
    end)

    local setESP = makeToggle(frame, 72, "Player ESP", Toggles.PlayerESP, function(v)
        Toggles.PlayerESP = v
        if v then
            refreshAllESP()
        else
            clearAllESP()
        end
    end)

    -- Optional: start minimized? flip these two lines if you want minimized by default.
    frame.Visible = true
end
