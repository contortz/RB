--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

--// Toggles
local Toggles = {
    PlayerESP = false,
    StayBehind = false,
}

--// GUI
if CoreGui:FindFirstChild("MiniGui") then
    CoreGui.MiniGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MiniGui"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0.5, -100, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "MiniHub"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

local function createButton(text, key, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text .. ": OFF"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = Frame

    btn.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        btn.Text = text .. ": " .. (Toggles[key] and "ON" or "OFF")
        btn.BackgroundColor3 = Toggles[key] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 60)
    end)
end

createButton("Player ESP", "PlayerESP", 40)
createButton("Stay Behind", "StayBehind", 80)

--// Helpers
local function getHealthFromCharacter(char)
    if not char then return nil end
    local attr = char:GetAttribute("Health")
    if attr then return attr end
    local nv = char:FindFirstChild("Health")
    if nv and nv:IsA("NumberValue") then return nv.Value end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    return nil
end

local function ensureBillboard(hrp, name)
    local bb = hrp:FindFirstChild("ESP")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "ESP"
        bb.Adornee = hrp
        bb.Size = UDim2.new(0, 150, 0, 30)
        bb.AlwaysOnTop = true
        bb.Parent = hrp

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 0, 0)
        label.TextScaled = true
        label.Name = "Text"
        label.Parent = bb
    end
    return bb
end

--// Loop
local BEHIND_DISTANCE, VERTICAL_OFFSET = 4, 1.5

RunService.Heartbeat:Connect(function()
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    -- ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char, hrp = p.Character, p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Toggles.PlayerESP then
                    local hp = getHealthFromCharacter(char)
                    local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                    local bb = ensureBillboard(hrp, p.Name)
                    local label = bb:FindFirstChild("Text")
                    if label then
                        label.Text = string.format("%s | HP: %s | %dm",
                            p.Name, hp and math.floor(hp) or "?", dist)
                    end
                else
                    if hrp:FindFirstChild("ESP") then hrp.ESP:Destroy() end
                end
            end
        end
    end

    -- Stay Behind
    if Toggles.StayBehind then
        local closest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < dist then
                        closest, dist = p, d
                    end
                end
            end
        end
        if closest and closest.Character then
            local tHRP = closest.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local pos = tHRP.Position - (tHRP.CFrame.LookVector * BEHIND_DISTANCE) + Vector3.new(0, VERTICAL_OFFSET, 0)
                myHRP.CFrame = CFrame.new(pos, tHRP.Position)
            end
        end
    end
end)
