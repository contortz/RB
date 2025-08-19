--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// Toggles
local Toggles = {
    AutoPickCash = false,
    AutoPunch = false,
    AutoSwing = false,
    PlayerESP = false,
    ATMESP = false,
    SalonPunchTest = false,
    GiveDinero = false,
    StayBehind = false, -- NEW
}

--// GUI Setup
local function createGui()
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 16
    TitleLabel.Text = "Dreamz MiniHub"
    TitleLabel.Parent = MainFrame

    local function createButton(name, toggleKey, yPos)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, 0, yPos)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame

        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)
    end

    createButton("Auto Pick Cash", "AutoPickCash", 40)
    createButton("Auto Punch", "AutoPunch", 75)
    createButton("Auto Swing", "AutoSwing", 110)
    createButton("Player ESP", "PlayerESP", 145)
    createButton("ATM ESP", "ATMESP", 180)
    createButton("Stay Behind Closest", "StayBehind", 215) -- NEW
    createButton("Salon Punch Test", "SalonPunchTest", 250)
    createButton("Give Dinero Test", "GiveDinero", 285)

    -- Teleport to next ATM
    local tpATMButton = Instance.new("TextButton")
    tpATMButton.Size = UDim2.new(0.9, 0, 0, 30)
    tpATMButton.Position = UDim2.new(0.05, 0, 0, 320)
    tpATMButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    tpATMButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpATMButton.Text = "Teleport Next ATM"
    tpATMButton.Parent = MainFrame

    local atmIndex = 1
    tpATMButton.MouseButton1Click:Connect(function()
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        local myHRP = myChar.HumanoidRootPart

        local dmgFolder = Workspace:FindFirstChild("Damageables")
        if dmgFolder then
            local atms = {}
            for _, obj in pairs(dmgFolder:GetChildren()) do
                if obj:IsA("Model") and obj.Name == "ATM" then
                    table.insert(atms, obj)
                end
            end

            if #atms > 0 then
                if atmIndex > #atms then atmIndex = 1 end
                local target = atms[atmIndex]
                local part = target:FindFirstChildWhichIsA("BasePart")
                if part then
                    myHRP.CFrame = part.CFrame + Vector3.new(0, 4, 0)
                end
                atmIndex = atmIndex + 1
            end
        end
    end)
end

createGui()

--// Helpers
local function getClosestAliveOtherPlayer(myHRP)
    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")

            -- check attribute
            local pvpEnabled = p:GetAttribute("PVP_ENABLED")
            if pvpEnabled == nil or pvpEnabled == true then
                if hum and hrp and hum.Health > 0 then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closest = p
                        closestDist = d
                    end
                end
            end
        end
    end
    return closest, closestDist
end


--// ESP Functions
local function updatePlayerESP()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = otherPlayer.Character.HumanoidRootPart
            local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            local health = humanoid and math.floor(humanoid.Health) or "?"
            local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)

            if Toggles.PlayerESP then
                if not hrp:FindFirstChild("Player_ESP") then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "Player_ESP"
                    billboard.Adornee = hrp
                    billboard.Size = UDim2.new(0, 150, 0, 40)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = hrp

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 0, 0)
                    label.TextStrokeTransparency = 0
                    label.TextScaled = true
                    label.Text = string.format("%s | HP: %s | %dm", otherPlayer.Name, health, dist)
                    label.Parent = billboard
                else
                    local label = hrp.Player_ESP:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm", otherPlayer.Name, health, dist)
                    end
                end
            else
                if hrp:FindFirstChild("Player_ESP") then
                    hrp.Player_ESP:Destroy()
                end
            end
        end
    end
end

local function updateATMESP()
    local dmgFolder = Workspace:FindFirstChild("Damageables")
    if not dmgFolder then return end

    for _, atm in pairs(dmgFolder:GetChildren()) do
        if atm:IsA("Model") and atm.Name == "ATM" then
            local part = atm:FindFirstChildWhichIsA("BasePart")
            if part then
                if Toggles.ATMESP then
                    if not part:FindFirstChild("ATM_ESP") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "ATM_ESP"
                        billboard.Adornee = part
                        billboard.Size = UDim2.new(0, 100, 0, 30)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = part

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = "💰 ATM"
                        label.TextColor3 = Color3.fromRGB(0, 255, 0)
                        label.TextStrokeTransparency = 0
                        label.TextScaled = true
                        label.Parent = billboard
                    end
                else
                    if part:FindFirstChild("ATM_ESP") then
                        part.ATM_ESP:Destroy()
                    end
                end
            end
        end
    end
end

--// Cash Teleport + Prompt
local lastTeleport = 0
local teleportCooldown = 0.25
local currentCashIndex = 1

local function purchasePromptActive()
    local promptGui = player:FindFirstChild("PlayerGui"):FindFirstChild("ProximityPrompts")
    return promptGui and #promptGui:GetChildren() > 0
end

local function simulateKeyPress(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--// Stay-Behind constants (every-frame CFrame)
local BEHIND_DISTANCE = 3.5   -- studs behind target
local VERTICAL_OFFSET = 1.5   -- small lift to avoid clipping

--// Main loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then return end

        -- Auto Pick Cash
        if Toggles.AutoPickCash and now - lastTeleport >= teleportCooldown then
            local cashFolder = Workspace:FindFirstChild("Cash")
            if cashFolder then
                local allCash = {}
                for _, obj in pairs(cashFolder:GetChildren()) do
                    if obj:IsA("BasePart") and obj.Name == "Cash" then
                        table.insert(allCash, obj)
                    end
                end

                if #allCash > 0 then
                    if currentCashIndex > #allCash then currentCashIndex = 1 end
                    local targetCash = allCash[currentCashIndex]
                    if targetCash then
                        myHRP.CFrame = targetCash.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.05)
                        if purchasePromptActive() then
                            simulateKeyPress(Enum.KeyCode.E)
                        end
                    end
                    currentCashIndex = currentCashIndex + 1
                    lastTeleport = now
                end
            end
        end

        -- Auto Punch
        if Toggles.AutoPunch then
            local punchRemote = ReplicatedStorage:FindFirstChild("PUNCHEVENT")
            if punchRemote then
                punchRemote:FireServer(1)
            end
        end

        -- Auto Swing
        if Toggles.AutoSwing then
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            if modules then
                local net = modules:FindFirstChild("Net")
                if net then
                    local pipe = net:FindFirstChild("RE/PipeActivated")
                    if pipe then pipe:FireServer(1) end
                    local stopSign = net:FindFirstChild("RE/stopsignalHit")
                    if stopSign then stopSign:FireServer(1) end
                end
            end
        end

        -- Give Dinero (test)
        if Toggles.GiveDinero then
            local events = ReplicatedStorage:FindFirstChild("events")
            if events then
                local commandEvents = events:FindFirstChild("customer_command_events")
                if commandEvents then
                    local giveDinero = commandEvents:FindFirstChild("giveDinero")
                    if giveDinero and giveDinero:IsA("RemoteEvent") then
                        giveDinero:FireServer(999999)
                    end
                end
            end
        end

        -- Salon Punch Test
        if Toggles.SalonPunchTest then
            local remote = ReplicatedStorage:FindFirstChild("Roles")
            if remote then
                local tools = remote:FindFirstChild("Tools")
                if tools then
                    local default = tools:FindFirstChild("Default")
                    if default then
                        local remotes = default:FindFirstChild("Remotes")
                        if remotes then
                            local weapons = remotes:FindFirstChild("Weapons")
                            if weapons then
                                local salonPunch = weapons:FindFirstChild("SalonPunches")
                                if salonPunch and salonPunch:IsA("RemoteFunction") then
                                    local result = salonPunch:InvokeServer(1)
                                    print("🧪 SalonPunch result:", result)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- NEW: Stay Behind Closest (EVERY FRAME hard CFrame)
        if Toggles.StayBehind then
            local targetPlayer = nil
            local closestDist = nil
            do
                local p, d = getClosestAliveOtherPlayer(myHRP)
                targetPlayer, closestDist = p, d
            end

            if targetPlayer and targetPlayer.Character then
                local tHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tHum and tHRP and tHum.Health > 0 then
                    -- compute a point directly behind target, and face same direction
                    local desiredPos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
                    myHRP.CFrame = CFrame.new(desiredPos, desiredPos + tHRP.CFrame.LookVector)
                end
            end
        end

        -- ESP
        if Toggles.PlayerESP then updatePlayerESP() end
        if Toggles.ATMESP then updateATMESP() end
    end)
end)
