-- ADVANCED ROOM FARMING - Open Doors + Loot + Sell
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RemoteEvent = ReplicatedStorage.Remotes:WaitForChild("RemoteEvent")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local RunService = game:GetService("RunService")

local COLLECTOR_NPC = workspace.NPC["Storage Collector"]

-- ============================================
-- CONFIGURATION
-- ============================================

-- Sell Position (Storage Collector)
local SELL_POSITION = Vector3.new(672.603699, 5.80000257, -11.9104958)

-- Safe position (far away from hostile NPCs)
local SAFE_POSITION = Vector3.new(0, 10, 0) -- Change this to a safe spot

-- How often to check for loot (seconds)
local SCAN_INTERVAL = 2

-- Items to KEEP (WILL NOT be sold)
local KEEP_ITEMS = {
    "Wallet",
    "Money",
    "Cash",
    -- Add any items you want to keep
}

-- Items to SELL (if empty, sells everything except KEEP_ITEMS)
local SELL_ITEMS = {} -- Empty = sell everything except KEEP_ITEMS

-- ============================================
-- STATE
-- ============================================

local farming = false
local farmingThread = nil
local currentRoom = nil
local roomsFarmed = 0
local totalLooted = 0
local totalSold = 0

-- GUI References
local guiVisible = true
local screenGui = nil
local frame = nil
local farmButton = nil
local statusLabel = nil
local statsLabel = nil

-- ============================================
-- GET CHARACTER
-- ============================================

local function GetCharacter()
    local live = Workspace:FindFirstChild("Live")
    if live then
        local char = live:FindFirstChild(LocalPlayer.Name)
        if char then
            return char
        end
    end
    return LocalPlayer.Character
end

local function GetHRP()
    local character = GetCharacter()
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ============================================
-- TELEPORT FUNCTIONS
-- ============================================

local function TeleportTo(position)
    local hrp = GetHRP()
    if not hrp then
        print("❌ No HRP found!")
        return false
    end
    
    local targetPos = position + Vector3.new(0, 2, 0)
    print("   📍 Teleporting to: " .. tostring(targetPos))
    
    local success, err = pcall(function()
        hrp.CFrame = CFrame.new(targetPos)
    end)
    
    if not success then
        print("   ❌ Teleport failed: " .. tostring(err))
        return false
    end
    
    wait(0.2)
    print("   ✅ At: " .. tostring(hrp.Position))
    return true
end

local function TeleportToSellPosition()
    print("💰 Teleporting to Storage Collector...")
    return TeleportTo(SELL_POSITION)
end

local function TeleportToSafePosition()
    print("🛡️ Teleporting to safe position...")
    return TeleportTo(SAFE_POSITION)
end

-- ============================================
-- CAMERA CONTROL
-- ============================================

local function LookAt(targetPosition)
    local camera = Workspace:FindFirstChild("Camera")
    if not camera then return false end
    
    local hrp = GetHRP()
    if not hrp then return false end
    
    local currentPos = hrp.Position
    local direction = (targetPosition - currentPos).Unit
    local cameraOffset = direction * -3 + Vector3.new(0, 2, 0)
    local cameraPos = currentPos + cameraOffset
    local lookAtCFrame = CFrame.new(cameraPos, targetPosition)
    
    pcall(function()
        camera.CFrame = lookAtCFrame
    end)
    return true
end

local function Face(targetPosition)
    local hrp = GetHRP()
    if not hrp then return false end
    
    local currentPos = hrp.Position
    local direction = (targetPosition - currentPos)
    direction = Vector3.new(direction.X, 0, direction.Z)
    
    if direction.Magnitude > 0.5 then
        local lookAtCFrame = CFrame.lookAt(currentPos, currentPos + direction)
        pcall(function()
            hrp.CFrame = lookAtCFrame
        end)
        return true
    end
    return false
end

-- ============================================
-- PRESS E FUNCTION
-- ============================================

local function PressE(count)
    count = count or 5
    for i = 1, count do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
        wait(0.05)
    end
end

-- ============================================
-- ROOM FUNCTIONS
-- ============================================

local function GetRooms()
    local rooms = {}
    local storages = Workspace:FindFirstChild("Storages")
    if not storages then return rooms end
    
    for _, room in pairs(storages:GetChildren()) do
        if string.find(room.Name, "Room") then
            table.insert(rooms, room)
        end
    end
    
    return rooms
end

local function GetDoor(room)
    local door = room:FindFirstChild("Door")
    if door then
        return door
    end
    return nil
end

local function GetDoorHandle(door)
    if door then
        return door:FindFirstChild("Handle")
    end
    return nil
end

local function GetDoorLock(door)
    if door then
        return door:FindFirstChild("Lock")
    end
    return nil
end

local function IsDoorLocked(room)
    local door = GetDoor(room)
    if door then
        local lock = GetDoorLock(door)
        return lock ~= nil
    end
    return false
end

local function GetLootInRoom(room)
    local lootItems = {}
    local contents = room:FindFirstChild("Contents")
    if contents then
        local lootFolder = contents:FindFirstChild("Loot")
        if lootFolder then
            for _, loot in pairs(lootFolder:GetChildren()) do
                if loot:FindFirstChild("ProximityPrompt") then
                    table.insert(lootItems, loot)
                end
            end
        end
    end
    return lootItems
end

local function GetHandlePosition(room)
    local door = GetDoor(room)
    if door then
        local handle = GetDoorHandle(door)
        if handle then
            if handle:IsA("BasePart") then
                return handle.Position, handle.CFrame
            end
            -- If handle is a model, find its position
            for _, child in pairs(handle:GetDescendants()) do
                if child:IsA("BasePart") then
                    return child.Position, child.CFrame
                end
            end
        end
    end
    return nil, nil
end

-- ============================================
-- OPEN DOOR
-- ============================================

local function OpenDoor(room)
    print("   🚪 Opening door for: " .. room.Name)
    
    local pos, cframe = GetHandlePosition(room)
    if not pos then
        print("   ❌ Could not find door handle!")
        return false
    end
    
    -- Teleport to handle
    local targetPos = pos + Vector3.new(0, 1, 0)
    if not TeleportTo(targetPos) then
        return false
    end
    
    wait(0.3)
    
    -- Look at handle
    LookAt(pos)
    wait(0.2)
    Face(pos)
    wait(0.2)
    
    -- Press E to open
    print("   🔑 Pressing E to open door...")
    PressE(10)
    wait(0.5)
    
    print("   ✅ Door opened!")
    return true
end

-- ============================================
-- LOOT ROOM
-- ============================================

local function LootRoom(room)
    local lootItems = GetLootInRoom(room)
    
    if #lootItems == 0 then
        print("   📦 No loot in " .. room.Name)
        return 0
    end
    
    print("   🎯 Found " .. #lootItems .. " items in " .. room.Name)
    local count = 0
    
    for i, loot in pairs(lootItems) do
        print("      [" .. i .. "/" .. #lootItems .. "] Looting: " .. loot.Name)
        
        local pos, cframe = nil, nil
        if loot:IsA("BasePart") then
            pos = loot.Position
        elseif loot:IsA("Model") then
            local part = loot:FindFirstChildWhichIsA("BasePart")
            if part then
                pos = part.Position
            end
        end
        
        if pos then
            local targetPos = pos + Vector3.new(0, 1, 0)
            TeleportTo(targetPos)
            wait(0.2)
            LookAt(pos)
            wait(0.2)
            Face(pos)
            wait(0.2)
            PressE(8)
            wait(0.3)
            count = count + 1
            print("         ✅ Looted: " .. loot.Name)
        else
            print("         ❌ Could not find position for: " .. loot.Name)
        end
        
        wait(0.3)
    end
    
    print("   ✅ Looted " .. count .. "/" .. #lootItems .. " items from " .. room.Name)
    return count
end

-- ============================================
-- SELL FUNCTIONS
-- ============================================

local function ShouldSellItem(itemName)
    -- Check if item is in keep list
    for _, keepItem in pairs(KEEP_ITEMS) do
        if itemName == keepItem then
            return false
        end
    end
    
    -- If SELL_ITEMS is empty, sell everything except KEEP_ITEMS
    if #SELL_ITEMS == 0 then
        return true
    end
    
    -- Check if item is in sell list
    for _, sellItem in pairs(SELL_ITEMS) do
        if itemName == sellItem then
            return true
        end
    end
    
    return false
end

local function SellAllItems()
    print("💰 Selling items...")
    
    -- Teleport to Storage Collector
    if not TeleportToSellPosition() then
        print("   ❌ Could not reach Storage Collector!")
        return 0
    end
    
    wait(0.5)
    
    -- Get items from backpack
    local items = {}
    for _, item in pairs(Backpack:GetChildren()) do
        table.insert(items, item.Name)
    end
    
    if #items == 0 then
        print("   💰 Nothing to sell")
        return 0
    end
    
    local sold = 0
    for _, name in pairs(items) do
        if ShouldSellItem(name) then
            local success, err = pcall(function()
                RemoteEvent:FireServer("SellItem", name, COLLECTOR_NPC)
            end)
            
            if success then
                sold = sold + 1
                print("   ✅ Sold: " .. name)
            else
                print("   ❌ Failed to sell: " .. name)
            end
            wait(0.1)
        else
            print("   ⛔ Keeping: " .. name)
        end
    end
    
    print("   💰 Sold " .. sold .. " items")
    return sold
end

-- ============================================
-- MAIN FARMING LOOP
-- ============================================

local function FarmRooms()
    print("")
    print("========================================")
    print("🌾 STARTING FARMING CYCLE")
    print("========================================")
    
    local rooms = GetRooms()
    if #rooms == 0 then
        print("❌ No rooms found!")
        return
    end
    
    print("📋 Found " .. #rooms .. " rooms")
    
    for i, room in pairs(rooms) do
        if not farming then
            print("⏹️ Farming stopped!")
            break
        end
        
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📍 ROOM " .. i .. "/" .. #rooms .. ": " .. room.Name)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        currentRoom = room.Name
        
        -- Check if door is locked
        if IsDoorLocked(room) then
            print("   🔒 Door is LOCKED - Skipping!")
            print("   📍 Moving to next room...")
            wait(1)
            goto continue
        end
        
        -- Open the door
        print("   🚪 Door is unlocked - Opening...")
        if not OpenDoor(room) then
            print("   ❌ Failed to open door!")
            wait(1)
            goto continue
        end
        
        wait(0.5)
        
        -- Loot the room
        local looted = LootRoom(room)
        totalLooted = totalLooted + looted
        
        if looted == 0 then
            print("   📦 No loot found - Moving to next room...")
            wait(1)
            goto continue
        end
        
        -- Sell items after looting
        if looted > 0 then
            print("   💰 Looted " .. looted .. " items - Selling...")
            local sold = SellAllItems()
            totalSold = totalSold + sold
            roomsFarmed = roomsFarmed + 1
        end
        
        ::continue::
        wait(1)
    end
    
    print("")
    print("========================================")
    print("🌾 FARMING CYCLE COMPLETE")
    print("📊 Rooms farmed: " .. roomsFarmed)
    print("🎯 Items looted: " .. totalLooted)
    print("💰 Items sold: " .. totalSold)
    print("========================================")
    
    -- Teleport to safe position when done
    print("🛡️ Teleporting to safe position...")
    TeleportToSafePosition()
end

-- ============================================
-- TOGGLE FARMING
-- ============================================

local function ToggleFarming()
    farming = not farming
    
    if farming then
        print("▶️▶️▶️ FARMING STARTED! ◀️◀️◀️")
        print("📍 Will farm rooms, open doors, loot, and sell!")
        
        if farmingThread then
            coroutine.close(farmingThread)
            farmingThread = nil
        end
        
        farmingThread = coroutine.create(function()
            while farming do
                FarmRooms()
                if farming then
                    print("")
                    print("⏳ Waiting " .. SCAN_INTERVAL .. "s before next cycle...")
                    wait(SCAN_INTERVAL)
                end
            end
        end)
        coroutine.resume(farmingThread)
    else
        print("⏹️⏹️⏹️ FARMING STOPPED! ⏹️⏹️⏹️")
        if farmingThread then
            coroutine.close(farmingThread)
            farmingThread = nil
        end
    end
    
    UpdateGUI()
end

-- ============================================
-- UPDATE GUI
-- ============================================

local function UpdateGUI()
    if farmButton then
        if farming then
            farmButton.Text = "⏹️ Stop Farming"
            farmButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        else
            farmButton.Text = "🌾 Start Farming"
            farmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        end
    end
    
    if statusLabel then
        if farming then
            statusLabel.Text = "Status: 🟢 Farming..."
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            statusLabel.Text = "Status: 🔴 Idle"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    
    if statsLabel then
        statsLabel.Text = "📊 Rooms: " .. roomsFarmed .. " | Looted: " .. totalLooted .. " | Sold: " .. totalSold
    end
end

-- ============================================
-- CREATE GUI
-- ============================================

local function CreateGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RoomFarmingGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 230)
    frame.Position = UDim2.new(0, 20, 0.5, -115)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 200, 100)
    frame.Visible = true
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = frame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.BackgroundTransparency = 0.3
    titleBar.Parent = frame

    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 10)
    titleBarCorner.Parent = titleBar

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Text = "🌾 Room Farmer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 1, 0)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BackgroundTransparency = 1
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = titleBar

    -- Status
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Position = UDim2.new(0, 10, 0, 45)
    statusLabel.Text = "Status: 🔴 Idle"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Name = "Status"
    statusLabel.Parent = frame

    -- Current Room
    local roomLabel = Instance.new("TextLabel")
    roomLabel.Size = UDim2.new(1, -20, 0, 20)
    roomLabel.Position = UDim2.new(0, 10, 0, 70)
    roomLabel.Text = "📍 Current Room: None"
    roomLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    roomLabel.BackgroundTransparency = 1
    roomLabel.TextSize = 12
    roomLabel.TextXAlignment = Enum.TextXAlignment.Left
    roomLabel.Name = "CurrentRoom"
    roomLabel.Parent = frame

    -- Protected items
    local protectedLabel = Instance.new("TextLabel")
    protectedLabel.Size = UDim2.new(1, -20, 0, 16)
    protectedLabel.Position = UDim2.new(0, 10, 0, 88)
    protectedLabel.Text = "🛡️ Protected: " .. table.concat(KEEP_ITEMS, ", ")
    protectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    protectedLabel.BackgroundTransparency = 1
    protectedLabel.TextSize = 10
    protectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    protectedLabel.Parent = frame

    -- Farm Button
    farmButton = Instance.new("TextButton")
    farmButton.Size = UDim2.new(0, 250, 0, 45)
    farmButton.Position = UDim2.new(0.5, -125, 0, 115)
    farmButton.Text = "🌾 Start Farming"
    farmButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    farmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmButton.Font = Enum.Font.GothamBold
    farmButton.TextSize = 16
    farmButton.BorderSizePixel = 0
    farmButton.Parent = frame

    local farmCorner = Instance.new("UICorner")
    farmCorner.CornerRadius = UDim.new(0, 8)
    farmCorner.Parent = farmButton

    -- Stats
    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -20, 0, 20)
    statsLabel.Position = UDim2.new(0, 10, 0, 175)
    statsLabel.Text = "📊 Rooms: 0 | Looted: 0 | Sold: 0"
    statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Name = "Stats"
    statsLabel.Parent = frame

    -- Keybind Info
    local keybindLabel = Instance.new("TextLabel")
    keybindLabel.Size = UDim2.new(1, -20, 0, 20)
    keybindLabel.Position = UDim2.new(0, 10, 0, 195)
    keybindLabel.Text = "📌 Press K to show/hide this GUI"
    keybindLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    keybindLabel.BackgroundTransparency = 1
    keybindLabel.TextSize = 11
    keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    keybindLabel.Parent = frame

    -- Button click
    farmButton.MouseButton1Click:Connect(ToggleFarming)

    -- Close button
    closeButton.MouseButton1Click:Connect(function()
        guiVisible = false
        frame.Visible = false
        print("📌 GUI hidden (Press K to show)")
    end)

    -- Make draggable
    local function MakeDraggable()
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        
        titleBar.InputBegan:Connect(function(input)
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
        
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    MakeDraggable()
    UpdateGUI()
end

-- ============================================
-- K KEY TOGGLE GUI
-- ============================================

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        guiVisible = not guiVisible
        if frame then
            frame.Visible = guiVisible
            print(guiVisible and "📌 GUI shown" or "📌 GUI hidden")
        end
    end
end)

-- ============================================
-- INITIALIZE
-- ============================================

-- Create GUI
CreateGUI()

-- Update current room display periodically
spawn(function()
    while true do
        wait(1)
        if frame then
            local roomLabel = frame:FindFirstChild("CurrentRoom")
            if roomLabel then
                roomLabel.Text = "📍 Current Room: " .. (currentRoom or "None")
            end
        end
    end
end)

print("")
print("========================================")
print("🌾 ROOM FARMER SCRIPT LOADED")
print("========================================")
print("📌 Press K to show/hide GUI")
print("🌾 Click 'Start Farming' to begin")
print("")
print("🔑 Opens doors by looking at Handle + E")
print("🔒 Skips rooms with Locks")
print("🎯 Loots all items in room")
print("💰 Sells items (except protected ones)")
print("🛡️ Protected: " .. table.concat(KEEP_ITEMS, ", "))
print("========================================")
