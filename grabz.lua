--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local root = player.Character:WaitForChild("HumanoidRootPart")

-- Variables
local magnetEnabled = false
local claimHitboxes = {}
local claimCoinsRemote = ReplicatedStorage.Packages.Net["RE/PlotService/ClaimCoins"]

-- Create GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MagnetGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 180, 0, 90)
Frame.Position = UDim2.new(0.5, -90, 0.5, -45)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local MagnetBtn = Instance.new("TextButton", Frame)
MagnetBtn.Size = UDim2.new(1, -10, 0, 30)
MagnetBtn.Position = UDim2.new(0, 5, 0, 5)
MagnetBtn.Text = "🧲 Magnet: OFF"
MagnetBtn.TextColor3 = Color3.new(1, 1, 1)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

local ClaimAllBtn = Instance.new("TextButton", Frame)
ClaimAllBtn.Size = UDim2.new(1, -10, 0, 30)
ClaimAllBtn.Position = UDim2.new(0, 5, 0, 45)
ClaimAllBtn.Text = "💰 Claim All (1–10)"
ClaimAllBtn.TextColor3 = Color3.new(1, 1, 1)
ClaimAllBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Collect all hitboxes from all podiums
local function CollectClaimHitboxes()
    table.clear(claimHitboxes)
    for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local claimFolder = podium:FindFirstChild("Claim")
                if claimFolder then
                    for _, obj in ipairs(claimFolder:GetChildren()) do
                        if obj:IsA("BasePart") and obj.Name == "Hitbox" then
                            obj.Anchored = false
                            obj.CanCollide = false
                            obj.Transparency = 1
                            table.insert(claimHitboxes, obj)
                        end
                    end
                end
            end
        end
    end
end

-- Toggle magnet
MagnetBtn.MouseButton1Click:Connect(function()
    magnetEnabled = not magnetEnabled
    MagnetBtn.Text = "🧲 Magnet: " .. (magnetEnabled and "ON" or "OFF")
    if magnetEnabled then
        CollectClaimHitboxes()
    end
end)

-- Move all hitboxes each frame
RunService.Heartbeat:Connect(function()
    if magnetEnabled then
        for index, hitbox in ipairs(claimHitboxes) do
            local angle = (index / #claimHitboxes) * math.pi * 2
            local radius = 3
            local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            hitbox.CFrame = root.CFrame + offset
        end
    end
end)

-- Claim all podiums 1–10
ClaimAllBtn.MouseButton1Click:Connect(function()
    for i = 1, 10 do
        claimCoinsRemote:FireServer(i)
    end
end)
