--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseUnlockHelper"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0, 24, 0.5, -100)
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

-- HUD
local baseInfoLabel = Instance.new("TextLabel")
baseInfoLabel.Size = UDim2.new(1, -10, 0, 26)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 112)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1,1,1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"
baseInfoLabel.Parent = frame

local slotInfoLabel = Instance.new("TextLabel")
slotInfoLabel.Size = UDim2.new(1, -10, 0, 26)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 142)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1,1,1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.Parent = frame

-- Show your base info
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
                                total = total + 1
                                if spawn:FindFirstChild("Attachment") then
                                    filled = filled + 1
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

local lastConfirmAt = 0
local CONFIRM_COOLDOWN = 1.2

local originalPromptDist = setmetatable({}, { __mode = "k" }) -- weak keys

-- ===== Helpers =====
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

-- Preferred anchor position: MainRoot; then StealHitBox; then PrimaryPart; then any BasePart
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

-- Identify unlock prompts robustly (name or ActionText prefix)
local function isUnlockPrompt(d)
    return d:IsA("ProximityPrompt")
       and (d.Name == "UnlockBase"
            or (typeof(d.ActionText) == "string" and d.ActionText:sub(1, 11) == "Unlock Base"))
end

-- Build the ActionText with Floor tag if present
local function actionTextWithFloor(prompt)
    local floorAttr = prompt:GetAttribute("Floor")
    if floorAttr ~= nil then
        return ("Unlock Base (%s)"):format(tostring(floorAttr))
    end
    return "Unlock Base"
end

-- Collect prompts from BOTH layouts:
--  A) Workspace.Plots.<plot>.Unlock...
--  B) Workspace.Unlock.<plotName>...
local function getAllUnlockPromptsMapped()
    -- returns array of {prompt = ProximityPrompt, plot = Model}
    local mapped = {}

    -- A) per-plot Unlock
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

    -- B) Workspace.Unlock.<plotName>...
    local globalUnlock = Workspace:FindFirstChild("Unlock")
    if globalUnlock then
        for _, holder in ipairs(globalUnlock:GetChildren()) do
            local plot = getPlotByName(holder.Name)
            for _, d in ipairs(holder:GetDescendants()) do
                if isUnlockPrompt(d) then
                    if not plot then
                        -- fallback: nearest plot to this prompt
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
    prompt.ActionText = actionTextWithFloor(prompt) -- keep label with Floor tag
    prompt.MaxActivationDistance = dist
    -- Debug: print(("[SetDist] %s -> %d"):format(prompt:GetFullName(), dist))
end

local function restoreAllPromptDistances()
    for _, pair in ipairs(getAllUnlockPromptsMapped()) do
        local prompt = pair.prompt
        local orig = originalPromptDist[prompt]
        prompt.ActionText = actionTextWithFloor(prompt)
        prompt.MaxActivationDistance = typeof(orig) == "number" and orig or DEFAULT_DIST
    end
end

-- ===== Auto-confirm helpers =====
local function looksLikeOK(s)
    if typeof(s) ~= "string" then return false end
    s = s:lower():gsub("%s+", "")
    return (s == "ok" or s == "okay" or s == "ok!")
end

-- Scan any Text-like descendants for the first number; return number (or nil)
local function findNumberInText(root)
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and typeof(d.Text) == "string" then
            local num = d.Text:match("(%d+)")
            if num then
                return tonumber(num), d
            end
        end
    end
    return nil
end

-- Find the actual OK button inside Buttons.1, ensuring its label says "OK"
local function findOKButton(buttons)
    local holder = buttons:FindFirstChild("1")
    if not holder then return nil end

    -- Usually a nested TextButton/ImageButton exists
    local btn = holder:FindFirstChildWhichIsA("TextButton", true)
             or holder:FindFirstChildWhichIsA("ImageButton", true)
             or (holder:IsA("TextButton") and holder)
             or (holder:IsA("ImageButton") and holder)

    if not btn then return nil end

    -- Your path: ButtonContent.ButtonMiddleContent.Text
    local okLabel = holder:FindFirstChild("ButtonContent", true)
    okLabel = okLabel and okLabel:FindFirstChild("ButtonMiddleContent", true)
    okLabel = okLabel and okLabel:FindFirstChild("Text", true)

    -- Fallback: any TextLabel saying OK
    if not okLabel then
        for _, d in ipairs(holder:GetDescendants()) do
            if d:IsA("TextLabel") and looksLikeOK(d.Text) then
                okLabel = d
                break
            end
        end
    end

    if okLabel and looksLikeOK(okLabel.Text) then
        return btn
    end
    return nil
end

-- Auto-confirm purchase (OK) with price guard [30..50]
local function tryConfirmPurchase()
    if not autoConfirmUnlock then return end
    if typeof(firesignal) ~= "function" then return end
    if os.clock() - lastConfirmAt < CONFIRM_COOLDOWN then return end

    local root = CoreGui:FindFirstChild("PurchasePromptApp"); if not root then return end
    local container = root:FindFirstChild("ProductPurchaseContainer"); if not container then return end
    local animator = container:FindFirstChild("Animator"); if not animator then return end
    local prompt = animator:FindFirstChild("Prompt"); if not prompt then return end
    local controls = prompt:FindFirstChild("AlertControls"); if not controls then return end
    local footer = controls:FindFirstChild("Footer"); if not footer then return end
    local buttons = footer:FindFirstChild("Buttons"); if not buttons then return end

    -- Ensure a number 30..50 is present in the prompt text
    local num = findNumberInText(prompt)
    if not num or num < 30 or num > 50 then
        return
    end

    -- Find the OK button (Buttons.1 … OK)
    local okBtn = findOKButton(buttons)
    if not okBtn then return end

    -- Click it (firesignal), once per cooldown
    pcall(function()
        if okBtn.MouseButton1Click then firesignal(okBtn.MouseButton1Click) end
        if okBtn.Activated then firesignal(okBtn.Activated) end
    end)
    lastConfirmAt = os.clock()
end

-- ===== Main loop: choose closest ENEMY plot (by MainRoot) and boost its prompts =====
RunService.Heartbeat:Connect(function()
    if not unlockClosestBase then return end
    if os.clock() - lastTune < RETUNE_INTERVAL then return end
    lastTune = os.clock()

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pairsList = getAllUnlockPromptsMapped()
    if #pairsList == 0 then return end

    -- Determine the enemy plot closest to YOU
    local pf = plotsFolder()
    local closestEnemyPlot, closestDist = nil, math.huge
    if pf then
        for _, plot in ipairs(pf:GetChildren()) do
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

    if not closestEnemyPlot then
        -- No enemy plots? normalize all
        for _, pair in ipairs(pairsList) do
            setPromptDistance(pair.prompt, DEFAULT_DIST)
        end
        return
    end

    -- Apply distances; also keep ActionText updated with Floor tag
    for _, pair in ipairs(pairsList) do
        if pair.plot == closestEnemyPlot then
            setPromptDistance(pair.prompt, MAX_DIST)
        else
            setPromptDistance(pair.prompt, DEFAULT_DIST)
        end
    end

    tryConfirmPurchase()
end)

-- Toggles
local btn1 = makeButton(40, "Unlock Closest Base Only (OFF)", function(b)
    unlockClosestBase = not unlockClosestBase
    b.Text = unlockClosestBase and "Unlock Closest Base Only (ON)" or "Unlock Closest Base Only (OFF)"
    b.BackgroundColor3 = unlockClosestBase and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
    if not unlockClosestBase then restoreAllPromptDistances() end
end)

local btn2 = makeButton(74, "Auto-Confirm Unlock (OFF)", function(b)
    autoConfirmUnlock = not autoConfirmUnlock
    b.Text = autoConfirmUnlock and "Auto-Confirm Unlock (ON)" or "Auto-Confirm Unlock (OFF)"
    b.BackgroundColor3 = autoConfirmUnlock and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end)

-- Defensive reset on respawn (when feature is off)
player.CharacterAdded:Connect(function()
    if not unlockClosestBase then
        task.delay(1, restoreAllPromptDistances)
        task.delay(1, findLocalPlayerBase)
    end
end)
