--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local serverTime = Workspace:GetServerTimeNow()

-- Remote from decompile
local StealRemote = require(ReplicatedStorage.Packages.Net):RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52")

-- Loop all Plots & podiums
for _, plot in ipairs(Workspace.Map.Plots:GetChildren()) do
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if podiums then
        for _, podium in ipairs(podiums:GetChildren()) do
            -- This UUID might be in Claim folder, or can be static from ProximityPrompt logic
            local claimFolder = podium:FindFirstChild("Claim")
            if claimFolder then
                -- We can just use the fixed UUIDs from decompile
                StealRemote:FireServer(serverTime + 71, "e48572ed-dadc-4d9b-9124-315d813815db")
                StealRemote:FireServer(serverTime + 71, "614ca939-6c52-4dab-b3ab-5cde12e0a5f2")
            end
        end
    end
end
