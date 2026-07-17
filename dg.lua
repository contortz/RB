-- Fixed Combat Exploit GUI (No Errors)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Services references
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
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Make it draggable
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
    
    -- Blur effect
    local blur = Instance.new("BlurEffect", game:GetService("Lighting"))
    blur.Size = 0
    
    -- Toggle Button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
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
            blur.Size = 12
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            blur.Size = 0
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
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Section 1: Hitbox Manipulation
    local hitboxSection = CreateSection(mainFrame, "🎯 Hitbox Manipulation", 50)
    
    -- Hitbox Size Slider
    local hitboxSizeLabel = CreateLabel(hitboxSection, "Hitbox Size: 1.0x", 10)
    local hitboxSlider = CreateSlider(hitboxSection, 30, 1, 5, 1)
    hitboxSlider.ValueChanged.Event:Connect(function(value)
        hitboxSizeLabel.Text = string.format("Hitbox Size: %.1fx", value)
        UpdateHitboxSize(value)
    end)
    
    -- Hitbox Offset
    local offsetLabel = CreateLabel(hitboxSection, "Hitbox Offset: 0 studs", 65)
    local offsetSlider = CreateSlider(hitboxSection, 85, -10, 10, 0)
    offsetSlider.ValueChanged.Event:Connect(function(value)
        offsetLabel.Text = string.format("Hitbox Offset: %.1f studs", value)
        UpdateHitboxOffset(value)
    end)
    
    -- Hitbox Toggle
    local hitboxToggle, hitboxEnabled = CreateToggle(hitboxSection, "Enable Hitbox Manipulation", 120)
    hitboxToggle.MouseButton1Click:Connect(function()
        hitboxEnabled.Value = not hitboxEnabled.Value
        if hitboxEnabled.Value then
            hitboxToggle.Text = "✅ Enabled"
            hitboxToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            StartHitboxManipulation()
        else
            hitboxToggle.Text = "❌ Disabled"
            hitboxToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            StopHitboxManipulation()
        end
    end)
    
    -- Section 2: Invincibility
    local invincSection = CreateSection(mainFrame, "🛡️ Invincibility", 190)
    
    -- Invincibility Toggle
    local invincToggle, invincEnabled = CreateToggle(invincSection, "God Mode", 10)
    invincToggle.MouseButton1Click:Connect(function()
        invincEnabled.Value = not invincEnabled.Value
        if invincEnabled.Value then
            invincToggle.Text = "✅ Enabled"
            invincToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            EnableInvincibility()
        else
            invincToggle.Text = "❌ Disabled"
            invincToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            DisableInvincibility()
        end
    end)
    
    -- Auto-Parry (Bonus)
    local parryToggle, parryEnabled = CreateToggle(invincSection, "Auto Parry", 45)
    parryToggle.MouseButton1Click:Connect(function()
        parryEnabled.Value = not parryEnabled.Value
        if parryEnabled.Value then
            parryToggle.Text = "✅ Enabled"
            parryToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            StartAutoParry()
        else
            parryToggle.Text = "❌ Disabled"
            parryToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            StopAutoParry()
        end
    end)
    
    -- Position Freeze
    local freezeToggle, freezeEnabled = CreateToggle(invincSection, "Freeze Position", 80)
    freezeToggle.MouseButton1Click:Connect(function()
        freezeEnabled.Value = not freezeEnabled.Value
        if freezeEnabled.Value then
            freezeToggle.Text = "✅ Enabled"
            freezeToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            FreezePosition()
        else
            freezeToggle.Text = "❌ Disabled"
            freezeToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            UnfreezePosition()
        end
    end)
    
    -- Section 3: Visual Options
    local visualSection = CreateSection(mainFrame, "👁️ Visual Options", 280)
    
    -- ESP
    local espToggle, espEnabled = CreateToggle(visualSection, "ESP Players", 10)
    espToggle.MouseButton1Click:Connect(function()
        espEnabled.Value = not espEnabled.Value
        if espEnabled.Value then
            espToggle.Text = "✅ Enabled"
            espToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            EnableESP()
        else
            espToggle.Text = "❌ Disabled"
            espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            DisableESP()
        end
    end)
    
    -- Speed
    local speedLabel = CreateLabel(visualSection, "Speed: 1.0x", 55)
    local speedSlider = CreateSlider(visualSection, 70, 0.5, 5, 1)
    speedSlider.ValueChanged.Event:Connect(function(value)
        speedLabel.Text = string.format("Speed: %.1fx", value)
        SetSpeed(value)
    end)
    
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
    section.Size = UDim2.new(1, -20, 0, 80)
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

-- FIXED SLIDER FUNCTION
function CreateSlider(parent, yPos, min, max, default)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0.8, 0, 0, 20)
    sliderFrame.Position = UDim2.new(0, 0, 0, yPos)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent
    
    -- Background track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0.4, 0)
    track.Position = UDim2.new(0, 0, 0.3, 0)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    track.Parent = sliderFrame
    
    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    -- Slider button
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 16, 0, 16)
    button.Position = UDim2.new(0.5, -8, 0.5, -8)
    button.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = sliderFrame
    
    -- Value display
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
    valueLabel.Position = UDim2.new(1.05, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    valueLabel.TextSize = 12
    valueLabel.Parent = sliderFrame
    
    local currentValue = default
    
    -- Create ValueChanged event
    sliderFrame.ValueChanged = Instance.new("BindableEvent")
    
    local function updateSlider(input)
        local mousePos = input.Position.X
        local framePos = sliderFrame.AbsolutePosition.X
        local frameWidth = sliderFrame.AbsoluteSize.X
        
        if frameWidth <= 0 then return end
        
        local percent = math.clamp((mousePos - framePos) / frameWidth, 0, 1)
        currentValue = min + (max - min) * percent
        currentValue = math.round(currentValue * 10) / 10
        
        fill.Size = UDim2.new(percent, 0, 1, 0)
        button.Position = UDim2.new(percent, -8, 0.5, -8)
        valueLabel.Text = tostring(currentValue)
        
        sliderFrame.ValueChanged:Fire(currentValue)
    end
    
    button.MouseButton1Down:Connect(function()
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        local endedConnection
        endedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if connection then connection:Disconnect() end
                if endedConnection then endedConnection:Disconnect() end
            end
        end)
    end)
    
    -- Click on track to jump
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)
    
    -- Initialize at default
    local defaultPercent = (default - min) / (max - min)
    fill.Size = UDim2.new(defaultPercent, 0, 1, 0)
    button.Position = UDim2.new(defaultPercent, -8, 0.5, -8)
    valueLabel.Text = tostring(default)
    
    return sliderFrame
end

-- FIXED TOGGLE FUNCTION
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
    
    local enabled = {Value = false}
    
    return toggle, enabled
end

-- Exploit Functions
local hitboxConnections = {}
local originalHitboxes = {}

function UpdateHitboxSize(scale)
    local character = player.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:find("Hitbox") then
            local originalSize = originalHitboxes[part] or part.Size
            if not originalHitboxes[part] then
                originalHitboxes[part] = part.Size
            end
            part.Size = originalSize * scale
        end
    end
end

function UpdateHitboxOffset(offset)
    local character = player.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:find("Hitbox") then
            local direction = character.Humanoid.MoveDirection or Vector3.new(0, 0, 1)
            if direction.Magnitude == 0 then
                direction = character.Humanoid.RootPart.CFrame.LookVector
            end
            part.Position = part.Position + direction * offset
        end
    end
end

function StartHitboxManipulation()
    hitboxConnections.hitboxLoop = RunService.Heartbeat:Connect(function()
        -- Additional hitbox manipulation can go here
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
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    invincConnections.stateManipulator = RunService.Stepped:Connect(function()
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            if humanoid:GetState() == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
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
            local character = otherPlayer.Character
            if character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Parent = character
                highlight.Adornee = character
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
            local character = newPlayer.Character or newPlayer.CharacterAdded:Wait()
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Parent = character
            highlight.Adornee = character
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

-- Cleanup on death
player.CharacterAdded:Connect(function()
    StopHitboxManipulation()
    DisableInvincibility()
    StopAutoParry()
    UnfreezePosition()
    DisableESP()
    character = player.Character
end)

print("✅ Combat Exploit GUI Loaded!")
print("Press the ⚔ button to open the menu")
