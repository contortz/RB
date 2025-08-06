--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local root = player.Character:WaitForChild("HumanoidRootPart")

-- Variables
local magnetEnabled = false
local claimHitboxes = {}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MagnetGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 180, 0, 60)
Frame.Position = UDim2.new(0.5, -90, 0.5, -30)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local MagnetBtn = Instance.new("TextButton", Frame)
MagnetBtn.Size = UDim2.new(1, -10, 0, 40)
MagnetBtn.Position = UDim2.new(0, 5, 0, 10)
MagnetBtn.Text = "🧲 Magnet: OFF"
MagnetBtn.TextColor3 = Color3.new(1, 1, 1)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

-- Function: Collect all Claim Hitboxes
local function CollectClaimHitboxes()
    table.clear(claimHitboxes)
    for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, numFolder in ipairs(podiums:GetChildren()) do
                local claim = numFolder:FindFirstChild("Claim")
                if claim and claim:FindFirstChild("Hitbox") then
                    local hitbox = claim.Hitbox
                    if hitbox:IsA("BasePart") then
                        table.insert(claimHitboxes, hitbox)

                        -- Optional: Ghost them
                        hitbox.CanCollide = false
                        hitbox.Transparency = 1
                        hitbox.Anchored = true
                    end
                end
            end
        end
    end
end

-- Toggle function
MagnetBtn.MouseButton1Click:Connect(function()
    magnetEnabled = not magnetEnabled
    MagnetBtn.Text = "🧲 Magnet: " .. (magnetEnabled and "ON" or "OFF")

    if magnetEnabled then
        CollectClaimHitboxes()
    end
end)

-- Update positions every frame
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
