--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local serverTime = Workspace:GetServerTimeNow()

-- Remotes from decompile
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52")
local ClaimCoinsRemote = ReplicatedStorage.Packages.Net["RE/PlotService/ClaimCoins"]

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MassStealGui"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Parent = ScreenGui

-- Steal Button
local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(1, -10, 0, 40)
StealBtn.Position = UDim2.new(0, 5, 0, 5)
StealBtn.Text = "💸 Mass Steal"
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StealBtn.Parent = Frame

-- Claim Button
local ClaimBtn = Instance.new("TextButton")
ClaimBtn.Size = UDim2.new(1, -10, 0, 40)
ClaimBtn.Position = UDim2.new(0, 5, 0, 50)
ClaimBtn.Text = "💰 Mass Claim"
ClaimBtn.TextColor3 = Color3.new(1, 1, 1)
ClaimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ClaimBtn.Parent = Frame

-- Mass Steal Function
local function MassSteal()
    for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local claimFolder = podium:FindFirstChild("Claim")
                if claimFolder then
                    -- Fire with UUIDs from decompile
                    StealRemote:FireServer(serverTime + 71, "e48572ed-dadc-4d9b-9124-315d813815db")
                    StealRemote:FireServer(serverTime + 71, "614ca939-6c52-4dab-b3ab-5cde12e0a5f2")
                end
            end
        end
    end
end

-- Mass Claim Function
local function MassClaim()
    for i = 1, 10 do
        ClaimCoinsRemote:FireServer(i)
    end
end

-- Button Actions
StealBtn.MouseButton1Click:Connect(MassSteal)
ClaimBtn.MouseButton1Click:Connect(MassClaim)
