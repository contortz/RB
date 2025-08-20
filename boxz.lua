--=== SAFE UI ROOT ===--
local Players   = game:GetService("Players")
local CoreGui   = game:GetService("CoreGui")
local RunService= game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not game:IsLoaded() then game.Loaded:Wait() end
local localPlayer = Players.LocalPlayer
while not localPlayer do task.wait() localPlayer = Players.LocalPlayer end

-- UI constants
local UI_NAME        = "BrainRotzToggleUI"
local ESP_TAG_NAME   = "__BR_ESP__"

-- Kill any previous instance so we don't stack UIs
local old = CoreGui:FindFirstChild(UI_NAME)
if old then old:Destroy() end

-- Build UI in CoreGui (most reliable)
local gui = Instance.new("ScreenGui")
gui.Name = UI_NAME
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 99999
gui.Parent = CoreGui

-- Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 140)
frame.Position = UDim2.new(0, 20, 0, 140)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true
frame.Parent = gui

-- Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 28)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "BrainRotz – Tools"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Minimize button
local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0, 28, 0, 24)
mini.Position = UDim2.new(1, -34, 0, 2)
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)
mini.TextColor3 = Color3.new(1,1,1)
mini.Text = "-"
mini.Font = Enum.Font.SourceSansBold
mini.TextSize = 20
mini.Parent = frame

local miniIcon = Instance.new("TextButton")
miniIcon.Size = UDim2.new(0, 140, 0, 34)
miniIcon.Position = UDim2.new(0, 20, 0, 100)
miniIcon.BackgroundColor3 = Color3.fromRGB(60,60,60)
miniIcon.TextColor3 = Color3.new(1,1,1)
miniIcon.Text = "Open BrainRotz"
miniIcon.Font = Enum.Font.SourceSansBold
miniIcon.TextSize = 16
miniIcon.Visible = false
miniIcon.Parent = gui

mini.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniIcon.Visible = true
end)
miniIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    miniIcon.Visible = false
end)

-- Toggle button factory
local function makeToggle(parent, y, label, initial, onChanged)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = ""
    btn.Parent = parent

    local state = initial and true or false
    local function render()
        btn.Text = string.format("[%s]  %s", state and "ON" or "OFF", label)
        btn.BackgroundColor3 = state and Color3.fromRGB(35,120,60) or Color3.fromRGB(60,60,60)
    end
    render()

    btn.MouseButton1Click:Connect(function()
        state = not state
        render()
        onChanged(state)
    end)

    return function(setTo)
        state = setTo and true or false
        render()
        onChanged(state)
    end
end

--================ LOGIC ================--

local Toggles = {
    LockPunchMeter = false,
    PlayerESP      = false,
}

-- Find player models (Workspace.<Name>, BrookMap.<Name>, or ring containers)
local function findModelByName(name)
    local w = Workspace
    local direct = w:FindFirstChild(name)
    if direct and direct:IsA("Model") then return direct end
    local brook = w:FindFirstChild("BrookMap")
    if brook then
        local m = brook:FindFirstChild(name)
        if m and m:IsA("Model") then return m end
    end
    -- scan ring “Players” folders or Player1/Player2 containers
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
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model:FindFirstChild("FakeRootPart")
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

-- Lock PunchMeter to 100 for local player
local function lockPunch()
    local my = findModelByName(Players.LocalPlayer.Name)
    if not my then return end
    local pm = my:FindFirstChild("PunchMeter")
    if pm and pm:IsA("NumberValue") and pm.Value ~= 100 then
        pm.Value = 100
    end
end

-- ESP
local function clearAllESP()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BillboardGui") and d.Name == ESP_TAG_NAME then
            d:Destroy()
        end
    end
end

local function addESP(model, ownerName)
    local head = getPrimary(model)
    if not head then return end

    -- delete stale
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BillboardGui") and c.Name == ESP_TAG_NAME then c:Destroy() end
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = ESP_TAG_NAME
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,0,0,0)
    bb.ExtentsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    bb.Adornee = head
    bb.Parent = model

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0, 240, 0, 28)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0.5
    lbl.Text = ownerName
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
        local hpStr = hp and (" | HP: "..math.floor(hp)) or ""
        local me = (ownerName == Players.LocalPlayer.Name) and " (YOU)" or ""
        lbl.Text = string.format("%s%s | %.1fm%s", ownerName, me, dist, hpStr)
    end)

    bb:GetPropertyChangedSignal("Parent"):Connect(function()
        if not bb.Parent and conn then conn:Disconnect() end
    end)
end

local function refreshESP()
    clearAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        local m = findModelByName(plr.Name)
        if m then addESP(m, plr.Name) end
    end
end

-- Toggle wires
local setPunch = makeToggle(frame, 36, "Lock PunchMeter = 100", false, function(v)
    Toggles.LockPunchMeter = v
end)

local setESP = makeToggle(frame, 72, "Player ESP", false, function(v)
    Toggles.PlayerESP = v
    if v then refreshESP() else clearAllESP() end
end)

-- Background loops
local espTick = 0
RunService.RenderStepped:Connect(function(dt)
    if Toggles.PlayerESP then
        espTick += dt
        if espTick >= 0.75 then
            espTick = 0
            refreshESP()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Toggles.LockPunchMeter then
        lockPunch()
    end
end)
