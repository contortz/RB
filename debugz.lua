--[[ 
  Attach-To-Object (Follow Anchor) – Dreamz
  • Type any Instance path (e.g., Workspace.Snake.Head), click ATTACH.
  • Your HRP snaps above it every frame. Change Offset Y to float higher/lower.
  • Match Rotation toggle to face same direction as target.
  • Draggable window + Minimize button; click floating icon to restore.
  • Hotkey: R toggles attach/detach with current path.
]]

--// Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")

if not game:IsLoaded() then game.Loaded:Wait() end
local me = Players.LocalPlayer
while not me do task.wait() me = Players.LocalPlayer end

-- ========= UI helpers =========
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

for _, root in ipairs({getHiddenUi(), CoreGui, me:FindFirstChild("PlayerGui")}) do
    if root and root:FindFirstChild(UI_NAME) then root[UI_NAME]:Destroy() end
end

-- ========= Path resolving =========
local function findBasePartInModel(m)
    if not m or not m:IsA("Model") then return nil end
    if m.PrimaryPart and m.PrimaryPart:IsA("BasePart") then return m.PrimaryPart end
    local head = m:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function resolvePath(path)
    if type(path) ~= "string" or path == "" then return nil end
    local tokens = {}
    for t in string.gmatch(path, "[^%.]+") do table.insert(tokens, t) end
    if #tokens == 0 then return nil end

    local root, i
    if tokens[1] == "game" then root, i = game, 2 end
    if not root then
        if tokens[1]:lower() == "workspace" then root, i = Workspace, 2
        else root, i = Workspace, 1 end
    end

    local cur = root
    while i <= #tokens and cur do
        cur = cur:FindFirstChild(tokens[i]); i += 1
    end
    if not cur then return nil end

    if cur:IsA("BasePart") then return cur end
    if cur:IsA("Model") then return findBasePartInModel(cur) end
    if cur:IsA("Folder") or cur:IsA("Accessory") or cur:IsA("Tool") then
        for _, d in ipairs(cur:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end

-- ========= GUI =========
local parentRoot = getHiddenUi() or CoreGui or me:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = UI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
protectGui(gui)
gui.Parent = parentRoot

-- Main window
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 184)
frame.Position = UDim2.new(0.5, -160, 0.5, -92)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

-- Title bar
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(50,50,50)
header.BorderSizePixel = 0
header.Font = Enum.Font.SourceSansBold
header.TextSize = 16
header.TextColor3 = Color3.new(1,1,1)
header.Text = "Attach To Object – Dreamz"
header.Parent = frame

-- Minimize button (title bar)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 24)
minimizeBtn.Position = UDim2.new(1, -30, 0, 2)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.Parent = frame

-- Floating restore icon (shows when minimized)
local restoreIcon = Instance.new("ImageButton")
restoreIcon.Name = "RestoreIcon"
restoreIcon.Size = UDim2.new(0, 56, 0, 56)
restoreIcon.Position = UDim2.new(0, 16, 0, 120)
restoreIcon.BackgroundTransparency = 1
restoreIcon.Image = "rbxassetid://76154122039576" -- swap if you want a different icon
restoreIcon.Visible = false
restoreIcon.ZIndex = 1000
restoreIcon.Parent = gui

minimizeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    restoreIcon.Visible = true
end)
restoreIcon.MouseButton1Click:Connect(function()
    frame.Visible = true
    restoreIcon.Visible = false
end)

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
pathLabel.Parent = frame

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
pathBox.Parent = frame

local offsetLabel = Instance.new("TextLabel")
offsetLabel.BackgroundTransparency = 1
offsetLabel.Position = UDim2.new(0, 10, 0, 72)
offsetLabel.Size = UDim2.new(0, 92, 0, 22)
offsetLabel.Font = Enum.Font.SourceSans
offsetLabel.TextSize = 16
offsetLabel.TextXAlignment = Enum.TextXAlignment.Left
offsetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
offsetLabel.Text = "Offset Y:"
offsetLabel.Parent = frame

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
offsetBox.Parent = frame

local matchRotBtn = Instance.new("TextButton")
matchRotBtn.Name = "MatchRotation"
matchRotBtn.Text = "Match Rotation: OFF"
matchRotBtn.Font = Enum.Font.SourceSansBold
matchRotBtn.TextSize = 14
matchRotBtn.TextColor3 = Color3.new(1,1,1)
matchRotBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
matchRotBtn.BorderSizePixel = 0
matchRotBtn.Position = UDim2.new(0, 200, 0, 72)
matchRotBtn.Size = UDim2.new(0, 110, 0, 24)
matchRotBtn.Parent = frame

local attachBtn = Instance.new("TextButton")
attachBtn.Text = "ATTACH"
attachBtn.Font = Enum.Font.SourceSansBold
attachBtn.TextSize = 16
attachBtn.TextColor3 = Color3.new(1,1,1)
attachBtn.BackgroundColor3 = Color3.fromRGB(0,120,0)
attachBtn.BorderSizePixel = 0
attachBtn.Position = UDim2.new(0, 10, 0, 110)
attachBtn.Size = UDim2.new(0, 140, 0, 28)
attachBtn.Parent = frame

local detachBtn = Instance.new("TextButton")
detachBtn.Text = "DETACH"
detachBtn.Font = Enum.Font.SourceSansBold
detachBtn.TextSize = 16
detachBtn.TextColor3 = Color3.new(1,1,1)
detachBtn.BackgroundColor3 = Color3.fromRGB(120,0,0)
detachBtn.BorderSizePixel = 0
detachBtn.Position = UDim2.new(0, 170, 0, 110)
detachBtn.Size = UDim2.new(0, 140, 0, 28)
detachBtn.Parent = frame

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 10, 0, 146)
status.Size = UDim2.new(1, -20, 0, 24)
status.Font = Enum.Font.SourceSansSemibold
status.TextSize = 15
status.TextColor3 = Color3.fromRGB(200, 220, 255)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Status: Idle"
status.Parent = frame

-- ========= State =========
local attached = false
local matchRotation = false
local savedPath = ""
local followConn

local function setMatchButton(on)
    matchRotation = on
    matchRotBtn.Text = "Match Rotation: " .. (on and "ON" or "OFF")
    matchRotBtn.BackgroundColor3 = on and Color3.fromRGB(0,110,70) or Color3.fromRGB(60,60,60)
end
setMatchButton(false)

matchRotBtn.MouseButton1Click:Connect(function()
    setMatchButton(not matchRotation)
end)

local function getOffsetY()
    local n = tonumber(offsetBox.Text)
    if not n then n = 2.5 end
    return n
end

local function stopFollowing()
    attached = false
    if followConn then pcall(function() followConn:Disconnect() end) end
    followConn = nil
    status.Text = "Status: Detached"
end

local function startFollowing(path)
    savedPath = path
    attached = true

    if followConn then pcall(function() followConn:Disconnect() end) end
    followConn = nil
    status.Text = "Status: Resolving target…"

    followConn = RunService.Heartbeat:Connect(function()
        if not attached then return end
        local char = me.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- resolve every frame in case the object respawns
        local tgt = resolvePath(savedPath)
        if tgt and tgt:IsA("BasePart") then
            local offY = getOffsetY()
            local baseCF = tgt.CFrame
            local targetPos = baseCF.Position + Vector3.new(0, offY, 0)

            if matchRotation then
                local lookAt = targetPos + baseCF.LookVector
                hrp.CFrame = CFrame.new(targetPos, lookAt)
            else
                -- keep current orientation
                local _, _, _, r00,r01,r02, r10,r11,r12, r20,r21,r22 = hrp.CFrame:GetComponents()
                hrp.CFrame = CFrame.fromMatrix(targetPos,
                    Vector3.new(r00,r10,r20), Vector3.new(r01,r11,r21), Vector3.new(r02,r12,r22))
            end

            status.Text = "Status: Attached to " .. tgt:GetFullName()
        else
            status.Text = "Status: Target not found (searching…) "
        end
    end)
end

attachBtn.MouseButton1Click:Connect(function()
    local path = (pathBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if path == "" then
        status.Text = "Status: Enter a path (e.g., Workspace.Snake.Head)"
        return
    end
    startFollowing(path)
end)

detachBtn.MouseButton1Click:Connect(function() stopFollowing() end)

-- Hotkey: R = toggle attach/detach with current path
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        if attached then
            stopFollowing()
        else
            local path = (pathBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if path == "" then
                status.Text = "Status: Enter a path before pressing R."
                return
            end
            startFollowing(path)
        end
    end
end)

-- Watchdog: re-parent UI if nuked
task.spawn(function()
    while task.wait(0.5) do
        if not gui.Parent then
            gui.Parent = getHiddenUi() or CoreGui or me:FindFirstChild("PlayerGui")
        end
    end
end)

print("[Attach-To-Object] Loaded. Type a path like Workspace.Snake.Head and click ATTACH.")
