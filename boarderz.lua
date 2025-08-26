--// Mexican Boarder – Auto Wheat Harvester (single toggle)
-- Walks to each Wheat prompt under Workspace["Wheat&Sickle"].Wheat and holds the prompt.

-- Services
local Players                  = game:GetService("Players")
local RunService               = game:GetService("RunService")
local PathfindingService       = game:GetService("PathfindingService")
local ProximityPromptService   = game:GetService("ProximityPromptService")
local StarterGui               = game:GetService("StarterGui")
local LocalPlayer              = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

-- Character / HRP helpers
local character, humanoid, hrp
local function attachCharacter(c)
    character = c
    humanoid = c:WaitForChild("Humanoid")
    hrp = c:WaitForChild("HumanoidRootPart")
end
attachCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(attachCharacter)

-- UI (single toggle + status)
local screen = Instance.new("ScreenGui")
screen.Name = "MexicanBoarderUI"
screen.ResetOnSpawn = false
screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 90)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.BorderSizePixel = 0
frame.Active, frame.Draggable = true, true
frame.Parent = screen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 26)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Mexican Boarder (Wheat)"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 120, 0, 32)
toggleBtn.Position = UDim2.new(0, 8, 0, 46)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggleBtn.TextColor3 = Color3.fromRGB(255,110,110)
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 14
toggleBtn.Text = "Toggle: OFF"
toggleBtn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 120, 0, 32)
status.Position = UDim2.new(0, 132, 0, 46)
status.BackgroundTransparency = 1
status.Text = "Status: idle"
status.TextColor3 = Color3.fromRGB(200,200,200)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local enabled = false
local function setToggleVisual()
    toggleBtn.Text = "Toggle: " .. (enabled and "ON" or "OFF")
    toggleBtn.TextColor3 = enabled and Color3.fromRGB(110,255,110) or Color3.fromRGB(255,110,110)
end
setToggleVisual()

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    setToggleVisual()
    StarterGui:SetCore("SendNotification", {Title="Wheat", Text = enabled and "Auto ON" or "Auto OFF", Duration=2})
end)

-- Find the Wheat root container:
local function getWheatRoot()
    local wns = workspace:FindFirstChild("Wheat&Sickle")
    if not wns then return nil end
    local wheatRoot = wns:FindFirstChild("Wheat")
    return wheatRoot
end

-- Enumerate active proximity prompts under the Wheat root
local function collectWheatPrompts()
    local root = getWheatRoot()
    if not root then return {} end
    local list = {}
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            table.insert(list, d)
        end
    end
    return list
end

-- Get world position to stand near a prompt
local function promptWorldPos(prompt)
    -- Prefer adornee if present
    local adornee = prompt.Adornee
    if adornee and adornee:IsA("BasePart") then
        return adornee.Position
    end
    -- Else, the prompt is usually parented to a BasePart
    local parentPart = prompt.Parent
    if parentPart and parentPart:IsA("BasePart") then
        return parentPart.Position
    end
    -- Try model PrimaryPart
    local model = prompt:FindFirstAncestorOfClass("Model")
    if model and model.PrimaryPart then
        return model.PrimaryPart.Position
    end
    return nil
end

-- Move helper: pathfind first, fallback to MoveTo
local function moveTo(pos, radius)
    if not humanoid or not hrp or not character then return false end
    radius = radius or 4
    local start = hrp.Position
    local path = PathfindingService:CreatePath({AgentCanJump = true})
    path:ComputeAsync(start, pos)
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in ipairs(waypoints) do
            humanoid:MoveTo(wp.Position)
            local reached = humanoid.MoveToFinished:Wait()
            if not reached then break end
        end
    else
        humanoid:MoveTo(pos)
        humanoid.MoveToFinished:Wait()
    end
    return (hrp.Position - pos).Magnitude <= radius
end

-- Try to trigger/hold a proximity prompt
local function holdPrompt(prompt)
    if not prompt or not prompt.Enabled then return false, "prompt missing/disabled" end

    local targetPos = promptWorldPos(prompt)
    if not targetPos then return false, "no target pos" end

    local maxDist = (prompt.MaxActivationDistance or 10)
    local arriveRadius = math.clamp(maxDist * 0.8, 2, 8)

    status.Text = "Status: moving…"
    local arrived = moveTo(targetPos, arriveRadius)
    if not arrived then
        return false, "could not reach"
    end

    -- Within range: hold for required duration
    local holdTime = (prompt.HoldDuration and prompt.HoldDuration > 0) and prompt.HoldDuration or 10.5

    status.Text = ("Status: holding (%.1fs)…"):format(holdTime)

    -- Prefer executor helper if available
    if typeof(fireproximityprompt) == "function" then
        -- Some executors accept second arg as hold time; safe to also wait
        pcall(function() fireproximityprompt(prompt, holdTime) end)
        local done = false
        local conn; conn = prompt.Triggered:Connect(function()
            done = true
        end)
        task.wait(holdTime + 0.2)
        if conn then conn:Disconnect() end
        return true
    else
        -- Use official API to simulate input hold
        ProximityPromptService:InputHoldBegin(prompt)
        local done = false
        local conn; conn = prompt.Triggered:Connect(function()
            done = true
        end)
        local t0 = os.clock()
        while os.clock() - t0 < holdTime + 0.5 do
            if not enabled then break end
            if not prompt.Enabled then break end
            if done then break end
            task.wait(0.1)
        end
        ProximityPromptService:InputHoldEnd(prompt)
        if conn then conn:Disconnect() end
        return true
    end
end

-- Choose next prompt: nearest first, re-scan each cycle
local function getNearestPrompt()
    local prompts = collectWheatPrompts()
    local best, bestDist = nil, math.huge
    if not hrp then return nil end
    local myPos = hrp.Position
    for _, p in ipairs(prompts) do
        local pos = promptWorldPos(p)
        if pos then
            local dist = (pos - myPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = p
            end
        end
    end
    return best, bestDist
end

-- Main loop
task.spawn(function()
    while true do
        if enabled then
            local root = getWheatRoot()
            if not root then
                status.Text = "Status: Wheat root missing"
                task.wait(1)
            else
                local prompt, dist = getNearestPrompt()
                if prompt then
                    local ok, reason = holdPrompt(prompt)
                    if ok then
                        status.Text = "Status: harvested"
                    else
                        status.Text = "Status: " .. tostring(reason)
                    end
                    task.wait(0.2) -- small pause between nodes
                else
                    status.Text = "Status: no prompts"
                    task.wait(1.0)
                end
            end
        else
            task.wait(0.25)
        end
    end
end)
