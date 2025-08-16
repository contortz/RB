--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Data
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

--// Rarities
local RarityColors = {
    Common = Color3.fromRGB(150,150,150),
    Rare = Color3.fromRGB(0,170,255),
    Epic = Color3.fromRGB(170,0,255),
    Legendary = Color3.fromRGB(255,215,0),
    Mythic = Color3.fromRGB(255,85,0),
    ["Brainrot God"] = Color3.fromRGB(255,0,0),
    Secret = Color3.fromRGB(0,255,255),
}
local EnabledRarities = {}
for r in pairs(RarityColors) do
    EnabledRarities[r] = (r == "Brainrot God" or r == "Secret")
end
local function getRarityFromName(name)
    for r in pairs(RarityColors) do
        if string.find(name, r) then return r end
    end
end

--// Toggles & thresholds
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = true
local BeeHiveImmune = true
local PurchaseThreshold = 20000
local WalkPurchaseEnabled = false

-- Only for WALKER: ignore animals **near your base**
local BaseIgnoreRadiusStuds = 20        -- default ignore radius
local ShowBaseIgnoreRadius = true       -- draw the circle ring on your base

local ThresholdOptions = {
    ["0K"]   = 0,
    ["1K"]   = 1000,
    ["5K"]   = 5000,
    ["10K"]  = 10000,
    ["20K"]  = 20000,
    ["50K"]  = 50000,
    ["100K"] = 100000,
    ["300K"] = 300000
}

--// Helpers
local function updateToggleColor(btn, on) btn.BackgroundColor3 = on and Color3.fromRGB(0,200,0) or Color3.fromRGB(70,70,70) end
local function formatPrice(v)
    if v >= 1e9 then return string.format("%.1fB", v/1e9)
    elseif v >= 1e6 then return string.format("%.1fM", v/1e6)
    elseif v >= 1e3 then return string.format("%.1fK", v/1e3)
    else return tostring(v) end
end
local function parseGenerationText(t)
    local n = tonumber((t or ""):match("[%d%.]+")) or 0
    if (t or ""):find("K") then n = n * 1000 end
    if (t or ""):find("M") then n = n * 1000000 end
    return n
end
local function countKeys(t) local c=0; for _ in pairs(t) do c = c + 1 end; return c end

--// ESP folders
local worldESPFolder = Instance.new("Folder", CoreGui) ; worldESPFolder.Name = "WorldRarityESP"
local playerESPFolder = Instance.new("Folder", CoreGui); playerESPFolder.Name = "PlayerESPFolder"

--// UI root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Slots HUD (top center)
local slotInfoLabel = Instance.new("TextLabel", screenGui)
slotInfoLabel.Position = UDim2.new(0.5, -100, 0, 10)
slotInfoLabel.Size = UDim2.new(0, 200, 0, 30)
slotInfoLabel.BackgroundTransparency = 1
slotInfoLabel.TextColor3 = Color3.new(1,1,1)
slotInfoLabel.TextStrokeTransparency = 0.4
slotInfoLabel.TextScaled = true
slotInfoLabel.Font = Enum.Font.GothamBold
slotInfoLabel.Text = "Slots: ? / ?"
slotInfoLabel.ZIndex = 10

-- Main frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 560)
frame.Position = UDim2.new(0, 20, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

-- Minimize + restore
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Text = "-"
minimizeBtn.ZIndex = 999

local cornIcon = Instance.new("ImageButton", screenGui)
cornIcon.Size = UDim2.new(0, 60, 0, 60)
cornIcon.Position = UDim2.new(0, 15, 0.27, 0)
cornIcon.BackgroundTransparency = 1
cornIcon.Image = "rbxassetid://76154122039576"
cornIcon.ZIndex = 999
cornIcon.Visible = false

minimizeBtn.MouseButton1Click:Connect(function() frame.Visible=false; cornIcon.Visible=true end)
cornIcon.MouseButton1Click:Connect(function() frame.Visible=true; cornIcon.Visible=false end)
do -- drag corn icon
    local dragging, dragInput, dragStart, startPos
    cornIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = cornIcon.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    cornIcon.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input==dragInput then
            local d = input.Position - dragStart
            cornIcon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "BrainRotz by Dreamz"
title.TextSize = 10

-- Buttons
local function makeBtn(y, text)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -10, 0, 25)
    b.Position = UDim2.new(0, 5, 0, y)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    return b
end

-- Avoid In Machine
local btnAvoid = makeBtn(30, "Avoid In Machine: ON"); updateToggleColor(btnAvoid, true)
btnAvoid.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    btnAvoid.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
    updateToggleColor(btnAvoid, AvoidInMachine)
end)

-- Player ESP
local btnPesp = makeBtn(60, "Player ESP: OFF"); updateToggleColor(btnPesp, false)
btnPesp.MouseButton1Click:Connect(function()
    PlayerESPEnabled = not PlayerESPEnabled
    btnPesp.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
    updateToggleColor(btnPesp, PlayerESPEnabled)
end)

-- Most Expensive
local btnMost = makeBtn(90, "Most Expensive: OFF"); updateToggleColor(btnMost, false)
btnMost.MouseButton1Click:Connect(function()
    MostExpensiveOnly = not MostExpensiveOnly
    btnMost.Text = "Most Expensive: " .. (MostExpensiveOnly and "ON" or "OFF")
    updateToggleColor(btnMost, MostExpensiveOnly)
end)

-- Auto Purchase
local btnAuto = makeBtn(120, "Auto Purchase: ON"); updateToggleColor(btnAuto, true)
btnAuto.MouseButton1Click:Connect(function()
    AutoPurchaseEnabled = not AutoPurchaseEnabled
    btnAuto.Text = "Auto Purchase: " .. (AutoPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(btnAuto, AutoPurchaseEnabled)
end)

-- Threshold
local btnThresh = makeBtn(150, "Threshold: ≥ 20K")
btnThresh.BackgroundColor3 = Color3.fromRGB(0,120,255)
btnThresh.MouseButton1Click:Connect(function()
    local keys = {"0K","1K","5K","10K","20K","50K","100K","300K"}
    local cur = table.find(keys, tostring(PurchaseThreshold/1000).."K") or 5
    local nexti = cur % #keys + 1
    local pick = keys[nexti]
    PurchaseThreshold = ThresholdOptions[pick]
    btnThresh.Text = "Threshold: ≥ "..pick
end)

-- SHOW IGNORE RADIUS (visual ring)
local btnShowRing = makeBtn(180, "Show Ignore Radius: ON"); updateToggleColor(btnShowRing, true)
btnShowRing.MouseButton1Click:Connect(function()
    ShowBaseIgnoreRadius = not ShowBaseIgnoreRadius
    btnShowRing.Text = "Show Ignore Radius: " .. (ShowBaseIgnoreRadius and "ON" or "OFF")
    updateToggleColor(btnShowRing, ShowBaseIgnoreRadius)
end)

-- Radius -/+ controls
local minusBtn = Instance.new("TextButton", frame)
minusBtn.Size = UDim2.new(0, 40, 0, 24)
minusBtn.Position = UDim2.new(0, 5, 0, 208)
minusBtn.Text = "-5"
minusBtn.TextColor3 = Color3.new(1,1,1)
minusBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)

local plusBtn = Instance.new("TextButton", frame)
plusBtn.Size = UDim2.new(0, 40, 0, 24)
plusBtn.Position = UDim2.new(0, 50, 0, 208)
plusBtn.Text = "+5"
plusBtn.TextColor3 = Color3.new(1,1,1)
plusBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)

minusBtn.MouseButton1Click:Connect(function() BaseIgnoreRadiusStuds = math.max(0, BaseIgnoreRadiusStuds - 5) end)
plusBtn.MouseButton1Click:Connect(function() BaseIgnoreRadiusStuds = BaseIgnoreRadiusStuds + 5 end)

-- Speed boost
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70
local btnSpeed = makeBtn(240, "Speed Boost: OFF"); updateToggleColor(btnSpeed, false)
btnSpeed.MouseButton1Click:Connect(function()
    SpeedBoostEnabled = not SpeedBoostEnabled
    btnSpeed.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(btnSpeed, SpeedBoostEnabled)
end)

-- Anti AFK
local AutoJumperEnabled, JumpInterval, LastJumpTime = false, 60, tick()
local btnAFK = makeBtn(270, "Anti AFK: OFF"); updateToggleColor(btnAFK, false)
btnAFK.MouseButton1Click:Connect(function()
    AutoJumperEnabled = not AutoJumperEnabled
    btnAFK.Text = "Anti AFK: " .. (AutoJumperEnabled and "ON" or "OFF")
    updateToggleColor(btnAFK, AutoJumperEnabled)
end)

-- Walk Purchase
local btnWalk = makeBtn(300, "Walk Purchase: OFF"); updateToggleColor(btnWalk, false)
btnWalk.MouseButton1Click:Connect(function()
    WalkPurchaseEnabled = not WalkPurchaseEnabled
    btnWalk.Text = "Walk Purchase: " .. (WalkPurchaseEnabled and "ON" or "OFF")
    updateToggleColor(btnWalk, WalkPurchaseEnabled)
end)

-- Rarity toggles (for ESP display only)
local y = 332
for r in pairs(RarityColors) do
    local b = makeBtn(y, r .. ": " .. (EnabledRarities[r] and "ON" or "OFF"))
    updateToggleColor(b, EnabledRarities[r])
    b.MouseButton1Click:Connect(function()
        EnabledRarities[r] = not EnabledRarities[r]
        b.Text = r .. ": " .. (EnabledRarities[r] and "ON" or "OFF")
        updateToggleColor(b, EnabledRarities[r])
    end)
    y = y + 28
end

-- After rarity buttons: BeeHive & NoRagdoll
local afterY = 332 + countKeys(RarityColors)*28 + 8

-- BeeHive Immune
local CharController = require(ReplicatedStorage.Controllers.CharacterController)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local btnBee = makeBtn(afterY, "BeeHive Immune: ON"); updateToggleColor(btnBee, true)
btnBee.MouseButton1Click:Connect(function()
    BeeHiveImmune = not BeeHiveImmune
    btnBee.Text = "BeeHive Immune: " .. (BeeHiveImmune and "ON" or "OFF")
    updateToggleColor(btnBee, BeeHiveImmune)
    if BeeHiveImmune then Controls.moveFunction = CharController.originalMoveFunction end
end)

-- No Ragdoll
local RagdollController = require(ReplicatedStorage.Controllers.RagdollController)
local originalToggleControls = RagdollController.ToggleControls
local btnRag = makeBtn(afterY + 30, "No Ragdoll: ON"); updateToggleColor(btnRag, true)
local NoRagdoll = true
btnRag.MouseButton1Click:Connect(function()
    NoRagdoll = not NoRagdoll
    btnRag.Text = "No Ragdoll: " .. (NoRagdoll and "ON" or "OFF")
    updateToggleColor(btnRag, NoRagdoll)
    if NoRagdoll then
        RagdollController.ToggleControls = function(_, _enable) Controls:Enable() end
    else
        RagdollController.ToggleControls = originalToggleControls
    end
end)

--// Slot counter
local function updateSlotCountOnly()
    local plots = Workspace:FindFirstChild("Plots"); if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")
        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == player.Name then
                local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    local filled,total=0,0
                    for _, podium in ipairs(animalPodiums:GetChildren()) do
                        if podium:IsA("Model") then
                            local base = podium:FindFirstChild("Base")
                            local spawn = base and base:FindFirstChild("Spawn")
                            if spawn and spawn:IsA("BasePart") then
                                total = total + 1
                                if spawn:FindFirstChild("Attachment") then filled = filled + 1 end
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
task.delay(1, updateSlotCountOnly)
task.spawn(function() while true do updateSlotCountOnly(); task.wait(5) end end)

--// Prompt holder (auto purchase)
local function tryHoldPrompt(prompt, holdTime, maxRetries)
    maxRetries = maxRetries or 2
    for _=1,maxRetries do
        prompt:InputHoldBegin()
        task.wait(holdTime)
        prompt:InputHoldEnd()
        task.wait(0.25)
        if not prompt:IsDescendantOf(game) or not prompt.Enabled then break end
    end
end

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if not (AutoPurchaseEnabled and prompt and prompt.ActionText) then return end
    if not string.find(string.lower(prompt.ActionText), "purchase") then return end

    local model = prompt:FindFirstAncestorWhichIsA("Model"); if not model then return end

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

    -- Lucky Blocks by price name lookup
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

--// Speed, AFK, Bee, Ragdoll keepers
RunService.Heartbeat:Connect(function()
    -- speed
    if SpeedBoostEnabled then
        local _, humanoid = CharController:GetCharacter()
        if humanoid then humanoid.WalkSpeed = DesiredWalkSpeed end
    end
    -- anti AFK
    if AutoJumperEnabled and tick() - LastJumpTime >= JumpInterval then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        LastJumpTime = tick()
    end
    -- beehive
    if BeeHiveImmune then
        local blur = game:GetService("Lighting"):FindFirstChild("BeeBlur"); if blur then blur.Enabled=false end
        local cam = Workspace.CurrentCamera; if cam and cam.FieldOfView ~= 70 then cam.FieldOfView = 70 end
        if Controls.moveFunction ~= CharController.originalMoveFunction then
            Controls.moveFunction = CharController.originalMoveFunction
        end
    end
    -- no ragdoll
    if NoRagdoll then
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

--// Base anchor finder (used by walker + ring)
local function findMyBaseAnchorPos()
    local plots = Workspace:FindFirstChild("Plots"); if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local gui = sign and sign:FindFirstChild("SurfaceGui")
        local fr = gui and gui:FindFirstChild("Frame")
        local label = fr and fr:FindFirstChild("TextLabel")
        if label and label.Text then
            local owner = label.Text:match("^(.-)'s Base")
            if owner == player.Name then
                local mainRoot = plot:FindFirstChild("MainRoot")
                if mainRoot and mainRoot:IsA("BasePart") then return mainRoot.Position end
                local hb = plot:FindFirstChild("StealHitBox")
                if hb and hb:IsA("BasePart") then return hb.Position end
                if plot.PrimaryPart then return plot.PrimaryPart.Position end
                for _, d in ipairs(plot:GetDescendants()) do
                    if d:IsA("BasePart") then return d.Position end
                end
            end
        end
    end
    return nil
end

-- Visible radius ring
local radiusRing
local function ensureRadiusRing()
    if not ShowBaseIgnoreRadius then
        if radiusRing then radiusRing:Destroy(); radiusRing=nil end
        return
    end
    local pos = findMyBaseAnchorPos()
    if not pos then
        if radiusRing then radiusRing:Destroy(); radiusRing=nil end
        return
    end
    if not radiusRing then
        local p = Instance.new("Part")
        p.Name = "BaseIgnoreRadiusRing"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = true
        p.Locked = true
        p.Material = Enum.Material.ForceField
        p.Color = Color3.fromRGB(0,170,255)
        p.Transparency = 0.65
        p.CastShadow = false
        radiusRing = p
        radiusRing.Parent = Workspace
    end
    local diameter = BaseIgnoreRadiusStuds * 2
    radiusRing.Size = Vector3.new(0.25, diameter, diameter)
    radiusRing.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) -- lay flat
end
task.spawn(function() while true do ensureRadiusRing(); task.wait(0.5) end end)
player.CharacterAdded:Connect(function() task.wait(1); ensureRadiusRing() end)

--// Walk-target helpers
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
    humanoid:MoveTo(pos); humanoid.WalkToPoint = pos
end
local function stopWalking(humanoid, hrp)
    if not humanoid then return end
    humanoid:Move(Vector3.new(), true)
    if hrp then humanoid:MoveTo(hrp.Position); humanoid.WalkToPoint = hrp.Position end
end

-- purchase prompt check (informational pause only)
local function purchasePromptActive()
    local promptGui = player.PlayerGui:FindFirstChild("ProximityPrompts"); if not promptGui then return false end
    local promptFrame = promptGui:FindFirstChild("Prompt", true); if not promptFrame then return false end
    local actionText = promptFrame:FindFirstChild("ActionText", true); if not actionText then return false end
    return string.find(string.lower(actionText.Text or ""), "purchase") ~= nil
end

-- Walker: ignore near YOUR base; ESP unaffected
local pauseDistance, pauseTime, lastPause = 5, 0.35, 0
RunService.Heartbeat:Connect(function()
    if not WalkPurchaseEnabled then return end

    local char = Workspace:FindFirstChild(player.Name)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local baseAnchor = findMyBaseAnchorPos()
    local bestModel, bestGen, bestDist = nil, -math.huge, math.huge

    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") then
            local overhead = m:FindFirstChild("AnimalOverhead", true)
            local genLabel = overhead and overhead:FindFirstChild("Generation")
            if genLabel then
                local skip = false
                if AvoidInMachine then
                    local s = overhead:FindFirstChild("Stolen")
                    if s and s:IsA("TextLabel") and (s.Text=="IN MACHINE" or s.Text=="FUSING") then
                        skip = true
                    end
                end
                if not skip then
                    local tpart = findTargetPart(m)
                    if tpart and tpart:IsA("BasePart") then
                        if baseAnchor and (tpart.Position - baseAnchor).Magnitude <= BaseIgnoreRadiusStuds then
                            -- ignore ones near my base
                        else
                            local genVal = parseGenerationText(genLabel.Text or "")
                            if genVal >= PurchaseThreshold then
                                local d = (hrp.Position - tpart.Position).Magnitude
                                if (genVal > bestGen) or (genVal == bestGen and d < bestDist) then
                                    bestModel, bestGen, bestDist = m, genVal, d
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not bestModel then return end
    local targetPart = findTargetPart(bestModel); if not (targetPart and targetPart:IsA("BasePart")) then return end

    local dist = (hrp.Position - targetPart.Position).Magnitude
    if dist <= pauseDistance and (tick()-lastPause) >= pauseTime then
        if not purchasePromptActive() then stopWalking(humanoid, hrp); return end
        lastPause = tick()
    end
    setWalkTarget(humanoid, targetPart.Position)
end)

--// ESP (unchanged logic; shows all)
local function isInMachine(overhead)
    local s = overhead:FindFirstChild("Stolen")
    return s and s:IsA("TextLabel") and (s.Text=="FUSING" or s.Text=="IN MACHINE")
end
local function createBillboard(adorn, color, text)
    local g = Instance.new("BillboardGui")
    g.Adornee = adorn
    g.Size = UDim2.new(0, 200, 0, 20)
    g.StudsOffset = Vector3.new(0, 3, 0)
    g.AlwaysOnTop = true
    local tl = Instance.new("TextLabel", g)
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Text = text
    local stroke = Instance.new("UIStroke", tl)
    stroke.Color = Color3.new(0,0,0)
    stroke.Thickness = 2
    return g
end

RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    local maxAnimal, maxGen = nil, -math.huge
    local maxBlock, maxPrice = nil, -math.huge

    for _, d in ipairs(Workspace:GetDescendants()) do
        if d.Name == "AnimalOverhead" then
            local rarityLabel = d:FindFirstChild("Rarity")
            local rarity = rarityLabel and rarityLabel.Text
            if rarity and RarityColors[rarity] then
                if not (AvoidInMachine and isInMachine(d)) then
                    local gen = parseGenerationText((d:FindFirstChild("Generation") or {}).Text or "")
                    if MostExpensiveOnly then
                        if gen > maxGen then maxGen, maxAnimal = gen, d end
                    else
                        if EnabledRarities[rarity] then
                            local displayName = d:FindFirstChild("DisplayName")
                            local modelPart = d.Parent and d.Parent.Parent
                            if displayName and modelPart and modelPart:IsA("BasePart") then
                                local genText = (d:FindFirstChild("Generation") and d.Generation.Text) or ""
                                local bb = createBillboard(modelPart, RarityColors[rarity], displayName.Text .. " | " .. genText)
                                bb.Parent = worldESPFolder
                            end
                        end
                    end
                end
            end
        elseif d.Name:find("Lucky Block") then
            local rarity = getRarityFromName(d.Name)
            if rarity then
                local data = AnimalsData[d.Name]
                local price = data and data.Price or 0
                if MostExpensiveOnly then
                    if price > maxPrice then maxPrice, maxBlock = price, d end
                else
                    if EnabledRarities[rarity] then
                        local pp = d.PrimaryPart
                        if pp then
                            local bb = createBillboard(pp, RarityColors[rarity], d.Name .. " | $" .. formatPrice(price))
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
            local modelPart = maxAnimal.Parent and maxAnimal.Parent.Parent
            if modelPart and modelPart:IsA("BasePart") then
                local genText = (maxAnimal:FindFirstChild("Generation") and maxAnimal.Generation.Text) or ""
                local bb = createBillboard(modelPart, RarityColors[rarity], displayName .. " | " .. genText)
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
