--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

--// Toggles
local Toggles = {
    AutoPickCash = false,
    AutoPunch = false,
    AutoSwing = false
}

--// GUI
local function createGui()
    if CoreGui:FindFirstChild("StreetFightGui") then
        CoreGui.StreetFightGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StreetFightGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -100, 0.5, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 16
    TitleLabel.Text = "Dreamz MiniHub"
    TitleLabel.Parent = MainFrame

    local function createButton(name, toggleKey, yPos)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, 0, yPos)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = name .. ": OFF"
        button.Parent = MainFrame

        button.MouseButton1Click:Connect(function()
            Toggles[toggleKey] = not Toggles[toggleKey]
            button.Text = name .. ": " .. (Toggles[toggleKey] and "ON" or "OFF")
            button.BackgroundColor3 = Toggles[toggleKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        end)
    end

    createButton("Auto Pick Cash", "AutoPickCash", 40)
    createButton("Auto Punch", "AutoPunch", 75)
    createButton("Auto Swing", "AutoSwing", 110)
end

createGui()

--// Teleport variables
local lastTeleport = 0
local teleportCooldown = 1.5
local currentCashIndex = 1

--// Main loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        local myChar = player.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        local myHRP = myChar.HumanoidRootPart
        local now = tick()

        -- 🔁 Auto Pick Cash
        if Toggles.AutoPickCash and now - lastTeleport >= teleportCooldown then
            local worldspace = Workspace:FindFirstChild("Worldspace")
            local cashFolder = worldspace and worldspace:FindFirstChild("Cash")
            if cashFolder then
                local cashObjects = cashFolder:GetChildren()
                if #cashObjects > 0 then
                    if currentCashIndex > #cashObjects then currentCashIndex = 1 end
                    local targetCash = cashObjects[currentCashIndex]
                    if targetCash:IsA("BasePart") then
                        myHRP.CFrame = targetCash.CFrame + Vector3.new(0, 3, 0)
                    end
                    currentCashIndex += 1
                    lastTeleport = now
                end
            end
        end

        -- 🔁 Auto Punch
        if Toggles.AutoPunch then
            local args = { 1 }
            local punchRemote = ReplicatedStorage:FindFirstChild("PUNCHEVENT")
            if punchRemote then
                punchRemote:FireServer(unpack(args))
            end
        end

        -- 🔁 Auto Swing (Pipe)
        if Toggles.AutoSwing then
            local args = { 1 }
            local pipeRemote = ReplicatedStorage:FindFirstChild("Modules")
            if pipeRemote then
                local net = pipeRemote:FindFirstChild("Net")
                local swing = net and net:FindFirstChild("RE/PipeActivated")
                if swing then
                    swing:FireServer(unpack(args))
                end
            end
        end
    end)
end)
