--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Toggles
local Toggles = {
    AutoFollow = false,
    AutoPunch = false,
    AutoThrow = false,
    AutoSwing = false,
    AutoShoot = false,
    AutoPickMoney = false,
    ATMESP = false,
    PlayerESP = false
}

-- GUI
local function createGui()
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 300) -- ✅ Reduced from 350
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
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
    TitleLabel.Text = "Street Fight by Dreamz"
    TitleLabel.Parent = MainFrame


-- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.Text = "-"
    minimizeBtn.ZIndex = 999
    minimizeBtn.Parent = MainFrame



    -- Icon when minimized
    local miniIcon = Instance.new("ImageButton")
miniIcon.Size = UDim2.new(0, 60, 0, 60) -- ⬆️ increased size
miniIcon.Position = UDim2.new(0, 15, 0.27, -50) -- ⬆️ moved up 10 pixels
    miniIcon.BackgroundTransparency = 1
    miniIcon.Image = "rbxassetid://76154122039576" -- Replace with your icon asset
    miniIcon.ZIndex = 999
    miniIcon.Visible = false
    miniIcon.Parent = ScreenGui

    -- Toggle Minimize
    minimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        miniIcon.Visible = true
    end)

    miniIcon.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        miniIcon.Visible = false
    end)

    local yPos = 0.15
    local function createButton(name, toggleKey)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, yPos, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame
        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
        end)
        yPos += 0.08
    end

    -- Create buttons
    createButton("Auto Follow", "AutoFollow")
    createButton("Auto Punch", "AutoPunch")
    createButton("Auto Throw", "AutoThrow")
    createButton("Auto Swing", "AutoSwing")
    createButton("Auto Shoot", "AutoShoot")
    createButton("Auto PickMoney", "AutoPickMoney")
    createButton("ATM ESP", "ATMESP")
    createButton("Player ESP", "PlayerESP")




    -- ATM Teleport (Cycle Mode)
local atmIndex = 1 -- Tracks which ATM we are on

local tpATMButton = Instance.new("TextButton")
tpATMButton.Size = UDim2.new(0.9, 0, 0, 30)
tpATMButton.Position = UDim2.new(0.05, 0, yPos, 0)
tpATMButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
tpATMButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tpATMButton.Text = "Teleport Next ATM"
tpATMButton.Parent = MainFrame
tpATMButton.MouseButton1Click:Connect(function()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart

    local atmsFolder = Workspace:FindFirstChild("ATMs")
    if atmsFolder and #atmsFolder:GetChildren() > 0 then
        -- Wrap around if index goes past total ATMs
        if atmIndex > #atmsFolder:GetChildren() then
            atmIndex = 1
        end

        -- Get ATM at current index
        local atm = atmsFolder:GetChildren()[atmIndex]
        local part = atm:IsA("BasePart") and atm or atm:FindFirstChildWhichIsA("BasePart")

        -- Teleport to it
        if part then
            myHRP.CFrame = part.CFrame + Vector3.new(0, 5, 0)
        end

        -- Move to next index
        atmIndex += 1
    end
end)
yPos += 0.08


-- Tools Cycle Teleport Button
local toolIndex = 1
local tpToolsButton = Instance.new("TextButton")
tpToolsButton.Size = UDim2.new(0.9, 0, 0, 30)
tpToolsButton.Position = UDim2.new(0.05, 0, yPos, 0)
tpToolsButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
tpToolsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tpToolsButton.Text = "Teleport Next Tool"
tpToolsButton.Parent = MainFrame
tpToolsButton.MouseButton1Click:Connect(function()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart
    local toolsFolder = Workspace:FindFirstChild("Others") and Workspace.Others:FindFirstChild("Tools")
    if toolsFolder then
        local tools = toolsFolder:GetChildren()
        if #tools > 0 then
            if toolIndex > #tools then toolIndex = 1 end
            local tool = tools[toolIndex]
            local part = tool:IsA("BasePart") and tool or tool:FindFirstChildWhichIsA("BasePart")
            if part then
                myHRP.CFrame = part.CFrame + Vector3.new(0, 5, 0)
            end
            toolIndex += 1
        end
    end
end)
yPos += 0.08
end -- ✅ CLOSES createGui()


createGui()
if not CoreGui:FindFirstChild("StreetFightGui") then
    createGui()
end


-- Remotes
local PunchRemote = ReplicatedStorage:FindFirstChild("Roles") and ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons:FindFirstChild("Punch")
local ThrowRemote = ReplicatedStorage:FindFirstChild("Utils") and ReplicatedStorage.Utils.Throwables.Default.Remotes:FindFirstChild("Throw")
local SwingRemote = ReplicatedStorage:FindFirstChild("Roles") and ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons:FindFirstChild("Swing")

-- ESP Functions
local function updateATMESP()
    local atmsFolder = Workspace:FindFirstChild("ATMs")
    if not atmsFolder then return end
    
    for _, atm in pairs(atmsFolder:GetChildren()) do
        local part = atm:IsA("BasePart") and atm or atm:FindFirstChildWhichIsA("BasePart")
        if part then
            if Toggles.ATMESP then
                -- Create ESP if missing
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
                -- ✅ Remove ESP if toggle is off
                if part:FindFirstChild("ATM_ESP") then
                    part.ATM_ESP:Destroy()
                end
            end
        end
    end
end


local function updatePlayerESP()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart

    local charFolder = Workspace:FindFirstChild("Characters")
    if not charFolder then return end

    for _, char in pairs(charFolder:GetChildren()) do
        if char:IsA("Model") and char.Name ~= player.Name and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local humanoid = char:FindFirstChild("Humanoid")
            local healthText = humanoid and math.floor(humanoid.Health) or "?"
            local distText = math.floor((myHRP.Position - hrp.Position).Magnitude)

            if Toggles.PlayerESP then
                -- Create ESP if missing
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
                    label.Text = string.format("%s | HP: %s | %dm", char.Name, healthText, distText)
                    label.Parent = billboard
                else
                    -- Update text
                    local label = hrp.Player_ESP:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm", char.Name, healthText, distText)
                    end
                end
            else
                -- ✅ Remove ESP if toggle is off
                if hrp:FindFirstChild("Player_ESP") then
                    hrp.Player_ESP:Destroy()
                end
            end
        end
    end
end



-- Cooldowns
local punchCooldown, swingCooldown, throwCooldown, pickMoneyCooldown, followInterval = 0.2, 0.2, 0.3, 0.5, 0.1
local lastPunch, lastSwing, lastThrow, lastPick, lastFollow = 0, 0, 0, 0, 0

-- Main Loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character or Workspace:FindFirstChild(player.Name)
        if not myChar then return end

        -- ESP Updates
        if Toggles.ATMESP then updateATMESP() end
        if Toggles.PlayerESP then updatePlayerESP() end

        -- Auto Punch
        if Toggles.AutoPunch and now - lastPunch >= punchCooldown then
            lastPunch = now
            pcall(function() PunchRemote:InvokeServer() end)
        end

        -- Auto Swing
        if Toggles.AutoSwing and now - lastSwing >= swingCooldown then
            lastSwing = now
            pcall(function() SwingRemote:InvokeServer() end)
        end



-- Auto Shoot
if Toggles.AutoShoot and myChar:FindFirstChild("HumanoidRootPart") then
    local myHRP = myChar.HumanoidRootPart
    local closestPlayer, closestPart
    local closestDist = math.huge

    -- Loop through all players
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local char = otherPlayer.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            -- ✅ Skip if dead or no humanoid
            if humanoid and humanoid.Health > 0 then
                -- Search for any BasePart to shoot at
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local dist = (myHRP.Position - part.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestPlayer = otherPlayer
                            closestPart = part
                        end
                    end
                end
            end
        end
    end

    -- Shoot at closest part
    if closestPart then
        local direction = (closestPart.Position - myHRP.Position).Unit
        local args = {{
            Instance = closestPart,
            Distance = closestDist,
            Normal = direction,
            Position = closestPart.Position
        }}

        pcall(function()
            ReplicatedStorage.Roles.Tools.Default.Remotes.Weapons.Shoot:InvokeServer(unpack(args))
        end)
    end
end


        
        
        -- Auto Throw
        if Toggles.AutoThrow and now - lastThrow >= throwCooldown and myChar:FindFirstChild("HumanoidRootPart") then
            lastThrow = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
                local closestHRP, closestDist = nil, math.huge
                for _, obj in pairs(searchFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
                        local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestHRP = obj.HumanoidRootPart
                        end
                    end
                end
                if closestHRP then
                    local direction = (closestHRP.Position - myHRP.Position).Unit
                    ThrowRemote:InvokeServer(direction)
                end
            end)
        end

        -- Auto Follow
        if Toggles.AutoFollow and now - lastFollow >= followInterval and myChar:FindFirstChild("HumanoidRootPart") then
            lastFollow = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local myHumanoid = myChar:FindFirstChild("Humanoid")
                local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
                local closestHRP, closestDist = nil, math.huge
                for _, obj in pairs(searchFolder:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= player.Name and obj:FindFirstChild("HumanoidRootPart") then
                        local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestHRP = obj.HumanoidRootPart
                        end
                    end
                end
                if closestHRP and myHumanoid then
                    myHumanoid.WalkToPoint = closestHRP.Position
                end
            end)
        end





                
        -- Auto PickMoney
        if Toggles.AutoPickMoney and now - lastPick >= pickMoneyCooldown and myChar:FindFirstChild("HumanoidRootPart") then
            lastPick = now
            pcall(function()
                local myHRP = myChar.HumanoidRootPart
                local moneyFolder = Workspace:FindFirstChild("Spawned") and Workspace.Spawned:FindFirstChild("Money")
                if moneyFolder then
                    for _, obj in pairs(moneyFolder:GetChildren()) do
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if part and prompt and prompt.Enabled then
                            myHRP.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                            task.wait(0.05)
                            fireproximityprompt(prompt)
                            break
                        end
                    end
                end
            end)
        end
    end)
end)
