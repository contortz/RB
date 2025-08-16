--// Services & Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Data (Lucky Blocks)
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

-- =========================
--   CONFIG / CONSTANTS
-- =========================
local IGNORE_RADIUS = 90                  -- fixed default (no UI to change)
local AvoidInMachine = true               -- ESP filter
local PlayerESPEnabled = false
local MostExpensiveOnly = false           -- ESP "max only"
local AutoPurchaseEnabled = true          -- hold prompts automatically
local BeeHiveImmune = true
local PurchaseThreshold = 20000           -- animals only; Lucky Blocks bypass this
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70
local AutoJumperEnabled = false
local WalkPurchaseEnabled = false
local ShowIgnoreRing = true               -- show the blue ring ESP

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255),
}

-- Enabled rarities (default)
local EnabledRarities = {}
for r in pairs(RarityColors) do
    EnabledRarities[r] = (r == "Brainrot God" or r == "Secret")
end

-- Rarity priority (for choosing Lucky Blocks)
local RarityPriority = {
    Secret = 7, ["Brainrot God"] = 6, Mythic = 5,
    Legendary = 4, Epic = 3, Rare = 2, Common = 1,
}

-- Threshold options (UI)
local ThresholdOptions = {
    ["0K"] = 0, ["1K"] = 1000, ["5K"] = 5000, ["10K"] = 10000,
    ["20K"] = 20000, ["50K"] = 50000, ["100K"] = 100000, ["300K"] = 300000
}

-- =========================
--   HELPERS
-- =========================
local function updateToggleColor(btn, isOn)
    if not btn then return end
    btn.BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
end

local function formatPrice(v)
    if v >= 1e9 then return string.format("%.1fB", v/1e9)
    elseif v >= 1e6 then return string.format("%.1fM", v/1e6)
    elseif v >= 1e3 then return string.format("%.1fK", v/1e3)
    else return tostring(v) end
end

-- "123K/s" -> 123000
local function parseGenerationText(text)
    local num = tonumber((text or ""):match("[%d%.]+")) or 0
    if text:find("K") then num *= 1e3 end
    if text:find("M") then num *= 1e6 end
    return num
end

-- Lucky Block utilities
local function getRarityFromName(name)
    for r in pairs(RarityColors) do
        if string.find(name, r) then return r end
    end
    return nil
end

local function isLuckyBlockModel(model)
    if not (model and model:IsA("Model")) then return false end
    if model.Name:find("Lucky Block") or model.Name:find("LuckyBlock") then return true end
    local rec = AnimalsData[model.Name]
    return rec and (rec.LuckyBlock or rec.DisplayName == "Lucky Block") or false
end

local function getLuckyBlockRarity(model)
    local rec = AnimalsData[model.Name]
    return (rec and rec.Rarity) or getRarityFromName(model.Name)
end

local function findTargetPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model:FindFirstChild("FakeRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Part", true)
        or model:FindFirstChildWhichIsA("BasePart", true)
end

-- Safe requires / fallbacks
local okCC, CharController = pcall(function()
    return require(ReplicatedStorage.Controllers.CharacterController)
end)
if not okCC or type(CharController) ~= "table" or not CharController.GetCharacter then
    CharController = {
        GetCharacter = function()
            local c = player.Character or player.CharacterAdded:Wait()
            local h = c:FindFirstChildOfClass("Humanoid")
            return c, h
        end,
        originalMoveFunction = nil
    }
end

local okRC, RagdollController = pcall(function()
    return require(ReplicatedStorage.Controllers.RagdollController)
end)
if not okRC or type(RagdollController) ~= "table" then
    RagdollController = { ToggleControls = function() end }
end

-- =========================
--   ESP FOLDERS
-- =========================
local worldESPFolder = Instance.new("Folder")
worldESPFolder.Name = "WorldRarityESP"
worldESPFolder.Parent = CoreGui

local playerESPFolder = Instance.new("Folder")
playerESPFolder.Name = "PlayerESPFolder"
playerESPFolder.Parent = CoreGui

-- =========================
--   UI
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Slot info (top-middle)
local slotInfoLabel = Instance.new("TextLabel")
slotInfoLabel.Position = UDim2.new(0.5, -100, 0, 10)
slotInfoLabel.Size = UDim2.new(0, 200, 0, 30)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1,1,1)
slotInfoLabel.TextStrokeTransparency = 0.4
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.ZIndex = 10
slotInfoLabel.Parent = screenGui

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 560)
frame.Position = UDim2.new(0, 20, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Minimize + restore icon
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Text = "-"
minimizeBtn.ZIndex = 999
minimizeBtn.Parent = frame

local cornIcon = Instance.new("ImageButton")
cornIcon.Size = UDim2.new(0, 60, 0, 60)
cornIcon.Position = UDim2.new(0, 15, 0.27, 0)
cornIcon.BackgroundTransparency = 1
cornIcon.Image = "rbxassetid://76154122039576"
cornIcon.ZIndex = 999
cornIcon.Visible = false
cornIcon.Parent = screenGui

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    cornIcon.Visible = true
end)
cornIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    cornIcon.Visible = false
end)

-- Dragging for corn icon
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
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            cornIcon.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.Text = "BrainRotz by Dreamz"
title.Parent = frame

-- Buttons factory
local function makeBtn(y, text, onClick, isToggle)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 25)
    b.Position = UDim2.new(0, 5, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.Parent = frame
    if onClick then b.MouseButton1Click:Connect(function() onClick(b) end) end
    if isToggle ~= nil then updateToggleColor(b, isToggle) end
    return b
end

-- Top toggles
local yRow = 30
local btnAvoid = makeBtn(yRow, "Avoid In Machine: ON", function(b)
    AvoidInMachine = not AvoidInMachine
    b.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
    updateToggleColor(b, AvoidInMachine)
end, AvoidInMachine); yRow = yRow + 30

local btnPESP = makeBtn(yRow, "Player ESP: OFF", function(b)
    PlayerESPEnabled = not PlayerESPEnabled
    b.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
    updateToggleColor(b, PlayerESPEnabled)
end, PlayerESPEnabled); yRow = yRow + 30

local btnMost = makeBtn(yRow, "Most Expensive: OFF", function(b)
    MostExpensiveOnly = not MostExpensiveOnly
    b.Text = "Most Expensive: " .. (MostExpensiveOnly and "ON" or "OFF")
    updateToggleColor(b, MostExpensiveOnly)
end, MostExpensiveOnly); yRow = yRow + 30

local btnAuto = makeBtn(yRow, "Auto Purchase: ON", function(b)
    AutoPurchaseEnabled = not AutoPurchaseEnabled
    b.Text = "Auto Purchase: " .. (AutoPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(b, AutoPurchaseEnabled)
end, AutoPurchaseEnabled); yRow = yRow + 30

-- Threshold dropdown (animals only)
local thresholdDropdown = makeBtn(yRow, "Threshold: ≥ 20K", function(b)
    local order = {"0K","1K","5K","10K","20K","50K","100K","300K"}
    local current = tostring(PurchaseThreshold/1000).."K"
    local idx = table.find(order, current) or 5
    idx = (idx % #order) + 1
    local sel = order[idx]
    PurchaseThreshold = ThresholdOptions[sel]
    b.Text = "Threshold: ≥ " .. sel
end); yRow = yRow + 30

-- Show ignore ring toggle
local btnRing = makeBtn(yRow, "Show Ignore Ring: ON", function(b)
    ShowIgnoreRing = not ShowIgnoreRing
    b.Text = "Show Ignore Ring: " .. (ShowIgnoreRing and "ON" or "OFF")
    updateToggleColor(b, ShowIgnoreRing)
end, ShowIgnoreRing); yRow = yRow + 30

-- Speed boost
local btnSpeed = makeBtn(yRow, "Speed Boost: OFF", function(b)
    SpeedBoostEnabled = not SpeedBoostEnabled
    b.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(b, SpeedBoostEnabled)
end, SpeedBoostEnabled); yRow = yRow + 30

-- Anti AFK
local btnAFK = makeBtn(yRow, "Anti AFK: OFF", function(b)
    AutoJumperEnabled = not AutoJumperEnabled
    b.Text = "Anti AFK: " .. (AutoJumperEnabled and "ON" or "OFF")
    updateToggleColor(b, AutoJumperEnabled)
end, AutoJumperEnabled); yRow = yRow + 30

-- Walk purchase
local btnWalk = makeBtn(yRow, "Walk Purchase: OFF", function(b)
    WalkPurchaseEnabled = not WalkPurchaseEnabled
    b.Text = "Walk Purchase: " .. (WalkPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(b, WalkPurchaseEnabled)
end, WalkPurchaseEnabled); yRow = yRow + 30

-- Rarity toggles
local rarityStartY = yRow
for rarity in pairs(RarityColors) do
    makeBtn(rarityStartY, rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF"), function(b)
        EnabledRarities[rarity] = not EnabledRarities[rarity]
        b.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
        updateToggleColor(b, EnabledRarities[rarity])
    end, EnabledRarities[rarity])
    rarityStartY = rarityStartY + 28
end

-- =========================
--   SLOT COUNTER
-- =========================
local function updateSlotCountOnly()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr  = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")
        if label and label.Text and label.Text:match("^(.-)'s Base") == player.Name then
            local animalPodiums = plot:FindFirstChild("AnimalPodiums")
            if animalPodiums then
                local filled, total = 0, 0
                for _, m in ipairs(animalPodiums:GetChildren()) do
                    if m:IsA("Model") then
                        local base = m:FindFirstChild("Base")
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
task.delay(1, updateSlotCountOnly)
task.spawn(function()
    while true do
        updateSlotCountOnly()
        task.wait(5)
    end
end)

-- =========================
--   PROMPT HOLD (AUTO BUY)
-- =========================
local function tryHoldPrompt(prompt, holdTime, maxRetries)
    maxRetries = maxRetries or 2
    for _ = 1, maxRetries do
        prompt:InputHoldBegin()
        task.wait(holdTime)
        prompt:InputHoldEnd()
        task.wait(0.2)
        if not prompt:IsDescendantOf(game) or not prompt.Enabled then break end
    end
end

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if not (AutoPurchaseEnabled and prompt and prompt.ActionText) then return end
    if not string.find(prompt.ActionText:lower(), "purchase") then return end

    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model then return end

    -- 1) Animals by Generation (use threshold)
    local overhead = model:FindFirstChild("AnimalOverhead", true)
    if overhead and overhead:FindFirstChild("Generation") then
        local genValue = parseGenerationText(overhead.Generation.Text)
        if genValue >= PurchaseThreshold then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 8)
        end
        return
    end

    -- 2) Lucky Blocks (bypass threshold, still optionally respect rarity toggle)
    if isLuckyBlockModel(model) then
        local rarity = getLuckyBlockRarity(model)
        if not rarity or EnabledRarities[rarity] then
            task.wait(0.10)
            tryHoldPrompt(prompt, 3, 3)
        end
        return
    end
end)

-- =========================
--   SPEED BOOST / ANTI AFK
-- =========================
RunService.Heartbeat:Connect(function()
    if SpeedBoostEnabled then
        local _, humanoid = CharController:GetCharacter()
        if humanoid then humanoid.WalkSpeed = DesiredWalkSpeed end
    end
end)

local JumpInterval, LastJumpTime = 60, tick()
RunService.Heartbeat:Connect(function()
    if AutoJumperEnabled and tick() - LastJumpTime >= JumpInterval then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        LastJumpTime = tick()
    end
end)

-- =========================
--   NO RAGDOLL / BEEHIVE
-- =========================
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local NoRagdoll = true
if RagdollController and RagdollController.ToggleControls then
    RagdollController.ToggleControls = function(_, _enable) Controls:Enable() end
end

RunService.Heartbeat:Connect(function()
    -- BeeHive immunity (cam blur + movement restore)
    if BeeHiveImmune then
        local blur = game:GetService("Lighting"):FindFirstChild("BeeBlur")
        if blur then blur.Enabled = false end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= 70 then cam.FieldOfView = 70 end
        if CharController and Controls and Controls.moveFunction and CharController.originalMoveFunction and Controls.moveFunction ~= CharController.originalMoveFunction then
            Controls.moveFunction = CharController.originalMoveFunction
        end
    end

    -- Safety exit ragdoll
    if NoRagdoll then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- =========================
--   BASE CENTER + BLUE RING
-- =========================
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
            local fr  = gui and gui:FindFirstChild("Frame")
            local label = fr and fr:FindFirstChild("TextLabel")
            if label and label.Text and label.Text:match("^(.-)'s Base") == player.Name then
                baseRootCache = plot:FindFirstChild("MainRoot")
                local cf = nil
                if plot:IsA("Model") then
                    cf = select(1, plot:GetBoundingBox())
                end
                if not cf then
                    if baseRootCache then
                        cf = baseRootCache.CFrame
                    else
                        for _, d in ipairs(plot:GetDescendants()) do
                            if d:IsA("BasePart") then cf = d.CFrame break end
                        end
                    end
                end
                if cf then basePosCache = cf.Position end
                break
            end
        end
    end
    baseCacheAt = os.clock()
    return baseRootCache, basePosCache
end

-- Blue ring
local ringAdornment, ringAnchorPart
local function destroyIgnoreRing()
    if ringAdornment then ringAdornment:Destroy(); ringAdornment = nil end
    if ringAnchorPart then ringAnchorPart:Destroy(); ringAnchorPart = nil end
end
local function ensureIgnoreRing()
    if not ShowIgnoreRing then destroyIgnoreRing(); return end
    local baseRoot, basePos = getLocalBaseRootAndPos()
    if not baseRoot and not basePos then destroyIgnoreRing(); return end

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
        ringAnchorPart:Destroy()
        ringAnchorPart = nil
    end
    if not adorneePart then destroyIgnoreRing(); return end

    if not ringAdornment or not ringAdornment.Parent then
        local cyl = Instance.new("CylinderHandleAdornment")
        cyl.Name = "IgnoreRadiusRing"
        cyl.AlwaysOnTop = true
        cyl.ZIndex = 10
        cyl.Transparency = 0.2
        cyl.Color3 = Color3.fromRGB(0, 155, 255)  -- blue
        cyl.Height = 0.06
        cyl.Radius = IGNORE_RADIUS
        cyl.Adornee = adorneePart
        cyl.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        -- Parent to camera (safe for adornments)
        cyl.Parent = Workspace.CurrentCamera
        ringAdornment = cyl
    else
        ringAdornment.Adornee = adorneePart
        ringAdornment.Radius = IGNORE_RADIUS
        ringAdornment.Height = 0.06
        ringAdornment.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        ringAdornment.Parent = Workspace.CurrentCamera
    end
end
task.spawn(function()
    while true do
        pcall(ensureIgnoreRing)
        task.wait(0.5)
    end
end)

-- =========================
--   WALK-TO-PURCHASE
-- =========================
local pauseDistance, pauseTime, lastPause = 5, 0.35, 0

RunService.Heartbeat:Connect(function()
    if not WalkPurchaseEnabled then return end

    local char = Workspace:FindFirstChild(player.Name)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    -- get base center to ignore nearby targets
    local _, baseCenter = getLocalBaseRootAndPos()

    local bestAnimal, bestGen, bestADist = nil, -math.huge, math.huge
    local bestBlock, bestBPri, bestBDist = nil, -math.huge, math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local adornee = findTargetPart(obj)
            if adornee then
                if baseCenter then
                    local dBase = (adornee.Position - baseCenter).Magnitude
                    if dBase <= IGNORE_RADIUS then
                        goto continue_obj
                    end
                end

                local overhead = obj:FindFirstChild("AnimalOverhead", true)
                local genLabel = overhead and overhead:FindFirstChild("Generation")

                if genLabel then
                    if AvoidInMachine then
                        local stolen = overhead:FindFirstChild("Stolen")
                        local inMachine = stolen and stolen:IsA("TextLabel") and (stolen.Text == "IN MACHINE" or stolen.Text == "FUSING")
                        if inMachine then goto continue_obj end
                    end
                    local g = parseGenerationText(genLabel.Text or "")
                    if g >= PurchaseThreshold then
                        local dist = (hrp.Position - adornee.Position).Magnitude
                        if (g > bestGen) or (g == bestGen and dist < bestADist) then
                            bestAnimal, bestGen, bestADist = obj, g, dist
                        end
                    end
                    goto continue_obj
                end

                if isLuckyBlockModel(obj) then
                    local rarity = getLuckyBlockRarity(obj)
                    if not rarity or EnabledRarities[rarity] then
                        local pri = RarityPriority[rarity] or 0
                        local dist = (hrp.Position - adornee.Position).Magnitude
                        if (pri > bestBPri) or (pri == bestBPri and dist < bestBDist) then
                            bestBlock, bestBPri, bestBDist = obj, pri, dist
                        end
                    end
                end
            end
        end
        ::continue_obj::
    end

    local target = bestAnimal or bestBlock
    if not target then return end
    local tPart = findTargetPart(target)
    if not tPart then return end

    local dist = (hrp.Position - tPart.Position).Magnitude
    if dist <= pauseDistance and (tick() - lastPause) >= pauseTime then
        humanoid:Move(Vector3.new(), true)
        lastPause = tick()
        return
    end

    humanoid:MoveTo(tPart.Position)
    humanoid.WalkToPoint = tPart.Position
end)

-- =========================
--   WORLD / PLAYER ESP
-- =========================
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
                            local model = podium.Parent and podium.Parent.Parent
                            if displayName and model and model:IsA("BasePart") then
                                local gtxt = (podium:FindFirstChild("Generation") and podium.Generation.Text) or ""
                                local bb = createBillboard(model, RarityColors[rarity], displayName.Text .. " | " .. gtxt)
                                bb.Parent = worldESPFolder
                            end
                        end
                    end
                end
            end
        elseif podium:IsA("Model") and isLuckyBlockModel(podium) then
            local rarity = getLuckyBlockRarity(podium)
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
                local gtxt = (maxAnimal:FindFirstChild("Generation") and maxAnimal.Generation.Text) or ""
                local bb = createBillboard(model, RarityColors[rarity], displayName .. " | " .. gtxt)
                bb.Parent = worldESPFolder
            end
        end
        if maxBlock then
            local rarity = getLuckyBlockRarity(maxBlock)
            local data = AnimalsData[maxBlock.Name]
            local price = data and data.Price or 0
            if maxBlock.PrimaryPart then
                local bb = createBillboard(maxBlock.PrimaryPart, RarityColors[rarity], maxBlock.Name .. " | $" .. formatPrice(price))
                bb.Parent = worldESPFolder
            end
        end
    end

    if PlayerESPEnabled then
        local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if me and hrp then
                    local dist = (me.Position - hrp.Position).Magnitude
                    local bb = createBillboard(hrp, Color3.fromRGB(0,255,255), plr.Name .. " | " .. math.floor(dist) .. "m")
                    bb.Parent = playerESPFolder
                end
            end
        end
    end
end)
