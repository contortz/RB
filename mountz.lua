local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local isTracking = false
local noclipEnabled = false
local espEnabled = false
local filterEnabled = false
local espInstances = {}

-- 1. UTILITY: SAFE REFERENCE
local function getCrystalFolder()
    local things = workspace:FindFirstChild("Things")
    return things and things:FindFirstChild("Crystals")
end

-- 2. NOCLIP ENGINE
local function setNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

RunService.Stepped:Connect(function()
    if (noclipEnabled or isTracking) and LocalPlayer.Character then
        setNoclip(true)
    end
end)

-- 3. ESP LOGIC (Same as before)
local function createESP(target)
    if not target or espInstances[target] then return end
    local val = target:GetAttribute("Value") or 0
    if filterEnabled and val < 100000 then return end
    
    local highlight = Instance.new("Highlight", target)
    highlight.Name = "CrystalESP"
    highlight.Adornee = target
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    
    local bb = Instance.new("BillboardGui", target)
    bb.Size = UDim2.new(0, 200, 0, 80)
    bb.AlwaysOnTop = true
    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Text = string.format("Tier: %s\nValue: %d", target:GetAttribute("TierName") or "Unknown", val)
    
    espInstances[target] = {Highlight = highlight, Billboard = bb}
end

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
main.Size = UDim2.new(0, 220, 0, 400)
main.Position = UDim2.new(0.5, -110, 0.5, -200)
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
local noclipBtn = createBtn("NOCLIP: OFF", UDim2.new(0.05, 0, 0.2, 0), Color3.fromRGB(50, 50, 50))
local farmBtn = createBtn("AUTO-FARM: OFF", UDim2.new(0.05, 0, 0.35, 0), Color3.fromRGB(100, 0, 150))

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "TOGGLE ESP"
    refreshESP()
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"
    if not noclipEnabled then setNoclip(false) end
end)

farmBtn.MouseButton1Click:Connect(function()
    isTracking = not isTracking
    farmBtn.Text = isTracking and "AUTO-FARM: ON" or "AUTO-FARM: OFF"
    if not isTracking then setNoclip(false) end
end)

-- 5. AUTO-FARM ENGINE
task.spawn(function()
    while true do
        task.wait(0.2)
        if isTracking and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local folder = getCrystalFolder()
            if folder then
                local best = nil; local maxV = -1
                for _, c in pairs(folder:GetChildren()) do
                    local v = c:GetAttribute("Value") or 0
                    if v > maxV then maxV = v; best = c end
                end
                
                if best then
                    local targetPart = best:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
    end
end)
