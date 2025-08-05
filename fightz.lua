--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Feature Toggles
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
_G.AutoPunchEnabled = AutoPunchEnabled
_G.AutoThrowEnabled = AutoThrowEnabled
_G.AutoSwingEnabled = AutoSwingEnabled
_G.AutoPickMoneyEnabled = AutoPickMoneyEnabled

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

    -- Auto Swing (25/sec)
    if _G.AutoSwingEnabled then
        for _ = 1, 25 do
            SwingRemote:InvokeServer()
        end
    end

    -- Auto PickMoney (constant attempt)
    if _G.AutoPickMoneyEnabled then
        PickMoneyRemote:InvokeServer(PickMoneyID)
    end
end)
