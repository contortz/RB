--// Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local CoreGui    = game:GetService("CoreGui")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
while not player do task.wait() player = Players.LocalPlayer end

-- ========= CONFIG for Auto Target by Base =========
local AUTO_SELECT_INTERVAL = 0.25   -- seconds between auto-base checks
local BASE_SELECT_RADIUS   = 80     -- studs; use math.huge to pick always-nearest base
local lastAutoSelectCheck  = 0

-- ========= TOGGLES =========
local Toggles = {
    PlayerESP        = false,
    StayBehind       = false,
    AutoTargetBase   = false,  -- auto choose target by nearest base owner
    FallbackClosest  = true,   -- if no target, follow closest alive player
    AutoEquipRS      = false,  -- Rainbowrath: keep equipped
    AutoActivateRS   = false,  -- Rainbowrath: loop :Activate()
    AutoEquipLS      = false,  -- Lava Slap: keep equipped
    AutoActivateLS   = false,  -- Lava Slap: loop :Activate()
}

-- ========= UI (robust parent + watchdog) =========
local UI_NAME = "MiniStayBehindGui"

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

for _, root in ipairs({getHiddenUi(), CoreGui, player:FindFirstChild("PlayerGui")}) do
    if root and root:FindFirstChild(UI_NAME) then root[UI_NAME]:Destroy() end
end

-- forward decls
local refreshHUD, rebuildPlayerList

local selectedTarget      -- manual selection (Players.Player)
local autoSelectedTarget  -- auto selection (by base proximity)

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
    Frame.Size = UDim2.new(0, 260, 0, 460) -- taller to fit mini pairs
    Frame.Position = UDim2.new(0.5, -130, 0.5, -230)
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
    Title.Text = "MiniHub – ESP / Follow"
    Title.Parent = Frame

    local function paintBtn(btn, on)
        btn.Text = btn.Name .. ": " .. (on and "ON" or "OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    end

    local function makeToggle(y, label, key)
        local b = Instance.new("TextButton")
        b.Name = label
        b.Size = UDim2.new(0.92, 0, 0, 28)
        b.Position = UDim2.new(0.04, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 14
        b.Parent = Frame
        paintBtn(b, Toggles[key])

        b.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            paintBtn(b, Toggles[key])
            if key == "PlayerESP" and not Toggles.PlayerESP then
                -- clear labels
                for _, p in ipairs(Players:GetPlayers()) do
                    local c = p.Character
                    if c then
                        local hrp = c:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp:FindFirstChild("Player_ESP") then hrp.Player_ESP:Destroy() end
                    end
                end
            end
            if refreshHUD then refreshHUD() end
        end)
    end

    local function makeMiniPair(y, leftLabel, leftKey, rightLabel, rightKey)
        local left = Instance.new("TextButton")
        left.Name = leftLabel
        left.Size = UDim2.new(0.44, 0, 0, 24)
        left.Position = UDim2.new(0.04, 0, 0, y)
        left.BackgroundColor3 = Color3.fromRGB(60,60,60)
        left.BorderSizePixel = 0
        left.TextColor3 = Color3.new(1,1,1)
        left.Font = Enum.Font.SourceSansBold
        left.TextSize = 13
        left.Parent = Frame
        left.Text = leftLabel
        paintBtn(left, Toggles[leftKey])

        local right = Instance.new("TextButton")
        right.Name = rightLabel
        right.Size = UDim2.new(0.44, 0, 0, 24)
        right.Position = UDim2.new(0.52, 0, 0, y)
        right.BackgroundColor3 = Color3.fromRGB(60,60,60)
        right.BorderSizePixel = 0
        right.TextColor3 = Color3.new(1,1,1)
        right.Font = Enum.Font.SourceSansBold
        right.TextSize = 13
        right.Parent = Frame
        right.Text = rightLabel
        paintBtn(right, Toggles[rightKey])

        left.MouseButton1Click:Connect(function()
            Toggles[leftKey] = not Toggles[leftKey]
            paintBtn(left, Toggles[leftKey])
        end)
        right.MouseButton1Click:Connect(function()
            Toggles[rightKey] = not Toggles[rightKey]
            paintBtn(right, Toggles[rightKey])
        end)
    end

    -- Full-width toggles
    makeToggle(36,  "Player ESP",       "PlayerESP")
    makeToggle(68,  "Stay Behind",      "StayBehind")
    makeToggle(100, "Auto Target Base", "AutoTargetBase")
    makeToggle(132, "Fallback Closest", "FallbackClosest")

    -- Mini pairs (side-by-side)
    makeMiniPair(164, "Equip RS", "AutoEquipRS", "Loop RS", "AutoActivateRS")
    makeMiniPair(196, "Equip LS", "AutoEquipLS", "Loop LS", "AutoActivateLS")

    -- Target label
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.new(0.92, 0, 0, 22)
    targetLabel.Position = UDim2.new(0.04, 0, 0, 232)
    targetLabel.BackgroundTransparency = 1
    targetLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    targetLabel.Font = Enum.Font.SourceSansSemibold
    targetLabel.TextScaled = true
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.Text = "Target: (none)"
    targetLabel.Parent = Frame

    -- Player list header
    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(0.92, 0, 0, 20)
    hdr.Position = UDim2.new(0.04, 0, 0, 258)
    hdr.BackgroundTransparency = 1
    hdr.TextColor3 = Color3.fromRGB(220,220,220)
    hdr.Font = Enum.Font.SourceSansBold
    hdr.TextScaled = true
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Text = "Players (click to select manual target)"
    hdr.Parent = Frame

    -- Player list
    local list = Instance.new("ScrollingFrame")
    list.Name = "PlayerList"
    list.Size = UDim2.new(0.92, 0, 0, 180)
    list.Position = UDim2.new(0.04, 0, 0, 282)
    list.BackgroundColor3 = Color3.fromRGB(40,40,40)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 6
    list.CanvasSize = UDim2.new(0,0,0,0)
    list.Parent = Frame

    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0,6)
    uiPadding.PaddingBottom = UDim.new(0,6)
    uiPadding.PaddingLeft = UDim.new(0,6)
    uiPadding.PaddingRight = UDim.new(0,6)
    uiPadding.Parent = list

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    layout.Parent = list

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 8)
    end)

    local widgets = {
        ScreenGui = ScreenGui,
        Frame = Frame,
        TargetLabel = targetLabel,
        PlayerList = list,
    }

    -- watchdog: re-parent if nuked
    task.spawn(function()
        while task.wait(0.3) do
            if not ScreenGui.Parent then
                ScreenGui.Parent = getHiddenUi() or CoreGui or player:FindFirstChild("PlayerGui")
            end
        end
    end)

    print("[MiniHub] UI parent:", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "nil")
    return widgets
end

local UI = createGui()

-- ========= Health from Character =========
local function getHealthFromCharacter(char)
    if not char then return nil end
    local attr = char:GetAttribute("Health")
    if attr ~= nil then
        local n = tonumber(attr); if n then return n end
    end
    local nv = char:FindFirstChild("Health")
    if nv and nv:IsA("NumberValue") then
        local n = tonumber(nv.Value); if n then return n end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    return nil
end

-- ========= ESP =========
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
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Toggles.PlayerESP then
                    local hp   = getHealthFromCharacter(char)
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    local bb   = ensureBillboard(hrp)
                    local label= bb:FindFirstChild("Text")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm",
                            p.Name, hp and math.floor(hp) or "?", math.floor(dist))
                    end
                else
                    if hrp:FindFirstChild("Player_ESP") then hrp.Player_ESP:Destroy() end
                end
            end
        end
    end
end

-- ========= Base helpers (for AutoTargetBase) =========
local function plotsFolder() return Workspace:FindFirstChild("Plots") end

local function getPlotOwner(plotModel)
    local sign = plotModel:FindFirstChild("PlotSign")
    local gui  = sign and sign:FindFirstChild("SurfaceGui")
    local fr   = gui and gui:FindFirstChild("Frame")
    local label= fr and fr:FindFirstChild("TextLabel")
    if label and typeof(label.Text) == "string" then
        return label.Text:match("^(.-)'s Base")
    end
end

local function plotAnchorPosition(plot)
    local mainRoot = plot:FindFirstChild("MainRoot")
    if mainRoot and mainRoot:IsA("BasePart") then return mainRoot.Position end
    local hb = plot:FindFirstChild("StealHitBox")
    if hb and hb:IsA("BasePart") then return hb.Position end
    if plot:IsA("Model") and plot.PrimaryPart then return plot.PrimaryPart.Position end
    for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("BasePart") then return d.Position end
    end
    return nil
end

local function autoSelectOwnerByProximity()
    if not Toggles.AutoTargetBase then return end
    local now = os.clock()
    if now - lastAutoSelectCheck < AUTO_SELECT_INTERVAL then return end
    lastAutoSelectCheck = now

    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local pf = plotsFolder()
    if not pf then return end

    local closestPlot, closestDist = nil, math.huge
    for _, plot in ipairs(pf:GetChildren()) do
        local owner = getPlotOwner(plot)
        if owner and owner ~= player.Name then
            local pos = plotAnchorPosition(plot)
            if pos then
                local d = (pos - myHRP.Position).Magnitude
                if d < closestDist then
                    closestDist = d; closestPlot = plot
                end
            end
        end
    end

    local newAutoTarget = nil
    if closestPlot and (closestDist <= BASE_SELECT_RADIUS or BASE_SELECT_RADIUS == math.huge) then
        local ownerName = getPlotOwner(closestPlot)
        if ownerName and ownerName ~= player.Name then
            newAutoTarget = Players:FindFirstChild(ownerName)
        end
    end

    autoSelectedTarget = newAutoTarget
    if refreshHUD then refreshHUD() end
end

-- ========= Manual target list =========
local rowsByPlayer = {}  -- [player] = row

local function setRowSelected(row, isSel)
    if not row then return end
    row.BackgroundColor3 = isSel and Color3.fromRGB(0,110,70) or Color3.fromRGB(55,55,55)
end

local function selectTargetPlayer(plr)
    if selectedTarget == plr then
        if refreshHUD then refreshHUD() end
        return
    end
    if rowsByPlayer[selectedTarget] then setRowSelected(rowsByPlayer[selectedTarget], false) end
    selectedTarget = plr
    if rowsByPlayer[selectedTarget] then setRowSelected(rowsByPlayer[selectedTarget], true) end
    if refreshHUD then refreshHUD() end
end

local function addPlayerRow(plr, order)
    if plr == player then return end
    local list = UI.PlayerList
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(55,55,55)
    row.BorderSizePixel = 0
    row.AutoButtonColor = true
    row.LayoutOrder = order or 0
    row.Text = ""
    row.Parent = list

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSans
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = string.format("%s  (%d)", plr.Name, plr.UserId)
    lbl.Parent = row

    row.MouseButton1Click:Connect(function()
        selectTargetPlayer(plr)
    end)

    rowsByPlayer[plr] = row
    if selectedTarget == plr then setRowSelected(row, true) end
end

rebuildPlayerList = function()
    for plr, row in pairs(rowsByPlayer) do
        if row and row.Parent then row:Destroy() end
    end
    rowsByPlayer = {}
    local list = Players:GetPlayers()
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)
    local order = 1
    for _, plr in ipairs(list) do
        addPlayerRow(plr, order); order += 1
    end
end

Players.PlayerAdded:Connect(rebuildPlayerList)
Players.PlayerRemoving:Connect(function(rem)
    if selectedTarget == rem then selectTargetPlayer(nil) end
    if autoSelectedTarget == rem then autoSelectedTarget = nil end
    rebuildPlayerList()
end)
task.defer(rebuildPlayerList)

-- ========= HUD label updater =========
refreshHUD = function()
    local active = autoSelectedTarget or selectedTarget
    UI.TargetLabel.Text = string.format(
        "Target: %s%s",
        (active and active.Name or "(none)"),
        (Toggles.AutoTargetBase and active == autoSelectedTarget) and "  [AUTO]"
            or (active and active == selectedTarget) and "  [MANUAL]" or ""
    )
end

-- ========= Target selection for follow =========
local function currentFollowTarget(myHRP)
    -- Priority: AUTO → MANUAL → CLOSEST (if toggle)
    if Toggles.AutoTargetBase and autoSelectedTarget then
        return autoSelectedTarget
    end
    if selectedTarget then
        return selectedTarget
    end
    if Toggles.FallbackClosest then
        local closest, best = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local char = p.Character
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                local hp   = getHealthFromCharacter(char)
                if hrp and hp and hp > 0 then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < best then closest, best = p, d end
                end
            end
        end
        return closest
    end
    return nil
end

-- ========= Stay Behind movement =========
local BEHIND_DISTANCE, VERTICAL_OFFSET = 3.5, 1.5
local function doStayBehind(myHRP)
    local target = currentFollowTarget(myHRP)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local thp  = getHealthFromCharacter(target.Character)
    if not tHRP or not thp or thp <= 0 then return end

    local desiredPos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
    local lookAt     = desiredPos + tHRP.CFrame.LookVector
    myHRP.CFrame = CFrame.new(desiredPos, lookAt)
end

-- ========= Tool Helpers =========
local RainbowrathNames = { "Rainbowrath Sword", "Rainbowrath", "RainbowrathSword" }
local LavaSlapNames    = { "Lava Slap", "LavaSlap", "Lava Slap Glove" }

local function findToolByNames(container, names)
    if not container then return nil end
    for _, n in ipairs(names) do
        local t = container:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
    end
    -- fuzzy fallback
    for _, inst in ipairs(container:GetChildren()) do
        if inst:IsA("Tool") then
            local nm = inst.Name:lower()
            for _, n in ipairs(names) do
                if nm:find(n:lower(), 1, true) then
                    return inst
                end
            end
        end
    end
    return nil
end

local function keepEquipped(names, enabled)
    if not enabled then return end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if not char or not backpack then return end
    if findToolByNames(char, names) then return end
    local tool = findToolByNames(backpack, names)
    if tool then tool.Parent = char end
end

local lastRSActivate, lastLSActivate = 0, 0
local ACTIVATE_INTERVAL = 0.46

local function activateTool(names, enabled, lastRefName)
    if not enabled then return end
    local now = os.clock()
    if now - _G[lastRefName] < ACTIVATE_INTERVAL then return end
    local char = player.Character
    if not char then return end
    local tool = findToolByNames(char, names)
    if tool then
        _G[lastRefName] = now
        pcall(function() tool:Activate() end)
    end
end
_G._lastRS = lastRSActivate
_G._lastLS = lastLSActivate

-- ========= Main loop =========
RunService.Heartbeat:Connect(function()
    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- Auto-target by base proximity (runs on its own cadence)
    autoSelectOwnerByProximity()

    -- Keep tools equipped / activate if requested
    keepEquipped(RainbowrathNames, Toggles.AutoEquipRS)
    keepEquipped(LavaSlapNames,    Toggles.AutoEquipLS)
    activateTool(RainbowrathNames, Toggles.AutoActivateRS, "_lastRS")
    activateTool(LavaSlapNames,    Toggles.AutoActivateLS, "_lastLS")

    if Toggles.PlayerESP then
        updateESP(myHRP)
    end

    if Toggles.StayBehind then
        doStayBehind(myHRP)
    end
end)
