-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local root = player.Character:WaitForChild("HumanoidRootPart")

-- Settings
local stickOffset = Vector3.new(3, 0, 0) -- offset so they don't overlap too hard
local claimHitboxes = {}

-- Step 1: Find all claim hitboxes
for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, numFolder in ipairs(podiums:GetChildren()) do
            local claim = numFolder:FindFirstChild("Claim")
            if claim and claim:FindFirstChild("Hitbox") then
                local hitbox = claim.Hitbox
                if hitbox:IsA("BasePart") then
                    table.insert(claimHitboxes, hitbox)

                    -- Optional: Make invisible and no collision
                    hitbox.CanCollide = false
                    hitbox.Transparency = 1
                    hitbox.Anchored = true
                end
            end
        end
    end
end

-- Step 2: Update position every frame
RunService.Heartbeat:Connect(function()
    for index, hitbox in ipairs(claimHitboxes) do
        local angle = (index / #claimHitboxes) * math.pi * 2
        local radius = 3
        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        hitbox.CFrame = root.CFrame + offset
    end
end)
