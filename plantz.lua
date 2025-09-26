-- Seed Auto Buyer (timer-based, cash only) – buys selected seeds twice each 5-min cycle

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local lp = Players.LocalPlayer

-- BridgeNet2: real shop call
local BridgeNet2 = require(ReplicatedStorage.Modules.Utility.BridgeNet2)
local BuyItem    = BridgeNet2.ReferenceBridge("BuyItem")

-- Seeds + defaults (toggle in UI)
local ORDERED = { "Watermelon Seed","Cocotank Seed","Tomatrio Seed","Mr Carrot Seed" }
local SELECTED = {
    ["Watermelon Seed"] = true,
    ["Cocotank Seed"]   = true,
    ["Tomatrio Seed"]   = false,
    ["Mr Carrot Seed"]  = false,
}

-- Find George's timer label on your plot
local function getTimerLabel()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local pid = lp:GetAttribute("Plot")
    if pid then
        local p = plots:FindFirstChild(tostring(pid))
        if p and p:FindFirstChild("NPCs") then
            local g = p.NPCs:FindFirstChild("George")
            if g then
                local bg = g:FindFirstChild("Timer")
                if bg and bg:IsA("BillboardGui") then
                    local lbl = bg:FindFirstChild("Timer")
                    if lbl and lbl:IsA("TextLabel") then
                        return lbl
                    end
                end
            end
        end
    end

    for _, p in ipairs(plots:GetChildren()) do
        local g = p:FindFirstChild("NPCs") and p.NPCs:FindFirstChild("George")
        if g then
            local bg = g:FindFirstChild("Timer")
            local lbl = bg and bg:FindFirstChild("Timer")
            if lbl and lbl:IsA("TextLabel") then
                return lbl
            end
        end
    end
    return nil
end

local timerLabel = getTimerLabel()
if not timerLabel then warn("Timer TextLabel not found yet; waiting...") end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "SeedAutoBuyerUI"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 180)
frame.Position = UDim2.new(1, -280, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.new(0, 5, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(0,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Seed Auto Buyer - (loading...)"
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 26)
toggleBtn.Position = UDim2.new(0, 10, 0, 36)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Text = "Enable Auto-Buy"
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 0, 100)
list.Position = UDim2.new(0, 10, 0, 70)
list.ScrollBarThickness = 6
list.BackgroundTransparency = 1
list.Parent = frame
local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 6)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = list

for _, name in ipairs(ORDERED) do
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -6, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(50,50,50)
    row.TextColor3 = Color3.fromRGB(255,255,255)
    row.Font = Enum.Font.Gotham
    row.TextSize = 14
    row.Text = name
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)

    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(0, 22, 1, 0)
    box.Position = UDim2.new(1, -26, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(70,70,70)
    box.Text = SELECTED[name] and "[x]" or "[ ]"
    box.TextColor3 = Color3.fromRGB(0,255,255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

    row.MouseButton1Click:Connect(function()
        SELECTED[name] = not SELECTED[name]
        box.Text = SELECTED[name] and "[x]" or "[ ]"
    end)
end

-- live timer text
RunService.Heartbeat:Connect(function()
    if not timerLabel then
        timerLabel = getTimerLabel()
    end
    if timerLabel then
        title.Text = "Seed Auto Buyer - (" .. (timerLabel.Text or "?") .. ")"
    end
end)

-- core watcher
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleBtn.Text = enabled and "Disable Auto-Buy" or "Enable Auto-Buy"
    toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0,200,100) or Color3.fromRGB(60,60,60)
end)

local lastSeconds = nil
local inCycle = false
local firstShotDone = false
local secondShotDone = false
local cycleStartT = 0

local function parseTime(t)
    local m, s = string.match(t or "", "^(%d+):(%d%d)$")
    if not m or not s then return nil end
    return tonumber(m) * 60 + tonumber(s)
end

local function fireSelected(tag)
    if not BuyItem then return end
    for _, seed in ipairs(ORDERED) do
        if SELECTED[seed] then
            pcall(function() BuyItem:Fire(seed) end)
            -- print(("[SAB] fired %s (%s)"):format(seed, tag))
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not enabled then return end
    if not timerLabel then return end

    local t = parseTime(timerLabel.Text)
    if not t then return end

    local startsWithFive = string.sub(timerLabel.Text, 1, 2) == "5:"
    local jumpedUp = (lastSeconds and (t - lastSeconds) >= 200) or false

    if (startsWithFive or jumpedUp) and not inCycle then
        inCycle = true
        firstShotDone, secondShotDone = false, false
        cycleStartT = os.clock()
        fireSelected("reset")
        firstShotDone = true
    end

    if inCycle and not secondShotDone and (os.clock() - cycleStartT) >= 1.0 then
        fireSelected("second")
        secondShotDone = true
    end

    if inCycle and t <= 1 then
        inCycle = false
    end

    lastSeconds = t
end)
