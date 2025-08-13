local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")

-- Create simple status label:
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 200, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 24
statusLabel.Text = ""
statusLabel.Parent = playerGui
statusLabel.Visible = false

local function showStatus(text, duration)
    statusLabel.Text = text
    statusLabel.Visible = true
    task.delay(duration or 2, function()
        statusLabel.Visible = false
    end)
end

v5.Activated:Connect(function()
    if u8:GetAttribute("Stealing") then
        return
    else
        local v11 = require(u1.Packages.PlayerMouse)
        local v12 = v11.Hit
        local v13 = v11.Target
        if v13 and not (v13.Parent:FindFirstChild("Humanoid") or v13.Parent.Parent:FindFirstChild("Humanoid")) then
            local v14 = v12.Position
            local v15 = u8.Character
            if v15 then
                local v16 = v15:FindFirstChildWhichIsA("Tool", true)
                if v16 and v16.Name == "Grapple Hook" then
                    local v17 = v15:FindFirstChild("HumanoidRootPart")
                    local humanoid = v15:FindFirstChildOfClass("Humanoid")
                    if v17 and humanoid then
                        local v18 = (v14 - v17.Position).Unit
                        local v19 = (v14 - v17.Position).Magnitude
                        if v19 >= 10 and v19 <= 100 then
                            if u4(("ItemUse/GrappleHook/Client/%*"):format(u8.Name), 3) then
                                return
                            end
                            u10:Play()
                            u3:RemoteEvent("UseItem"):FireServer(v19 / 120)
                            local u20 = Instance.new("Part")
                            u20.Anchored = true
                            u20.CanCollide = false
                            u20.Transparency = 1
                            u20.Position = v14
                            u20.Size = Vector3.new(0.1, 0.1, 0.1)
                            u20.Parent = workspace
                            local u21 = Instance.new("Attachment")
                            u21.Position = Vector3.new(0, 0, 0)
                            u21.Parent = u20
                            u7.Attachment0 = u21
                            local u22 = Instance.new("BodyVelocity")
                            u22.Name = "FlightPower"
                            u22.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            u22.Velocity = v18 * 100
                            u22.P = 2000
                            u22.Parent = v17
                            u9:Play()

                            -- Speed & Jump Boost
                            local originalSpeed = humanoid.WalkSpeed
                            local originalJump = humanoid.JumpPower
                            local boostSpeed = 50
                            local boostJump = 100
                            humanoid.WalkSpeed = boostSpeed
                            humanoid.JumpPower = boostJump
                            showStatus("Speed & Jump Boost Active!", 3)

                            task.delay(3, function()
                                if humanoid and humanoid.Parent then
                                    humanoid.WalkSpeed = originalSpeed
                                    humanoid.JumpPower = originalJump
                                    showStatus("Speed & Jump Boost Ended", 2)
                                end
                            end)

                            local u23 = nil
                            local u24 = nil
                            local function u25()
                                if u23 then
                                    u23:Disconnect()
                                    u23 = nil
                                end
                                if u24 then
                                    if coroutine.status(u24) == "suspended" then
                                        pcall(task.cancel, u24)
                                    end
                                    u24 = nil
                                end
                                u22:Destroy()
                                u21:Destroy()
                                u20:Destroy()
                                u7.Attachment0 = nil
                            end
                            u23 = u8:GetAttributeChangedSignal("Stealing"):Connect(function()
                                if u8:GetAttribute("Stealing") then
                                    task.defer(u25)
                                end
                            end)
                            u24 = task.delay(v19 / 120, function()
                                task.defer(u25)
                            end)
                            if u8:GetAttribute("Stealing") then
                                task.defer(u25)
                            end
                        end
                    end
                end
            end
        end
    end
end)
