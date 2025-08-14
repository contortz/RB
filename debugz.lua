--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseUnlockHelper"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 180)
frame.Position = UDim2.new(0, 20, 0.5, -90)
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

-- Debug HUD labels
local baseInfoLabel = Instance.new("TextLabel")
baseInfoLabel.Size = UDim2.new(1, -10, 0, 26)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 110)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1,1,1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"
baseInfoLabel.Parent = frame

local slotInfoLabel = Instance.new("TextLabel")
slotInfoLabel.Size = UDim2.new(1, -10, 0, 26)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 140)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1,1,1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.Parent = frame

-- Show your base name/tier + slots filled/total
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
                local tier = plot:GetAttribute("Tier")
                baseInfoLabel.Text = "🏠 Base: " .. plot.Name .. " | Tier: " .. tostring(tier or "?")

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
                    slotInfoLabel.Text = "Slots: " .. filled .. " / " .. total
                end
                break
            end
        end
    end
end
task.delay(1, findLocalPlayerBase)

--// State
local unlockClosestBase = false      -- Toggle 1
local autoConfirmUnlock = false      -- Toggle 2

local MAX_DIST = 999999
local DEFAULT_DIST = 15
local RETUNE_INTERVAL = 0.1
local lastTune = 0

-- Cache original distances so we can restore
local originalDist = setmetatable({}, { __mode = "k" }) -- weak keys

-- Helpers
local function getPlotOwner(plotModel)
    local sign = plotModel:FindFirstChild("PlotSign")
    local gui = sign and sign:FindFirstChild("SurfaceGui")
    local fr = gui and gui:FindFirstChild("Frame")
    local label = fr and fr:FindFirstChild("TextLabel")
    if label and label.Text then
        return label.Text:match("^(.-)'s Base")
    end
end

local function getUnlockPrompt(plotModel)
    -- Path: Workspace.Plots.<plot>.Unlock.Main.UnlockBase (ProximityPrompt)
    local unlock = plotModel:FindFirstChild("Unlock")
    local main = unlock and unlock:FindFirstChild("Main")
    local prompt = main and main:FindFirstChild("UnlockBase")
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end
end

local function restoreAllPromptDistances()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local prompt = getUnlockPrompt(plot)
        if prompt then
            local orig = originalDist[prompt]
            if typeof(orig) == "number" then
                prompt.MaxActivationDistance = orig
            else
                prompt.MaxActivationDistance = DEFAULT_DIST
            end
        end
    end
end

-- Auto-confirm purchase (Yes) – avoids VirtualInputManager
local function tryConfirmPurchase()
    if not autoConfirmUnlock then return end
    local root = CoreGui:FindFirstChild("PurchasePromptApp")
    if not root then return end

    local container = root:FindFirstChild("ProductPurchaseContainer")
    local animator = container and container:FindFirstChild("Animator")
    local prompt = animator and animator:FindFirstChild("Prompt")
    local controls = prompt and prompt:FindFirstChild("AlertControls")
    local footer = controls and controls:FindFirstChild("Footer")
    local buttons = footer and footer:FindFirstChild("Buttons")
    if not buttons then return end

    -- As observed: 1 = No, 2 = Yes
    local yesHolder = buttons:FindFirstChild("2")
    if not yesHolder then return end

    local btn = yesHolder:FindFirstChildWhichIsA("TextButton", true)
            or yesHolder:FindFirstChildWhichIsA("ImageButton", true)
    if btn and typeof(firesignal) == "function" then
        pcall(function()
            if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
            if btn.Activated then firesignal(btn.Activated) end
        end)
    end
end

-- Main loop: Only nearest enemy plot gets huge prompt distance
RunService.Heartbeat:Connect(function()
    if not unlockClosestBase then return end
    if os.clock() - lastTune < RETUNE_INTERVAL then return end
    lastTune = os.clock()

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local plots = Workspace:FindFirstChild("Plots")
    if not (hrp and plots) then return end

    -- Find nearest plot that is NOT ours
    local closestPlot, closestDist = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = getPlotOwner(plot)
        if owner ~= player.Name then
            local hitbox = plot:FindFirstChild("StealHitBox")
            if hitbox and hitbox:IsA("BasePart") then
                local d = (hitbox.Position - hrp.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestPlot = plot
                end
            end
        end
    end

    -- Tune prompts: only the closest gets MAX_DIST
    for _, plot in ipairs(plots:GetChildren()) do
        local prompt = getUnlockPrompt(plot)
        if prompt then
            if originalDist[prompt] == nil then
                originalDist[prompt] = prompt.MaxActivationDistance
            end
            prompt.RequiresLineOfSight = false
            prompt.ClickablePrompt = true
            prompt.ActionText = "Unlock Base"

            if plot == closestPlot then
                prompt.MaxActivationDistance = MAX_DIST
            else
                prompt.MaxActivationDistance = DEFAULT_DIST
            end
        end
    end

    -- If a purchase UI popped, try to confirm (optional)
    tryConfirmPurchase()
end)

-- UI Toggles
local btn1 = makeButton(40, "Unlock Closest Base Only (OFF)", function(b)
    unlockClosestBase = not unlockClosestBase
    b.Text = unlockClosestBase and "Unlock Closest Base Only (ON)" or "Unlock Closest Base Only (OFF)"
    b.BackgroundColor3 = unlockClosestBase and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
    if not unlockClosestBase then
        restoreAllPromptDistances()
    end
end)

local btn2 = makeButton(74, "Auto-Confirm Unlock (OFF)", function(b)
    autoConfirmUnlock = not autoConfirmUnlock
    b.Text = autoConfirmUnlock and "Auto-Confirm Unlock (ON)" or "Auto-Confirm Unlock (OFF)"
    b.BackgroundColor3 = autoConfirmUnlock and Color3.fromRGB(0,170,0) or Color3.fromRGB(50,50,50)
end)

-- Defensive: restore on respawn if feature is off
player.CharacterAdded:Connect(function()
    if not unlockClosestBase then
        task.delay(1, restoreAllPromptDistances)
        task.delay(1, findLocalPlayerBase)
    end
end)
