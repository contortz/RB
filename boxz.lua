--[[ BrainRotz – Dual Name/DisplayName Support + Hardened UI
     - Finds player models by Player.Name or Player.DisplayName
     - Searches Workspace root, BrookMap, and BoxingRing Players containers
     - UI parents: gethui -> CoreGui -> PlayerGui (watchdog & protect)
     - Drawing overlay fallback with hotkeys (P=Punch, O=ESP)
--]]

--// Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")

if not game:IsLoaded() then game.Loaded:Wait() end
local me = Players.LocalPlayer
while not me do task.wait() me = Players.LocalPlayer end

--// Toggles
local Toggles = {
    LockPunchMeter = false,
    PlayerESP      = false,
}

--// ===== Model discovery (supports Name or DisplayName) =====
local function modelNamed(root, id)
    if not root or not id or id == "" then return nil end
    local m = root:FindFirstChild(id)
    return (m and m:IsA("Model")) and m or nil
end

local function findModelById(id)
    if not id or id == "" then return nil end
    local w = Workspace

    -- 1) Workspace root
    local m = modelNamed(w, id)
    if m then return m end

    -- 2) Workspace.BrookMap
    local brook = w:FindFirstChild("BrookMap")
    if brook then
        m = modelNamed(brook, id)
        if m then return m end
    end

    -- 3) Any .../BoxingRing/.../Players/<id> or Player1/Player2/<id>
    for _, d in ipairs(w:GetDescendants()) do
        if d:IsA("Folder") and d.Name == "Players" then
            local c = d:FindFirstChild(id)
            if c and c:IsA("Model") then return c end
        elseif d:IsA("Model") and (d.Name == "Player1" or d.Name == "Player2") then
            local c2 = d:FindFirstChild(id)
            if c2 and c2:IsA("Model") then return c2 end
        end
    end

    return nil
end

local function findPlayerModel(plr)
    -- Try username first (most common), then display name
    return findModelById(plr.Name) or findModelById(plr.DisplayName)
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
    local attr = model:GetAttribute("Health")
    if attr ~= nil then return tonumber(attr) end
    local hv = model:FindFirstChild("Health")
    if hv and hv.Value ~= nil then return tonumber(hv.Value) end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    return nil
end

--// ===== PunchMeter lock (local player only) =====
local function lockPunch()
    local myModel = findPlayerModel(me)
    if not myModel then return end
    local pm = myModel:FindFirstChild("PunchMeter")
    if pm and pm:IsA("NumberValue") and pm.Value ~= 100 then
        pm.Value = 100
    end
end

--// ===== ESP =====
local ESP_TAG = "__WS_PLAYER_ESP__"

local function clearESP()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BillboardGui") and d.Name == ESP_TAG then
            d:Destroy()
        end
    end
end

local function addESPFor(plr, model)
    local head = getPrimary(model)
    if not head then return end

    -- remove stale from this model
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
    lbl.Size = UDim2.new(0, 260, 0, 28)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0.5
    lbl.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
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
        local meTag = (plr == me) and " (YOU)" or ""
        lbl.Text = string.format("%s%s | %.1fm%s", plr.DisplayName .. " (@" .. plr.Name .. ")", meTag, dist, hpStr)
    end)

    bb:GetPropertyChangedSignal("Parent"):Connect(function()
        if not bb.Parent and conn then conn:Disconnect() end
    end)
end

local function refreshESP()
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        local mdl = findPlayerModel(plr)
        if mdl then addESPFor(plr, mdl) end
    end
end

--// ===== UI creation (multi-fallback) =====
local UI_NAME = "BrainRotzToggleUI"

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

-- remove old copies anywhere obvious
for _, where in ipairs({getHiddenUi(), game:GetService("CoreGui"), me:FindFirstChild("PlayerGui")}) do
    if where and where:FindFirstChild(UI_NAME) then where[UI_NAME]:Destroy() end
end

local function tryBuildScreenGui(parentRoot)
    if not parentRoot then return nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = UI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 999999
    protectGui(gui)
    gui.Parent = parentRoot

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 140)
    frame.Position = UDim2.new(0.5, -130, 0.5, -70) -- center
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BrainRotz – Workspace"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local function makeToggle(y, label, key)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 32)
        b.Position = UDim2.new(0, 10, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 16
        b.Text = "[" .. (Toggles[key] and "ON" or "OFF") .. "] " .. label
        b.Parent = frame
        b.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            b.Text = "[" .. (Toggles[key] and "ON" or "OFF") .. "] " .. label
            b.BackgroundColor3 = Toggles[key] and Color3.fromRGB(35,120,60) or Color3.fromRGB(60,60,60)
            if key == "PlayerESP" then
                if Toggles.PlayerESP then refreshESP() else clearESP() end
            end
        end)
        b.BackgroundColor3 = Toggles[key] and Color3.fromRGB(35,120,60) or Color3.fromRGB(60,60,60)
    end

    makeToggle(36, "Lock PunchMeter = 100", "LockPunchMeter")
    makeToggle(72, "Player ESP (Name/DisplayName)", "PlayerESP")

    -- watchdog to reparent if nuked
    task.spawn(function()
        while task.wait(0.3) do
            if not gui or not gui.Parent then
                local parent = getHiddenUi() or game:GetService("CoreGui") or me:FindFirstChild("PlayerGui")
                if parent then gui.Parent = parent end
            end
        end
    end)

    print("[BrainRotz UI] ScreenGui parent:", gui.Parent and gui.Parent:GetFullName() or "nil")
    return gui
end

local uiParent = getHiddenUi() or game:GetService("CoreGui") or me:WaitForChild("PlayerGui")
local ScreenGui = tryBuildScreenGui(uiParent)

--// ===== Drawing overlay fallback (P/O hotkeys) =====
local drawingEnabled = false
local drawFrame, drawTitle, drawPM, drawESP

local function canUseDrawing()
    local ok = pcall(function() local t = Drawing.new("Square"); t.Visible = false; t:Remove() end)
    return ok
end

local function buildDrawingOverlay()
    if not canUseDrawing() then return false end
    drawingEnabled = true

    drawFrame = Drawing.new("Square")
    drawFrame.Size = Vector2.new(300, 110)
    drawFrame.Position = Vector2.new(40, 60)
    drawFrame.Filled = true
    drawFrame.Transparency = 0.85
    drawFrame.Visible = true

    drawTitle = Drawing.new("Text")
    drawTitle.Text = "BrainRotz – Fallback (P=Punch, O=ESP)"
    drawTitle.Size = 18
    drawTitle.Position = Vector2.new(46, 66)
    drawTitle.Color = Color3.new(1,1,1)
    drawTitle.Visible = true

    drawPM = Drawing.new("Text")
    drawPM.Size = 16
    drawPM.Position = Vector2.new(46, 94)
    drawPM.Color = Color3.new(1,1,1)
    drawPM.Visible = true

    drawESP = Drawing.new("Text")
    drawESP.Size = 16
    drawESP.Position = Vector2.new(46, 114)
    drawESP.Color = Color3.new(1,1,1)
    drawESP.Visible = true

    local function rerender()
        if not drawingEnabled then return end
        drawPM.Text  = "Lock PunchMeter = 100: " .. (Toggles.LockPunchMeter and "ON" or "OFF") .. "  [P]"
        drawESP.Text = "Player ESP: " .. (Toggles.PlayerESP and "ON" or "OFF") .. "  [O]"
    end
    rerender()

    UserInput.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.P then
            Toggles.LockPunchMeter = not Toggles.LockPunchMeter
            rerender()
        elseif inp.KeyCode == Enum.KeyCode.O then
            Toggles.PlayerESP = not Toggles.PlayerESP
            rerender()
            if Toggles.PlayerESP then refreshESP() else clearESP() end
        end
    end)

    print("[BrainRotz UI] Using Drawing overlay fallback")
    return true
end

if not ScreenGui then
    buildDrawingOverlay()
end

--// ===== Background loops =====
local espTicker = 0
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
        lockPunch()
    end
end)
