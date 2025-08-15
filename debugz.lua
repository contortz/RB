--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote (ShopService/Purchase)
local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local PurchaseRE = NetFolder:FindFirstChild("RE/ShopService/Purchase")

-- Floor → ProductId map (Arg 1)
local ProductIds = {
    [1] = 3312023518, -- Floor 1
    [2] = 3312023590, -- Floor 2
    [3] = 3312023715, -- Floor 3
}

-- ===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseUnlockHelper"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 520) -- taller to fit player list + floor picker
frame.Position = UDim2.new(0, 24, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "Base Unlock Helper"
title.Parent = frame

local function makeButton(y, text, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 28)
    b.Position = UDim2.new(0, 6, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.Gotham
    b.Text = text
    b.Parent = frame
    b.MouseButton1Click:Connect(function() onClick(b) end)
    return b
end

-- Tiny banner for “press OK/price” fallback
local confirmBanner = Instance.new("TextLabel")
confirmBanner.Size = UDim2.new(1, -12, 0, 24)
confirmBanner.Position = UDim2.new(0, 6, 0, 6)
confirmBanner.BackgroundColor3 = Color3.fromRGB(60, 60, 20)
confirmBanner.TextColor3 = Color3.fromRGB(255, 255, 180)
confirmBanner.TextScaled = true
confirmBanner.Font = Enum.Font.GothamBold
confirmBanner.Text = ""
confirmBanner.Visible = false
confirmBanner.Parent = frame

-- HUD
local baseInfoLabel = Instance.new("TextLabel")
baseInfoLabel.Size = UDim2.new(1, -10, 0, 26)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 120)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1,1,1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"
baseInfoLabel.Parent = frame

local slotInfoLabel = Instance.new("TextLabel")
slotInfoLabel.Size = UDim2.new(1, -10, 0, 26)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 150)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1,1,1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.Parent = frame

-- === Players list (Name — UserId) ===
local playersHeader = Instance.new("TextLabel")
playersHeader.Size = UDim2.new(1, -10, 0, 22)
playersHeader.Position = UDim2.new(0, 5, 0, 184)
playersHeader.BackgroundTransparency = 1
playersHeader.TextColor3 = Color3.fromRGB(200, 220, 255)
playersHeader.TextScaled = true
playersHeader.Font = Enum.Font.GothamSemibold
playersHeader.Text = "Players (tap to select)"
playersHeader.Parent = frame

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -12, 0, 220)
playerList.Position = UDim2.new(0, 6, 0, 210)
playerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 6
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.Parent = frame

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 6)
uiPadding.PaddingBottom = UDim.new(0, 6)
uiPadding.PaddingLeft = UDim.new(0, 6)
uiPadding.PaddingRight = UDim.new(0, 6)
uiPadding.Parent = playerList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = playerList

local function autoSizeCanvas()
    playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoSizeCanvas)

-- Selection state for target player
local selectedTarget: Player? = nil
local selectedRow: Instance? = nil

local function setRowSelected(row, isSel)
    if not row then return end
    row.BackgroundColor3 = isSel and Color3.fromRGB(0, 110, 70) or Color3.fromRGB(55, 55, 55)
end

-- Selected target display + floor picker
local pickerBox = Instance.new("Frame")
pickerBox.Size = UDim2.new(1, -12, 0, 72)
pickerBox.Position = UDim2.new(0, 6, 0, 440)
pickerBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
pickerBox.BorderSizePixel = 0
pickerBox.Parent = frame

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -8, 0, 22)
selectedLabel.Position = UDim2.new(0, 4, 0, 4)
selectedLabel.BackgroundTransparency = 1
selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
selectedLabel.Font = Enum.Font.GothamSemibold
selectedLabel.TextScaled = true
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Text = "Selected: (none)"
selectedLabel.Parent = pickerBox

local buttonsRow = Instance.new("Frame")
buttonsRow.Size = UDim2.new(1, -8, 0, 36)
buttonsRow.Position = UDim2.new(0, 4, 0, 30)
buttonsRow.BackgroundTransparency = 1
buttonsRow.Parent = pickerBox

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rowLayout.Padding = UDim.new(0, 6)
rowLayout.Parent = buttonsRow

local function smallBtn(txt, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 88, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.Gotham
    b.Text = txt
    b.Parent = buttonsRow
    b.MouseButton1Click:Connect(onClick)
    return b
end

local function purchaseForSelected(floor)
    if not selectedTarget then
        confirmBanner.Text = "Select a player first"
        confirmBanner.Visible = true
        task.delay(1.5, function() if confirmBanner then confirmBanner.Visible = false end end)
        return
    end
    local productId = ProductIds[floor]
    if not (PurchaseRE and productId) then
        confirmBanner.Text = "Purchase remote not found"
        confirmBanner.Visible = true
        task.delay(1.5, function() if confirmBanner then confirmBanner.Visible = false end end)
        return
    end
    local userId = selectedTarget.UserId -- Arg 2
    -- Fire: Arg1=ProductId (floor), Arg2=UserId (target)
    PurchaseRE:FireServer(productId, userId)
    confirmBanner.Text = ("Sent: %s → Floor %d"):format(selectedTarget.Name, floor)
    confirmBanner.Visible = true
    task.delay(1.2, function() if confirmBanner then confirmBanner.Visible = false end end)
end

smallBtn("Floor 1", function() purchaseForSelected(1) end)
smallBtn("Floor 2", function() purchaseForSelected(2) end)
smallBtn("Floor 3", function() purchaseForSelected(3) end)

-- Build each player row (clickable)
local function addPlayerRow(plr, order)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    row.BorderSizePixel = 0
    row.AutoButtonColor = true
    row.LayoutOrder = order or 0
    row.Text = ""
    row.Parent = playerList

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Text = string.format("%s — %d", plr.Name, plr.UserId)
    lbl.Parent = row

    row.MouseButton1Click:Connect(function()
        if selectedRow and selectedRow ~= row then setRowSelected(selectedRow, false) end
        selectedRow = row
        setRowSelected(row, true)
        selectedTarget = plr
        selectedLabel.Text = string.format("Selected: %s (%d)", plr.Name, plr.UserId)
    end)

    return row
end

local function rebuildPlayerList()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local list = Players:GetPlayers()
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)

    selectedRow = nil
    selectedTarget = nil
    selectedLabel.Text = "Selected: (none)"

    for i, plr in ipairs(list) do
        addPlayerRow(plr, i)
    end
    autoSizeCanvas()
end

Players.PlayerAdded:Connect(rebuildPlayerList)
Players.PlayerRemoving:Connect(function(rem)
    if selectedTarget == rem then
        selectedTarget = nil
        selectedRow = nil
        selectedLabel.Text = "Selected: (none)"
    end
    rebuildPlayerList()
end)
task.defer(rebuildPlayerList)

-- ===== Base info (unchanged) =====
local function findLocalPlayerBase()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")
        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == player.Name then
                baseInfoLabel.Text = ("🏠 Base: %s | Tier: %s"):format(plot.Name, tostring(plot:GetAttribute("Tier") or "?"))
                local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled, total = 0, 0
                    for _, podium in ipairs(animalPodiums:GetChildren()) do
                        if podium:IsA("Model") then
                            local base = podium:FindFirstChild("Base")
                            local spawn = base and base:FindFirstChild("Spawn")
                            if spawn and spawn:IsA("BasePart") then
                                total += 1
                                if spawn:FindFirstChild("Attachment") then
                                    filled += 1
                                end
                            end
                        end
                    end
                    slotInfoLabel.Text = ("Slots: %d / %d"):format(filled, total)
                end
                break
            end
        end
    end
end
task.delay(1, findLocalPlayerBase)

-- ===== State / consts =====
local unlockClosestBase = false      -- Toggle 1
local autoConfirmUnlock = false      -- Toggle 2

local MAX_DIST = 999999
local DEFAULT_DIST = 15
local RETUNE_INTERVAL = 0.10
local lastTune = 0

-- auto-confirm throttles + phasing
local PRICE_MIN, PRICE_MAX = 39, 50
local lastConfirmAt = 0
local CONFIRM_COOLDOWN = 1.2
local confirmPhase = "idle"     -- "idle" | "price_pressed"
local PHASE_TIMEOUT = 3.0
local phaseUntil = 0

local originalPromptDist = setmetatable({}, { __mode = "k" })

-- ===== Helpers (plot + prompts) =====
local function plotsFolder() return Workspace:FindFirstChild("Plots") end

local function getPlotOwner(plotModel)
    local sign = plotModel:FindFirstChild("PlotSign")
    local gui = sign and sign:FindFirstChild("SurfaceGui")
    local fr = gui and gui:FindFirstChild("Frame")
    local label = fr and fr:FindFirstChild("TextLabel")
    if label and label.Text then
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

local function getPlotByName(name)
    local plots = plotsFolder()
    if not plots then return nil end
    return plots:FindFirstChild(name)
end

local function isUnlockPrompt(d)
    return d:IsA("ProximityPrompt")
       and (d.Name == "UnlockBase"
            or (typeof(d.ActionText) == "string" and d.ActionText:sub(1, 11) == "Unlock Base"))
end

local function actionTextWithFloor(prompt)
    local floorAttr = prompt:GetAttribute("Floor")
    if floorAttr ~= nil then
        return ("Unlock Base (%s)"):format(tostring(floorAttr))
    end
    return "Unlock Base"
end

local function getAllUnlockPromptsMapped()
    local mapped = {}
    local plots = plotsFolder()
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local unlock = plot:FindFirstChild("Unlock")
            if unlock then
                for _, d in ipairs(unlock:GetDescendants()) do
                    if isUnlockPrompt(d) then
                        table.insert(mapped, {prompt = d, plot = plot})
                    end
                end
            end
        end
    end
    local globalUnlock = Workspace:FindFirstChild("Unlock")
    if globalUnlock then
        for _, holder in ipairs(globalUnlock:GetChildren()) do
            local plot = getPlotByName(holder.Name)
            for _, d in ipairs(holder:GetDescendants()) do
                if isUnlockPrompt(d) then
                    if not plot then
                        local parent, pos = d.Parent, nil
                        if parent then
                            if parent:IsA("BasePart") then pos = parent.Position
                            elseif parent:IsA("Model") and parent.PrimaryPart then pos = parent.PrimaryPart.Position end
                        end
                        if pos then
                            local best, bestD = nil, math.huge
                            local pf = plotsFolder()
                            if pf then
                                for _, p in ipairs(pf:GetChildren()) do
                                    local a = plotAnchorPosition(p)
                                    if a then
                                        local dd = (a - pos).Magnitude
                                        if dd < bestD then bestD = dd; best = p end
                                    end
                                end
                            end
                            plot = best
                        end
                    end
                    table.insert(mapped, {prompt = d, plot = plot})
                end
            end
        end
    end
    return mapped
end

local function setPromptDistance(prompt, dist)
    if originalPromptDist[prompt] == nil then
        originalPromptDist[prompt] = prompt.MaxActivationDistance
    end
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.ActionText = actionTextWithFloor(prompt)
    prompt.MaxActivationDistance = dist
end

local function restoreAllPromptDistances()
    for _, pair in ipairs(getAllUnlockPromptsMapped()) do
        local prompt = pair.prompt
        local orig = originalPromptDist[prompt]
        prompt.ActionText = actionTextWithFloor(prompt)
        prompt.MaxActivationDistance = typeof(orig) == "number" and orig or DEFAULT_DIST
    end
end

-- ===== Auto-confirm helpers (two-phase, iPad-friendly) =====
local function looksLikeOK(s)
    if typeof(s) ~= "string" then return false end
    s = s:lower():gsub("%s+", "")
    return (s == "ok" or s == "okay" or s == "ok!")
end

local function findNumberNodeIn(root, minV, maxV)
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and typeof(d.Text) == "string" then
            local num = d.Text:match("(%d+)")
            if num then
                local val = tonumber(num)
                if val and val >= minV and val <= maxV then
                    return d, val
                end
            end
        end
    end
    return nil
end

local function holderHasOK(holder)
    if not holder then return nil end
    for _, d in ipairs(holder:GetDescendants()) do
        if d:IsA("TextLabel") and looksLikeOK(d.Text) then
            return d
        end
    end
    local btnContent = holder:FindFirstChild("ButtonContent", true)
    local mid = btnContent and btnContent:FindFirstChild("ButtonMiddleContent", true)
    if mid then
        local icon = mid:FindFirstChild("Icon") or mid:FindFirstChild("ImageLabel")
        if icon then return icon end
    end
    return nil
end

local function clickableIn(holder)
    if not holder then return nil end
    if holder:IsA("TextButton") or holder:IsA("ImageButton") then return holder end
    return holder:FindFirstChildWhichIsA("TextButton", true)
        or holder:FindFirstChildWhichIsA("ImageButton", true)
end

local function pressButton(btn)
    if not btn then return false end
    local ok = false
    if btn.Activate then
        ok = pcall(function() btn:Activate() end)
    end
    if not ok and typeof(firesignal) == "function" then
        pcall(function()
            if btn.MouseButton1Down then firesignal(btn.MouseButton1Down) end
            if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
            if btn.MouseButton1Up then firesignal(btn.MouseButton1Up) end
            if btn.Activated then firesignal(btn.Activated) end
        end)
        ok = true
    end
    return ok
end

-- One-shot binding: next real input activates targetBtn, then runs afterFn (if any)
local _oneTapConn
local function bindOneTapPress(targetBtn, afterFn)
    if _oneTapConn then _oneTapConn:Disconnect() end
    _oneTapConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local t, k = input.UserInputType, input.KeyCode
        if t == Enum.UserInputType.Touch
        or t == Enum.UserInputType.MouseButton1
        or k == Enum.KeyCode.Return
        or k == Enum.KeyCode.KeypadEnter
        or k == Enum.KeyCode.ButtonA then
            pressButton(targetBtn)
            if afterFn then pcall(afterFn) end
            if _oneTapConn then _oneTapConn:Disconnect() _oneTapConn = nil end
            confirmBanner.Visible = false
        end
    end)
end

local lastConfirmAt = 0
local CONFIRM_COOLDOWN = 1.2
local confirmPhase = "idle"
local PHASE_TIMEOUT = 3.0
local PRICE_MIN, PRICE_MAX = 39, 50
local phaseUntil = 0

-- Two-phase: Phase1 press the price (39..50) -> Buttons.1, then Phase2 press OK (1 or 2)
local function tryConfirmPurchase()
    if not autoConfirmUnlock then return end
    if os.clock() - lastConfirmAt < CONFIRM_COOLDOWN then return end

    local root = CoreGui:FindFirstChild("PurchasePromptApp"); if not root then return end
    local container = root:FindFirstChild("ProductPurchaseContainer"); if not container then return end
    local animator = container:FindFirstChild("Animator"); if not animator then return end
    local prompt = animator:FindFirstChild("Prompt"); if not prompt then return end
    local controls = prompt:FindFirstChild("AlertControls"); if not controls then return end
    local footer = controls:FindFirstChild("Footer"); if not footer then return end
    local buttons = footer:FindFirstChild("Buttons"); if not buttons then return end

    local holder1 = buttons:FindFirstChild("1")
    local holder2 = buttons:FindFirstChild("2")

    if confirmPhase ~= "price_pressed" then
        local anyNumNode, price = findNumberNodeIn(prompt, PRICE_MIN, PRICE_MAX)
        if not anyNumNode then return end
        local tapBtn = clickableIn(holder1)
        if not tapBtn then return end

        local pressed = pressButton(tapBtn)
        if not pressed then
            confirmBanner.Text = ("Tap price to continue (%d)"):format(price)
            confirmBanner.Visible = true
            bindOneTapPress(tapBtn, function()
                confirmPhase = "price_pressed"
                phaseUntil = os.clock() + PHASE_TIMEOUT
                lastConfirmAt = os.clock()
            end)
            return
        end

        confirmPhase = "price_pressed"
        phaseUntil = os.clock() + PHASE_TIMEOUT
        lastConfirmAt = os.clock()
        return
    end

    if os.clock() > phaseUntil then
        confirmPhase = "idle"
        return
    end

    local okNodeH1 = holderHasOK(holder1)
    local okNodeH2 = holderHasOK(holder2)
    local targetBtn =
        (okNodeH1 and clickableIn(holder1)) or
        (okNodeH2 and clickableIn(holder2)) or
        clickableIn(holder2) or clickableIn(holder1)

    if not targetBtn then return end

    local pressedOK = pressButton(targetBtn)
    if not pressedOK then
        confirmBanner.Text = "Tap OK to confirm"
        confirmBanner.Visible = true
        pcall(function() GuiService.SelectedObject = targetBtn end)
        bindOneTapPress(targetBtn, function()
            confirmPhase = "idle"
            lastConfirmAt = os.clock()
        end)
        return
    end

    confirmPhase = "idle"
    lastConfirmAt = os.clock()
end

-- ===== Main loop: choose closest ENEMY plot (by MainRoot) and boost its prompts =====
local unlockClosestBase = false
local autoConfirmUnlock = false
local MAX_DIST, DEFAULT_DIST = 999999, 15
local RETUNE_INTERVAL, lastTune = 0.10, 0
local originalPromptDist = setmetatable({}, { __mode = "k" })

local function getAllUnlockPromptsMapped()
    local mapped = {}
    local function isUnlockPrompt(d)
        return d:IsA("ProximityPrompt")
           and (d.Name == "UnlockBase"
                or (typeof(d.ActionText) == "string" and d.ActionText:sub(1, 11) == "Unlock Base"))
    end
    local function actionTextWithFloor(prompt)
        local floorAttr = prompt:GetAttribute("Floor")
        if floorAttr ~= nil then
            return ("Unlock Base (%s)"):format(tostring(floorAttr))
        end
        return "Unlock Base"
    end
    local function setPromptDistance(prompt, dist)
        if originalPromptDist[prompt] == nil then
            originalPromptDist[prompt] = prompt.MaxActivationDistance
        end
        prompt.RequiresLineOfSight = false
        prompt.ClickablePrompt = true
        prompt.ActionText = actionTextWithFloor(prompt)
        prompt.MaxActivationDistance = dist
    end

    -- expose helpers to outer scope
    _G.__setPromptDistance = setPromptDistance
    _G.__actionTextWithFloor = actionTextWithFloor

    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local unlock = plot:FindFirstChild("Unlock")
            if unlock then
                for _, d in ipairs(unlock:GetDescendants()) do
                    if isUnlockPrompt(d) then
                        table.insert(mapped, {prompt = d, plot = plot})
                    end
                end
            end
        end
    end
    local function plotsFolder() return Workspace:FindFirstChild("Plots") end
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
    local function getPlotByName(name)
        local plots = plotsFolder()
        if not plots then return nil end
        return plots:FindFirstChild(name)
    end

    local globalUnlock = Workspace:FindFirstChild("Unlock")
    if globalUnlock then
        for _, holder in ipairs(globalUnlock:GetChildren()) do
            local plot = getPlotByName(holder.Name)
            for _, d in ipairs(holder:GetDescendants()) do
                if isUnlockPrompt(d) then
                    if not plot then
                        local parent, pos = d.Parent, nil
                        if parent then
                            if parent:IsA("BasePart") then pos = parent.Position
                            elseif parent:IsA("Model") and parent.PrimaryPart then pos = parent.PrimaryPart.Position end
                        end
                        if pos then
                            local best, bestD = nil, math.huge
                            local pf = plotsFolder()
                            if pf then
                                for _, p in ipairs(pf:GetChildren()) do
                                    local a = plotAnchorPosition(p)
                                    if a then
                                        local dd = (a - pos).Magnitude
                                        if dd < bestD then bestD = dd; best = p end
                                    end
                                end
                            end
                            plot = best
                        end
                    end
                    table.insert(mapped, {prompt = d, plot = plot})
                end
            end
        end
    end
    return mapped
end

local function setPromptDistance(prompt, dist)
    _G.__setPromptDistance(prompt, dist)
end
local function actionTextWithFloor(prompt)
    return _G.__actionTextWithFloor(prompt)
end

local function restoreAllPromptDistances()
    for _, pair in ipairs(getAllUnlockPromptsMapped()) do
        local prompt = pair.prompt
        local orig = originalPromptDist[prompt]
        prompt.ActionText = actionTextWithFloor(prompt)
        prompt.MaxActivationDistance = typeof(orig) == "number" and orig or DEFAULT_DIST
    end
end

RunService.Heartbeat:Connect(function()
    if os.clock() - lastTune < RETUNE_INTERVAL then return end
    lastTune = os.clock()

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pairsList = getAllUnlockPromptsMapped()

    if unlockClosestBase and #pairsList > 0 then
        local plots = Workspace:FindFirstChild("Plots")
        local function getPlotOwner(plotModel)
            local sign = plotModel:FindFirstChild("PlotSign")
            local gui = sign and sign:FindFirstChild("SurfaceGui")
            local fr = gui and gui:FindFirstChild("Frame")
            local label = fr and fr:FindFirstChild("TextLabel")
            if label and label.Text then
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

        local closestEnemyPlot, closestDist = nil, math.huge
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                local owner = getPlotOwner(plot)
                if owner ~= player.Name then
                    local anchor = plotAnchorPosition(plot)
                    if anchor then
                        local d = (anchor - hrp.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closestEnemyPlot = plot
                        end
                    end
                end
            end
        end

        if closestEnemyPlot then
            for _, pair in ipairs(pairsList) do
                if pair.plot == closestEnemyPlot then
                    setPromptDistance(pair.prompt, MAX_DIST)
                else
                    setPromptDistance(pair.prompt, DEFAULT_DIST)
                end
            end
        else
            for _, pair in ipairs(pairsList) do
                setPromptDistance(pair.prompt, DEFAULT_DIST)
            end
        end
    end

    -- Auto-confirm if a purchase prompt is open
    tryConfirmPurchase()

    -- Cleanup binding/banner if prompt closed
    if not CoreGui:FindFirstChild("PurchasePromptApp") then
        if _oneTapConn then _oneTapConn:Disconnect() _oneTapConn = nil end
        if confirmBanner.Visible then confirmBanner.Visible = false end
        confirmPhase = "idle"
    end
end)

-- Toggles
local btn1 = makeButton(40, "Unlock Closest Base Only (OFF)", function(b)
    unlockClosestBase = not unlockClosestBase
    b.Text = unlockClosestBase and "Unlock Closest Base Only (ON)" or "Unlock Closest Base Only (OFF)"
    b.BackgroundColor3 = unlockClosestBase and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
    if not unlockClosestBase then restoreAllPromptDistances() end
end)

local btn2 = makeButton(74, "Auto-Confirm (39–50 then OK) (OFF)", function(b)
    autoConfirmUnlock = not autoConfirmUnlock
    b.Text = autoConfirmUnlock and "Auto-Confirm (39–50 then OK) (ON)" or "Auto-Confirm (39–50 then OK) (OFF)"
    b.BackgroundColor3 = autoConfirmUnlock and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end)

-- Defensive reset on respawn (when feature is off)
player.CharacterAdded:Connect(function()
    if not unlockClosestBase then
        task.delay(1, restoreAllPromptDistances)
        task.delay(1, findLocalPlayerBase)
    end
end)
