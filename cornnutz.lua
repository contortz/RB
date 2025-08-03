--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 170, 255),
    Epic = Color3.fromRGB(170, 0, 255),
    Legendary = Color3.fromRGB(255, 215, 0),
    Mythic = Color3.fromRGB(255, 85, 0),
    ["Brainrot God"] = Color3.fromRGB(255, 0, 0),
    Secret = Color3.fromRGB(0, 255, 255)
}

-- Enabled rarities
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Toggles
local AvoidInMachine = true
local PlayerESPEnabled = false

-- ESP Folders
local worldESPFolder = Instance.new("Folder", CoreGui)
worldESPFolder.Name = "WorldRarityESP"
local playerESPFolder = Instance.new("Folder", CoreGui)
playerESPFolder.Name = "PlayerESPFolder"

-- UI
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ESPMenuUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 320)
frame.Position = UDim2.new(0, 20, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "ESP Menu"
title.TextSize = 16

-- Avoid In Machine Toggle
local toggleAvoidBtn = Instance.new("TextButton", frame)
toggleAvoidBtn.Size = UDim2.new(1, -10, 0, 25)
toggleAvoidBtn.Position = UDim2.new(0, 5, 0, 30)
toggleAvoidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAvoidBtn.TextColor3 = Color3.new(1, 1, 1)
toggleAvoidBtn.Text = "Avoid In Machine: ON"
toggleAvoidBtn.MouseButton1Click:Connect(function()
    AvoidInMachine = not AvoidInMachine
    toggleAvoidBtn.Text = "Avoid In Machine: " .. (AvoidInMachine and "ON" or "OFF")
end)

-- Player ESP Toggle
local togglePlayerESPBtn = Instance.new("TextButton", frame)
togglePlayerESPBtn.Size = UDim2.new(1, -10, 0, 25)
togglePlayerESPBtn.Position = UDim2.new(0, 5, 0, 60)
togglePlayerESPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
togglePlayerESPBtn.TextColor3 = Color3.new(1, 1, 1)
togglePlayerESPBtn.Text = "Player ESP: OFF"
togglePlayerESPBtn.MouseButton1Click:Connect(function()
    PlayerESPEnabled = not PlayerESPEnabled
    togglePlayerESPBtn.Text = "Player ESP: " .. (PlayerESPEnabled and "ON" or "OFF")
end)

-- Rarity Toggles
local y = 90
for rarity in pairs(RarityColors) do
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -10, 0, 25)
    button.Position = UDim2.new(0, 5, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    button.MouseButton1Click:Connect(function()
        EnabledRarities[rarity] = not EnabledRarities[rarity]
        button.Text = rarity .. ": " .. (EnabledRarities[rarity] and "ON" or "OFF")
    end)
    y += 28
end

-- World ESP (Animals & Lucky Blocks)
local function highlightEntity(model, displayName, valueText, rarity)
    if not EnabledRarities[rarity] then return end
    
    local uniqueTag = "WorldESP_" .. model:GetDebugId()
    if worldESPFolder:FindFirstChild(uniqueTag) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = uniqueTag
    billboard.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    billboard.Size = UDim2.new(0, 200, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = worldESPFolder

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = RarityColors[rarity] or Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = displayName .. " | " .. valueText
    textLabel.Parent = billboard
end

-- Player ESP
local function highlightPlayer(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = char:FindFirstChild("HumanoidRootPart")

    local distanceText = ""
    if myHRP and targetHRP then
        distanceText = string.format(" | %dm", math.floor((myHRP.Position - targetHRP.Position).Magnitude))
    end

    local tag = "PlayerESP_" .. targetPlayer:GetDebugId()
    if playerESPFolder:FindFirstChild(tag) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = tag
    billboard.Adornee = char.HumanoidRootPart
    billboard.Size = UDim2.new(0, 200, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = playerESPFolder

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = targetPlayer.Name .. distanceText
    textLabel.Parent = billboard
end

-- Heartbeat Loop
RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    -- Animals
    for _, podium in ipairs(Workspace:GetDescendants()) do
        if podium.Name == "AnimalOverhead" then
            local rarityLabel = podium:FindFirstChild("Rarity")
            local genLabel = podium:FindFirstChild("Generation")
            local nameLabel = podium:FindFirstChild("DisplayName")
            local stolenLabel = podium:FindFirstChild("Stolen")

            if rarityLabel and nameLabel and genLabel then
                if AvoidInMachine and stolenLabel and stolenLabel.Text == "IN MACHINE" then
                    continue
                end
                highlightEntity(podium.Parent.Parent, nameLabel.Text, genLabel.Text, rarityLabel.Text)
            end
        end
    end

    -- Lucky Blocks
    for _, block in ipairs(Workspace:GetDescendants()) do
        for rarity, _ in pairs(RarityColors) do
            if string.find(block.Name, rarity .. " Lucky Block") then
                highlightEntity(block, block.Name, "$?", rarity) -- Uses rarity toggle & color
            end
        end
    end

    -- Player ESP
    if PlayerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            highlightPlayer(plr)
        end
    end
end)
