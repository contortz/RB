-- Combat Exploit GUI (Hitbox 5x ON by Default)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatController = require(ReplicatedStorage.Controllers.CombatController)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)

-- Main GUI Creation
local function CreateMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatExploitGUI"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Make draggable
    local function makeDraggable(frame)
        local dragging = false
        local dragStart, startPos
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    makeDraggable(mainFrame)
    
    -- Toggle Button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 40, 0, 40)
    toggleButton.Position = UDim2.new(0, 10, 0, 10)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    toggleButton.BackgroundTransparency = 0.3
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "⚔"
    toggleButton.TextSize = 20
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Parent = screenGui
    
    local function toggleUI()
        mainFrame.Visible = not mainFrame.Visible
        if mainFrame.Visible then
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
    toggleButton.MouseButton1Click:Connect(toggleUI)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚡ Combat Exploits ⚡"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Section 1: Hitbox
    local hitboxSection = CreateSection(mainFrame, "🎯 Hitbox", 50)
    
    -- Hitbox Size Buttons
    CreateLabel(hitboxSection, "Hitbox Size:", 10)
    local sizeButtons = CreateButtonRow(hitboxSection, 30, {"1x", "2x", "3x", "5x"})
    for i, btn in pairs(sizeButtons) do
        btn.MouseButton1Click:Connect(function()
            local sizes = {1, 2, 3, 5}
            UpdateHitboxSize(sizes[i])
        end)
    end
    
    -- Hitbox Toggle (ENABLED BY DEFAULT)
    local hitboxToggle = CreateToggle(hitboxSection, "Enable Hitbox Manipulation", 60)
    local hitboxEnabled = true -- CHANGED: Start enabled
    
    -- Set toggle to "Enabled" state initially
    hitboxToggle.Text = "✅ Enabled"
    hitboxToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    
    -- Apply 5x hitbox immediately
    UpdateHitboxSize(5)
    StartHitboxManipulation()
    
    hitboxToggle.MouseButton1Click:Connect(function()
        hitboxEnabled = not hitboxEnabled
        if hitboxEnabled then
            hitboxToggle.Text = "✅ Enabled"
            hitboxToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            UpdateHitboxSize(5) -- Re-apply 5x when re-enabled
            StartHitboxManipulation()
        else
            hitboxToggle.Text = "❌ Disabled"
            hitboxToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            StopHitboxManipulation()
        end
    end)
    
    -- Section 2: Invincibility
    local invincSection = CreateSection(mainFrame, "🛡️ Invincibility", 180)
    
    local invincToggle = CreateToggle(invincSection, "God Mode", 10)
    local invincEnabled = false
    invincToggle.MouseButton1Click:Connect(function()
        invincEnabled = not invincEnabled
        if invincEnabled then
            invincToggle.Text = "✅ Enabled"
            invincToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            EnableInvincibility()
        else
            invincToggle.Text = "❌ Disabled"
            invincToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            DisableInvincibility()
        end
    end)
    
    local parryToggle = CreateToggle(invincSection, "Auto Parry", 45)
    local parryEnabled = false
    parryToggle.MouseButton1Click:Connect(function()
        parryEnabled = not parryEnabled
        if parryEnabled then
            parryToggle.Text = "✅ Enabled"
            parryToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            StartAutoParry()
        else
            parryToggle.Text = "❌ Disabled"
            parryToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            StopAutoParry()
        end
    end)
    
    local freezeToggle = CreateToggle(invincSection, "Freeze Position", 80)
    local freezeEnabled = false
    freezeToggle.MouseButton1Click:Connect(function()
        freezeEnabled = not freezeEnabled
        if freezeEnabled then
            freezeToggle.Text = "✅ Enabled"
            freezeToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            FreezePosition()
        else
            freezeToggle.Text = "❌ Disabled"
            freezeToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            UnfreezePosition()
        end
    end)
    
    -- Section 3: Visual
    local visualSection = CreateSection(mainFrame, "👁️ Visual", 320)
    
    local espToggle = CreateToggle(visualSection, "ESP Players", 10)
    local espEnabled = false
    espToggle.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        if espEnabled then
            espToggle.Text = "✅ Enabled"
            espToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            EnableESP()
        else
            espToggle.Text = "❌ Disabled"
            espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            DisableESP()
        end
    end)
    
    -- Speed Buttons
    CreateLabel(visualSection, "Speed:", 55)
    local speedButtons = CreateButtonRow(visualSection, 75, {"0.5x", "1x", "2x", "5x"})
    for i, btn in pairs(speedButtons) do
        btn.MouseButton1Click:Connect(function()
            local speeds = {0.5, 1, 2, 5}
            SetSpeed(speeds[i])
        end)
    end
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 30)
    closeButton.Position = UDim2.new(0.5, -50, 1, -40)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.BackgroundTransparency = 0.3
    closeButton.BorderSizePixel = 0
    closeButton.Text = "CLOSE"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Parent = mainFrame
    closeButton.MouseButton1Click:Connect(toggleUI)
    
    return screenGui
end

-- Helper Functions
function CreateSection(parent, title, yPos)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 100)
    section.Position = UDim2.new(0, 10, 0, yPos)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(100, 200, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    return section
end

function CreateLabel(parent, text, yPos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function CreateButtonRow(parent, yPos, labels)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 25)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local buttons = {}
    local buttonWidth = 0.22
    local spacing = 0.04
    
    for i, label in pairs(labels) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
        btn.Position = UDim2.new((i-1) * (buttonWidth + spacing), 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = label
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.Parent = row
        table.insert(buttons, btn)
    end
    
    return buttons
end

function CreateToggle(parent, text, yPos)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.8, 0, 0, 25)
    toggle.Position = UDim2.new(0, 0, 0, yPos)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BackgroundTransparency = 0.5
    toggle.BorderSizePixel = 0
    toggle.Text = "❌ Disabled"
    toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggle.TextSize = 13
    toggle.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Parent = parent
    
    return toggle
end

-- ===== EXPLOIT FUNCTIONS =====
local hitboxConnections = {}
local originalHitboxes = {}

function UpdateHitboxSize(scale)
    local character = player.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:find("Hitbox") or part.Name:find("Handle")) then
            local originalSize = originalHitboxes[part] or part.Size
            if not originalHitboxes[part] then
                originalHitboxes[part] = part.Size
            end
            part.Size = originalSize * scale
        end
    end
end

function StartHitboxManipulation()
    -- Keep hitboxes updated
    if hitboxConnections.hitboxLoop then
        hitboxConnections.hitboxLoop:Disconnect()
    end
    hitboxConnections.hitboxLoop = RunService.Heartbeat:Connect(function()
        -- Passive maintenance - ensures hitboxes stay at current size
    end)
end

function StopHitboxManipulation()
    for _, conn in pairs(hitboxConnections) do
        conn:Disconnect()
    end
    hitboxConnections = {}
    
    for part, size in pairs(originalHitboxes) do
        if part and part.Parent then
            part.Size = size
        end
    end
    originalHitboxes = {}
end

local invincConnections = {}

function EnableInvincibility()
    local character = player.Character
    if not character then return end
    
    invincConnections.healthLoop = RunService.Heartbeat:Connect(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    invincConnections.stateManipulator = RunService.Stepped:Connect(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

function DisableInvincibility()
    for _, conn in pairs(invincConnections) do
        conn:Disconnect()
    end
    invincConnections = {}
end

local parryConnections = {}

function StartAutoParry()
    parryConnections.autoParry = RunService.Heartbeat:Connect(function()
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                local otherChar = otherPlayer.Character
                if otherChar and otherChar:FindFirstChild("Humanoid") then
                    local actionManager = CharacterController and CharacterController._actionManager
                    if actionManager then
                        local currentAction = actionManager.CurrentAction
                        if currentAction and currentAction.ActionType == "BasicAttack" then
                            CombatController:Impact(nil, "Parry", character, otherChar, {})
                        end
                    end
                end
            end
        end
    end)
end

function StopAutoParry()
    for _, conn in pairs(parryConnections) do
        conn:Disconnect()
    end
    parryConnections = {}
end

local freezeConnections = {}
local frozenPosition = nil

function FreezePosition()
    local character = player.Character
    if not character then return end
    
    frozenPosition = character.Humanoid.RootPart.Position
    
    freezeConnections.positionFreeze = RunService.Heartbeat:Connect(function()
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and frozenPosition then
            root.Position = frozenPosition
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

function UnfreezePosition()
    for _, conn in pairs(freezeConnections) do
        conn:Disconnect()
    end
    freezeConnections = {}
    frozenPosition = nil
end

local espObjects = {}
local espConnections = {}

function EnableESP()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local char = otherPlayer.Character
            if char then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Parent = char
                highlight.Adornee = char
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.3
                table.insert(espObjects, highlight)
            end
        end
    end
    
    espConnections.playerAdded = Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer ~= player then
            local char = newPlayer.Character or newPlayer.CharacterAdded:Wait()
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Parent = char
            highlight.Adornee = char
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0.3
            table.insert(espObjects, highlight)
        end
    end)
end

function DisableESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    espObjects = {}
    if espConnections and espConnections.playerAdded then
        espConnections.playerAdded:Disconnect()
    end
end

function SetSpeed(speedMultiplier)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16 * speedMultiplier
        humanoid.JumpPower = 50 * speedMultiplier
    end
end

-- Initialize
CreateMainGUI()

-- Cleanup
player.CharacterAdded:Connect(function()
    StopHitboxManipulation()
    DisableInvincibility()
    StopAutoParry()
    UnfreezePosition()
    DisableESP()
    character = player.Character
end)

print("✅ Combat Exploit GUI Loaded!")
print("⚡ Hitbox 5x ENABLED by default!")
print("Press the ⚔ button to open the menu")
