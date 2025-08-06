--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Net = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
local Synchronizer = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))

-- Remotes
local PrepRemote = Net:RemoteEvent("d8276bf9-acc4-4361-9149-ffd91b3fed52") -- Prep
local GrabRemote = Net:RemoteEvent("39c0ed9f-fd96-4f2c-89c8-b7a9b2d44d2e") -- Grab

-- UUIDs
local myUUID, victimUUID = nil, nil

-- Scan function
local function ScanPlots()
    myUUID = nil
    victimUUID = nil
    
    for _, plot in ipairs(Workspace:WaitForChild("Plots"):GetChildren()) do
        local channel = Synchronizer:Wait(plot.Name)
        if channel and typeof(channel.Get) == "function" then
            local owner = channel:Get("Owner")
            if owner then
                if owner == Players.LocalPlayer then
                    myUUID = plot.Name
                else
                    if not victimUUID then
                        victimUUID = plot.Name
                    end
                end
            end
        end
    end
end

-- Instant grab mimic
local function DoGrab(fromUUID, toUUID)
    local t = Workspace:GetServerTimeNow()
    PrepRemote:FireServer(t, fromUUID)
    PrepRemote:FireServer(t, toUUID)
    GrabRemote:FireServer(t, fromUUID, toUUID, 2)
end

-- Hook ProximityPrompt for instant steal
ProximityPromptService.PromptShown:Connect(function(prompt)
    if prompt:GetAttribute("State") == "Grab" then
        ScanPlots()
        if myUUID and victimUUID then
            -- Instantly grab
            DoGrab(myUUID, victimUUID)
            print("✅ Instant steal triggered via prompt")
        else
            print("⚠️ Couldn’t find victim UUID")
        end
    end
end)
