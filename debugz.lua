--[[ 
  Attach-To-Object (Follow Anchor) – Dreamz (minimize+dock)
  • Type any path (e.g., Workspace.Snake.Head) and ATTACH.
  • Offset Y = how high above the target you float.
  • Match Rotation = face same direction as the target.
  • Minimize button in title bar → shows a floating restore dock.
  • Start minimized toggle below (START_MINIMIZED).
  • Hotkeys: M toggles menu, R toggles attach/detach with current path.
]]

-- ===== Config =====
local START_MINIMIZED = true          -- set true to start with dock only
local DOCK_TEXT       = "🧲 Attach"   -- text on the floating restore dock
local DOCK_SIZE       = 56            -- pixels (square)
local DOCK_OFFSET     = Vector2.new(16, 120) -- from top-left of screen

--// Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Workspace  = game:GetService("Workspace")
local UserInput  = game:GetService("UserInputService")

if not game:IsLoaded() then game.Loaded:Wait() end
local localPlayer = Players.LocalPlayer
while not localPlayer do task.wait() localPlayer = Players.LocalPlayer end

-- ===== UI helpers =====
local UI_NAME = "AttachToObjectGui"

local function getHiddenUi()
    return (gethui and gethui())
        or (get_hidden_gui and get_hidden_gui())
        or (gethiddengui and gethiddengui())
        or nil
end

local function protectGui(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    pcall(function() if protect_gui then protect_gui(gui) end end)
end

for _, root in ipairs({getHiddenUi(), CoreGui, localPlayer:FindFirstChild("PlayerGui")}) do
    if root and root:FindFirstChild(UI_NAME) then root[UI_NAME]:Destroy() end
end

-- ===== Path resolving =====
local function findBasePartInModel(model)
    if not model or not model:IsA("Model") then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function resolvePath(pathText)
    if type(pathText) ~= "string" or pathText == "" then return nil end
    local tokens = {}
    for t in string.gmatch(pathText, "[^%.]+") do table.insert(tokens, t) end
    if #tokens == 0 then return nil end

    local root, index = nil, 1
    if tokens[1] == "game" then root, index = game, 2 end
    if not root then
        if tokens[1]:lower() == "workspace" then root, index = Workspace, 2
        else root, index = Workspace, 1 end
    end

    local current = root
    while index <= #tokens and current do
        current = current:FindFirstChild(tokens[index])
        index += 1
    end
    if not current then return nil end

    if current:IsA("BasePart") then return current end
    if current:IsA("Model") then return findBasePartInModel(current) end
    if current:IsA("Folder") or current:IsA("Accessory") or current:IsA("Tool") then
        for _, d in ipairs(current:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end

-- ===== GUI =====
local parentRoot = getHiddenUi() or CoreGui or localPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
protectGui(screenGui)
screenGui.Parent = parentRoot

-- Main window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(320, 184)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -92)
mainFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title bar
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(50,50,50)
titleBar.BorderSizePixel = 0
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 16
titleBar.TextColor3 = Color3.new(1,1,1)
titleBar.Text = "Attach To Object – Dreamz"
titleBar.Parent = mainFrame

-- Minimize button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 26, 0, 24)
minimizeButton.Position = UDim2.new(1, -30, 0, 2)
minimizeButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
minimizeButton.TextColor3 = Color3.new(1,1,1)
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 18
minimizeButton.Parent = mainFrame

-- Floating restore dock (draggable round button)
local restoreDock = Instance.new("TextButton")
restoreDock.Name = "RestoreDock"
restoreDock.Size = UDim2.fromOffset(DOCK_SIZE, DOCK_SIZE)
restoreDock.Position = UDim2.new(0, DOCK_OFFSET.X, 0, DOCK_OFFSET.Y)
restoreDock.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
restoreDock.AutoButtonColor = true
restoreDock.Text = DOCK_TEXT
restoreDock.TextScaled = true
restoreDock.Font = Enum.Font.GothamBold
restoreDock.TextColor3 = Color3.new(1,1,1)
restoreDock.ZIndex = 1000
restoreDock.Parent = screenGui

-- make it round
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, DOCK_SIZE) -- fully round
corner.Parent = restoreDock

-- Simple drag for the dock
do
    local dragging = false
    local dragStart, startPos
    restoreDock.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = restoreDock.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            restoreDock.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Body controls
local pathLabel = Instance.new("TextLabel")
pathLabel.BackgroundTransparency = 1
pathLabel.Position = UDim2.new(0, 10, 0, 40)
pathLabel.Size = UDim2.new(0, 92, 0, 22)
pathLabel.Font = Enum.Font.SourceSans
pathLabel.TextSize = 16
pathLabel.TextXAlignment = Enum.TextXAlignment.Left
pathLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
pathLabel.Text = "Object Path:"
pathLabel.Parent = mainFrame

local pathBox = Instance.new("TextBox")
pathBox.PlaceholderText = "Workspace.Snake.Head"
pathBox.ClearTextOnFocus = false
pathBox.Text = ""
pathBox.Font = Enum.Font.SourceSans
pathBox.TextSize = 16
pathBox.TextColor3 = Color3.new(1,1,1)
pathBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
pathBox.BorderSizePixel = 0
pathBox.Position = UDim2.new(0, 110, 0, 40)
pathBox.Size = UDim2.new(1, -120, 0, 24)
pathBox.Parent = mainFrame

local offsetLabel = Instance.new("TextLabel")
offsetLabel.BackgroundTransparency = 1
offsetLabel.Position = UDim2.new(0, 10, 0, 72)
offsetLabel.Size = UDim2.new(0, 92, 0, 22)
offsetLabel.Font = Enum.Font.SourceSans
offsetLabel.TextSize = 16
offsetLabel.TextXAlignment = Enum.TextXAlignment.Left
offsetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
offsetLabel.Text = "Offset Y:"
offsetLabel.Parent = mainFrame

local offsetBox = Instance.new("TextBox")
offsetBox.PlaceholderText = "e.g. 2.5"
offsetBox.ClearTextOnFocus = false
offsetBox.Text = "2.5"
offsetBox.Font = Enum.Font.SourceSans
offsetBox.TextSize = 16
offsetBox.TextColor3 = Color3.new(1,1,1)
offsetBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
offsetBox.BorderSizePixel = 0
offsetBox.Position = UDim2.new(0, 110, 0, 72)
offsetBox.Size = UDim2.new(0, 80, 0, 24)
offsetBox.Parent = mainFrame

local matchRotationButton = Instance.new("TextButton")
matchRotationButton.Name = "MatchRotation"
matchRotationButton.Text = "Match Rotation: OFF"
matchRotationButton.Font = Enum.Font.SourceSansBold
matchRotationButton.TextSize = 14
matchRotationButton.TextColor3 = Color3.new(1,1,1)
matchRotationButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
matchRotationButton.BorderSizePixel = 0
matchRotationButton.Position = UDim2.new(0, 200, 0, 72)
matchRotationButton.Size = UDim2.new(0, 110, 0, 24)
matchRotationButton.Parent = mainFrame

local attachButton = Instance.new("TextButton")
attachButton.Text = "ATTACH"
attachButton.Font = Enum.Font.SourceSansBold
attachButton.TextSize = 16
attachButton.TextColor3 = Color3.new(1,1,1)
attachButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
attachButton.BorderSizePixel = 0
attachButton.Position = UDim2.new(0, 10, 0, 110)
attachButton.Size = UDim2.new(0, 140, 0, 28)
attachButton.Parent = mainFrame

local detachButton = Instance.new("TextButton")
detachButton.Text = "DETACH"
detachButton.Font = Enum.Font.SourceSansBold
detachButton.TextSize = 16
detachButton.TextColor3 = Color3.new(1,1,1)
detachButton.BackgroundColor3 = Color3.fromRGB(120,0,0)
detachButton.BorderSizePixel = 0
detachButton.Position = UDim2.new(0, 170, 0, 110)
detachButton.Size = UDim2.new(0, 140, 0, 28)
detachButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 10, 0, 146)
statusLabel.Size = UDim2.new(1, -20, 0, 24)
statusLabel.Font = Enum.Font.SourceSansSemibold
statusLabel.TextSize = 15
statusLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Status: Idle"
statusLabel.Parent = mainFrame

-- ===== State & logic =====
local attached = false
local matchRotation = false
local savedPath = ""
local followConnection

local function setMatchRotation(on)
    matchRotation = on
    matchRotationButton.Text = "Match Rotation: " .. (on and "ON" or "OFF")
    matchRotationButton.BackgroundColor3 = on and Color3.fromRGB(0,110,70) or Color3.fromRGB(60,60,60)
end
setMatchRotation(false)

matchRotationButton.MouseButton1Click:Connect(function()
    setMatchRotation(not matchRotation)
end)

local function getOffsetY()
    local n = tonumber(offsetBox.Text)
    if not n then n = 2.5 end
    return n
end

local function stopFollowing()
    attached = false
    if followConnection then pcall(function() followConnection:Disconnect() end) end
    followConnection = nil
    statusLabel.Text = "Status: Detached"
end

local function startFollowing(pathText)
    savedPath = pathText
    attached = true
    if followConnection then pcall(function() followConnection:Disconnect() end) end
    followConnection = nil
    statusLabel.Text = "Status: Resolving target…"

    followConnection = RunService.Heartbeat:Connect(function()
        if not attached then return end
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetPart = resolvePath(savedPath) -- re-resolve each frame in case it respawns
        if targetPart and targetPart:IsA("BasePart") then
            local offsetY = getOffsetY()
            local baseCFrame = targetPart.CFrame
            local desiredPosition = baseCFrame.Position + Vector3.new(0, offsetY, 0)

            if matchRotation then
                local lookAt = desiredPosition + baseCFrame.LookVector
                hrp.CFrame = CFrame.new(desiredPosition, lookAt)
            else
                local _, _, _, r00,r01,r02, r10,r11,r12, r20,r21,r22 = hrp.CFrame:GetComponents()
                hrp.CFrame = CFrame.fromMatrix(
                    desiredPosition,
                    Vector3.new(r00,r10,r20), Vector3.new(r01,r11,r21), Vector3.new(r02,r12,r22)
                )
            end
            statusLabel.Text = "Status: Attached to " .. targetPart:GetFullName()
        else
            statusLabel.Text = "Status: Target not found (searching…)"
        end
    end)
end

attachButton.MouseButton1Click:Connect(function()
    local pathText = (pathBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if pathText == "" then
        statusLabel.Text = "Status: Enter a path (e.g., Workspace.Snake.Head)"
        return
    end
    startFollowing(pathText)
end)

detachButton.MouseButton1Click:Connect(function()
    stopFollowing()
end)

-- ===== Minimize / Restore =====
local function showDockOnly()
    mainFrame.Visible = false
    restoreDock.Visible = true
end
local function showMainOnly()
    mainFrame.Visible = true
    restoreDock.Visible = false
end

minimizeButton.MouseButton1Click:Connect(showDockOnly)
restoreDock.MouseButton1Click:Connect(showMainOnly)

-- Start minimized if desired
if START_MINIMIZED then
    showDockOnly()
else
    showMainOnly()
end

-- Hotkeys
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.M then
        if mainFrame.Visible then showDockOnly() else showMainOnly() end
    elseif input.KeyCode == Enum.KeyCode.R then
        if attached then
            stopFollowing()
        else
            local pathText = (pathBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if pathText == "" then
                statusLabel.Text = "Status: Enter a path before pressing R."
                return
            end
            startFollowing(pathText)
        end
    end
end)

-- Watchdog: re-parent if nuked
task.spawn(function()
    while task.wait(0.5) do
        if not screenGui.Parent then
            screenGui.Parent = getHiddenUi() or CoreGui or localPlayer:FindChild("PlayerGui")
        end
    end
end)

print("[Attach-To-Object] Loaded. Use the dock or press M to open the menu.")
