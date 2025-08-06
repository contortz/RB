--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")

-- Remote
local grabRemote = ReplicatedStorage.Packages.Net["RE/StealService/Grab"]

-- Setup GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "GrabBlinkGui"

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.new(0, 150, 0, 40)
btn.Position = UDim2.new(0.5, -75, 0.5, -20)
btn.Text = "💸 Blink Grab"
btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btn.TextColor3 = Color3.new(1, 1, 1)

-- Function: Blink and grab from closest steal hitbox
local function BlinkGrab()
    if not hrp then return end

    local oldCFrame = hrp.CFrame
    local closest = nil
    local closestDistance = math.huge

    -- Check each floor
    for _, floorName in ipairs({ "FirstFloor", "SecondFloor", "ThirdFloor" }) do
        local floor = ReplicatedStorage:FindFirstChild("Bases"):FindFirstChild(floorName)
        if floor and floor:FindFirstChild("StealHitbox") then
            local hitbox = floor.StealHitbox

            if hitbox:IsA("BasePart") then
                local dist = (hrp.Position - hitbox.Position).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closest = hitbox
                end
            end
        end
    end

    if closest then
        -- Blink to hitbox
        hrp.CFrame = closest.CFrame + Vector3.new(0, 2, 0)

        -- Fire Grab
        grabRemote:FireServer("Grab", 2)

        -- Return to original pos
        task.wait()
        hrp.CFrame = oldCFrame
    else
        warn("No StealHitbox found.")
    end
end

-- Button action
btn.MouseButton1Click:Connect(BlinkGrab)
