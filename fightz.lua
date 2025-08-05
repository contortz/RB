--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Feature Toggles
local AutoFollowEnabled = false
local AutoPunchEnabled = false
local AutoThrowEnabled = false
local AutoSwingEnabled = false
local AutoPickMoneyEnabled = false

-- Remotes
local PunchRemote = ReplicatedStorage:WaitForChild("Roles"):WaitForChild("Tools"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Weapons"):WaitForChild("Punch")
local ThrowRemote = ReplicatedStorage:WaitForChild("Utils"):WaitForChild("Throwables"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Throw")
local SwingRemote = ReplicatedStorage:WaitForChild("Roles"):WaitForChild("Tools"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("Weapons"):WaitForChild("Swing")
local PickMoneyRemote = ReplicatedStorage:WaitForChild("Stats"):WaitForChild("Core"):WaitForChild("Default"):WaitForChild("Remotes"):WaitForChild("PickMoney")

-- Default Throw Vector + PickMoney ID
local ThrowVector = Vector3.new(0.09, 0, -0.99)
local PickMoneyID = "2c476e20-7e93-4ad0-bdc8-bd781e73c0e9"

-- Create GUI (persistent & draggable)
if player.PlayerGui:FindFirstChild("StreetFightGui") then
    player.PlayerGui.StreetFightGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StreetFightGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 250)
MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Text = "Street Fight by Dreamz"
TitleLabel.Parent = MainFrame

local yPos = 0.15
local function createButton(name, stateVarName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9, 0, 0, 30)
    button.Position = UDim2.new(0.05, 0, yPos, 0)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = name .. ": OFF"
    button.Parent = MainFrame

    button.MouseButton1Click:Connect(function()
        _G[stateVarName] = not _G[stateVarName]
        button.Text = name .. ": " .. (_G[stateVarName] and "ON" or "OFF")
        button.BackgroundColor3 = _G[stateVarName] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
    end)

    yPos += 0.15
end

-- Buttons
_G.AutoFollowEnabled = AutoFollowEnabled
_G.AutoPunchEnabled = AutoPunchEnabled
_G.AutoThrowEnabled = AutoThrowEnabled
_G.AutoSwingEnabled = AutoSwingEnabled
_G.AutoPickMoneyEnabled = AutoPickMoneyEnabled

createButton("Auto Follow", "AutoFollowEnabled")
createButton("Auto Punch", "AutoPunchEnabled")
createButton("Auto Throw", "AutoThrowEnabled")
createButton("Auto Swing", "AutoSwingEnabled")
createButton("Auto PickMoney", "AutoPickMoneyEnabled")

-- Main Loop
RunService.Heartbeat:Connect(function()
    -- Auto Punch (25/sec)
    if _G.AutoPunchEnabled then
        for _ = 1, 25 do
            PunchRemote:InvokeServer()
        end
    end

    -- Auto Throw (5/sec for stability)
    if _G.AutoThrowEnabled then
        for _ = 1, 5 do
            ThrowRemote:InvokeServer(ThrowVector)
        end
    end


-- Auto Follow (walk to closest player)
if _G.AutoFollowEnabled then
    local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
    local myChar = searchFolder:FindFirstChild(player.Name)

    if myChar and myChar:FindFirstChild("Humanoid") and myChar:FindFirstChild("HumanoidRootPart") then
        local myHRP = myChar.HumanoidRootPart
        local myHumanoid = myChar.Humanoid

        local closestHRP = nil
        local closestDist = math.huge

        for _, obj in pairs(searchFolder:GetChildren()) do
            if obj:IsA("Model")
            and obj.Name ~= player.Name
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart") then
                local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestHRP = obj.HumanoidRootPart
                end
            end
        end

        if closestHRP then
            local targetPos = closestHRP.Position
            local direction = (targetPos - myHRP.Position).Unit * (closestDist - 5)
            myHumanoid.WalkToPoint = targetPos - direction
        end
    end
end


-- Auto Throw (aim at closest player)
if _G.AutoThrowEnabled then
    local searchFolder = Workspace:FindFirstChild("Characters") or Workspace
    local myChar = searchFolder:FindFirstChild(player.Name)

    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local myHRP = myChar.HumanoidRootPart
        local closestHRP
        local closestDist = math.huge

        -- Find closest enemy
        for _, obj in pairs(searchFolder:GetChildren()) do
            if obj:IsA("Model")
            and obj.Name ~= player.Name
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart") then
                local dist = (myHRP.Position - obj.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestHRP = obj.HumanoidRootPart
                end
            end
        end

        -- Throw at target if found
        if closestHRP then
            local direction = (closestHRP.Position - myHRP.Position).Unit
            for _ = 1, 5 do
                ThrowRemote:InvokeServer(direction)
            end
        end
    end
end


    --- Auto PickMoney (grab money from Workspace.Spawned)
if _G.AutoPickMoneyEnabled then
    local spawnedFolder = Workspace:FindFirstChild("Spawned")
    if spawnedFolder then
        for _, obj in pairs(spawnedFolder:GetChildren()) do
            -- Look for money objects
            if obj.Name:lower():find("Money") then
                PickMoneyRemote:InvokeServer(obj.Name)
            end
        end
    end
end
