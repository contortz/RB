--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Animal data (for Lucky Blocks)
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

-- Enabled rarities
local EnabledRarities = {}
for rarity in pairs(RarityColors) do
    EnabledRarities[rarity] = (rarity == "Brainrot God" or rarity == "Secret")
end

-- Toggles
local AvoidInMachine = true
local PlayerESPEnabled = false
local MostExpensivePerBase = false

-- Price formatting
local function formatPrice(value)
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
frame.Size = UDim2.new(0, 200, 0, 375)
frame.Position = UDim2.new(0, 20, 0.5, -187)
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

-- Most Expensive Per Base Toggle
local toggleMostExpBaseBtn = Instance.new("TextButton", frame)
toggleMostExpBaseBtn.Size = UDim2.new(1, -10, 0, 25)
toggleMostExpBaseBtn.Position = UDim2.new(0, 5, 0, 90)
toggleMostExpBaseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleMostExpBaseBtn.TextColor3 = Color3.new(1, 1, 1)
toggleMostExpBaseBtn.Text = "Most Exp Per Base: OFF"
toggleMostExpBaseBtn.MouseButton1Click:Connect(function()
    MostExpensivePerBase = not MostExpensivePerBase
    toggleMostExpBaseBtn.Text = "Most Exp Per Base: " .. (MostExpensivePerBase and "ON" or "OFF")
end)

-- Rarity Toggles
local y = 120
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

-- Utility: Check "IN MACHINE"
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel and stolenLabel:IsA("TextLabel") and stolenLabel.Text == "IN MACHINE"
end

-- Billboard
local function createBillboard(adorn, color, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adorn
    billboard.Size = UDim2.new(0, 200, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = textLabel

    return billboard
end

-- Heartbeat
RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    if MostExpensivePerBase then
        -- For each base (Plot), find most expensive
        for _, plot in ipairs(Workspace:GetChildren()) do
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                local maxOverhead, maxGen = nil, -math.huge
                for _, podium in ipairs(podiums:GetDescendants()) do
                    if podium.Name == "AnimalOverhead" then
                        local rarityLabel = podium:FindFirstChild("Rarity")
                        local rarity = rarityLabel and rarityLabel.Text
                        if rarity and RarityColors[rarity] then
                            if AvoidInMachine and isInMachine(podium) then continue end
                            local gen = tonumber((podium:FindFirstChild("Generation") or {}).Text) or 0
                            if gen > maxGen then
                                maxGen, maxOverhead = gen, podium
                            end
                        end
                    end
                end
                if maxOverhead then
                    local rarity = maxOverhead.Rarity.Text
                    local displayName = maxOverhead.DisplayName.Text
                    local model = maxOverhead.Parent and maxOverhead.Parent.Parent
                    if model and model:IsA("BasePart") then
                        createBillboard(model, RarityColors[rarity], displayName .. " | " .. maxOverhead.Generation.Text).Parent = worldESPFolder
                    end
                end
            end
        end
    else
        -- Normal ESP (Animals + Lucky Blocks)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "AnimalOverhead" then
                local rarityLabel = obj:FindFirstChild("Rarity")
                local rarity = rarityLabel and rarityLabel.Text
                if rarity and RarityColors[rarity] and EnabledRarities[rarity] then
                    if AvoidInMachine and isInMachine(obj) then continue end
                    local displayName = obj:FindFirstChild("DisplayName")
                    local generation = obj:FindFirstChild("Generation")
                    local model = obj.Parent and obj.Parent.Parent
                    if model and model:IsA("BasePart") then
                        createBillboard(model, RarityColors[rarity], displayName.Text .. " | " .. generation.Text).Parent = worldESPFolder
                    end
                end
            elseif obj.Name:find("Lucky Block") then
                for r in pairs(RarityColors) do
                    if obj.Name:find(r) and EnabledRarities[r] then
                        local data = AnimalsData[obj.Name]
                        local price = data and data.Price or 0
                        if obj.PrimaryPart then
                            createBillboard(obj.PrimaryPart, RarityColors[r], obj.Name .. " | $" .. formatPrice(price)).Parent = worldESPFolder
                        end
                    end
                end
            end
        end
    end

    -- Player ESP
    if PlayerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                createBillboard(plr.Character.HumanoidRootPart, Color3.fromRGB(0,255,255), plr.Name .. " | " .. math.floor(dist) .. "m").Parent = playerESPFolder
            end
        end
    end
end)
