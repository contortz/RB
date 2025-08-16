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

-- Enabled rarities
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Lucky Block helpers (name/rarity based)
local function getRarityFromName(objectName)
    for rarity in pairs(RarityColors) do
        if string.find(objectName, rarity) then
            return rarity
        end
    end
    return nil
end

local function isLuckyBlockModel(model)
    if not model or not model:IsA("Model") then return false end
    if model.Name:find("Lucky Block") or model.Name:find("LuckyBlock") then return true end
    local rec = AnimalsData[model.Name]
    return rec and (rec.LuckyBlock or rec.DisplayName == "Lucky Block") or false
end

local function getLuckyBlockRarity(model)
    local rec = AnimalsData[model.Name]
    return (rec and rec.Rarity) or getRarityFromName(model.Name)
end

-- Prefer the exact BasePart that owns a ProximityPrompt, then a BasePart named "Part",
-- then fall back to HRP/Root/PrimaryPart/any BasePart.
local function findPromptPart(model)
    -- 1) A ProximityPrompt's parent BasePart (strongest signal)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local p = d.Parent
            if p and p:IsA("BasePart") then
                return p
            end
        end
    end
    -- 2) A BasePart literally named "Part"
    local p = model:FindFirstChild("Part") or model:FindFirstChild("Part", true)
    if p and p:IsA("BasePart") then
        return p
    end
    -- 3) Fallbacks
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("FakeRootPart")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)
end

-- Rarity priority for blocks (used by walker fallback)
local RarityPriority = {
    ["Secret"] = 7,
    ["Brainrot God"] = 6,
    ["Mythic"] = 5,
    ["Legendary"] = 4,
    ["Epic"] = 3,
    ["Rare"] = 2,
    ["Common"] = 1,
}

-- Exclude certain block rarities entirely (default: skip Mythic)
local BlockRarityBlacklist = { Mythic = true }

-- Toggles & Threshold
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = true
local BeeHiveImmune = true
local PurchaseThreshold = 20000 -- default 20K

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

-- Helper for toggle color
local function updateToggleColor(button, isOn)
    button.BackgroundColor3 = isOn and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(70, 70, 70)
end

-- Price formatting
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
local worldESPFolder = Instance.new("Folder", CoreGui)
worldESPFolder.Name = "WorldRarityESP"
local playerESPFolder = Instance.new("Folder", CoreGui)
playerESPFolder.Name = "PlayerESPFolder"

-- UI
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Slot Info Display (top-center)
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

-- Frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 525)
frame.Position = UDim2.new(0, 20, 0.5, -200)
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

-- Corn Icon
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
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    cornIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            cornIcon.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
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

-- Most Expensive Only Toggle
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

-- Auto Purchase Toggle
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

-- Only show filled / total slots
local function updateSlotCountOnly()
    local playerName = player.Name
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, model in ipairs(plots:GetChildren()) do
        local sign = model:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local frame_ = gui and gui:FindFirstChild("Frame")
        local label = frame_ and frame_:FindFirstChild("TextLabel")

        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == playerName then
                local animalPodiums = model:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled = 0
                    local total = 0
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

-- Try hold prompt helper
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

-- Auto-purchase on ProximityPrompt
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if AutoPurchaseEnabled and prompt.ActionText and string.find(prompt.ActionText:lower(), "purchase") then
        local model = prompt:FindFirstAncestorWhichIsA("Model")
        if not model then return end

        -- Animals by generation
        local overhead = model:FindFirstChild("AnimalOverhead", true)
        if overhead and overhead:FindFirstChild("Generation") then
            local genValue = parseGenerationText(overhead.Generation.Text)
            if genValue >= PurchaseThreshold then
                task.wait(0.10)
                tryHoldPrompt(prompt, 3, 8)
            end
            return
        end

        -- Lucky Blocks by rarity toggle
        if isLuckyBlockModel(model) then
            local rarity = getLuckyBlockRarity(model)
            if rarity and not BlockRarityBlacklist[rarity] and EnabledRarities[rarity] then
                task.wait(0.10)
                tryHoldPrompt(prompt, 3, 2)
            end
            return
        end
    end
end)

-- Speed Boost
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70

local toggleSpeedBoostBtn = Instance.new("TextButton", frame)
toggleSpeedBoostBtn.Size = UDim2.new(1, -10, 0, 25)
toggleSpeedBoostBtn.Position = UDim2.new(0, 5, 0, 240)
toggleSpeedBoostBtn.TextColor3 = Color3.new(1, 1, 1)
toggleSpeedBoostBtn.Text = "Speed Boost: OFF"
updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
toggleSpeedBoostBtn.MouseButton1Click:Connect(function()
    SpeedBoostEnabled = not SpeedBoostEnabled
    toggleSpeedBoostBtn.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
end)

-- Use CharacterController module consistently
local CharacterControllerModule = require(ReplicatedStorage.Controllers.CharacterController)

RunService.Heartbeat:Connect(function()
    if SpeedBoostEnabled then
        local char, humanoid = CharacterControllerModule:GetCharacter()
        if humanoid then
            humanoid.WalkSpeed = DesiredWalkSpeed
        end
    end
end)

-- Anti-AFK (auto jumper)
local AutoJumperEnabled = false
local JumpInterval = 60
local LastJumpTime = tick()

local toggleAutoJumperBtn = Instance.new("TextButton", frame)
toggleAutoJumperBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoJumperBtn.Position = UDim2.new(0, 5, 0, 270)
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
toggleWalkPurchaseBtn.Position = UDim2.new(0, 5, 0, 300)
toggleWalkPurchaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleWalkPurchaseBtn.Text = "Walk Purchase: OFF"
updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
toggleWalkPurchaseBtn.MouseButton1Click:Connect(function()
    WalkPurchaseEnabled = not WalkPurchaseEnabled
    toggleWalkPurchaseBtn.Text = "Walk Purchase: " .. (WalkPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(toggleWalkPurchaseBtn, WalkPurchaseEnabled)
end)

-- Pause settings for walker
local pauseDistance = 5
local pauseTime = 0.35
local lastPause = 0

-- Check if purchase prompt is visible in PlayerGui
local function purchasePromptActive()
    local promptGui = player.PlayerGui:FindFirstChild("ProximityPrompts")
    if not promptGui then return false end
    local promptFrame = promptGui:FindFirstChild("Prompt", true)
    if not promptFrame then return false end
    local actionText = promptFrame:FindFirstChild("ActionText", true)
    if not actionText then return false end
    return string.find(actionText.Text:lower(), "purchase") ~= nil
end

-- Walker helpers (drive both systems and provide a hard stop)
local function setWalkTarget(humanoid, pos)
    if not (humanoid and pos) then return end
    humanoid:MoveTo(pos)           -- pathfinding target
    humanoid.WalkToPoint = pos     -- direct walk target
end

local function stopWalking(humanoid, hrp)
    if not humanoid then return end
    humanoid:Move(Vector3.new(), true)
    if hrp then
        humanoid:MoveTo(hrp.Position)
        humanoid.WalkToPoint = hrp.Position
    end
end

-- Walk Purchase Logic (Animals by Generation; Lucky Blocks by rarity)
RunService.Heartbeat:Connect(function()
    if not WalkPurchaseEnabled then return end

    local char = workspace:FindFirstChild(player.Name)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local containers = {
        workspace:FindFirstChild("RenderedMovingAnimals"),
        workspace:FindFirstChild("MovingAnimals"),
    }

    ----------------------------------------------------------------
    -- PASS 1: Animals (highest Generation >= PurchaseThreshold)
    ----------------------------------------------------------------
    local bestAnimal, bestGen, bestAnimalDist, bestAnimalPart =
        nil, -math.huge, math.huge, nil

    for _, folder in ipairs(containers) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                local overhead = model:FindFirstChild("AnimalOverhead", true)
                local genLabel = overhead and overhead:FindFirstChild("Generation")
                if genLabel then
                    local targetPart = findPromptPart(model)
                    if targetPart then
                        local genValue = parseGenerationText(genLabel.Text or "")
                        if genValue >= PurchaseThreshold then
                            local dist = (hrp.Position - targetPart.Position).Magnitude
                            if (genValue > bestGen) or (genValue == bestGen and dist < bestAnimalDist) then
                                bestAnimal, bestGen, bestAnimalDist, bestAnimalPart = model, genValue, dist, targetPart
                            end
                        end
                    end
                end
            end
        end
    end

    if bestAnimal and bestAnimalPart then
        local dist = (hrp.Position - bestAnimalPart.Position).Magnitude
        if dist <= pauseDistance then
            if tick() - lastPause >= pauseTime then
                if not purchasePromptActive() then
                    stopWalking(humanoid, hrp)
                    return
                end
                lastPause = tick()
            end
        end
        setWalkTarget(humanoid, bestAnimalPart.Position)
        return
    end

    ----------------------------------------------------------------
    -- PASS 2: Lucky Blocks (rarity priority; Mythic can be blacklisted)
    ----------------------------------------------------------------
    local bestBlock, bestPri, bestBlockDist, bestBlockPart =
        nil, -math.huge, math.huge, nil

    for _, folder in ipairs(containers) do
        if folder then
            for _, mdl in ipairs(folder:GetChildren()) do
                if mdl:IsA("Model") and isLuckyBlockModel(mdl) then
                    local rarity = getLuckyBlockRarity(mdl)
                    if rarity and not (BlockRarityBlacklist and BlockRarityBlacklist[rarity]) and EnabledRarities[rarity] then
                        local adorn = findPromptPart(mdl)
                        if adorn then
                            local pri = (RarityPriority and RarityPriority[rarity]) or 0
                            local dist = (hrp.Position - adorn.Position).Magnitude
                            if (pri > bestPri) or (pri == bestPri and dist < bestBlockDist) then
                                bestBlock, bestPri, bestBlockDist, bestBlockPart = mdl, pri, dist, adorn
                            end
                        end
                    end
                end
            end
        end
    end

    if bestBlock and bestBlockPart then
        local dist = (hrp.Position - bestBlockPart.Position).Magnitude
        if dist <= pauseDistance then
            if tick() - lastPause >= pauseTime then
                if not purchasePromptActive() then
                    stopWalking(humanoid, hrp)
                    return
                end
                lastPause = tick()
            end
        end
        setWalkTarget(humanoid, bestBlockPart.Position)
    end
end)

-- BeeHive Immune Toggle (use CharacterControllerModule + Controls)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local toggleBeeHiveBtn = Instance.new("TextButton", frame)
toggleBeeHiveBtn.Size = UDim2.new(1, -10, 0, 25)
toggleBeeHiveBtn.Position = UDim2.new(0, 5, 0, 210)
toggleBeeHiveBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBeeHiveBtn.Text = "BeeHive Immune: ON"
updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)
toggleBeeHiveBtn.MouseButton1Click:Connect(function()
    BeeHiveImmune = not BeeHiveImmune
    toggleBeeHiveBtn.Text = "BeeHive Immune: " .. (BeeHiveImmune and "ON" or "OFF")
    updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)
    if BeeHiveImmune then
        Controls.moveFunction = CharacterControllerModule.originalMoveFunction
    end
end)

RunService.Heartbeat:Connect(function()
    if BeeHiveImmune then
        local blur = game:GetService("Lighting"):FindFirstChild("BeeBlur")
        if blur then blur.Enabled = false end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= 70 then cam.FieldOfView = 70 end
        if Controls.moveFunction ~= CharacterControllerModule.originalMoveFunction then
            Controls.moveFunction = CharacterControllerModule.originalMoveFunction
        end
    end
end)

-- No Ragdoll Toggle (keep modules distinct)
local NoRagdoll = true
local RagdollController = require(ReplicatedStorage.Controllers.RagdollController)
local originalToggleControls = RagdollController.ToggleControls

local toggleNoRagdollBtn = Instance.new("TextButton", frame)
toggleNoRagdollBtn.Size = UDim2.new(1, -10, 0, 25)
toggleNoRagdollBtn.Position = UDim2.new(0, 5, 0, 180)
toggleNoRagdollBtn.TextColor3 = Color3.new(1, 1, 1)
toggleNoRagdollBtn.Text = "No Ragdoll: ON"
updateToggleColor(toggleNoRagdollBtn, NoRagdoll)
toggleNoRagdollBtn.MouseButton1Click:Connect(function()
    NoRagdoll = not NoRagdoll
    toggleNoRagdollBtn.Text = "No Ragdoll: " .. (NoRagdoll and "ON" or "OFF")
    updateToggleColor(toggleNoRagdollBtn, NoRagdoll)
    if NoRagdoll then
        RagdollController.ToggleControls = function(_, enable)
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

-- "IN MACHINE" (FUSING) check
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel and stolenLabel:IsA("TextLabel") and stolenLabel.Text == "FUSING"
end

-- World ESP
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

-- ESP Loop
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
                            local basePart = podium.Parent and podium.Parent.Parent
                            if basePart and basePart:IsA("BasePart") then
                                local bb = createBillboard(basePart, RarityColors[rarity], displayName.Text .. " | " .. (podium.Generation and podium.Generation.Text or "?"))
                                bb.Parent = worldESPFolder
                            end
                        end
                    end
                end
            end

        elseif podium.Name:find("Lucky Block") then
            local rarity
            for r in pairs(RarityColors) do
                if podium.Name:find(r) then rarity = r break end
            end
            if rarity then
                local data = AnimalsData[podium.Name]
                local price = data and data.Price or 0
                if MostExpensiveOnly then
                    if price > maxPrice then
                        maxPrice, maxBlock = price, podium
                    end
                else
                    if EnabledRarities[rarity] then
                        local modelPart = podium.PrimaryPart
                        if modelPart then
                            local bb = createBillboard(modelPart, RarityColors[rarity], podium.Name .. " | $" .. formatPrice(price))
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
            local basePart = maxAnimal.Parent and maxAnimal.Parent.Parent
            if basePart and basePart:IsA("BasePart") then
                local bb = createBillboard(basePart, RarityColors[rarity], displayName .. " | " .. (maxAnimal.Generation and maxAnimal.Generation.Text or "?"))
                bb.Parent = worldESPFolder
            end
        end
        if maxBlock then
            local rarity
            for r in pairs(RarityColors) do
                if maxBlock.Name:find(r) then rarity = r break end
            end
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
