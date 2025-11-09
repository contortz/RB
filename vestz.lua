--// Dreamz ESP + TP + Godmode + Map Teleport Dropdown
--// + BabyShroom Nuker (GUID aware)
--// + CTRL Auto
--// + Auto Hunter (Target + Priority override, behind target, auto F)
--// + Spam Abilities (3-9)
--// + Auto Item Pickup
--// + Auto Sell (Whitelist)
--// + Teleport to Coords (XYZ or CFrame)
--// + Map Teleport from teleporter bricks in workspace.persistentModel

------------------------ Services ------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

------------------------ Folders ------------------------

local placeFolders = workspace:WaitForChild("placeFolders", 5)
local entityManifestCollection = placeFolders and placeFolders:WaitForChild("entityManifestCollection", 5)
local itemsFolder = placeFolders and placeFolders:WaitForChild("items", 5)

------------------------ VirtualInputManager ------------------------

local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

------------------------ Modules (for Auto Sell, Network) ------------------------

local Modules = ReplicatedStorage:FindFirstChild("modules")
local Network, ItemData

if Modules then
    pcall(function()
        Network = require(Modules:WaitForChild("network"))
    end)
    pcall(function()
        ItemData = require(ReplicatedStorage:WaitForChild("itemData"))
    end)
end

------------------------ State ------------------------

local playerESPEnabled = false
local monsterESPEnabled = false
local espUpdateConnection

local godmodeEnabled = false
local healthConn
local gmMaxHealth

-- Shroom nuker
local autoAttackEnabled = false
local autoAttackInterval = 1.0
local autoAttackCoroutine = nil

-- CTRL auto-hold
local ctrlAutoEnabled = false
local ctrlAttackCoroutine = nil

-- Auto Hunter
local autoHunterEnabled = false
local autoHunterCoroutine = nil
local autoHunterTarget = ""          -- normal filter (e.g. "crow")
local priorityTargets = {}           -- priority substrings (e.g. { "rootbeard", "elder shroom" })

-- Spam Abilities
local spamAbilitiesEnabled = false
local spamAbilitiesCoroutine = nil

-- Auto Item Pickup
local autoItemPickupEnabled = false
local autoItemPickupCoroutine = nil

-- Auto Sell
local autoSellEnabled = false
local autoSellCoroutine = nil

------------------------ Small Helpers ------------------------

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function pressKeyOnce(keyCode)
    if not VirtualInputManager then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function holdKey(keyCode, state)
    if not VirtualInputManager then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(state, keyCode, false, game)
    end)
end

local function pressCtrlOnce()
    pressKeyOnce(Enum.KeyCode.LeftControl)
end

local function setPriorityTargetsFromString(str)
    priorityTargets = {}
    if not str then return end
    for part in string.gmatch(str, "([^,]+)") do
        local t = trim(part)
        if t ~= "" then
            table.insert(priorityTargets, string.lower(t))
        end
    end
end

------------------------ Local Hitbox / Entities ------------------------

local function getLocalModel()
    if not entityManifestCollection then return nil end
    return entityManifestCollection:FindFirstChild(LocalPlayer.Name)
end

local function getLocalHitbox()
    local model = getLocalModel()
    if not model then return nil end

    if model:IsA("BasePart") and model.Name == "hitbox" then
        return model
    end

    local hitbox = model:FindFirstChild("hitbox")
    if hitbox and hitbox:IsA("BasePart") then
        return hitbox
    end

    for _, obj in ipairs(model:GetChildren()) do
        if obj:IsA("BasePart") then
            return obj
        end
    end

    return nil
end

-- Generic hitbox resolver
local function getHitboxFromEntity(entity)
    if not entity then return nil end

    if entity:IsA("BasePart") then
        return entity
    end

    local hrp = entity:FindFirstChild("HumanoidRootPart", true)
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end

    local hb = entity:FindFirstChild("hitbox", true)
    if hb and hb:IsA("BasePart") then
        return hb
    end

    for _, obj in ipairs(entity:GetDescendants()) do
        if obj:IsA("BasePart") then
            return obj
        end
    end

    return nil
end

------------------------ Health Helpers / Godmode ------------------------

local function getHealthObjectForLocal()
    local model = getLocalModel()
    if not model then return nil end

    local hv = model:FindFirstChild("health")
    if hv and hv:IsA("NumberValue") then
        return hv
    end

    local hb = model:FindFirstChild("hitbox")
    if hb then
        local hv2 = hb:FindFirstChild("health")
        if hv2 and hv2:IsA("NumberValue") then
            return hv2
        end
    end

    local containers = {
        model:FindFirstChild("Attributes"),
        model:FindFirstChild("Stats"),
        hb and hb:FindFirstChild("Attributes") or nil,
        hb and hb:FindFirstChild("Stats") or nil,
    }

    for _, c in ipairs(containers) do
        if c then
            local hv3 = c:FindFirstChild("health")
            if hv3 and hv3:IsA("NumberValue") then
                return hv3
            end
        end
    end

    for _, obj in ipairs(model:GetDescendants()) do
        if obj.Name == "health" and obj:IsA("NumberValue") then
            return obj
        end
    end

    return nil
end

local function getHealthFrom(entityOrHitbox)
    if not entityOrHitbox then return nil end

    local hv = entityOrHitbox:FindFirstChild("health")
    if hv and hv:IsA("NumberValue") then
        return hv.Value
    end

    local attrs = entityOrHitbox:FindFirstChild("Attributes") or entityOrHitbox:FindFirstChild("Stats")
    if attrs then
        local hv2 = attrs:FindFirstChild("health")
        if hv2 and hv2:IsA("NumberValue") then
            return hv2.Value
        end
    end

    return nil
end

local function enableGodmode()
    if healthConn then
        healthConn:Disconnect()
        healthConn = nil
    end

    local hv = getHealthObjectForLocal()
    if not hv then
        warn("[Dreamz] Godmode: couldn't find health NumberValue.")
        return
    end

    gmMaxHealth = hv.Value > 0 and hv.Value or 100
    hv.Value = gmMaxHealth

    healthConn = hv.Changed:Connect(function(new)
        if godmodeEnabled and new < gmMaxHealth then
            hv.Value = gmMaxHealth
        end
    end)
end

local function disableGodmode()
    if healthConn then
        healthConn:Disconnect()
        healthConn = nil
    end
    gmMaxHealth = nil
end

------------------------ Monster Check ------------------------

local function isMonster(entity)
    if not entity then return false end

    local attrType = entity:GetAttribute("entityType")
    if attrType == "monster" then
        return true
    end

    local attrs = entity:FindFirstChild("Attributes")
    if attrs then
        local et = attrs:FindFirstChild("entityType")
        if et and tostring(et.Value) == "monster" then
            return true
        end
    end

    return false
end

------------------------ ESP ------------------------

local function createBillboard(parent)
    if not parent or not parent:IsA("BasePart") then return nil end

    local existing = parent:FindFirstChild("Dreamz_ESP")
    if existing then
        return existing
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Dreamz_ESP"
    billboard.Adornee = parent
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1500

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = billboard

    billboard.Parent = parent
    return billboard
end

local function clearAllESP()
    if not entityManifestCollection then return end
    for _, entity in ipairs(entityManifestCollection:GetChildren()) do
        local hb = getHitboxFromEntity(entity)
        if hb then
            local esp = hb:FindFirstChild("Dreamz_ESP")
            if esp then
                esp:Destroy()
            end
        end
    end
end

local function updateESP()
    if not entityManifestCollection then return end

    if (not playerESPEnabled) and (not monsterESPEnabled) then
        clearAllESP()
        return
    end

    local used = {}

    if playerESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local entity = entityManifestCollection:FindFirstChild(plr.Name)
                if entity then
                    local hb = getHitboxFromEntity(entity)
                    if hb then
                        local hp = getHealthFrom(hb) or getHealthFrom(entity)
                        local esp = createBillboard(hb)
                        local label = esp and esp:FindFirstChild("Label")
                        if label then
                            label.Text = string.format("%s | HP: %s", plr.Name, hp and tostring(hp) or "?")
                        end
                        used[hb] = true
                    end
                end
            end
        end
    end

    if monsterESPEnabled then
        for _, entity in ipairs(entityManifestCollection:GetChildren()) do
            if isMonster(entity) then
                local hb = getHitboxFromEntity(entity)
                if hb then
                    local hp = getHealthFrom(hb) or getHealthFrom(entity)
                    local esp = createBillboard(hb)
                    local label = esp and esp:FindFirstChild("Label")
                    if label then
                        label.Text = string.format("%s | HP: %s", entity.Name, hp and tostring(hp) or "?")
                    end
                    used[hb] = true
                end
            end
        end
    end

    for _, entity in ipairs(entityManifestCollection:GetChildren()) do
        local hb = getHitboxFromEntity(entity)
        if hb then
            local esp = hb:FindFirstChild("Dreamz_ESP")
            if esp and not used[hb] then
                esp:Destroy()
            end
        end
    end
end

local function startESPUpdater()
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    espUpdateConnection = RunService.RenderStepped:Connect(updateESP)
end

startESPUpdater()

------------------------ Baby Shroom Nuker (GUID aware) ------------------------

local batchRemote, basicAttackEvent = nil, nil

do
    local ok, networkFolder = pcall(function()
        return ReplicatedStorage:WaitForChild("network", 2)
    end)

    if ok and networkFolder then
        local reFolder = networkFolder:FindFirstChild("RemoteEvent")
        if reFolder then
            batchRemote = reFolder:FindFirstChild("playerRequest_damageEntity_batch")
            basicAttackEvent = reFolder:FindFirstChild("fireEvent")
        end
    end
end

local function sendBasicAttackEvent()
    if basicAttackEvent then
        pcall(function()
            basicAttackEvent:FireServer("playerWillUseBasicAttack", LocalPlayer)
        end)
    end
end

local function getGuidForEntity(entity)
    if not entity then return nil end

    local attrGuid = entity:GetAttribute("guid")
    if typeof(attrGuid) == "string" and #attrGuid > 0 then
        return attrGuid
    end

    local guidValue = entity:FindFirstChild("guid")
    if guidValue and guidValue:IsA("StringValue") and #guidValue.Value > 0 then
        return guidValue.Value
    end

    return nil
end

local function collectBabyShrooms()
    local out = {}
    if not entityManifestCollection then return out end
    for _, ent in ipairs(entityManifestCollection:GetChildren()) do
        if tostring(ent.Name):find("Baby Shroom") then
            table.insert(out, ent)
        end
    end
    return out
end

local function buildEntryForEntity(entity)
    local hb = getHitboxFromEntity(entity)
    local pos

    if hb and hb:IsA("BasePart") then
        pos = hb.Position
    elseif entity:IsA("BasePart") then
        pos = entity.Position
    elseif entity.PrimaryPart then
        pos = entity.PrimaryPart.Position
    else
        for _, c in ipairs(entity:GetChildren()) do
            if c:IsA("BasePart") then
                pos = c.Position
                break
            end
        end
    end

    if not pos then return nil end

    local guid = getGuidForEntity(entity)
    if not guid then return nil end

    return { entity, pos, "equipment", "none", nil, guid }
end

local function fireEntry(entry)
    if not batchRemote or not entry then return end
    pcall(function()
        batchRemote:FireServer({ entry })
    end)
end

local function attackAllBabyShroomsOnce()
    local shrooms = collectBabyShrooms()
    if #shrooms == 0 then return end

    for _, ent in ipairs(shrooms) do
        local entry = buildEntryForEntity(ent)
        if entry then
            sendBasicAttackEvent()
            fireEntry(entry)
        end
    end
end

local function startAutoAttackLoop()
    if autoAttackCoroutine or autoAttackEnabled == true then return end
    autoAttackEnabled = true
    autoAttackCoroutine = coroutine.create(function()
        while autoAttackEnabled do
            attackAllBabyShroomsOnce()
            local startTime = tick()
            while autoAttackEnabled and (tick() - startTime) < autoAttackInterval do
                task.wait(0.05)
            end
        end
        autoAttackCoroutine = nil
    end)
    coroutine.resume(autoAttackCoroutine)
end

local function stopAutoAttackLoop()
    autoAttackEnabled = false
end

------------------------ CTRL Auto Attack (hold ctrl) ------------------------

local function startCtrlAutoAttack()
    if ctrlAttackCoroutine or ctrlAutoEnabled then return end
    if not VirtualInputManager then
        warn("[Dreamz] CTRL Auto: no VirtualInputManager.")
        return
    end

    ctrlAutoEnabled = true

    ctrlAttackCoroutine = coroutine.create(function()
        holdKey(Enum.KeyCode.LeftControl, true)
        while ctrlAutoEnabled do
            task.wait(0.10)
        end
        holdKey(Enum.KeyCode.LeftControl, false)
        ctrlAttackCoroutine = nil
    end)

    coroutine.resume(ctrlAttackCoroutine)
end

local function stopCtrlAutoAttack()
    ctrlAutoEnabled = false
end

------------------------ Spam Abilities (3-9) ------------------------

local function startSpamAbilities()
    if spamAbilitiesCoroutine or spamAbilitiesEnabled then return end
    if not VirtualInputManager then
        warn("[Dreamz] Spam Abilities: no VirtualInputManager.")
        return
    end

    spamAbilitiesEnabled = true

    spamAbilitiesCoroutine = coroutine.create(function()
        local keys = {
            Enum.KeyCode.Three,
            Enum.KeyCode.Four,
            Enum.KeyCode.Five,
            Enum.KeyCode.Six,
            Enum.KeyCode.Seven,
            Enum.KeyCode.Eight,
            Enum.KeyCode.Nine,
        }
        while spamAbilitiesEnabled do
            for _, key in ipairs(keys) do
                if not spamAbilitiesEnabled then break end
                pressKeyOnce(key)
                task.wait(0.15)
            end
        end
        spamAbilitiesCoroutine = nil
    end)

    coroutine.resume(spamAbilitiesCoroutine)
end

local function stopSpamAbilities()
    spamAbilitiesEnabled = false
end

------------------------ Auto Item Pickup ------------------------

local function getItemBasePart(obj)
    if obj:IsA("BasePart") then
        return obj
    end
    if obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart
    end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

local function startAutoItemPickupLoop()
    if autoItemPickupCoroutine or not autoItemPickupEnabled then return end
    if not itemsFolder then
        warn("[Dreamz] Auto Item Pickup: items folder missing.")
        return
    end

    autoItemPickupCoroutine = coroutine.create(function()
        while autoItemPickupEnabled do
            local myHB = getLocalHitbox()
            if myHB then
                holdKey(Enum.KeyCode.F, true)
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if not autoItemPickupEnabled then break end
                    local bp = getItemBasePart(item)
                    if bp then
                        myHB.CFrame = bp.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.05)
                    end
                end
                holdKey(Enum.KeyCode.F, false)
            end
            task.wait(0.1)
        end
        autoItemPickupCoroutine = nil
        holdKey(Enum.KeyCode.F, false)
    end)

    coroutine.resume(autoItemPickupCoroutine)
end

local function stopAutoItemPickupLoop()
    autoItemPickupEnabled = false
end

------------------------ Auto Hunter (with Priority) ------------------------

local function teleportBehindTargetHB(targetHB)
    local myHitbox = getLocalHitbox()
    if not myHitbox or not targetHB then return end

    local backOffset = -targetHB.CFrame.LookVector * 4
    local pos = targetHB.Position + backOffset + Vector3.new(0, 2, 0)
    myHitbox.CFrame = CFrame.new(pos, targetHB.Position)
end

local function getNearestAliveMonster(filterName)
    if not entityManifestCollection then return nil end

    local myHB = getLocalHitbox()
    if not myHB then return nil end

    local filter = (filterName and filterName ~= "") and string.lower(filterName) or nil

    -- 1) Priority targets first (in order)
    if #priorityTargets > 0 then
        for _, prioSub in ipairs(priorityTargets) do
            local bestEnt, bestDist
            for _, ent in ipairs(entityManifestCollection:GetChildren()) do
                if isMonster(ent) then
                    local nameLower = string.lower(ent.Name)
                    if string.find(nameLower, prioSub, 1, true) then
                        local hb = getHitboxFromEntity(ent)
                        if hb then
                            local hp = getHealthFrom(hb) or getHealthFrom(ent)
                            if hp and hp > 0 then
                                local dist = (hb.Position - myHB.Position).Magnitude
                                if not bestEnt or dist < bestDist then
                                    bestEnt, bestDist = ent, dist
                                end
                            end
                        end
                    end
                end
            end
            if bestEnt then
                return bestEnt
            end
        end
    end

    -- 2) Fallback: normal filter
    local bestEnt, bestDist
    for _, ent in ipairs(entityManifestCollection:GetChildren()) do
        if isMonster(ent) then
            local nameLower = string.lower(ent.Name)
            if (not filter) or string.find(nameLower, filter, 1, true) then
                local hb = getHitboxFromEntity(ent)
                if hb then
                    local hp = getHealthFrom(hb) or getHealthFrom(ent)
                    if hp and hp > 0 then
                        local dist = (hb.Position - myHB.Position).Magnitude
                        if not bestEnt or dist < bestDist then
                            bestEnt, bestDist = ent, dist
                        end
                    end
                end
            end
        end
    end

    return bestEnt
end

local function startAutoHunter()
    if autoHunterCoroutine or autoHunterEnabled then return end
    if not VirtualInputManager then
        warn("[Dreamz] Auto Hunter: no VirtualInputManager.")
        return
    end

    autoHunterEnabled = true
    stopCtrlAutoAttack()
    stopAutoAttackLoop()

    autoHunterCoroutine = coroutine.create(function()
        while autoHunterEnabled do
            local target = getNearestAliveMonster(autoHunterTarget)
            if not target then
                holdKey(Enum.KeyCode.F, false)
                task.wait(0.3)
            else
                while autoHunterEnabled do
                    local hb = getHitboxFromEntity(target)
                    if not hb then break end

                    local hp = getHealthFrom(hb) or getHealthFrom(target)
                    if not hp or hp <= 0 then
                        break
                    end

                    teleportBehindTargetHB(hb)
                    pressCtrlOnce()
                    holdKey(Enum.KeyCode.F, true)
                    task.wait(0.12)
                end
                holdKey(Enum.KeyCode.F, false)
            end
        end

        holdKey(Enum.KeyCode.F, false)
        autoHunterCoroutine = nil
    end)

    coroutine.resume(autoHunterCoroutine)
end

local function stopAutoHunter()
    autoHunterEnabled = false
end

------------------------ Auto Sell (Whitelist) ------------------------

local autoSellWhitelist = {
    ["ram skull mask"] = true,
    ["hay"] = true,
    ["crabby claw"] = true,
    ["leather"] = true,
    ["cow bell"] = true,
    ["raw steak"] = true,
    ["elder beard"] = true,
    ["boar meat"] = true,
    ["mushroom spore"] = true,
    ["red mushroom"] = true,
    ["guardian core"] = true,
    ["feather"] = true,
    ["arrow"] = true,
    ["apple"] = true,
    ["crow feather"] = true,
    ["dusty hat"] = true,
    ["magus hat"] = true,
    ["hoblino ear"] = true,
    ["hobgoblin ear"] = true,
    ["armoured goblin ear"] = true,
    ["dull tomahawk"] = true,
    ["dull corvus bow"] = true,
    ["dull wooden club"] = true,
    ["city guard pads"] = true,
    ["bronze helmet"] = true,
    ["lapis staff"] = true,
    ["ancient staff"] = true,
    ["dull lapis staff"] = true,
    ["swift lapis staff"] = true,
    ["dull bronze sword"] = true,
    ["plated iron helmet"] = true,
    ["iron armor"] = true,
    ["tattered iron armor"] = true,
    ["keen iron armor"] = true,
    ["lumberjack hatchet"] = true,
    ["spider fang"] = true,
    ["bear head"] = true,
    ["bear hide"] = true,
    ["bear paw"] = true,
    ["ram horn"] = true,
    ["ram hoof"] = true,
    ["ram hide"] = true,
    ["yeti fur"] = true,
    ["yeti antler"] = true,
}

local function shouldAutoSell(name)
    if not name then return false end
    local n = string.lower(name)
    for sub in pairs(autoSellWhitelist) do
        if string.find(n, sub, 1, true) then
            return true
        end
    end
    return false
end

local function runAutoSellOnce()
    if not Network or not ItemData then
        return
    end

    local inv = Network:invoke("getCacheValueByNameTag", "inventory") or {}
    if type(inv) ~= "table" then
        return
    end

    local entries = {}

    for _, raw in pairs(inv) do
        local data = ItemData(raw)
        if type(data) == "table" then
            local name   = data.name or data.itemName or raw.name or raw.itemName
            local serial = data.serial or raw.serial
            local stacks = data.stacks or raw.stacks or 1

            if serial and name and shouldAutoSell(name) then
                if not data.cantSell and not data.inventorybound and not data.questbound and not data.soulbound then
                    table.insert(entries, {
                        serial = serial,
                        stacks = stacks
                    })
                end
            end
        end
    end

    if #entries == 0 then
        return
    end

    table.sort(entries, function(a, b)
        return (a.stacks or 0) > (b.stacks or 0)
    end)

    local first = entries[1]
    local ok, res = pcall(function()
        return Network:invokeServer("playerRequest_sellItemsToShop", { first })
    end)

    if not ok then
        warn("[Dreamz AutoSell] Sell failed:", res)
    end
end

local function startAutoSell()
    if autoSellCoroutine or autoSellEnabled then return end
    if not Network or not ItemData then
        warn("[Dreamz AutoSell] Cannot start (missing modules).")
        return
    end

    autoSellEnabled = true

    autoSellCoroutine = coroutine.create(function()
        while autoSellEnabled do
            runAutoSellOnce()
            for _ = 1, 5 do
                if not autoSellEnabled then break end
                task.wait(1)
            end
        end
        autoSellCoroutine = nil
    end)

    coroutine.resume(autoSellCoroutine)
end

local function stopAutoSell()
    autoSellEnabled = false
end

------------------------ TP Direct Helpers ------------------------

local function findEntityByNameLoose(query)
    if not entityManifestCollection then return nil end
    if not query or query == "" then return nil end
    query = string.lower(query)

    for _, child in ipairs(entityManifestCollection:GetChildren()) do
        if string.lower(child.Name) == query then
            return child
        end
    end

    for _, inst in ipairs(entityManifestCollection:GetDescendants()) do
        if inst:IsA("Model") and string.lower(inst.Name) == query then
            return inst
        end
    end

    local best, bestLen
    for _, inst in ipairs(entityManifestCollection:GetDescendants()) do
        if inst:IsA("Model") then
            local n = string.lower(inst.Name)
            if string.find(n, query, 1, true) then
                local len = #n
                if not best or len < bestLen then
                    best, bestLen = inst, len
                end
            end
        end
    end

    return best
end

local function teleportToEntityByName(name)
    if not name or name == "" then return end

    local myHitbox = getLocalHitbox()
    if not myHitbox then
        warn("[Dreamz TP] No local hitbox found.")
        return
    end

    local target = findEntityByNameLoose(name)
    if not target then
        warn("[Dreamz TP] No entity matched '" .. tostring(name) .. "'.")
        return
    end

    local targetHB = getHitboxFromEntity(target)
    if not targetHB then
        warn("[Dreamz TP] Target '" .. target.Name .. "' has no valid hitbox/HRP.")
        return
    end

    myHitbox.CFrame = targetHB.CFrame + Vector3.new(0, 5, 0)
end

local function teleportToCoords(x, y, z)
    local myHitbox = getLocalHitbox()
    if not myHitbox then
        warn("[Dreamz TP] No local hitbox found.")
        return
    end
    if not (x and y and z) then
        warn("[Dreamz TP] Invalid coordinates.")
        return
    end
    myHitbox.CFrame = CFrame.new(x, y, z)
end

------------------------ MAP TELEPORT (persistentModel) ------------------------

local TeleportEntries = {}   -- { {name=..., brick=BasePart, id=...}, ... }
local NameCounts = {}
local lastMapTP = 0

local function getDisplayNameFromId(id)
    if not id or id <= 0 then
        return nil
    end
    local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id)
    if ok and info and typeof(info) == "table" and info.Name and info.Name ~= "" then
        return info.Name
    end
    return nil
end

local function makeUniqueName(base)
    if not NameCounts[base] then
        NameCounts[base] = 1
        return base
    else
        NameCounts[base] += 1
        return string.format("%s (%d)", base, NameCounts[base])
    end
end

do
    local persistentModel = workspace:FindFirstChild("persistentModel")
    if persistentModel then
        for _, obj in ipairs(persistentModel:GetDescendants()) do
            if obj:IsA("IntValue") and (obj.Name == "teleportDesination" or obj.Name == "teleportDestination") then
                local brick = obj.Parent
                if brick and brick:IsA("BasePart") then
                    local id = obj.Value
                    local baseName = getDisplayNameFromId(id)

                    if not baseName or baseName == "" then
                        if brick.Parent and brick.Parent.Name ~= "" then
                            baseName = brick.Parent.Name
                        elseif brick.Name and brick.Name ~= "" then
                            baseName = brick.Name
                        else
                            baseName = "Destination " .. tostring(id)
                        end
                    end

                    local finalName = makeUniqueName(baseName)

                    table.insert(TeleportEntries, {
                        name = finalName,
                        brick = brick,
                        id = id,
                    })
                end
            end
        end
    end

    table.sort(TeleportEntries, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    print(("[Dreamz MapTP] Loaded %d teleports from persistentModel."):format(#TeleportEntries))
end

local function teleportToMapEntry(entry)
    if not entry or not entry.brick or not entry.brick.Parent then
        warn("[Dreamz MapTP] Invalid entry/brick.")
        return
    end

    local myHB = getLocalHitbox()
    if not myHB then
        warn("[Dreamz MapTP] No local hitbox found.")
        return
    end

    if tick() - lastMapTP < 0.25 then
        return
    end
    lastMapTP = tick()

    local offset = Vector3.new(0, 4, 0)
    myHB.CFrame = entry.brick.CFrame + offset
end

------------------------ GUI ------------------------

local function createUI()
    local old = CoreGui:FindFirstChild("Dreamz_ESP_TP_GUI")
    if old then
        old:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Dreamz_ESP_TP_GUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 520)
    frame.Position = UDim2.new(0, 50, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Text = "Dreamz ESP + TP + GM + Shroom"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame

    -- Player ESP
    local playerESPBtn = Instance.new("TextButton")
    playerESPBtn.Size = UDim2.new(0, 120, 0, 26)
    playerESPBtn.Position = UDim2.new(0, 10, 0, 30)
    playerESPBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    playerESPBtn.TextColor3 = Color3.new(1, 1, 1)
    playerESPBtn.Font = Enum.Font.SourceSansBold
    playerESPBtn.TextSize = 14
    playerESPBtn.Text = "Player ESP: OFF"
    playerESPBtn.Parent = frame
    playerESPBtn.MouseButton1Click:Connect(function()
        playerESPEnabled = not playerESPEnabled
        playerESPBtn.Text = "Player ESP: " .. (playerESPEnabled and "ON" or "OFF")
    end)

    -- Monster ESP
    local monsterESPBtn = Instance.new("TextButton")
    monsterESPBtn.Size = UDim2.new(0, 120, 0, 26)
    monsterESPBtn.Position = UDim2.new(0, 150, 0, 30)
    monsterESPBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    monsterESPBtn.TextColor3 = Color3.new(1, 1, 1)
    monsterESPBtn.Font = Enum.Font.SourceSansBold
    monsterESPBtn.TextSize = 14
    monsterESPBtn.Text = "Mob ESP: OFF"
    monsterESPBtn.Parent = frame
    monsterESPBtn.MouseButton1Click:Connect(function()
        monsterESPEnabled = not monsterESPEnabled
        monsterESPBtn.Text = "Mob ESP: " .. (monsterESPEnabled and "ON" or "OFF")
    end)

    -- Godmode
    local gmBtn = Instance.new("TextButton")
    gmBtn.Size = UDim2.new(0, 120, 0, 26)
    gmBtn.Position = UDim2.new(0, 10, 0, 60)
    gmBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
    gmBtn.TextColor3 = Color3.new(1, 1, 1)
    gmBtn.Font = Enum.Font.SourceSansBold
    gmBtn.TextSize = 14
    gmBtn.Text = "Godmode: OFF"
    gmBtn.Parent = frame
    gmBtn.MouseButton1Click:Connect(function()
        godmodeEnabled = not godmodeEnabled
        gmBtn.Text = "Godmode: " .. (godmodeEnabled and "ON" or "OFF")
        if godmodeEnabled then enableGodmode() else disableGodmode() end
    end)

    -- CTRL Auto Attack
    local ctrlAttackBtn = Instance.new("TextButton")
    ctrlAttackBtn.Size = UDim2.new(0, 120, 0, 26)
    ctrlAttackBtn.Position = UDim2.new(0, 150, 0, 60)
    ctrlAttackBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    ctrlAttackBtn.TextColor3 = Color3.new(1, 1, 1)
    ctrlAttackBtn.Font = Enum.Font.SourceSans
    ctrlAttackBtn.TextSize = 12
    ctrlAttackBtn.Text = "CTRL Auto: OFF"
    ctrlAttackBtn.Parent = frame
    ctrlAttackBtn.MouseButton1Click:Connect(function()
        if autoHunterEnabled then
            warn("[Dreamz] Disable Auto Hunter before CTRL Auto.")
            return
        end
        if not ctrlAutoEnabled then
            ctrlAttackBtn.Text = "CTRL Auto: ON"
            startCtrlAutoAttack()
        else
            ctrlAttackBtn.Text = "CTRL Auto: OFF"
            stopCtrlAutoAttack()
        end
    end)

    -- Shroom Nuker Manual
    local attackBtn = Instance.new("TextButton")
    attackBtn.Size = UDim2.new(0, 150, 0, 24)
    attackBtn.Position = UDim2.new(0, 10, 0, 92)
    attackBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    attackBtn.TextColor3 = Color3.new(1, 1, 1)
    attackBtn.Font = Enum.Font.SourceSansBold
    attackBtn.TextSize = 13
    attackBtn.Text = "Attack All Baby Shroom"
    attackBtn.Parent = frame
    attackBtn.MouseButton1Click:Connect(attackAllBabyShroomsOnce)

    -- Shroom Nuker Auto
    local autoAttackBtn = Instance.new("TextButton")
    autoAttackBtn.Size = UDim2.new(0, 110, 0, 24)
    autoAttackBtn.Position = UDim2.new(0, 170, 0, 92)
    autoAttackBtn.BackgroundColor3 = Color3.fromRGB(50, 60, 40)
    autoAttackBtn.TextColor3 = Color3.new(1, 1, 1)
    autoAttackBtn.Font = Enum.Font.SourceSans
    autoAttackBtn.TextSize = 12
    autoAttackBtn.Text = "Auto-Shroom: OFF"
    autoAttackBtn.Parent = frame
    autoAttackBtn.MouseButton1Click:Connect(function()
        if autoHunterEnabled then
            warn("[Dreamz] Disable Auto Hunter before Auto-Shroom.")
            return
        end
        autoAttackEnabled = not autoAttackEnabled
        autoAttackBtn.Text = "Auto-Shroom: " .. (autoAttackEnabled and "ON" or "OFF")
        if autoAttackEnabled then startAutoAttackLoop() else stopAutoAttackLoop() end
    end)

    -- Auto Hunter Target
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -20, 0, 16)
    targetLabel.Position = UDim2.new(0, 10, 0, 120)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Auto Hunter Target (contains):"
    targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.Font = Enum.Font.SourceSans
    targetLabel.TextSize = 13
    targetLabel.Parent = frame

    local targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(1, -90, 0, 22)
    targetBox.Position = UDim2.new(0, 10, 0, 138)
    targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    targetBox.TextColor3 = Color3.new(1, 1, 1)
    targetBox.Font = Enum.Font.SourceSans
    targetBox.TextSize = 13
    targetBox.PlaceholderText = "e.g. Crow"
    targetBox.ClearTextOnFocus = false
    targetBox.Parent = frame

    local setTargetBtn = Instance.new("TextButton")
    setTargetBtn.Size = UDim2.new(0, 60, 0, 22)
    setTargetBtn.Position = UDim2.new(1, -70, 0, 138)
    setTargetBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
    setTargetBtn.TextColor3 = Color3.new(1, 1, 1)
    setTargetBtn.Font = Enum.Font.SourceSansBold
    setTargetBtn.TextSize = 12
    setTargetBtn.Text = "Set"
    setTargetBtn.Parent = frame

    local function updateTarget()
        autoHunterTarget = trim(targetBox.Text or "")
    end
    setTargetBtn.MouseButton1Click:Connect(updateTarget)
    targetBox.FocusLost:Connect(updateTarget)

    -- Auto Hunter Priority Targets
    local prioLabel = Instance.new("TextLabel")
    prioLabel.Size = UDim2.new(1, -20, 0, 16)
    prioLabel.Position = UDim2.new(0, 10, 0, 166)
    prioLabel.BackgroundTransparency = 1
    prioLabel.Text = "Priority Targets (comma-separated):"
    prioLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    prioLabel.TextXAlignment = Enum.TextXAlignment.Left
    prioLabel.Font = Enum.Font.SourceSans
    prioLabel.TextSize = 13
    prioLabel.Parent = frame

    local prioBox = Instance.new("TextBox")
    prioBox.Size = UDim2.new(1, -20, 0, 22)
    prioBox.Position = UDim2.new(0, 10, 0, 184)
    prioBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    prioBox.TextColor3 = Color3.new(1, 1, 1)
    prioBox.Font = Enum.Font.SourceSans
    prioBox.TextSize = 13
    prioBox.PlaceholderText = "e.g. Rootbeard, Elder Shroom"
    prioBox.ClearTextOnFocus = false
    prioBox.Parent = frame

    local function updatePrio()
        setPriorityTargetsFromString(prioBox.Text or "")
    end
    prioBox.FocusLost:Connect(updatePrio)

    -- Auto Hunter toggle
    local autoHunterBtn = Instance.new("TextButton")
    autoHunterBtn.Size = UDim2.new(0, 260, 0, 24)
    autoHunterBtn.Position = UDim2.new(0, 10, 0, 212)
    autoHunterBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 90)
    autoHunterBtn.TextColor3 = Color3.new(1, 1, 1)
    autoHunterBtn.Font = Enum.Font.SourceSansBold
    autoHunterBtn.TextSize = 13
    autoHunterBtn.Text = "Auto Hunter: OFF"
    autoHunterBtn.Parent = frame
    autoHunterBtn.MouseButton1Click:Connect(function()
        if not autoHunterEnabled then
            autoHunterBtn.Text = "Auto Hunter: ON"
            startAutoHunter()
        else
            autoHunterBtn.Text = "Auto Hunter: OFF"
            stopAutoHunter()
        end
    end)

    -- Spam Abilities
    local spamBtn = Instance.new("TextButton")
    spamBtn.Size = UDim2.new(0, 260, 0, 24)
    spamBtn.Position = UDim2.new(0, 10, 0, 240)
    spamBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 50)
    spamBtn.TextColor3 = Color3.new(1, 1, 1)
    spamBtn.Font = Enum.Font.SourceSansBold
    spamBtn.TextSize = 13
    spamBtn.Text = "Spam Abilities: OFF"
    spamBtn.Parent = frame
    spamBtn.MouseButton1Click:Connect(function()
        if not spamAbilitiesEnabled then
            spamBtn.Text = "Spam Abilities: ON"
            startSpamAbilities()
        else
            spamBtn.Text = "Spam Abilities: OFF"
            stopSpamAbilities()
        end
    end)

    -- Auto Item Pickup
    local autoItemBtn = Instance.new("TextButton")
    autoItemBtn.Size = UDim2.new(0, 260, 0, 24)
    autoItemBtn.Position = UDim2.new(0, 10, 0, 268)
    autoItemBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 90)
    autoItemBtn.TextColor3 = Color3.new(1, 1, 1)
    autoItemBtn.Font = Enum.Font.SourceSansBold
    autoItemBtn.TextSize = 13
    autoItemBtn.Text = "Auto Item Pickup: OFF"
    autoItemBtn.Parent = frame
    autoItemBtn.MouseButton1Click:Connect(function()
        autoItemPickupEnabled = not autoItemPickupEnabled
        autoItemBtn.Text = "Auto Item Pickup: " .. (autoItemPickupEnabled and "ON" or "OFF")
        if autoItemPickupEnabled then
            startAutoItemPickupLoop()
        else
            stopAutoItemPickupLoop()
        end
    end)

    -- Auto Sell (Whitelist) BELOW Auto Item Pickup
    local autoSellBtn = Instance.new("TextButton")
    autoSellBtn.Size = UDim2.new(0, 260, 0, 24)
    autoSellBtn.Position = UDim2.new(0, 10, 0, 296)
    autoSellBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 50)
    autoSellBtn.TextColor3 = Color3.new(1, 1, 1)
    autoSellBtn.Font = Enum.Font.SourceSansBold
    autoSellBtn.TextSize = 13
    autoSellBtn.Text = "Auto Sell (Whitelist): OFF"
    autoSellBtn.Parent = frame
    autoSellBtn.MouseButton1Click:Connect(function()
        if not autoSellEnabled then
            autoSellBtn.Text = "Auto Sell (Whitelist): ON"
            startAutoSell()
        else
            autoSellBtn.Text = "Auto Sell (Whitelist): OFF"
            stopAutoSell()
        end
    end)

    -- Teleport to Entity (Name)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 16)
    nameLabel.Position = UDim2.new(0, 10, 0, 324)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Teleport to Entity (Name):"
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextSize = 13
    nameLabel.Parent = frame

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(1, -120, 0, 22)
    nameBox.Position = UDim2.new(0, 10, 0, 342)
    nameBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    nameBox.TextColor3 = Color3.new(1, 1, 1)
    nameBox.Font = Enum.Font.SourceSans
    nameBox.TextSize = 13
    nameBox.PlaceholderText = "Name / partial (NPC/Monster/Player)"
    nameBox.Parent = frame

    local tpNameBtn = Instance.new("TextButton")
    tpNameBtn.Size = UDim2.new(0, 90, 0, 22)
    tpNameBtn.Position = UDim2.new(1, -100, 0, 342)
    tpNameBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
    tpNameBtn.TextColor3 = Color3.new(1, 1, 1)
    tpNameBtn.Font = Enum.Font.SourceSansBold
    tpNameBtn.TextSize = 12
    tpNameBtn.Text = "TP Name"
    tpNameBtn.Parent = frame
    tpNameBtn.MouseButton1Click:Connect(function()
        teleportToEntityByName(nameBox.Text)
    end)

    -- Teleport to Coords (XYZ or CFrame)
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Size = UDim2.new(1, -20, 0, 16)
    coordLabel.Position = UDim2.new(0, 10, 0, 370)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Text = "Teleport to Coords (XYZ or CFrame):"
    coordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    coordLabel.TextXAlignment = Enum.TextXAlignment.Left
    coordLabel.Font = Enum.Font.SourceSans
    coordLabel.TextSize = 13
    coordLabel.Parent = frame

    local coordBox = Instance.new("TextBox")
    coordBox.Size = UDim2.new(1, -110, 0, 22)
    coordBox.Position = UDim2.new(0, 10, 0, 388)
    coordBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    coordBox.TextColor3 = Color3.new(1, 1, 1)
    coordBox.Font = Enum.Font.SourceSans
    coordBox.TextSize = 13
    coordBox.PlaceholderText = "0 50 0 or CFrame.new(0,50,0)"
    coordBox.Parent = frame

    local tpCoordBtn = Instance.new("TextButton")
    tpCoordBtn.Size = UDim2.new(0, 80, 0, 22)
    tpCoordBtn.Position = UDim2.new(1, -90, 0, 388)
    tpCoordBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
    tpCoordBtn.TextColor3 = Color3.new(1, 1, 1)
    tpCoordBtn.Font = Enum.Font.SourceSansBold
    tpCoordBtn.TextSize = 12
    tpCoordBtn.Text = "TP XYZ"
    tpCoordBtn.Parent = frame
    tpCoordBtn.MouseButton1Click:Connect(function()
        local text = coordBox.Text or ""
        local nums = {}
        for num in text:gmatch("(-?[%d%.]+)") do
            nums[#nums+1] = tonumber(num)
            if #nums >= 3 then break end
        end
        if #nums >= 3 then
            teleportToCoords(nums[1], nums[2], nums[3])
        else
            warn("[Dreamz TP] Could not parse coordinates from input.")
        end
    end)

    -- Map Teleport (Dropdown) at the bottom
    local mapTpLabel = Instance.new("TextLabel")
    mapTpLabel.Size = UDim2.new(1, -20, 0, 16)
    mapTpLabel.Position = UDim2.new(0, 10, 0, 416)
    mapTpLabel.BackgroundTransparency = 1
    mapTpLabel.Text = "Map Teleport (Teleporter List):"
    mapTpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    mapTpLabel.TextXAlignment = Enum.TextXAlignment.Left
    mapTpLabel.Font = Enum.Font.SourceSans
    mapTpLabel.TextSize = 13
    mapTpLabel.Parent = frame

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(1, -20, 0, 22)
    dropdownBtn.Position = UDim2.new(0, 10, 0, 434)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
    dropdownBtn.Font = Enum.Font.SourceSans
    dropdownBtn.TextSize = 13
    dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropdownBtn.Text = (#TeleportEntries > 0) and "Select destination..." or "No teleports found"
    dropdownBtn.AutoButtonColor = true
    dropdownBtn.Parent = frame

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -18, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.SourceSansBold
    arrow.TextSize = 16
    arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
    arrow.Text = "▼"
    arrow.Parent = dropdownBtn

    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.Name = "MapTpOptions"
    optionsFrame.Size = UDim2.new(1, -20, 0, 70)
    optionsFrame.Position = UDim2.new(0, 10, 0, 460)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    optionsFrame.BorderSizePixel = 0
    optionsFrame.ScrollBarThickness = 4
    optionsFrame.Visible = false
    optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    optionsFrame.Parent = frame

    local optLayout = Instance.new("UIListLayout")
    optLayout.Padding = UDim.new(0, 2)
    optLayout.SortOrder = Enum.SortOrder.Name
    optLayout.Parent = optionsFrame

    local function updateOptionsCanvas()
        optionsFrame.CanvasSize = UDim2.new(0, 0, 0, optLayout.AbsoluteContentSize.Y + 4)
    end
    optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateOptionsCanvas)

    for _, entry in ipairs(TeleportEntries) do
        local opt = Instance.new("TextButton")
        opt.Name = entry.name
        opt.Size = UDim2.new(1, 0, 0, 20)
        opt.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        opt.BorderSizePixel = 0
        opt.Font = Enum.Font.SourceSans
        opt.TextSize = 13
        opt.TextColor3 = Color3.new(1, 1, 1)
        opt.TextXAlignment = Enum.TextXAlignment.Left
        opt.Text = entry.name
        opt.AutoButtonColor = true
        opt.Parent = optionsFrame

        opt.MouseButton1Click:Connect(function()
            dropdownBtn.Text = entry.name
            optionsFrame.Visible = false
            arrow.Text = "▼"
            teleportToMapEntry(entry)
        end)
    end

    updateOptionsCanvas()

    local open = false
    dropdownBtn.MouseButton1Click:Connect(function()
        if #TeleportEntries == 0 then
            return
        end
        open = not open
        optionsFrame.Visible = open
        arrow.Text = open and "▲" or "▼"
    end)
end

createUI()
