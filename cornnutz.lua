--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- Animal data (for Lucky Blocks)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

-- ===== Rarity colors
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

local function getRarityFromName(objectName)
    for rarity in pairs(RarityColors) do
        if string.find(objectName, rarity) then
            return rarity
        end
    end
    return nil
end

-- ===== Toggles & Thresholds
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = true
local BeeHiveImmune = true
local PurchaseThreshold = 20000 -- default 20K
local WalkPurchaseEnabled = false
local ShowIgnoreRing = true  -- NEW: show the 90-stud ring around your base

-- IMPORTANT: fixed ignore radius (no UI for value)
local IGNORE_RADIUS = 90 -- studs (used only to ignore animals near YOUR base for walking)

local ThresholdOptions = {
    ["0K"] = 0,
    ["1K"] = 1000,
    ["5K"] = 5000,
    ["10K"] = 10000,
    ["20K"] = 20000,
    ["50K"] = 50000,
    ["100K"] = 100000,
    ["300K"] = 300000
}

-- ===== UI helpers
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

-- ===== ESP folders
local worldESPFolder = Instance.new("Folder")
worldESPFolder.Name = "WorldRarityESP"
worldESPFolder.Parent = CoreGui

local playerESPFolder = Instance.new("Folder")
playerESPFolder.Name = "PlayerESPFolder"
playerESPFolder.Parent = CoreGui

-- ===== UI (simple, stable layout)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Slot Info Display (top-mid)
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

-- Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 640)
frame.Position = UDim2.new(0, 20, 0.5, -270)
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

-- Toggle Minimize
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

-- ===== Top toggles (simple, fixed positions)
local function makeToggle(y, text, get, set)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 25)
    b.Position = UDim2.new(0, 5, 0, y)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text .. ": " .. (get() and "ON" or "OFF")
    updateToggleColor(b, get())
    b.Parent = frame
    b.MouseButton1Click:Connect(function()
        set(not get())
        b.Text = text .. ": " .. (get() and "ON" or "OFF")
        updateToggleColor(b, get())
    end)
    return b
end

makeToggle(30,  "Avoid In Machine", function() return AvoidInMachine end, function(v) AvoidInMachine = v end)
makeToggle(60,  "Player ESP",       function() return PlayerESPEnabled end, function(v) PlayerESPEnabled = v end)
makeToggle(90,  "Most Expensive",   function() return MostExpensiveOnly end, function(v) MostExpensiveOnly = v end)
makeToggle(120, "Auto Purchase",    function() return AutoPurchaseEnabled end, function(v) AutoPurchaseEnabled = v end)

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

-- No Ragdoll Toggle
local RagdollController = require(ReplicatedStorage.Controllers.RagdollController)
local Controls = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local NoRagdoll = true
local originalToggleControls = RagdollController.ToggleControls

makeToggle(180, "No Ragdoll", function() return NoRagdoll end, function(v)
    NoRagdoll = v
    if NoRagdoll then
        RagdollController.ToggleControls = function(_, _enable)
            Controls:Enable()
        end
    else
        RagdollController.ToggleControls = originalToggleControls
    end
end)

-- BeeHive Immune Toggle
makeToggle(210, "BeeHive Immune", function() return BeeHiveImmune end, function(v) BeeHiveImmune = v end)

-- Speed Boost
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70
makeToggle(240, "Speed Boost", function() return SpeedBoostEnabled end, function(v) SpeedBoostEnabled = v end)
local CharController = require(ReplicatedStorage.Controllers.CharacterController)
RunService.Heartbeat:Connect(function()
    if SpeedBoostEnabled then
        local _, humanoid = CharController:GetCharacter()
        if humanoid then humanoid.WalkSpeed = DesiredWalkSpeed end
    end
end)

-- Anti AFK
local AutoJumperEnabled = false
local JumpInterval = 60
local LastJumpTime = tick()
makeToggle(270, "Anti AFK", function() return AutoJumperEnabled end, function(v) AutoJumperEnabled = v end)
RunService.Heartbeat:Connect(function()
    if AutoJumperEnabled and tick() - LastJumpTime >= JumpInterval then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        LastJumpTime = tick()
    end
end)

-- Walk Purchase Toggle
makeToggle(300, "Walk Purchase", function() return WalkPurchaseEnabled end, function(v) WalkPurchaseEnabled = v end)

-- NEW: Show/Hide Ignore Ring toggle
makeToggle(330, "Show Ignore Ring", function() return ShowIgnoreRing end, function(v) ShowIgnoreRing = v end)

-- ===== Slot counter
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

-- ===== Prompt hold helper
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

-- ===== Proximity Prompt Auto Purchase
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if not (AutoPurchaseEnabled and prompt and prompt.ActionText) then return end
    if not string.find(string.lower(prompt.ActionText), "purchase") then return end

    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model then return end

    -- 1) Animals: use generation threshold
    local overhead = model:FindFirstChild("AnimalOverhead", true)
    if overhead and overhead:FindFirstChild("Generation") then
        local genValue = parseGenerationText(overhead.Generation.Text)
        if genValue >= PurchaseThreshold then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 8)
        end
        return
    end

    -- 2) Lucky Blocks: BYPASS THRESHOLD (always purchase when prompt shows)
    if string.find(model.Name, "Lucky Block") then
        task.wait(0.10)
        tryHoldPrompt(prompt, 3, 2)
        return
    end
end)

-- ===== BeeHive Immune enforcement (lightweight)
RunService.Heartbeat:Connect(function()
    if BeeHiveImmune then
        local blur = Lighting:FindFirstChild("BeeBlur")
        if blur then blur.Enabled = false end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= 70 then cam.FieldOfView = 70 end
    end
end)

-- ===== No Ragdoll safety
RunService.Heartbeat:Connect(function()
    if NoRagdoll then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)

-- ===== Helpers (ESP + Walk)
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel and stolenLabel:IsA("TextLabel") and (stolenLabel.Text == "FUSING" or stolenLabel.Text == "IN MACHINE")
end

local function createBillboard(adorn, color, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adorn
    billboard.Size = UDim2.new(0, 200, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.Parent = billboard
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = textLabel
    return billboard
end

local function findTargetPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("FakeRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Part", true)
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function setWalkTarget(humanoid, pos)
    if not (humanoid and pos) then return end
    humanoid:MoveTo(pos)
    humanoid.WalkToPoint = pos
end

local function stopWalking(humanoid, hrp)
    if not humanoid then return end
    humanoid:Move(Vector3.new(), true)
    if hrp then
        humanoid:MoveTo(hrp.Position)
        humanoid.WalkToPoint = hrp.Position
    end
end

-- ===== Base center + ring (NEW)
local basePosCache, baseRootCache, baseCacheAt = nil, nil, 0

local function getLocalBaseRootAndPos()
    if os.clock() - baseCacheAt < 2 and basePosCache and baseRootCache then
        return baseRootCache, basePosCache
    end
    basePosCache, baseRootCache = nil, nil
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            local gui = sign and sign:FindFirstChild("SurfaceGui")
            local fr = gui and gui:FindFirstChild("Frame")
            local label = fr and fr:FindFirstChild("TextLabel")
            if label and label.Text then
                local owner = label.Text:match("^(.-)'s Base")
                if owner == player.Name then
                    local root = plot:FindFirstChild("MainRoot")
                    baseRootCache = root
                    basePosCache = (root and root.Position) or nil
                    if not basePosCache then
                        for _, d in ipairs(plot:GetDescendants()) do
                            if d:IsA("BasePart") then basePosCache = d.Position baseRootCache = d break end
                        end
                    end
                    break
                end
            end
        end
    end
    baseCacheAt = os.clock()
    return baseRootCache, basePosCache
end

-- Adornment ring
local ringAdornment : CylinderHandleAdornment? = nil
local ringAnchorPart : Part? = nil

local function destroyIgnoreRing()
    if ringAdornment then ringAdornment:Destroy(); ringAdornment = nil end
    if ringAnchorPart then ringAnchorPart:Destroy(); ringAnchorPart = nil end
end

local function ensureIgnoreRing()
    if not ShowIgnoreRing then
        destroyIgnoreRing()
        return
    end

    local baseRoot, basePos = getLocalBaseRootAndPos()
    if not baseRoot and not basePos then
        destroyIgnoreRing()
        return
    end

    local adorneePart = baseRoot

    if not adorneePart and basePos then
        if not ringAnchorPart or not ringAnchorPart.Parent then
            ringAnchorPart = Instance.new("Part")
            ringAnchorPart.Name = "IgnoreRingAnchor"
            ringAnchorPart.Anchored = true
            ringAnchorPart.CanCollide = false
            ringAnchorPart.Transparency = 1
            ringAnchorPart.Size = Vector3.new(1,1,1)
            ringAnchorPart.CFrame = CFrame.new(basePos)
            ringAnchorPart.Parent = Workspace
        else
            ringAnchorPart.CFrame = CFrame.new(basePos)
        end
        adorneePart = ringAnchorPart
    elseif adorneePart and ringAnchorPart then
        -- We have a real base root now; drop the temp anchor
        ringAnchorPart:Destroy()
        ringAnchorPart = nil
    end

    if not adorneePart then
        destroyIgnoreRing()
        return
    end

    if not ringAdornment or not ringAdornment.Parent then
        ringAdornment = Instance.new("CylinderHandleAdornment")
        ringAdornment.Name = "IgnoreRadiusRing"
        ringAdornment.AlwaysOnTop = true
        ringAdornment.Color3 = Color3.fromRGB(0, 255, 0)
        ringAdornment.Transparency = 0.25
        ringAdornment.ZIndex = 3
        ringAdornment.Height = 0.2
        ringAdornment.Radius = IGNORE_RADIUS
        ringAdornment.Adornee = adorneePart
        ringAdornment.Parent = CoreGui
    else
        ringAdornment.Adornee = adorneePart
        ringAdornment.Height = 0.2
        ringAdornment.Radius = IGNORE_RADIUS
    end
end

-- Keep ring fresh (update about twice a second)
task.spawn(function()
    while true do
        ensureIgnoreRing()
        task.wait(0.5)
    end
end)

-- ===== Walk-to-purchase (Animals by Generation), ignore near your base
local pauseDistance, pauseTime, lastPause = 5, 0.35, 0
RunService.Heartbeat:Connect(function()
    if not WalkPurchaseEnabled then return end

    local char = workspace:FindFirstChild(player.Name)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local bestModel, bestGen, bestDist = nil, -math.huge, math.huge
    local baseRoot, myBasePos = getLocalBaseRootAndPos()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local overhead = obj:FindFirstChild("AnimalOverhead", true)
            local genLabel = overhead and overhead:FindFirstChild("Generation")
            if genLabel then
                if AvoidInMachine and isInMachine(overhead) then
                    -- skip fusing/in-machine
                else
                    local targetPart = findTargetPart(obj)
                    if targetPart and targetPart:IsA("BasePart") then
                        -- ignore things too close to your base
                        local tooCloseToBase = false
                        if myBasePos then
                            local dToBase = (targetPart.Position - myBasePos).Magnitude
                            if dToBase <= IGNORE_RADIUS then
                                tooCloseToBase = true
                            end
                        end
                        if not tooCloseToBase then
                            local genValue = parseGenerationText(genLabel.Text or "")
                            if genValue >= PurchaseThreshold then
                                local dist = (hrp.Position - targetPart.Position).Magnitude
                                if (genValue > bestGen) or (genValue == bestGen and dist < bestDist) then
                                    bestModel, bestGen, bestDist = obj, genValue, dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not bestModel then return end
    local targetPart = findTargetPart(bestModel)
    if not (targetPart and targetPart:IsA("BasePart")) then return end

    local dist = (hrp.Position - targetPart.Position).Magnitude
    if dist <= pauseDistance and (tick() - lastPause) >= pauseTime then
        stopWalking(humanoid, hrp)
        lastPause = tick()
        return
    end

    setWalkTarget(humanoid, targetPart.Position)
end)

-- ===== Rarity toggles (ESP)
do
    local y = 360 -- moved down to make room for "Show Ignore Ring"
    for rarity in pairs(RarityColors) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 25)
        button.Position = UDim2.new(0, 5, 0, y)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
        updateToggleColor(button, EnabledRarities[rarity])
        button.Parent = frame
        button.MouseButton1Click:Connect(function()
            EnabledRarities[rarity] = not EnabledRarities[rarity]
            button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
            updateToggleColor(button, EnabledRarities[rarity])
        end)
        y += 28
    end
end

-- ===== ESP loop (ignore-radius does NOT affect ESP)
RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    local maxAnimal, maxGen = nil, -math.huge
    local maxBlock, maxPrice = nil, -math.huge

    for _, podium in ipairs(Workspace:GetDescendants()) do
        if podium.Name == "AnimalOverhead" then
            local rarityLabel = podium:FindFirstChild("Rarity")
            local rarity = rarityLabel and rarityLabel.Text
            if rarity and RarityColors[rarity] then
                if AvoidInMachine and isInMachine(podium) then
                    -- skip
                else
                    local gen = parseGenerationText((podium:FindFirstChild("Generation") or {}).Text or "")
                    if MostExpensiveOnly then
                        if gen > maxGen then
                            maxGen, maxAnimal = gen, podium
                        end
                    else
                        if EnabledRarities[rarity] then
                            local displayName = podium:FindFirstChild("DisplayName")
                            if displayName then
                                local model = podium.Parent and podium.Parent.Parent
                                if model and model:IsA("BasePart") then
                                    local bb = createBillboard(model, RarityColors[rarity], displayName.Text .. " | " .. (podium.Generation and podium.Generation.Text or ""))
                                    bb.Parent = worldESPFolder
                                end
                            end
                        end
                    end
                end
            end
        elseif podium.Name:find("Lucky Block") then
            local rarity = getRarityFromName(podium.Name)
            if rarity then
                local data = AnimalsData[podium.Name]
                local price = data and data.Price or 0
                if MostExpensiveOnly then
                    if price > maxPrice then
                        maxPrice, maxBlock = price, podium
                    end
                else
                    if EnabledRarities[rarity] then
                        local model = podium.PrimaryPart
                        if model then
                            local bb = createBillboard(model, RarityColors[rarity], podium.Name .. " | $" .. formatPrice(price))
                            bb.Parent = worldESPFolder
                        end
                    end
                end
            end
        end
    end

    if MostExpensiveOnly then
        if maxAnimal then
            local rarity = maxAnimal.Rarity.Text
            local displayName = maxAnimal.DisplayName.Text
            local model = maxAnimal.Parent and maxAnimal.Parent.Parent
            if model and model:IsA("BasePart") then
                local bb = createBillboard(model, RarityColors[rarity], displayName .. " | " .. (maxAnimal:FindFirstChild("Generation") and maxAnimal.Generation.Text or ""))
                bb.Parent = worldESPFolder
            end
        end
        if maxBlock then
            local rarity = getRarityFromName(maxBlock.Name)
            local data = AnimalsData[maxBlock.Name]
            local price = data and data.Price or 0
            if maxBlock.PrimaryPart then
                local bb = createBillboard(maxBlock.PrimaryPart, RarityColors[rarity], maxBlock.Name .. " | $" .. formatPrice(price))
                bb.Parent = worldESPFolder
            end
        end
    end

    if PlayerESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                local bb = createBillboard(plr.Character.HumanoidRootPart, Color3.fromRGB(0,255,255), plr.Name .. " | " .. math.floor(dist) .. "m")
                bb.Parent = playerESPFolder
            end
        end
    end
end)
