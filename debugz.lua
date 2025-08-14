--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- UI Setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 540)
frame.Position = UDim2.new(0, 20, 0.5, -270)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Info Labels
local baseInfoLabel = Instance.new("TextLabel", frame)
baseInfoLabel.Size = UDim2.new(1, -10, 0, 25)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 40)
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1, 1, 1)
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"

local slotInfoLabel = Instance.new("TextLabel", frame)
slotInfoLabel.Size = UDim2.new(1, -10, 0, 25)
slotInfoLabel.Position = UDim2.new(0, 5, 0, 70)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"

-- Base + Slot Logic
local function findLocalPlayerBase()
    local playerName = player.Name
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, model in ipairs(plots:GetChildren()) do
        local sign = model:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")

        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == playerName then
                local tier = model:GetAttribute("Tier")
                baseInfoLabel.Text = "🏠 Base: " .. model.Name .. " | Tier: " .. tostring(tier or "?")
                local animalPodiums = model:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled, total = 0, 0
                    for _, podiumModule in ipairs(animalPodiums:GetChildren()) do
                        if podiumModule:IsA("Model") then
                            local base = podiumModule:FindFirstChild("Base")
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

-- Button Helper
local function makeButton(yOffset, text, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, yOffset)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextScaled = true
    callback(button)
end

-- Remotes + State
local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)
local teleportLoop = false
local autoEquipQuantum = false
local autoActivateQuantum = false
local autoEquipBee = false
local autoActivateBee = false
local autoEquipBat = false
local autoSwingBat = false
local unlockClosestBase = false
local autoConfirmUnlock = false

-- Constants
local MAX_DIST = 999999
local DEFAULT_DIST = 15
local RETUNE_INTERVAL = 0.1 -- seconds

-- Cache original distances so we can restore
local originalDist = setmetatable({}, { __mode = "k" }) -- weak keys

-- Helpers to get the ProximityPrompt for a plot
local function getUnlockPrompt(plotModel)
    -- Path: Workspace.Plots.<plot>.Unlock.Main.UnlockBase (ProximityPrompt)
    local unlock = plotModel:FindFirstChild("Unlock")
    local main = unlock and unlock:FindFirstChild("Main")
    local prompt = main and main:FindFirstChild("UnlockBase")
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end
    return nil
end

-- (Optional) Auto-confirm purchase prompt (tries to press the "Yes" button)
local function tryConfirmPurchase()
    if not autoConfirmUnlock then return end
    local root = CoreGui:FindFirstChild("PurchasePromptApp")
    if not root then return end
    local path = root:FindFirstChild("ProductPurchaseContainer")
        and root.ProductPurchaseContainer:FindFirstChild("Animator")
        and root.ProductPurchaseContainer.Animator:FindFirstChild("Prompt")
        and root.ProductPurchaseContainer.Animator.Prompt:FindFirstChild("AlertControls")
        and root.ProductPurchaseContainer.Animator.Prompt.AlertControls:FindFirstChild("Footer")
        and root.ProductPurchaseContainer.Animator.Prompt.AlertControls.Footer:FindFirstChild("Buttons")
    if not path then return end

    -- Button "2" is usually Yes/Confirm in your screenshot
    local yesBtnHolder = path:FindFirstChild("2")
    if not yesBtnHolder then return end

    local btn = yesBtnHolder:FindFirstChildWhichIsA("TextButton", true)
                or yesBtnHolder:FindFirstChildWhichIsA("ImageButton", true)

    -- Prefer exploit-provided firesignal if available
    if btn then
        if typeof(firesignal) == "function" then
            if btn.MouseButton1Click then
                pcall(firesignal, btn.MouseButton1Click)
            end
            if btn.Activated then
                pcall(firesignal, btn.Activated)
            end
        else
            -- Fallback: do nothing (avoids VirtualInputManager since it got you banned)
        end
    end
end

-- Runtime Loops
local lastTune = 0
RunService.Heartbeat:Connect(function()
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    -- Tool Auto Equip/Activate
    if autoEquipQuantum and backpack and character and not character:FindFirstChild("Quantum Cloner") then
        local tool = backpack:FindFirstChild("Quantum Cloner")
        if tool then tool.Parent = character end
    end
    if autoActivateQuantum and character then
        local tool = character:FindFirstChild("Quantum Cloner")
        if tool then tool:Activate() end
    end
    if teleportLoop then
        Net:RemoteEvent("QuantumCloner/OnTeleport"):FireServer()
    end
    if autoEquipBee and backpack and character and not character:FindFirstChild("Bee Launcher") then
        local tool = backpack:FindFirstChild("Bee Launcher")
        if tool then tool.Parent = character end
    end
    if autoActivateBee and character then
        local tool = character:FindFirstChild("Bee Launcher")
        if tool then tool:Activate() end
    end
    if autoEquipBat and backpack and character and not character:FindFirstChild("Tung Bat") then
        local tool = backpack:FindFirstChild("Tung Bat")
        if tool then tool.Parent = character end
    end
    if autoSwingBat and character then
        local tool = character:FindFirstChild("Tung Bat")
        if tool then tool:Activate() end
    end

    -- Unlock Closest Base Logic
    if unlockClosestBase and os.clock() - lastTune >= RETUNE_INTERVAL then
        lastTune = os.clock()

        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local plots = Workspace:FindFirstChild("Plots")
        if not (hrp and plots) then return end

        local closestPlot, closestDist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            local hitbox = plot:FindFirstChild("StealHitBox")
            if hitbox and hitbox:IsA("BasePart") then
                local dist = (hitbox.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlot = plot
                end
            end
        end

        -- Tune all prompts: only the closest gets max range
        for _, plot in ipairs(plots:GetChildren()) do
            local prompt = getUnlockPrompt(plot)
            if prompt then
                -- store original once
                if originalDist[prompt] == nil then
                    originalDist[prompt] = prompt.MaxActivationDistance
                end
                -- make it easier to trigger from angles
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

        -- Try to confirm any purchase UI that pops for this
        tryConfirmPurchase()
    end
end)

-- Restore distances when turning the feature off
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

-- Buttons
makeButton(110, "Loop Equip Quantum Cloner", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipQuantum = not autoEquipQuantum
        btn.BackgroundColor3 = autoEquipQuantum and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(140, "Loop Activate Quantum", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoActivateQuantum = not autoActivateQuantum
        btn.BackgroundColor3 = autoActivateQuantum and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(170, "Loop Teleport to Clone", function(btn)
    btn.MouseButton1Click:Connect(function()
        teleportLoop = not teleportLoop
        btn.BackgroundColor3 = teleportLoop and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(200, "Loop Equip Bee Launcher", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipBee = not autoEquipBee
        btn.BackgroundColor3 = autoEquipBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(230, "Loop Activate Bee Launcher", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoActivateBee = not autoActivateBee
        btn.BackgroundColor3 = autoActivateBee and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(260, "Loop Equip Tung Bat", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoEquipBat = not autoEquipBat
        btn.BackgroundColor3 = autoEquipBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(290, "Auto Swing Bat", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoSwingBat = not autoSwingBat
        btn.BackgroundColor3 = autoSwingBat and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)

makeButton(320, "Unlock Closest Base Only", function(btn)
    btn.MouseButton1Click:Connect(function()
        unlockClosestBase = not unlockClosestBase
        btn.BackgroundColor3 = unlockClosestBase and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
        if not unlockClosestBase then
            restoreAllPromptDistances()
        end
    end)
end)

makeButton(350, "Auto-Confirm Unlock (Yes)", function(btn)
    btn.MouseButton1Click:Connect(function()
        autoConfirmUnlock = not autoConfirmUnlock
        btn.BackgroundColor3 = autoConfirmUnlock and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end)
end)
