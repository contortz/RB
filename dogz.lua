--// Single Toggle GUI + R to Teleport to Nearest Player Outside SafeArea
--   SafeArea path: Workspace.MainScene["1"].SafeArea

--== Services ==--
local Players              = game:GetService("Players")
local UserInputService     = game:GetService("UserInputService")
local StarterGui           = game:GetService("StarterGui")
local RunService           = game:GetService("RunService")
local LocalPlayer          = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

--== Character / HRP helpers ==--
local function getCharacterAndHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", math.huge)
    return character, hrp
end

local character, myRoot = getCharacterAndHRP()
LocalPlayer.CharacterAdded:Connect(function(ch)
    character = ch
    myRoot = character:WaitForChild("HumanoidRootPart", math.huge)
end)

--== SafeArea lookup ==--
local function getSafeAreaNode()
    local mainScene = workspace:FindFirstChild("MainScene")
    if not mainScene then return nil end
    local oneNode = mainScene:FindFirstChild("1") -- name is literally "1"
    if not oneNode then return nil end
    return oneNode:FindFirstChild("SafeArea")
end

local SafeAreaNode = getSafeAreaNode()

--== Geometry: point-in-OBB for a BasePart ==--
local function isPointInsidePartOBB(part, worldPosition)
    if not part or not worldPosition then return false end
    if not part:IsA("BasePart") then return false end
    -- convert world pos into the part's local space
    local localPoint = part.CFrame:PointToObjectSpace(worldPosition)
    local half = part.Size * 0.5
    return math.abs(localPoint.X) <= half.X
        and math.abs(localPoint.Y) <= half.Y
        and math.abs(localPoint.Z) <= half.Z
end

--== “Inside SafeArea?” Check (supports Model or Part) ==--
local function isPositionInsideSafeArea(worldPosition)
    if not SafeAreaNode then
        -- If SafeArea is missing, treat as "no one is safe" to avoid false negatives
        return false
    end

    if SafeAreaNode:IsA("BasePart") then
        return isPointInsidePartOBB(SafeAreaNode, worldPosition)
    end

    -- If it's a Model (or Folder), check any BasePart inside it
    local anyInside = false
    for _, descendant in ipairs(SafeAreaNode:GetDescendants()) do
        if descendant:IsA("BasePart") and isPointInsidePartOBB(descendant, worldPosition) then
            anyInside = true
            break
        end
    end
    return anyInside
end

--== Find closest other player who is OUTSIDE safe area ==--
local function getNearestUnsafePlayer()
    if not myRoot then return nil end
    local myPos = myRoot.Position

    local bestEntry = nil
    local bestDistance = math.huge

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer and other.Character then
            local humanoid = other.Character:FindFirstChildOfClass("Humanoid")
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and otherRoot and humanoid.Health > 0 then
                local outside = not isPositionInsideSafeArea(otherRoot.Position)
                if outside then
                    local distance = (otherRoot.Position - myPos).Magnitude
                    if distance < bestDistance then
                        bestDistance = distance
                        bestEntry = { player = other, root = otherRoot, distance = distance }
                    end
                end
            end
        end
    end

    return bestEntry
end

--== Teleport logic ==--
local function teleportNear(targetRoot)
    if not targetRoot or not myRoot then return false, "No target or self root" end
    -- Place slightly behind and above target to reduce collision issues
    local offsetCF = targetRoot.CFrame * CFrame.new(0, 3,  -3)
    myRoot.CFrame = offsetCF
    return true
end

--== GUI (single toggle) ==--
local screen = Instance.new("ScreenGui")
screen.Name = "TeleportToggleUI"
screen.ResetOnSpawn = false
screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.new(0, 240, 0, 80)
frame.Position = UDim2.new(1, -260, 0, 40) -- top-right-ish
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 26)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "R → Teleport to nearest (unsafe)"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextWrapped = true
title.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 110, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 110, 110)
toggleButton.Font = Enum.Font.GothamMedium
toggleButton.TextSize = 14
toggleButton.Text = "Toggle: OFF"
toggleButton.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 110, 0, 30)
statusLabel.Position = UDim2.new(0, 120, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local teleportEnabled = false
local teleportDebounce = false

local function setToggleVisual()
    toggleButton.Text = ("Toggle: %s"):format(teleportEnabled and "ON" or "OFF")
    toggleButton.TextColor3 = teleportEnabled and Color3.fromRGB(110,255,110) or Color3.fromRGB(255,110,110)
end
setToggleVisual()

toggleButton.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    setToggleVisual()
end)

--== R key binding ==--
UserInputService.InputBegan:Connect(function(input, isTypingInTextBox)
    if isTypingInTextBox then return end
    if input.KeyCode == Enum.KeyCode.R and teleportEnabled and not teleportDebounce then
        teleportDebounce = true
        statusLabel.Text = "Status: searching…"

        -- refresh SafeArea in case the scene reloaded
        SafeAreaNode = SafeAreaNode or getSafeAreaNode()

        local entry = getNearestUnsafePlayer()
        if entry and entry.root then
            local ok, reason = teleportNear(entry.root)
            if ok then
                statusLabel.Text = ("Status: teleported → %s (%.1f studs)"):format(entry.player.Name, entry.distance)
                StarterGui:SetCore("SendNotification", {Title="Teleport", Text=("To %s"):format(entry.player.Name), Duration=2})
            else
                statusLabel.Text = "Status: failed (" .. tostring(reason) .. ")"
            end
        else
            statusLabel.Text = "Status: no unsafe players"
            StarterGui:SetCore("SendNotification", {Title="Teleport", Text="No players outside SafeArea", Duration=2})
        end

        task.delay(0.35, function() teleportDebounce = false end)
    end
end)

-- Optional: tiny heartbeat to reflect if SafeArea goes missing/appears
RunService.Stepped:Connect(function()
    if not SafeAreaNode or not SafeAreaNode.Parent then
        SafeAreaNode = getSafeAreaNode()
    end
end)
