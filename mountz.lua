local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local espEnabled = false
local filter100k = false
local filterMythic = false
local filterLegendary = false
local espInstances = {}

-- 1. UTILITY: SAFE REFERENCE
local function getCrystalFolder()
    local things = workspace:FindFirstChild("Things")
    if not things then return nil end
    return things:FindFirstChild("Crystals")
end

-- 2. ESP LOGIC
local function createESP(target)
    if not target or espInstances[target] then return end
    
    -- Filter Logic
    local val = target:GetAttribute("Value") or 0
    local tier = target:GetAttribute("TierName") or "Common"
    
    if filter100k and val < 100000 then return end
    if filterMythic and tier ~= "Mythic" then return end
    if filterLegendary and tier ~= "Legendary" then return end
    
    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = target
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.Parent = target
    
    -- Create Billboard
    local bb = Instance.new("BillboardGui", target)
    bb.Size = UDim2.new(0, 200, 0, 100)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0) -- Hover above the object
    
    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextStrokeTransparency = 0 -- Better visibility
    
    espInstances[target] = {Highlight = highlight, Billboard = bb, Label = label, Tier = tier, Val = val}
end

-- Update Distance every frame
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for target, data in pairs(espInstances) do
        if target and target.Parent then
            -- Get position based on whether it is a model or part
            local targetPos = target:IsA("Model") and target:GetPivot().Position or target.Position
            local dist = (root.Position - targetPos).Magnitude
            data.Label.Text = string.format("Tier: %s\nValue: %d\nDist: %d studs", data.Tier, data.Val, math.floor(dist))
        else
            -- Cleanup if object destroyed
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            espInstances[target] = nil
        end
    end
end)

local function refreshESP()
    -- Clear existing
    for _, data in pairs(espInstances) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    espInstances = {}
    
    if espEnabled then
        local folder = getCrystalFolder()
        if folder then
            for _, child in pairs(folder:GetChildren()) do 
                createESP(child) 
            end
        end
    end
end

-- 3. UI SETUP
local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 220, 0, 350)
main.Position = UDim2.new(0.5, -110, 0.5, -175)
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
local f100k = createBtn("100K+: OFF", UDim2.new(0.05, 0, 0.2, 0), Color3.fromRGB(50, 50, 50))
local fMythic = createBtn("MYTHIC: OFF", UDim2.new(0.05, 0, 0.35, 0), Color3.fromRGB(50, 50, 50))
local fLegend = createBtn("LEGENDARY: OFF", UDim2.new(0.05, 0, 0.5, 0), Color3.fromRGB(50, 50, 50))

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "TOGGLE ESP"
    refreshESP()
end)

local function toggleFilter(btn, varName, label)
    if varName == "f100k" then filter100k = not filter100k; btn.Text = filter100k and label..": ON" or label..": OFF"
    elseif varName == "fMythic" then filterMythic = not filterMythic; btn.Text = filterMythic and label..": ON" or label..": OFF"
    elseif varName == "fLegend" then filterLegendary = not filterLegendary; btn.Text = filterLegendary and label..": ON" or label..": OFF"
    end
    refreshESP()
end

f100k.MouseButton1Click:Connect(function() toggleFilter(f100k, "f100k", "100K+") end)
fMythic.MouseButton1Click:Connect(function() toggleFilter(fMythic, "fMythic", "MYTHIC") end)
fLegend.MouseButton1Click:Connect(function() toggleFilter(fLegend, "fLegend", "LEGENDARY") end)

-- Handle new crystals appearing
local folder = getCrystalFolder()
if folder then
    folder.ChildAdded:Connect(function(child)
        if espEnabled then task.wait(0.5); createESP(child) end
    end)
end
