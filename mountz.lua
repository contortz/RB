local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local espEnabled = false
local filter100k = false
local filterMythic = false
local filterLegendary = false
local noclipEnabled = false
local isTracking = false
local espInstances = {}

-- 1. UTILITY: SAFE REFERENCE
local function getCrystalFolder()
    local things = workspace:FindFirstChild("Things")
    if not things then return nil end
    return things:FindFirstChild("Crystals")
end

-- 2. NOCLIP & MOVEMENT ENGINE
local function setNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
end

RunService.Stepped:Connect(function()
    if (noclipEnabled or isTracking) and LocalPlayer.Character then
        setNoclip(true)
    end
end)

-- 3. ESP LOGIC
local function createESP(target)
    if not target or espInstances[target] then return end
    
    local val = target:GetAttribute("Value") or 0
    local tier = target:GetAttribute("TierName") or "Common"
    
    if filter100k and val < 100000 then return end
    if filterMythic and tier ~= "Mythic" then return end
    if filterLegendary and tier ~= "Legendary" then return end
    
    local highlight = Instance.new("Highlight", target)
    highlight.Adornee = target
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    
    local bb = Instance.new("BillboardGui", target)
    bb.Size = UDim2.new(0, 200, 0, 100)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0)
    
    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextStrokeTransparency = 0
    
    espInstances[target] = {Highlight = highlight, Billboard = bb, Label = label, Tier = tier, Val = val}
end

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for target, data in pairs(espInstances) do
        if target and target.Parent then
            local targetPos = target:IsA("Model") and target:GetPivot().Position or target.Position
            local dist = (root.Position - targetPos).Magnitude
            data.Label.Text = string.format("Tier: %s\nValue: %d\nDist: %d studs", data.Tier, data.Val, math.floor(dist))
        else
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            espInstances[target] = nil
        end
    end
end)

local function refreshESP()
    for _, data in pairs(espInstances) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    espInstances = {}
    if espEnabled then
        local folder = getCrystalFolder()
        if folder then
            for _, child in pairs(folder:GetChildren()) do createESP(child) end
        end
    end
end

-- 4. UI SETUP
local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 220, 0, 450)
main.Position = UDim2.new(0.5, -110, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", main)
Instance.new("UIDragDetector", main)

local function createBtn(text, pos, color)
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(0.9, 0, 0, 40)
    b.Position = pos
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    return b
end

local espBtn = createBtn("TOGGLE ESP", UDim2.new(0.05, 0, 0.05, 0), Color3.fromRGB(200, 100, 0))
local f100k = createBtn("100K+: OFF", UDim2.new(0.05, 0, 0.17, 0), Color3.fromRGB(50, 50, 50))
local fMythic = createBtn("MYTHIC: OFF", UDim2.new(0.05, 0, 0.29, 0), Color3.fromRGB(50, 50, 50))
local fLegend = createBtn("LEGENDARY: OFF", UDim2.new(0.05, 0, 0.41, 0), Color3.fromRGB(50, 50, 50))
local noclipBtn = createBtn("NOCLIP: OFF", UDim2.new(0.05, 0, 0.53, 0), Color3.fromRGB(50, 50, 50))
local farmBtn = createBtn("AUTO-FARM: OFF", UDim2.new(0.05, 0, 0.65, 0), Color3.fromRGB(100, 0, 150))

-- Button Logic
espBtn.MouseButton1Click:Connect(function() espEnabled = not espEnabled; espBtn.Text = espEnabled and "ESP: ON" or "TOGGLE ESP"; refreshESP() end)
noclipBtn.MouseButton1Click:Connect(function() noclipEnabled = not noclipEnabled; noclipBtn.Text = noclipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"; if not noclipEnabled then setNoclip(false) end end)
farmBtn.MouseButton1Click:Connect(function() isTracking = not isTracking; farmBtn.Text = isTracking and "AUTO-FARM: ON" or "AUTO-FARM: OFF"; if not isTracking then setNoclip(false) end end)

local function toggleFilter(btn, varName, label)
    if varName == "f100k" then filter100k = not filter100k elseif varName == "fMythic" then filterMythic = not filterMythic else filterLegendary = not filterLegendary end
    btn.Text = (varName == "f100k" and filter100k or varName == "fMythic" and filterMythic or filterLegendary) and label..": ON" or label..": OFF"
    refreshESP()
end

f100k.MouseButton1Click:Connect(function() toggleFilter(f100k, "f100k", "100K+") end)
fMythic.MouseButton1Click:Connect(function() toggleFilter(fMythic, "fMythic", "MYTHIC") end)
fLegend.MouseButton1Click:Connect(function() toggleFilter(fLegend, "fLegend", "LEGENDARY") end)

-- 5. AUTO-FARM ENGINE
task.spawn(function()
    while true do
        task.wait(0.5)
        if isTracking and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local folder = getCrystalFolder()
            local best, maxV = nil, -1
            if folder then
                for _, c in pairs(folder:GetChildren()) do
                    local v = c:GetAttribute("Value") or 0
                    if v > maxV then maxV = v; best = c end
                end
                if best then
                    local targetPart = best:IsA("Model") and best.PrimaryPart or best:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        hrp.Anchored = true
                        TweenService:Create(hrp, TweenInfo.new(0.3), {CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)}):Play()
                        task.wait(0.3)
                        hrp.Anchored = false
                    end
                end
            end
        end
    end
end)

if folder then folder.ChildAdded:Connect(function(c) if espEnabled then task.wait(0.5); createESP(c) end end) end
