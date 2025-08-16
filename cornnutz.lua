--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Animal data (for Lucky Blocks)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

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

-- NEW: ignore animals near *your* base (affects WALK ONLY, not ESP)
local IgnoreNearMyBase = true
local IgnoreRadius = 70 -- padding around your plot bounds
local IgnoreRadiusOptions = {20,30,40,50,70,100,150}

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
local worldESPFolder = Instance.new("Folder", CoreGui); worldESPFolder.Name = "WorldRarityESP"
local playerESPFolder = Instance.new("Folder", CoreGui); playerESPFolder.Name = "PlayerESPFolder"

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Slot Info Display (top-middle)
local slotInfoLabel = Instance.new("TextLabel", screenGui)
slotInfoLabel.Position = UDim2.new(0.5, -100, 0, 10)
slotInfoLabel.Size = UDim2.new(0, 200, 0, 30)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
slotInfoLabel.TextStrokeTransparency = 0.4
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.ZIndex = 10

-- Main Frame (taller to fit everything)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 640)
frame.Position = UDim2.new(0, 20, 0.5, -280)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

-- Minimize Button
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Text = "-"
minimizeBtn.ZIndex = 999

-- Corn Icon (restore button)
local cornIcon = Instance.new("ImageButton", screenGui)
cornIcon.Size = UDim2.new(0, 60, 0, 60)
cornIcon.Position = UDim2.new(0, 15, 0.27, 0)
cornIcon.BackgroundTransparency = 1
cornIcon.Image = "rbxassetid://76154122039576"
cornIcon.ZIndex = 999
cornIcon.Visible = false

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
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Avoid In Machine Toggle
local toggleAvoidBtn = Instance.new("TextButton", frame)
toggleAvoidBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAvoidBtn.Position = UDim2.new(0, 5, 0, 30)
toggleAvoidBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAvoidBtn.Text = "Avoid In Machine: ON"
updateToggleColor(toggleAvoidBtn, AvoidInMachine)
toggleAvoidBtn.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    toggleAvoidBtn.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
    updateToggleColor(toggleAvoidBtn, AvoidInMachine)
end)

-- Player ESP Toggle
local togglePlayerESPBtn = Instance.new("TextButton", frame)
togglePlayerESPBtn.Size = UDim2.new(1, -10, 0, 25)
togglePlayerESPBtn.Position = UDim2.new(0, 5, 0, 60)
togglePlayerESPBtn.TextColor3 = Color3.new(1, 1, 1)
togglePlayerESPBtn.Text = "Player ESP: OFF"
updateToggleColor(togglePlayerESPBtn, PlayerESPEnabled)
togglePlayerESPBtn.MouseButton1Click:Connect(function()
    PlayerESPEnabled = not PlayerESPEnabled
    togglePlayerESPBtn.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
    updateToggleColor(togglePlayerESPBtn, PlayerESPEnabled)
end)

-- Most Expensive Only Toggle (for ESP)
local toggleMostExpBtn = Instance.new("TextButton", frame)
toggleMostExpBtn.Size = UDim2.new(1, -10, 0, 25)
toggleMostExpBtn.Position = UDim2.new(0, 5, 0, 90)
toggleMostExpBtn.TextColor3 = Color3.new(1, 1, 1)
toggleMostExpBtn.Text = "Most Expensive: OFF"
updateToggleColor(toggleMostExpBtn, MostExpensiveOnly)
toggleMostExpBtn.MouseButton1Click:Connect(function()
    MostExpensiveOnly = not MostExpensiveOnly
    toggleMostExpBtn.Text = "Most Expensive: " .. (MostExpensiveOnly and "ON" or "OFF")
    updateToggleColor(toggleMostExpBtn, MostExpensiveOnly)
end)

-- Auto Purchase Toggle (hold prompts)
local toggleAutoPurchaseBtn = Instance.new("TextButton", frame)
toggleAutoPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoPurchaseBtn.Position = UDim2.new(0, 5, 0, 120)
toggleAutoPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoPurchaseBtn.Text = "Auto Purchase: ON"
updateToggleColor(toggleAutoPurchaseBtn, AutoPurchaseEnabled)
toggleAutoPurchaseBtn.MouseButton1Click:Connect(function()
    AutoPurchaseEnabled = not AutoPurchaseEnabled
    toggleAutoPurchaseBtn.Text = "Auto Purchase: " .. (AutoPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(toggleAutoPurchaseBtn, AutoPurchaseEnabled)
end)

-- Purchase Threshold Dropdown
local thresholdDropdown = Instance.new("TextButton", frame)
thresholdDropdown.Size = UDim2.new(1, -10, 0, 25)
thresholdDropdown.Position = UDim2.new(0, 5, 0, 150)
thresholdDropdown.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
thresholdDropdown.TextColor3 = Color3.new(1, 1, 1)
thresholdDropdown.Text = "Threshold: ≥ 20K"
thresholdDropdown.MouseButton1Click:Connect(function()
    local keys = {"0K","1K","5K","10K","20K","50K","100K","300K"}
    local currentIndex = table.find(keys, tostring(PurchaseThreshold/1000).."K") or 5
    currentIndex = currentIndex % #keys + 1
    local selected = keys[currentIndex]
    PurchaseThreshold = ThresholdOptions[selected]
    thresholdDropdown.Text = "Threshold: ≥ "..selected
end)

-- Require Prompt Near Target toggle (optional)
local toggleReqPromptBtn = Instance.new("TextButton", frame)
toggleReqPromptBtn.Size = UDim2.new(1, -10, 0, 25)
toggleReqPromptBtn.Position = UDim2.new(0, 5, 0, 180)
toggleReqPromptBtn.TextColor3 = Color3.new(1, 1, 1)
toggleReqPromptBtn.Text = "Require Prompt Near Target: OFF"
updateToggleColor(toggleReqPromptBtn, RequirePromptNearTarget)
toggleReqPromptBtn.MouseButton1Click:Connect(function()
    RequirePromptNearTarget = not RequirePromptNearTarget
    toggleReqPromptBtn.Text = "Require Prompt Near Target: " .. (RequirePromptNearTarget and "ON" or "OFF")
    updateToggleColor(toggleReqPromptBtn, RequirePromptNearTarget)
end)

-- Ignore Near My Base toggle
local toggleIgnoreBaseBtn = Instance.new("TextButton", frame)
toggleIgnoreBaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleIgnoreBaseBtn.Position = UDim2.new(0, 5, 0, 210)
toggleIgnoreBaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleIgnoreBaseBtn.Text = "Ignore Near My Base: ON"
updateToggleColor(toggleIgnoreBaseBtn, IgnoreNearMyBase)
toggleIgnoreBaseBtn.MouseButton1Click:Connect(function()
    IgnoreNearMyBase = not IgnoreNearMyBase
    toggleIgnoreBaseBtn.Text = "Ignore Near My Base: " .. (IgnoreNearMyBase and "ON" or "OFF")
    updateToggleColor(toggleIgnoreBaseBtn, IgnoreNearMyBase)
end)

-- Ignore Radius button (cycles)
local ignoreRadiusBtn = Instance.new("TextButton", frame)
ignoreRadiusBtn.Size = UDim2.new(1, -10, 0, 25)
ignoreRadiusBtn.Position = UDim2.new(0, 5, 0, 240)
ignoreRadiusBtn.TextColor3 = Color3.new(1, 1, 1)
ignoreRadiusBtn.Text = ("Ignore Radius: %dstu"):format(IgnoreRadius)
updateToggleColor(ignoreRadiusBtn, true)
ignoreRadiusBtn.MouseButton1Click:Connect(function()
    local idx = table.find(IgnoreRadiusOptions, IgnoreRadius) or 5
    idx = idx % #IgnoreRadiusOptions + 1
    IgnoreRadius = IgnoreRadiusOptions[idx]
    ignoreRadiusBtn.Text = ("Ignore Radius: %dstu"):format(IgnoreRadius)
end)

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

-- Proximity Prompt Auto Purchase
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if not (AutoPurchaseEnabled and prompt and prompt.ActionText) then return end
    if not string.find(prompt.ActionText:lower(), "purchase") then return end

    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model then return end

    -- Animals by Generation
    local overhead = model:FindFirstChild("AnimalOverhead", true)
    if overhead and overhead:FindFirstChild("Generation") then
        local genValue = parseGenerationText(overhead.Generation.Text)
        if genValue >= PurchaseThreshold then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 8)
        end
        return
    end

    -- Lucky Blocks by price
    local rarityHit = getRarityFromName(model.Name)
    if rarityHit then
        local data = AnimalsData[model.Name]
        local price = data and data.Price or 0
        if price >= PurchaseThreshold then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 2)
        end
        return
    end
end)

-- Speed Boost
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70
local toggleSpeedBoostBtn = Instance.new("TextButton", frame)
toggleSpeedBoostBtn.Size = UDim2.new(1, -10, 0, 25)
toggleSpeedBoostBtn.Position = UDim2.new(0, 5, 0, 270)
toggleSpeedBoostBtn.TextColor3 = Color3.new(1, 1, 1)
toggleSpeedBoostBtn.Text = "Speed Boost: OFF"
updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
toggleSpeedBoostBtn.MouseButton1Click:Connect(function()
    SpeedBoostEnabled = not SpeedBoostEnabled
    toggleSpeedBoostBtn.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
end)

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
local toggleAutoJumperBtn = Instance.new("TextButton", frame)
toggleAutoJumperBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoJumperBtn.Position = UDim2.new(0, 5, 0, 300)
toggleAutoJumperBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoJumperBtn.Text = "Anti AFK: OFF"
updateToggleColor(toggleAutoJumperBtn, AutoJumperEnabled)
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
local toggleWalkPurchaseBtn = Instance.new("TextButton", frame)
toggleWalkPurchaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleWalkPurchaseBtn.Position = UDim2.new(0, 5, 0, 330)
toggleWalkPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleWalkPurchaseBtn.Text = "Walk Purchase: OFF"
updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
toggleWalkPurchaseBtn.MouseButton1Click:Connect(function()
    WalkPurchaseEnabled = not WalkPurchaseEnabled
    toggleWalkPurchaseBtn.Text = "Walk Purchase: " .. (WalkPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
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

local function isInsideOrNearMyBase(pos: Vector3)
    if not (IgnoreNearMyBase and myBaseCF and myBaseSize) then return false end
    -- Transform point into plot space & compare against extents + padding
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

-- Walk helpers: target part + movement
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

-- Walk-to-purchase (Workspace scan). ESP remains unchanged.
RunService.Heartbeat:Connect(function()
    if not WalkPurchaseEnabled then return end

    local char = workspace:FindFirstChild(player.Name)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local bestModel, bestGen, bestDist = nil, -math.huge, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local overhead = obj:FindFirstChild("AnimalOverhead", true)
            local genLabel = overhead and overhead:FindFirstChild("Generation")
            if genLabel then
                -- Skip fusing/in machine if requested
                if AvoidInMachine then
                    local stolen = overhead:FindFirstChild("Stolen")
                    local inMachine = stolen and stolen:IsA("TextLabel") and (stolen.Text == "IN MACHINE" or stolen.Text == "FUSING")
                    if inMachine then
                        goto continue_model
                    end
                end

                local targetPart = findTargetPart(obj)
                if targetPart and targetPart:IsA("BasePart") then
                    -- HARD IGNORE anything inside/near my base bounds
                    if isInsideOrNearMyBase(targetPart.Position) then
                        goto continue_model
                    end

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
        ::continue_model::
    end

    if not bestModel then return end

    local targetPart = findTargetPart(bestModel)
    if not (targetPart and targetPart:IsA("BasePart")) then return end

    local dist = (hrp.Position - targetPart.Position).Magnitude
    if dist <= pauseDistance and (tick() - lastPause) >= pauseTime then
        if RequirePromptNearTarget and not purchasePromptActive() then
            stopWalking(humanoid, hrp)
            return
        end
        lastPause = tick()
    end

    setWalkTarget(humanoid, targetPart.Position)
end)

-- Rarity Toggles (ESP)
do
    local y = 360
    for rarity in pairs(RarityColors) do
        local button = Instance.new("TextButton", frame)
        button.Size = UDim2.new(1, -10, 0, 25)
        button.Position = UDim2.new(0, 5, 0, y)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
        updateToggleColor(button, EnabledRarities[rarity])
        button.MouseButton1Click:Connect(function()
            EnabledRarities[rarity] = not EnabledRarities[rarity]
            button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
            updateToggleColor(button, EnabledRarities[rarity])
        end)
        y += 28
    end
end

-- BeeHive Immune Toggle (after rarity list)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()
local toggleBeeHiveBtn = Instance.new("TextButton", frame)
toggleBeeHiveBtn.Size = UDim2.new(1, -10, 0, 25)
toggleBeeHiveBtn.Position = UDim2.new(0, 5, 0, 560)
toggleBeeHiveBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBeeHiveBtn.Text = "BeeHive Immune: ON"
updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)
toggleBeeHiveBtn.MouseButton1Click:Connect(function()
    BeeHiveImmune = not BeeHiveImmune
    toggleBeeHiveBtn.Text = "BeeHive Immune: " .. (BeeHiveImmune and "ON" or "OFF")
    updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)
    if BeeHiveImmune then
        if CharController and CharController.originalMoveFunction then
            Controls.moveFunction = CharController.originalMoveFunction
        end
    end
end)
RunService.Heartbeat:Connect(function()
    if BeeHiveImmune then
        local blur = game:GetService("Lighting"):FindFirstChild("BeeBlur")
        if blur then blur.Enabled = false end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= 70 then cam.FieldOfView = 70 end
        if CharController and CharController.originalMoveFunction and Controls.moveFunction ~= CharController.originalMoveFunction then
            Controls.moveFunction = CharController.originalMoveFunction
        end
    end
end)

-- No Ragdoll Toggle
local NoRagdoll = true
local RagdollController = require(ReplicatedStorage.Controllers.RagdollController)
local originalToggleControls = RagdollController.ToggleControls
local toggleNoRagdollBtn = Instance.new("TextButton", frame)
toggleNoRagdollBtn.Size = UDim2.new(1, -10, 0, 25)
toggleNoRagdollBtn.Position = UDim2.new(0, 5, 0, 590)
toggleNoRagdollBtn.TextColor3 = Color3.new(1, 1, 1)
toggleNoRagdollBtn.Text = "No Ragdoll: ON"
updateToggleColor(toggleNoRagdollBtn, NoRagdoll)
toggleNoRagdollBtn.MouseButton1Click:Connect(function()
    NoRagdoll = not NoRagdoll
    toggleNoRagdollBtn.Text = "No Ragdoll: " .. (NoRagdoll and "ON" or "OFF")
    updateToggleColor(toggleNoRagdollBtn, NoRagdoll)
    if NoRagdoll then
        RagdollController.ToggleControls = function(_, _enable)
            Controls:Enable()
        end
    else
        RagdollController.ToggleControls = originalToggleControls
    end
end)
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

-- Machine state helper (for ESP filtering)
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel and stolenLabel:IsA("TextLabel") and (stolenLabel.Text == "FUSING" or stolenLabel.Text == "IN MACHINE")
end

-- Billboard helper
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

-- ESP loop (unchanged by ignore-base)
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
                if AvoidInMachine and isInMachine(podium) then continue end
                local gen = parseGenerationText((podium:FindFirstChild("Generation") or {}).Text or "")
                if MostExpensiveOnly then
                    if gen > maxGen then
                        maxGen, maxAnimal = gen, podium
                    end
                else
                    if EnabledRarities[rarity] then
                        local displayName = podium:FindFirstChild("DisplayName")
                        if displayName then
                            local modelPart = podium.Parent and podium.Parent.Parent
                            if modelPart and modelPart:IsA("BasePart") then
                                local genText = (podium:FindFirstChild("Generation") and podium.Generation.Text) or ""
                                local bb = createBillboard(modelPart, RarityColors[rarity], displayName.Text .. " | " .. genText)
                                bb.Parent = worldESPFolder
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
                local genText = (maxAnimal:FindFirstChild("Generation") and maxAnimal.Generation.Text) or ""
                local bb = createBillboard(model, RarityColors[rarity], displayName .. " | " .. genText)
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

    if PlayerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                local bb = createBillboard(plr.Character.HumanoidRootPart, Color3.fromRGB(0,255,255), plr.Name .. " | " .. math.floor(dist) .. "m")
                bb.Parent = playerESPFolder
            end
        end
    end
end)
