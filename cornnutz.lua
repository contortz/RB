--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Animal data
local AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

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

-- Enabled rarities (default Brainrot God & Secret ON)
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Avoid In Machine toggle
local AvoidInMachine = true

-- Player ESP toggle
local PlayerESPEnabled = false

-- Format number (K/M/B)
local function formatValue(value)
    if value >= 1e9 then
        return string.format("%.1fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.1fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fK", value / 1e3)
    else
        return tostring(value)
    end
end

-- ESP folders
local uiESPFolder = Instance.new("Folder", CoreGui)
uiESPFolder.Name = "UIRarityESP"

local worldESPFolder = Instance.new("Folder", CoreGui)
worldESPFolder.Name = "WorldRarityESP"

local playerESPFolder = Instance.new("Folder", CoreGui)
playerESPFolder.Name = "PlayerESPFolder"

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RarityESPUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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

-- Avoid in Machine toggle
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

-- Player ESP toggle
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

-- Rarity toggles
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

-- UI Highlight with Text
local function highlightViewportFrame(vpf, rarity, name, generation, inMachine)
    if not EnabledRarities[rarity] then return end
    if AvoidInMachine and inMachine then return end

    local stroke = vpf:FindFirstChild("Highlight")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "Highlight"
        stroke.Thickness = 3
        stroke.Transparency = 0
        stroke.Color = RarityColors[rarity]
        stroke.Parent = vpf
    else
        stroke.Color = RarityColors[rarity]
    end

    local label = vpf:FindFirstChild("ESPLabel")
    if not label then
        label = Instance.new("TextLabel")
        label.Name = "ESPLabel"
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, -0.3, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = vpf
    end
    label.TextColor3 = RarityColors[rarity]
    label.Text = name .. " | $" .. formatValue(generation) .. "/s"
end

-- Workspace Highlight
local function highlightWorldModel(model, rarity, name, generation, inMachine)
    if not EnabledRarities[rarity] then return end
    if AvoidInMachine and inMachine then return end
    if not model:IsA("Model") or not model.PrimaryPart then return end

    local tag = "WorldESP_" .. model:GetDebugId()
    if worldESPFolder:FindFirstChild(tag) then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = tag
    box.Adornee = model.PrimaryPart
    box.Size = model:GetExtentsSize()
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = RarityColors[rarity]
    box.Transparency = 0.5
    box.Parent = worldESPFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = tag .. "_Label"
    billboard.Adornee = model.PrimaryPart
    billboard.Size = UDim2.new(0, 200, 0, 20)
    billboard.StudsOffset = Vector3.new(0, model:GetExtentsSize().Y + 1, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = worldESPFolder

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = RarityColors[rarity]
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = name .. " | $" .. formatValue(generation) .. "/s"
    textLabel.Parent = billboard
end

-- Player ESP (Name + Distance in Yellow)
local function highlightPlayer(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = char:FindFirstChild("HumanoidRootPart")

    local distanceText = ""
    if myHRP and targetHRP then
        local dist = (myHRP.Position - targetHRP.Position).Magnitude
        distanceText = string.format(" | %dm", math.floor(dist))
    end

    local tag = "PlayerESP_" .. targetPlayer.Name
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
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cyan name
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = targetPlayer.Name
    textLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 1, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow distance
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.GothamBold
    distLabel.Text = distanceText
    distLabel.Position = UDim2.new(0, 0, 1, 0) -- Below name
    distLabel.Parent = billboard
end

-- Heartbeat
RunService.Heartbeat:Connect(function()
    uiESPFolder:ClearAllChildren()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    -- FuseMachine + Index ViewportFrames
    for _, uiRoot in ipairs({playerGui:FindFirstChild("FuseMachine"), playerGui:FindFirstChild("Index")}) do
        if uiRoot then
            for _, vpf in ipairs(uiRoot:GetDescendants()) do
                if vpf:IsA("ViewportFrame") and vpf:FindFirstChild("WorldModel") then
                    local model = vpf.WorldModel:FindFirstChildWhichIsA("Model")
                    if model then
                        local data = AnimalsData[model.Name]
                        if data and data.Rarity then
                            local inMachine = (uiRoot.Name == "FuseMachine")
                            highlightViewportFrame(vpf, data.Rarity, model.Name, data.Generation, inMachine)
                        end
                    end
                end
            end
        end
    end

    -- World animals
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model.PrimaryPart then
            local data = AnimalsData[model.Name]
            if data and data.Rarity then
                highlightWorldModel(model, data.Rarity, model.Name, data.Generation, false)
            end
        end
    end

    -- Players
    if PlayerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            highlightPlayer(plr)
        end
    end
end)
