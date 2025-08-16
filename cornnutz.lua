--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Animal data (for Lucky Blocks)
local AnimalsData do
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
    end)
    AnimalsData = ok and mod or {}
end

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255)
}

-- Enabled rarities (defaults)
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Lucky Block helper
local function getRarityFromName(objectName)
    for rarity in pairs(RarityColors) do
        if string.find(objectName, rarity) then
            return rarity
        end
    end
    return nil
end

-- Toggles & Thresholds
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = true
local BeeHiveImmune = true
local PurchaseThreshold = 20000 -- default 20K
local RequirePromptNearTarget = false -- animals usually have no prompt; leave OFF

-- Ignore animals near *your* base (walk logic only)
local IgnoreNearMyBase = true
local IgnoreRadius = 85 -- padding around your plot bounds
local IgnoreRadiusOptions = {70,85,90}

-- Show the ignore zone overlay (now a square that matches bbox+padding)
local ShowIgnoreZone = true

local ThresholdOptions = {
    ["0K"] = 0, ["1K"] = 1000, ["5K"] = 5000, ["10K"] = 10000,
    ["20K"] = 20000, ["50K"] = 50000, ["100K"] = 100000, ["300K"] = 300000
}

-- UI helpers
local function updateToggleColor(button, isOn)
    button.BackgroundColor3 = isOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(70, 70, 70)
end

local function formatPrice(value)
    if value >= 1e9 then
        return string.format("%.1fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.1fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fK", value / 1e3)
    else
        return tostring(value)
    end
end

-- Convert "100K/s" to numeric
local function parseGenerationText(text)
    local num = tonumber(text:match("[%d%.]+")) or 0
    if text:find("K") then num *= 1000 end
    if text:find("M") then num *= 1000000 end
    return num
end

-- ESP Folders
local worldESPFolder = Instance.new("Folder")
worldESPFolder.Name = "WorldRarityESP"
worldESPFolder.Parent = CoreGui

local playerESPFolder = Instance.new("Folder")
playerESPFolder.Name = "PlayerESPFolder"
playerESPFolder.Parent = CoreGui

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Slot Info Display (top-middle)
local slotInfoLabel = Instance.new("TextLabel")
slotInfoLabel.Position = UDim2.new(0.5, -100, 0, 10)
slotInfoLabel.Size = UDim2.new(0, 200, 0, 30)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
slotInfoLabel.TextStrokeTransparency = 0.4
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.ZIndex = 10
slotInfoLabel.Parent = screenGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 700)
frame.Position = UDim2.new(0, 20, 0.5, -315)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Text = "-"
minimizeBtn.ZIndex = 999
minimizeBtn.Parent = frame

-- Corn Icon (restore)
local cornIcon = Instance.new("ImageButton")
cornIcon.Size = UDim2.new(0, 60, 0, 60)
cornIcon.Position = UDim2.new(0, 15, 0.27, 0)
cornIcon.BackgroundTransparency = 1
cornIcon.Image = "rbxassetid://76154122039576"
cornIcon.ZIndex = 999
cornIcon.Visible = false
cornIcon.Parent = screenGui

-- Dragging for Corn Icon
do
    local dragging, dragInput, dragStart, startPos
    cornIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = cornIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    cornIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            cornIcon.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Minimize toggle
minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    cornIcon.Visible = true
end)
cornIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    cornIcon.Visible = false
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10
title.Parent = frame

-- Avoid In Machine Toggle
local toggleAvoidBtn = Instance.new("TextButton")
toggleAvoidBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAvoidBtn.Position = UDim2.new(0, 5, 0, 30)
toggleAvoidBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAvoidBtn.Text = "Avoid In Machine: ON"
updateToggleColor(toggleAvoidBtn, AvoidInMachine)
toggleAvoidBtn.Parent = frame
toggleAvoidBtn.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    toggleAvoidBtn.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
    updateToggleColor(toggleAvoidBtn, AvoidInMachine)
end)

-- Player ESP Toggle
local togglePlayerESPBtn = Instance.new("TextButton")
togglePlayerESPBtn.Size = UDim2.new(1, -10, 0, 25)
togglePlayerESPBtn.Position = UDim2.new(0, 5, 0, 60)
togglePlayerESPBtn.TextColor3 = Color3.new(1, 1, 1)
togglePlayerESPBtn.Text = "Player ESP: OFF"
updateToggleColor(togglePlayerESPBtn, PlayerESPEnabled)
togglePlayerESPBtn.Parent = frame
togglePlayerESPBtn.MouseButton1Click:Connect(function()
    PlayerESPEnabled = not PlayerESPEnabled
    togglePlayerESPBtn.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
    updateToggleColor(togglePlayerESPBtn, PlayerESPEnabled)
end)

-- Most Expensive Only Toggle (for ESP)
local toggleMostExpBtn = Instance.new("TextButton")
toggleMostExpBtn.Size = UDim2.new(1, -10, 0, 25)
toggleMostExpBtn.Position = UDim2.new(0, 5, 0, 90)
toggleMostExpBtn.TextColor3 = Color3.new(1, 1, 1)
toggleMostExpBtn.Text = "Most Expensive: OFF"
updateToggleColor(toggleMostExpBtn, MostExpensiveOnly)
toggleMostExpBtn.Parent = frame
toggleMostExpBtn.MouseButton1Click:Connect(function()
    MostExpensiveOnly = not MostExpensiveOnly
    toggleMostExpBtn.Text = "Most Expensive: " .. (MostExpensiveOnly and "ON" or "OFF")
    updateToggleColor(toggleMostExpBtn, MostExpensiveOnly)
end)

-- Auto Purchase Toggle (hold prompts)
local toggleAutoPurchaseBtn = Instance.new("TextButton")
toggleAutoPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoPurchaseBtn.Position = UDim2.new(0, 5, 0, 120)
toggleAutoPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoPurchaseBtn.Text = "Auto Purchase: ON"
updateToggleColor(toggleAutoPurchaseBtn, AutoPurchaseEnabled)
toggleAutoPurchaseBtn.Parent = frame
toggleAutoPurchaseBtn.MouseButton1Click:Connect(function()
    AutoPurchaseEnabled = not AutoPurchaseEnabled
    toggleAutoPurchaseBtn.Text = "Auto Purchase: " .. (AutoPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(toggleAutoPurchaseBtn, AutoPurchaseEnabled)
end)

-- Purchase Threshold Dropdown
local thresholdDropdown = Instance.new("TextButton")
thresholdDropdown.Size = UDim2.new(1, -10, 0, 25)
thresholdDropdown.Position = UDim2.new(0, 5, 0, 150)
thresholdDropdown.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
thresholdDropdown.TextColor3 = Color3.new(1, 1, 1)
thresholdDropdown.Text = "Threshold: ≥ 20K"
thresholdDropdown.Parent = frame
thresholdDropdown.MouseButton1Click:Connect(function()
    local keys = {"0K","1K","5K","10K","20K","50K","100K","300K"}
    local currentIndex = table.find(keys, tostring(PurchaseThreshold/1000).."K") or 5
    currentIndex = currentIndex % #keys + 1
    local selected = keys[currentIndex]
    PurchaseThreshold = ThresholdOptions[selected]
    thresholdDropdown.Text = "Threshold: ≥ "..selected
end)

-- Require Prompt Near Target toggle
local toggleReqPromptBtn = Instance.new("TextButton")
toggleReqPromptBtn.Size = UDim2.new(1, -10, 0, 25)
toggleReqPromptBtn.Position = UDim2.new(0, 5, 0, 180)
toggleReqPromptBtn.TextColor3 = Color3.new(1, 1, 1)
toggleReqPromptBtn.Text = "Require Prompt Near Target: OFF"
updateToggleColor(toggleReqPromptBtn, RequirePromptNearTarget)
toggleReqPromptBtn.Parent = frame
toggleReqPromptBtn.MouseButton1Click:Connect(function()
    RequirePromptNearTarget = not RequirePromptNearTarget
    toggleReqPromptBtn.Text = "Require Prompt Near Target: " .. (RequirePromptNearTarget and "ON" or "OFF")
    updateToggleColor(toggleReqPromptBtn, RequirePromptNearTarget)
end)

-- Ignore Near My Base toggle
local toggleIgnoreBaseBtn = Instance.new("TextButton")
toggleIgnoreBaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleIgnoreBaseBtn.Position = UDim2.new(0, 5, 0, 210)
toggleIgnoreBaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleIgnoreBaseBtn.Text = "Ignore Near My Base: ON"
updateToggleColor(toggleIgnoreBaseBtn, IgnoreNearMyBase)
toggleIgnoreBaseBtn.Parent = frame
toggleIgnoreBaseBtn.MouseButton1Click:Connect(function()
    IgnoreNearMyBase = not IgnoreNearMyBase
    toggleIgnoreBaseBtn.Text = "Ignore Near My Base: " .. (IgnoreNearMyBase and "ON" or "OFF")
    updateToggleColor(toggleIgnoreBaseBtn, IgnoreNearMyBase)
end)

-- Ignore Radius button
local ignoreRadiusBtn = Instance.new("TextButton")
ignoreRadiusBtn.Size = UDim2.new(1, -10, 0, 25)
ignoreRadiusBtn.Position = UDim2.new(0, 5, 0, 240)
ignoreRadiusBtn.TextColor3 = Color3.new(1, 1, 1)
ignoreRadiusBtn.Text = ("Ignore Radius: %dstu"):format(IgnoreRadius)
updateToggleColor(ignoreRadiusBtn, true)
ignoreRadiusBtn.Parent = frame
ignoreRadiusBtn.MouseButton1Click:Connect(function()
    local idx = table.find(IgnoreRadiusOptions, IgnoreRadius) or 2
    idx = idx % #IgnoreRadiusOptions + 1
    IgnoreRadius = IgnoreRadiusOptions[idx]
    ignoreRadiusBtn.Text = ("Ignore Radius: %dstu"):format(IgnoreRadius)
end)

-- Show Ignore Zone toggle (square overlay)
local toggleZoneBtn = Instance.new("TextButton")
toggleZoneBtn.Size = UDim2.new(1, -10, 0, 25)
toggleZoneBtn.Position = UDim2.new(0, 5, 0, 270)
toggleZoneBtn.TextColor3 = Color3.new(1, 1, 1)
toggleZoneBtn.Text = "Show Ignore Zone: ON"
updateToggleColor(toggleZoneBtn, ShowIgnoreZone)
toggleZoneBtn.Parent = frame
toggleZoneBtn.MouseButton1Click:Connect(function()
    ShowIgnoreZone = not ShowIgnoreZone
    toggleZoneBtn.Text = "Show Ignore Zone: " .. (ShowIgnoreZone and "ON" or "OFF")
    updateToggleColor(toggleZoneBtn, ShowIgnoreZone)
end)

-- Speed Boost
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70
local toggleSpeedBoostBtn = Instance.new("TextButton")
toggleSpeedBoostBtn.Size = UDim2.new(1, -10, 0, 25)
toggleSpeedBoostBtn.Position = UDim2.new(0, 5, 0, 300)
toggleSpeedBoostBtn.TextColor3 = Color3.new(1, 1, 1)
toggleSpeedBoostBtn.Text = "Speed Boost: OFF"
updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
toggleSpeedBoostBtn.Parent = frame
toggleSpeedBoostBtn.MouseButton1Click:Connect(function()
    SpeedBoostEnabled = not SpeedBoostEnabled
    toggleSpeedBoostBtn.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
end)

-- Anti AFK
local AutoJumperEnabled = false
local JumpInterval = 60
local LastJumpTime = tick()
local toggleAutoJumperBtn = Instance.new("TextButton")
toggleAutoJumperBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoJumperBtn.Position = UDim2.new(0, 5, 0, 330)
toggleAutoJumperBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoJumperBtn.Text = "Anti AFK: OFF"
updateToggleColor(toggleAutoJumperBtn, AutoJumperEnabled)
toggleAutoJumperBtn.Parent = frame
toggleAutoJumperBtn.MouseButton1Click:Connect(function()
    AutoJumperEnabled = not AutoJumperEnabled
    toggleAutoJumperBtn.Text = "Anti AFK: " .. (AutoJumperEnabled and "ON" or "OFF")
    updateToggleColor(toggleAutoJumperBtn, AutoJumperEnabled)
end)
RunService.Heartbeat:Connect(function()
    if AutoJumperEnabled and tick() - LastJumpTime >= JumpInterval then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        LastJumpTime = tick()
    end
end)

-- Walk Purchase Toggle
local WalkPurchaseEnabled = false
local toggleWalkPurchaseBtn = Instance.new("TextButton")
toggleWalkPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleWalkPurchaseBtn.Position = UDim2.new(0, 5, 0, 360)
toggleWalkPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleWalkPurchaseBtn.Text = "Walk Purchase: OFF"
updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
toggleWalkPurchaseBtn.Parent = frame
toggleWalkPurchaseBtn.MouseButton1Click:Connect(function()
    WalkPurchaseEnabled = not WalkPurchaseEnabled
    toggleWalkPurchaseBtn.Text = "Walk Purchase: " .. (WalkPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
end)

-- NEW: Quick Purchase button (fires RE/ShopService/Purchase with 3296448922)  -- "4x Luck"
local quickPurchaseBtn = Instance.new("TextButton")
quickPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
quickPurchaseBtn.Position = UDim2.new(0, 5, 0, 390)
quickPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
quickPurchaseBtn.Text = "4x Luck"
updateToggleColor(quickPurchaseBtn, true)
quickPurchaseBtn.Parent = frame

local quickPurchaseDebounce = false
quickPurchaseBtn.MouseButton1Click:Connect(function()
    if quickPurchaseDebounce then return end
    quickPurchaseDebounce = true
    local ok, remote = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages")
            :WaitForChild("Net")
            :WaitForChild("RE/ShopService/Purchase")
    end)
    if ok and remote and remote.FireServer then
        pcall(function()
            remote:FireServer(3296448922) -- product id
        end)
        local old = quickPurchaseBtn.Text
        quickPurchaseBtn.Text = "Sent!"
        task.delay(0.6, function()
            if quickPurchaseBtn then quickPurchaseBtn.Text = old end
        end)
    else
        quickPurchaseBtn.Text = "Remote not found"
        task.delay(1.2, function()
            if quickPurchaseBtn then quickPurchaseBtn.Text = "4x Luck" end
        end)
    end
    task.delay(0.5, function() quickPurchaseDebounce = false end)
end)

-- Pause settings
local pauseDistance = 5
local pauseTime = 0.35
local lastPause = 0

-- Purchase prompt check (optional gating near target)
local function purchasePromptActive()
    local promptGui = player.PlayerGui:FindFirstChild("ProximityPrompts")
    if not promptGui then return false end
    local promptFrame = promptGui:FindFirstChild("Prompt", true)
    if not promptFrame then return false end
    local actionText = promptFrame:FindFirstChild("ActionText", true)
    if not actionText then return false end
    return string.find(actionText.Text:lower(), "purchase") ~= nil
end

-- Slot counter
local function updateSlotCountOnly()
    local playerName = player.Name
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, model in ipairs(plots:GetChildren()) do
        local sign = model:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local f = gui and gui:FindFirstChild("Frame")
        local label = f and f:FindFirstChild("TextLabel")
        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == playerName then
                local animalPodiums = model:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled, total = 0, 0
                    for _, podiumModule in ipairs(animalPodiums:GetChildren()) do
                        if podiumModule:IsA("Model") then
                            local base = podiumModule:FindFirstChild("Base")
                            local spawn = base and base:FindFirstChild("Spawn")
                            if spawn and spawn:IsA("BasePart") then
                                total += 1
                                if spawn:FindFirstChild("Attachment") then
                                    filled += 1
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
task.delay(1, updateSlotCountOnly)
task.spawn(function()
    while true do
        updateSlotCountOnly()
        task.wait(5)
    end
end)

-- Prompt hold helper
local function tryHoldPrompt(prompt, holdTime, maxRetries)
    maxRetries = maxRetries or 2
    for _ = 1, maxRetries do
        prompt:InputHoldBegin()
        task.wait(holdTime)
        prompt:InputHoldEnd()
        task.wait(0.25)
        if not prompt:IsDescendantOf(game) or not prompt.Enabled then
            break
        end
    end
end

-- Proximity Prompt Auto Purchase (Lucky Blocks bypass threshold)
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if not (AutoPurchaseEnabled and prompt and prompt.ActionText) then return end
    if not string.find(prompt.ActionText:lower(), "purchase") then return end

    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model then return end

    -- Animals by Generation (uses threshold)
    local overhead = model:FindFirstChild("AnimalOverhead", true)
    if overhead and overhead:FindFirstChild("Generation") then
        local genValue = parseGenerationText(overhead.Generation.Text)
        if genValue >= PurchaseThreshold then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 8)
        end
        return
    end

    -- Lucky Blocks: BYPASS threshold
    local rarityHit = getRarityFromName(model.Name)
    if rarityHit then
        if EnabledRarities[rarityHit] then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 3)
        end
        return
    else
        local data = AnimalsData[model.Name]
        if data and (data.Rarity or data.LuckyBlock or tostring(model.Name):find("Lucky")) then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 3)
            return
        end
    end
end)

-- Speed-boost (CharacterController)
local CharController do
    local ok, mod = pcall(function()
        return require(ReplicatedStorage.Controllers.CharacterController)
    end)
    CharController = ok and mod or nil
end
RunService.Heartbeat:Connect(function()
    if SpeedBoostEnabled and CharController and CharController.GetCharacter then
        local _, humanoid = CharController:GetCharacter()
        if humanoid then humanoid.WalkSpeed = DesiredWalkSpeed end
    end
end)

-- === MY BASE BOUNDS (for ignore) ===
local myBaseCF, myBaseSize -- updated periodically

local function myPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")
        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == player.Name then
                return plot
            end
        end
    end
    return nil
end

local function refreshMyBaseBounds()
    myBaseCF, myBaseSize = nil, nil
    local plot = myPlot()
    if not plot then return end
    local ok, cf, size = pcall(function() return plot:GetBoundingBox() end)
    if ok and cf and size then
        myBaseCF, myBaseSize = cf, size
    end
end

local function isInsideOrNearMyBase(pos)
    if not (IgnoreNearMyBase and myBaseCF and myBaseSize) then return false end
    local p = myBaseCF:PointToObjectSpace(pos)
    local pad = IgnoreRadius
    return math.abs(p.X) <= (myBaseSize.X * 0.5 + pad)
        and math.abs(p.Z) <= (myBaseSize.Z * 0.5 + pad)
end

task.spawn(function()
    while true do
        refreshMyBaseBounds()
        task.wait(3)
    end
end)

-- ===== Blue ignore square (matches bbox + padding) =====
local squareSel, squarePart
local function destroyIgnoreSquare()
    if squareSel then squareSel:Destroy(); squareSel = nil end
    if squarePart then squarePart:Destroy(); squarePart = nil end
end

local function ensureIgnoreSquare()
    if not ShowIgnoreZone or not (myBaseCF and myBaseSize) then
        destroyIgnoreSquare()
        return
    end

    -- Pad the plot bounds by IgnoreRadius on X/Z
    local halfX = myBaseSize.X * 0.5
    local halfZ = myBaseSize.Z * 0.5
    local sizeX = (halfX + IgnoreRadius) * 2
    local sizeZ = (halfZ + IgnoreRadius) * 2

    -- Invisible anchor part so SelectionBox can render
    if not squarePart or not squarePart.Parent then
        squarePart = Instance.new("Part")
        squarePart.Name = "IgnoreSquareAnchor"
        squarePart.Anchored = true
        squarePart.CanCollide = false
        squarePart.Transparency = 1
        squarePart.Parent = Workspace
    end
    squarePart.Size = Vector3.new(sizeX, 0.1, sizeZ)
    squarePart.CFrame = myBaseCF

    -- Blue outline
    if not squareSel or not squareSel.Parent then
        squareSel = Instance.new("SelectionBox")
        squareSel.Name = "IgnoreSquare"
        squareSel.LineThickness = 0.05
        squareSel.Color3 = Col
