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

-- Toggles & Threshold
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensiveOnly = false
local AutoPurchaseEnabled = true
local BeeHiveImmune = false
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

-- Frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 460)
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

-- Proximity Prompt Auto Purchase Logic
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
    if AutoPurchaseEnabled and prompt.ActionText and string.find(prompt.ActionText:lower(), "purchase") then
        local model = prompt:FindFirstAncestorWhichIsA("Model")
        if model then
            -- Animals: Generation
            local overhead = model:FindFirstChild("AnimalOverhead", true)
            if overhead and overhead:FindFirstChild("Generation") then
                local genValue = parseGenerationText(overhead.Generation.Text)
                if genValue >= PurchaseThreshold then
                    task.wait(0.05)
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration or 0.25)
                    prompt:InputHoldEnd()
                end
                return
            end
            -- Lucky Blocks: Price
            for rarity in pairs(RarityColors) do
                if model.Name:find(rarity) then
                    local data = AnimalsData[model.Name]
                    local price = data and data.Price or 0
                    if price >= PurchaseThreshold then
                        task.wait(0.05)
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration or 0.25)
                        prompt:InputHoldEnd()
                    end
                    return
                end
            end
        end
    end
end)


-- Speed Boost Toggle
local SpeedBoostEnabled = false
local DesiredWalkSpeed = 70 -- Change this to whatever speed you want

local toggleSpeedBoostBtn = Instance.new("TextButton", frame)
toggleSpeedBoostBtn.Size = UDim2.new(1, -10, 0, 25)
toggleSpeedBoostBtn.Position = UDim2.new(0, 5, 0, 240) -- Puts it right under Threshold
toggleSpeedBoostBtn.TextColor3 = Color3.new(1, 1, 1)
toggleSpeedBoostBtn.Text = "Speed Boost: OFF"
updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)

toggleSpeedBoostBtn.MouseButton1Click:Connect(function()
    SpeedBoostEnabled = not SpeedBoostEnabled
    toggleSpeedBoostBtn.Text = "Speed Boost: " .. (SpeedBoostEnabled and "ON" or "OFF")
    updateToggleColor(toggleSpeedBoostBtn, SpeedBoostEnabled)
end)

-- Enforce speed ignoring all game logic (including stealing slowdown)
RunService.Heartbeat:Connect(function()
    if SpeedBoostEnabled then
        local char, humanoid = require(ReplicatedStorage.Controllers.CharacterController):GetCharacter()
        if humanoid then
            humanoid.WalkSpeed = DesiredWalkSpeed -- No slowdown applied
        end
    end
end)


-- Auto Jumper Toggle
local AutoJumperEnabled = false
local JumpInterval = 60 -- seconds between jumps
local LastJumpTime = tick()

local toggleAutoJumperBtn = Instance.new("TextButton", frame)
toggleAutoJumperBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAutoJumperBtn.Position = UDim2.new(0, 5, 0, 330) -- adjust so it sits under Speed Boost
toggleAutoJumperBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAutoJumperBtn.Text = "Auto Jumper: OFF"
updateToggleColor(toggleAutoJumperBtn, AutoJumperEnabled)

toggleAutoJumperBtn.MouseButton1Click:Connect(function()
    AutoJumperEnabled = not AutoJumperEnabled
    toggleAutoJumperBtn.Text = "Auto Jumper: " .. (AutoJumperEnabled and "ON" or "OFF")
    updateToggleColor(toggleAutoJumperBtn, AutoJumperEnabled)
end)

-- Auto Jumper Loop (Simulates Spacebar Press)
RunService.Heartbeat:Connect(function()
    if AutoJumperEnabled and tick() - LastJumpTime >= JumpInterval then
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        LastJumpTime = tick()
    end
end)


-- Rarity Toggles
local y = 300
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


-- BeeHive Immune Toggle
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local toggleBeeHiveBtn = Instance.new("TextButton", frame)
toggleBeeHiveBtn.Size = UDim2.new(1, -10, 0, 25)
toggleBeeHiveBtn.Position = UDim2.new(0, 5, 0, 210) -- ✅ right under No Ragdoll
toggleBeeHiveBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBeeHiveBtn.Text = "BeeHive Immune: OFF"
updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)

toggleBeeHiveBtn.MouseButton1Click:Connect(function()
    BeeHiveImmune = not BeeHiveImmune
    toggleBeeHiveBtn.Text = "BeeHive Immune: " .. (BeeHiveImmune and "ON" or "OFF")
    updateToggleColor(toggleBeeHiveBtn, BeeHiveImmune)

    if BeeHiveImmune then
        -- Immediately restore move function when toggled ON
        Controls.moveFunction = CharacterController.originalMoveFunction
    end
end)

-- BeeHive Immune Enforcement
RunService.Heartbeat:Connect(function()
    if BeeHiveImmune then
        -- Disable Bee Blur if it exists
        local blur = game:GetService("Lighting"):FindFirstChild("BeeBlur")
        if blur then
            blur.Enabled = false
        end
        
        -- Restore FOV instantly
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= 70 then
            cam.FieldOfView = 70
        end

        -- Ensure movement stays correct (failsafe in case game overrides it mid-Bee attack)
        if Controls.moveFunction ~= CharacterController.originalMoveFunction then
            Controls.moveFunction = CharacterController.originalMoveFunction
        end
    end
end)


-- No Ragdoll Toggle
local NoRagdoll = false
local CharacterController = require(ReplicatedStorage.Controllers.RagdollController)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

-- Save original ToggleControls
local originalToggleControls = CharacterController.ToggleControls

local toggleNoRagdollBtn = Instance.new("TextButton", frame)
toggleNoRagdollBtn.Size = UDim2.new(1, -10, 0, 25)
toggleNoRagdollBtn.Position = UDim2.new(0, 5, 0, 180)
toggleNoRagdollBtn.TextColor3 = Color3.new(1, 1, 1)
toggleNoRagdollBtn.Text = "No Ragdoll: OFF"
updateToggleColor(toggleNoRagdollBtn, NoRagdoll)

toggleNoRagdollBtn.MouseButton1Click:Connect(function()
    NoRagdoll = not NoRagdoll
    toggleNoRagdollBtn.Text = "No Ragdoll: " .. (NoRagdoll and "ON" or "OFF")
    updateToggleColor(toggleNoRagdollBtn, NoRagdoll)

    if NoRagdoll then
        -- Override ToggleControls so it never disables movement
        CharacterController.ToggleControls = function(_, enable)
            -- Ignore disable attempts, always enable
            Controls:Enable()
        end
    else
        -- Restore default behavior when toggled off
        CharacterController.ToggleControls = originalToggleControls
    end
end)

-- Safety: Force exit ragdoll if something slips through
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








-- Check if "IN MACHINE"
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel and stolenLabel:IsA("TextLabel") and stolenLabel.Text == "IN MACHINE"
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

-- Heartbeat Loop
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
                            local model = podium.Parent and podium.Parent.Parent
                            if model and model:IsA("BasePart") then
                                local bb = createBillboard(model, RarityColors[rarity], displayName.Text .. " | " .. podium.Generation.Text)
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
                local bb = createBillboard(model, RarityColors[rarity], displayName .. " | " .. maxAnimal.Generation.Text)
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
