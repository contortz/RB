local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local beam = handle:WaitForChild("Beam")
local ropeAttachment = handle:FindFirstChild("RopeAttachment")

local hitSound = script:WaitForChild("Hit")
local fireSound = script:WaitForChild("Fire")

local isGrappling = false
local grappleForce

-- Clean up grapple forces and visuals
local function cleanupGrapple()
    if grappleForce then
        grappleForce:Destroy()
        grappleForce = nil
    end
    beam.Attachment0 = nil
    isGrappling = false
end

-- Main grapple function
tool.Activated:Connect(function()
    if isGrappling then
        -- Already grappling, ignore new activation
        return
    end

    -- We allow grapple even if stealing (remove the check)
    -- if player:GetAttribute("Stealing") then return end -- REMOVED

    local mouse = player:GetMouse()
    local targetPos = mouse.Hit.p
    local targetPart = mouse.Target

    if not targetPart then return end

    -- Check that target is not humanoid (same as original)
    local targetHumanoid = targetPart.Parent:FindFirstChild("Humanoid") or targetPart.Parent.Parent and targetPart.Parent.Parent:FindFirstChild("Humanoid")
    if targetHumanoid then return end

    local charHRP = character:FindFirstChild("HumanoidRootPart")
    if not charHRP then return end

    local direction = (targetPos - charHRP.Position)
    local distance = direction.Magnitude
    local unitDir = direction.Unit

    if distance < 10 or distance > 100 then return end

    -- Play fire sound
    fireSound:Play()

    -- Create invisible anchor part at target point
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.Position = targetPos
    anchor.Parent = workspace

    -- Create attachment at anchor
    local anchorAttachment = Instance.new("Attachment")
    anchorAttachment.Position = Vector3.new(0, 0, 0)
    anchorAttachment.Parent = anchor

    beam.Attachment0 = anchorAttachment

    -- Create BodyForce to pull player toward anchor (allows player control)
    grappleForce = Instance.new("BodyForce")
    grappleForce.Force = Vector3.new(0,0,0)
    grappleForce.Parent = charHRP

    isGrappling = true

    local startTime = tick()
    local maxDuration = distance / 120 -- same as before, time to reach

    -- Update loop: apply force each frame pulling player toward anchor but allow input movement
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isGrappling or not charHRP or not anchor then
            cleanupGrapple()
            connection:Disconnect()
            return
        end

        local toTarget = (anchor.Position - charHRP.Position)
        local mag = toTarget.Magnitude

        if mag < 3 or (tick() - startTime) > maxDuration then
            cleanupGrapple()
            connection:Disconnect()
            return
        end

        local pullStrength = 2000 -- tweak this for grapple power
        grappleForce.Force = toTarget.Unit * pullStrength + Vector3.new(0, workspace.Gravity * humanoidRootPart:GetMass(), 0)
    end)

    hitSound:Play()

    -- Cleanup if player sets Stealing attribute during grapple
    local stealConn
    stealConn = player:GetAttributeChangedSignal("Stealing"):Connect(function()
        if player:GetAttribute("Stealing") then
            cleanupGrapple()
            stealConn:Disconnect()
            if connection.Connected then connection:Disconnect() end
        end
    end)
end)
