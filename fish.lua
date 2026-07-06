local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------
-- DATA & STATE
---------------------------------------------------------
local Locations = { Slot1 = nil, Slot2 = nil, Slot3 = nil }
local isFarming = false

---------------------------------------------------------
-- GUI SETUP
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "DraggableLocationSaver"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 240) -- Expanded to fit Farm button
mainFrame.Position = UDim2.new(0, 20, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "Dreamz Teleporter ;)"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14

---------------------------------------------------------
-- LOGIC FUNCTIONS
---------------------------------------------------------
local function getMyRoot()
    -- 1. Custom path check
    local customPath = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Characters")
    if customPath and customPath:FindFirstChild(LocalPlayer.Name) then
        return customPath[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
    end
    -- 2. Standard path check
    local stdChar = workspace:FindFirstChild(LocalPlayer.Name)
    if stdChar then return stdChar:FindFirstChild("HumanoidRootPart") end
    -- 3. API fallback
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function farmBestFish()
    while isFarming do
        local fishFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Fishes")
        local root = getMyRoot()
        
        if fishFolder and root and Locations.Slot1 then
            local bestFish = nil
            local maxCash = -1
            
            for _, fish in pairs(fishFolder:GetChildren()) do
                local cash = fish:GetAttribute("CashPerSec") or 0
                if cash > maxCash then
                    maxCash = cash
                    bestFish = fish
                end
            end
            
            if bestFish then
                root.CFrame = bestFish:GetPivot()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.6)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                root.CFrame = Locations.Slot1
            end
        end
        task.wait(1.5) -- Cooldown between farms
    end
end

---------------------------------------------------------
-- UI BUILDER
---------------------------------------------------------
local function createSlot(id, yPos)
    local slotId = "Slot" .. id
    local save = Instance.new("TextButton", mainFrame)
    save.Size = UDim2.new(0, 100, 0, 40); save.Position = UDim2.new(0, 15, 0, yPos)
    save.BackgroundColor3 = Color3.fromRGB(50, 120, 200); save.Text = "SAVE " .. id
    save.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", save)

    local tp = Instance.new("TextButton", mainFrame)
    tp.Size = UDim2.new(0, 100, 0, 40); tp.Position = UDim2.new(0, 125, 0, yPos)
    tp.BackgroundColor3 = Color3.fromRGB(40, 160, 80); tp.Text = "TP " .. id
    tp.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", tp)

    save.MouseButton1Click:Connect(function()
        local root = getMyRoot()
        if root then Locations[slotId] = root.CFrame end
    end)
    tp.MouseButton1Click:Connect(function()
        local root = getMyRoot()
        if root and Locations[slotId] then root.CFrame = Locations[slotId] end
    end)
end

createSlot(1, 45); createSlot(2, 90); createSlot(3, 135)

local farmBtn = Instance.new("TextButton", mainFrame)
farmBtn.Size = UDim2.new(0, 210, 0, 40); farmBtn.Position = UDim2.new(0, 15, 0, 185)
farmBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50); farmBtn.Text = "START FARM"
farmBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", farmBtn)

farmBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    farmBtn.Text = isFarming and "STOP FARM" or "START FARM"
    if isFarming then task.spawn(farmBestFish) end
end)
