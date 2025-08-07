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
    AutoMoney = false,
    SalonPunchTest = false,
    GiveDinero = false
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
    MainFrame.Size = UDim2.new(0, 200, 0, 280)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -140)
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
    createButton("Auto Money", "AutoMoney", 180)
    createButton("Salon Punch Test", "SalonPunchTest", 215)
    createButton("Give Dinero Test", "GiveDinero", 250)
end

createGui()

--// ESP Function
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

--// Prompt & Input Helper
local function purchasePromptActive()
    local promptGui = player:FindFirstChild("PlayerGui"):FindFirstChild("ProximityPrompts")
    return promptGui and #promptGui:GetChildren() > 0
end

local function simulateKeyPress(key, duration)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--// Cooldowns
local lastTeleport = 0
local teleportCooldown = 0.25
local currentCashIndex = 1
local lastAutoMoney = 0
local autoMoneyCooldown = 1.5

--// Main Loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        local myHRP = myChar.HumanoidRootPart

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
                            simulateKeyPress("E", 0.9)
                        end
                    end
                    currentCashIndex += 1
                    lastTeleport = now
                end
            end
        end

        -- Auto Money (2-prompt interaction)
        if Toggles.AutoMoney and now - lastAutoMoney >= autoMoneyCooldown then
            local registers = Workspace:FindFirstChild("Registers")
            if registers then
                for _, reg in pairs(registers:GetChildren()) do
                    if reg:IsA("Model") and reg.Name:match("^CRS_%d+") then
                        local stock = reg:FindFirstChild("Stock")
                        if stock then
                            local moneyModel = stock:FindFirstChild("MoneyModel")
                            if moneyModel and moneyModel:IsA("Model") then
                                for _, part in pairs(moneyModel:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        myHRP.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.25)

                                        if purchasePromptActive() then
                                            simulateKeyPress("E", 1.2)
                                            task.wait(0.5)
                                            if purchasePromptActive() then
                                                simulateKeyPress("E", 1.2)
                                            end
                                            lastAutoMoney = now
                                            return
                                        end
                                        task.wait(0.25)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Auto Punch
        if Toggles.AutoPunch then
            local punchRemote = ReplicatedStorage:FindFirstChild("PUNCHEVENT")
            if punchRemote then punchRemote:FireServer(1) end
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

        -- Give Dinero
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
                                    print("ð\xf0\xf0\x9f§\xf0\x9f\xa7ª\xf0\x9f\xa7\xaa SalonPunch result:", result)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Player ESP
        if Toggles.PlayerESP then updatePlayerESP() end
    end)
end)
