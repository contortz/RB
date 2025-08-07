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
    PlayerESP = false
}

-- GUI Setup
local function createGui()
    if CoreGui:FindFirstChild("LiveFollowGui") then
        CoreGui.LiveFollowGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LiveFollowGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 150)
    MainFrame.Position = UDim2.new(0.5, -100, 0.4, -75)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local yPos = 0.1
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
        yPos += 0.2
    end

    createButton("Auto Follow", "AutoFollow")
    createButton("Player ESP", "PlayerESP")
end

createGui()

-- ESP Logic for Workspace.Live
local function updatePlayerESP()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = myChar.HumanoidRootPart

    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return end

    for _, char in pairs(liveFolder:GetChildren()) do
        if char:IsA("Model") and char.Name ~= player.Name and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local healthText = humanoid and math.floor(humanoid.Health) or "?"
            local distText = math.floor((myHRP.Position - hrp.Position).Magnitude)

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
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                    label.TextStrokeTransparency = 0
                    label.TextScaled = true
                    label.Text = string.format("%s | HP: %s | %dm", char.Name, healthText, distText)
                    label.Parent = billboard
                else
                    local label = hrp.Player_ESP:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm", char.Name, healthText, distText)
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

-- Follow Logic for Workspace.Live
local followInterval = 0.1
local lastFollow = 0

RunService.Heartbeat:Connect(function()
    pcall(function()
        local now = tick()
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

        if Toggles.PlayerESP then
            updatePlayerESP()
        end

        if Toggles.AutoFollow and now - lastFollow >= followInterval then
            lastFollow = now
            local myHRP = myChar.HumanoidRootPart
            local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
            local closestHRP, closestDist = nil, math.huge
            local liveFolder = Workspace:FindFirstChild("Live")
            if liveFolder then
                for _, obj in pairs(liveFolder:GetChildren()) do
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
            end
        end
    end)
end)
