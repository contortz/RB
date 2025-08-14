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
frame.Size = UDim2.new(0, 260, 0, 140)
frame.Position = UDim2.new(0, 20, 0.5, -70)
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

--// State
local unlockClosestBase = false      -- Toggle 1
local autoConfirmUnlock = false      -- Toggle 2

local MAX_DIST = 999999
local DEFAULT_DIST = 15
local RETUNE_INTERVAL = 0.1 -- seconds
local lastTune = 0

-- Cache each prompt's original MaxActivationDistance so we can restore
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
    -- Expected path: Workspace.Plots.<plot>.Unlock.Main.UnlockBase (ProximityPrompt)
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

-- Auto-confirm purchase (Yes button) – avoids VirtualInputManager
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

    local yesHolder = buttons:FindFirstChild("2") -- per your observation: 1 = No, 2 = Yes
    if not yesHolder then return end

    local btn = yesHolder:FindFirstChildWhichIsA("TextButton", true)
            or yesHolder:FindFirstChildWhichIsA("ImageButton", true)
    if btn then
        if typeof(firesignal) == "function" then
            pcall(function()
                if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
                if btn.Activated then firesignal(btn.Activated) end
            end)
        end
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

    -- Tune prompts
    for _, plot in ipairs(plots:GetChildren()) do
        local prompt = getUnlockPrompt(plot)
        if prompt then
            if originalDist[prompt] == nil then
                originalDist[prompt] = prompt.MaxActivationDistance
            end
            -- QoL: make it easier to trigger
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

    -- If a purchase UI popped, try to confirm (optional toggle)
    tryConfirmPurchase()
end)

-- UI Buttons (two independent toggles)
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

-- Optional: restore on respawn (defensive)
player.CharacterAdded:Connect(function()
    if not unlockClosestBase then
        task.delay(1, restoreAllPromptDistances)
    end
end)
