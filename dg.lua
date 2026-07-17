-- LocalScript in StarterPlayerScripts or StarterGui
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
    mainFrame.Size = UDim2.new(0, 350, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Make it draggable
    local function makeDraggable(frame)
        local dragging = false
        local dragInput, dragStart, startPos
        
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
    hitboxSlider:GetPropertyChangedSignal("Value"):Connect(function()
        hitboxSizeLabel.Text = string.format("Hitbox Size: %.1fx", hitboxSlider.Value)
        UpdateHitboxSize(hitboxSlider.Value)
    end)
    
    -- Hitbox Offset
    local offsetLabel = CreateLabel(hitboxSection, "Hitbox Offset: 0 studs", 65)
    local offsetSlider = CreateSlider(hitboxSection, 85, -10, 10, 0)
    offsetSlider:GetPropertyChangedSignal("Value"):Connect(function()
        offsetLabel.Text = string.format("Hitbox Offset: %.1f studs", offsetSlider.Value)
        UpdateHitboxOffset(offsetSlider.Value)
    end)
    
    -- Hitbox Toggle
    local hitboxToggle = CreateToggle(hitboxSection, "Enable Hitbox Manipulation", 120)
    local hitboxEnabled = false
    hitboxToggle:GetPropertyChangedSignal("Text"):Connect(function()
        hitboxEnabled = hitboxToggle.Text == "✅ Enabled"
        if hitboxEnabled then
            StartHitboxManipulation()
        else
            StopHitboxManipulation()
        end
    end)
    
    -- Section 2: Invincibility
    local invincSection = CreateSection(mainFrame, "🛡️ Invincibility", 190)
    
    -- Invincibility Toggle
    local invincToggle = CreateToggle(invincSection, "God Mode", 10)
    local invincEnabled = false
    invincToggle:GetPropertyChangedSignal("Text"):Connect(function()
        invincEnabled = invincToggle.Text == "✅ Enabled"
        if invincEnabled then
            EnableInvincibility()
        else
            DisableInvincibility()
        end
    end)
    
    -- Auto-Parry (Bonus)
    local parryToggle = CreateToggle(invincSection, "Auto Parry", 45)
    local parryEnabled = false
    parryToggle:GetPropertyChangedSignal("Text"):Connect(function()
        parryEnabled = parryToggle.Text == "✅ Enabled"
        if parryEnabled then
            StartAutoParry()
        else
            StopAutoParry()
        end
    end)
    
    -- Position Freeze
    local freezeToggle = CreateToggle(invincSection, "Freeze Position", 80)
    local freezeEnabled = false
    freezeToggle:GetPropertyChangedSignal("Text"):Connect(function()
        freezeEnabled = freezeToggle.Text == "✅ Enabled"
        if freezeEnabled then
            FreezePosition()
        else
            UnfreezePosition()
        end
    end)
    
    -- Section 3: Visual Options
    local visualSection = CreateSection(mainFrame, "👁️ Visual Options", 280)
    
    -- ESP
    local espToggle = CreateToggle(visualSection, "ESP Players", 10)
    local espEnabled = false
    espToggle:GetPropertyChangedSignal("Text"):Connect(function()
        espEnabled = espToggle.Text == "✅ Enabled"
        if espEnabled then
            EnableESP()
        else
            DisableESP()
        end
    end)
    
    -- Speed
    local speedLabel = CreateLabel(visualSection, "Speed: 1.0x", 55)
    local speedSlider = CreateSlider(visualSection, 70, 0.5, 5, 1)
    speedSlider:GetPropertyChangedSignal("Value"):Connect(function()
        speedLabel.Text = string.format("Speed: %.1fx", speedSlider.Value)
        SetSpeed(speedSlider.Value)
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

function CreateSlider(parent, yPos, min, max, default)
    local slider = Instance.new("Slider")
    slider.Size = UDim2.new(0.8, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, yPos)
    slider.Min = min
    slider.Max = max
    slider.Value = default
    slider.Step = 0.1
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    slider.BorderSizePixel = 0
    slider.Parent = parent
    
    return slider
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
    
    toggle.MouseButton1Click:Connect(function()
        if toggle.Text == "❌ Disabled" then
            toggle.Text = "✅ Enabled"
            toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            toggle.Text = "❌ Disabled"
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end
    end)
    
    return toggle
end

-- Exploit Functions
local hitboxConnections = {}
local originalHitboxes = {}

function UpdateHitboxSize(scale)
    -- Manipulate hitbox size by scaling collision parts
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
    -- Move hitbox positions
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
    -- Continuously update hitboxes
    hitboxConnections.hitboxLoop = RunService.Heartbeat:Connect(function()
        if not hitboxEnabled then return end
        -- Additional hitbox manipulation can go here
    end)
end

function StopHitboxManipulation()
    for _, conn in pairs(hitboxConnections) do
        conn:Disconnect()
    end
    hitboxConnections = {}
    
    -- Reset hitboxes
    for part, size in pairs(originalHitboxes) do
        if part and part.Parent then
            part.Size = size
        end
    end
    originalHitboxes = {}
end

-- Invincibility Functions
local invincConnections = {}

function EnableInvincibility()
    local character = player.Character
    if not character then return end
    
    -- Method 1: Set health to max constantly
    invincConnections.healthLoop = RunService.Heartbeat:Connect(function()
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    -- Method 2: Remove all humanoid limbs (makes you invincible to some attacks)
    invincConnections.limbRemover = RunService.Heartbeat:Connect(function()
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            for _, limb in pairs(humanoid:GetChildren()) do
                if limb:IsA("HumanoidBone") and limb.Name == "RootRigAttachment" then
                    -- This is a bit aggressive, be careful
                end
            end
        end
    end)
    
    -- Method 3: Manipulate character state
    invincConnections.stateManipulator = RunService.Stepped:Connect(function()
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            -- Prevent death state
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

-- Auto Parry Functions
local parryConnections = {}

function StartAutoParry()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ImpactRemote = ReplicatedStorage.Remotes.Combat.Impact
    
    parryConnections.autoParry = RunService.Heartbeat:Connect(function()
        -- Look for incoming attacks and automatically parry
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                local otherChar = otherPlayer.Character
                if otherChar and otherChar:FindFirstChild("Humanoid") then
                    -- Check if they're attacking
                    local actionManager = CharacterController and CharacterController._actionManager
                    if actionManager then
                        local currentAction = actionManager.CurrentAction
                        if currentAction and currentAction.ActionType == "BasicAttack" then
                            -- Automatically parry
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

-- Position Freeze
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

-- ESP Functions
local espObjects = {}

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
    
    -- Watch for new players
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

-- Speed Functions
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
    -- Reset everything
    StopHitboxManipulation()
    DisableInvincibility()
    StopAutoParry()
    UnfreezePosition()
    DisableESP()
    
    -- Update references
    character = player.Character
end)

print("✅ Combat Exploit GUI Loaded!")
print("Press the ⚔ button to open the menu")
