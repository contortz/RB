--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- UI (same as before, unchanged) ...

-- In Machine check (case-insensitive)
local function isInMachine(overhead)
    local stolenLabel = overhead:FindFirstChild("Stolen")
    return stolenLabel 
        and stolenLabel:IsA("TextLabel") 
        and string.find(string.lower(stolenLabel.Text), "in machine")
end

-- Animal ESP
local function highlightAnimalOverhead(overhead, rarity)
    if not EnabledRarities[rarity] then return end
    if AvoidInMachine and isInMachine(overhead) then return end
    
    local displayName = overhead:FindFirstChild("DisplayName")
    local generation = overhead:FindFirstChild("Generation")
    if displayName and generation then
        local model = overhead.Parent and overhead.Parent.Parent
        if model and model:IsA("BasePart") then
            local primary = model
            local tag = "WorldESP_" .. model:GetDebugId() -- ✅ Unique ID
            if worldESPFolder:FindFirstChild(tag) then return end

            local billboard = Instance.new("BillboardGui")
            billboard.Name = tag
            billboard.Adornee = primary
            billboard.Size = UDim2.new(0, 200, 0, 20)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = worldESPFolder

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = RarityColors[rarity]
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Text = displayName.Text .. " | " .. generation.Text
            textLabel.Parent = billboard
        end
    end
end

-- Lucky Block ESP
local function highlightLuckyBlock(blockModel, rarity)
    if not EnabledRarities[rarity] then return end
    local data = AnimalsData[blockModel.Name]
    if not data then return end
    
    local primary = blockModel.PrimaryPart or blockModel:FindFirstChildWhichIsA("BasePart") -- ✅ Fallback
    if primary then
        local tag = "LuckyBlockESP_" .. blockModel:GetDebugId() -- ✅ Unique ID
        if worldESPFolder:FindFirstChild(tag) then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = tag
        billboard.Adornee = primary
        billboard.Size = UDim2.new(0, 200, 0, 20)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = worldESPFolder

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = RarityColors[rarity]
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Text = blockModel.Name .. " | $" .. tostring(data.Price)
        textLabel.Parent = billboard
    end
end

-- Player ESP (unchanged) ...

-- Heartbeat
RunService.Heartbeat:Connect(function()
    worldESPFolder:ClearAllChildren()
    playerESPFolder:ClearAllChildren()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "AnimalOverhead" then
            local rarityLabel = obj:FindFirstChild("Rarity")
            local rarity = rarityLabel and rarityLabel.Text
            if rarity and RarityColors[rarity] then
                highlightAnimalOverhead(obj, rarity)
            end
        elseif obj.Name:find("Lucky Block") then
            for r in pairs(RarityColors) do
                if obj.Name:find(r) then
                    highlightLuckyBlock(obj, r)
                    break
                end
            end
        end
    end

    if PlayerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            highlightPlayer(plr)
        end
    end
end)
