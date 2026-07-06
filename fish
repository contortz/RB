local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

---------------------------------------------------------
-- STATE & DATA
---------------------------------------------------------
local Locations = { Slot1 = nil, Slot2 = nil, Slot3 = nil }
local isFarming = false

-- (Keep the same getMyRoot, GUI Setup, and Dragging Logic from previous steps)
-- ... [Include the getMyRoot and GUI setup code here] ...

---------------------------------------------------------
-- FARMING LOGIC
---------------------------------------------------------
local function farmBestFish()
    while isFarming do
        local fishFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Fishes")
        if not fishFolder then 
            warn("Fishes folder not found!")
            break 
        end

        local bestFish = nil
        local maxCash = -1

        -- Find the fish with highest CashPerSec
        for _, fish in pairs(fishFolder:GetChildren()) do
            local cash = fish:GetAttribute("CashPerSec")
            if cash and cash > maxCash then
                maxCash = cash
                bestFish = fish
            end
        end

        local root = getMyRoot()
        if bestFish and root and Locations.Slot1 then
            -- Teleport to fish
            root.CFrame = bestFish:GetPivot() 
            
            -- Hold E
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.5) -- Adjust this time to ensure the fish is "grabbed"
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            -- Return to Slot 1
            root.CFrame = Locations.Slot1
            task.wait(1) -- Delay between farms so we don't get flagged for spamming
        else
            if not Locations.Slot1 then warn("Slot 1 not saved!") end
            task.wait(1)
        end
    end
end

-- Add this to your GUI setup (e.g., inside createSlot or a new function)
local farmBtn = Instance.new("TextButton", mainFrame)
farmBtn.Size = UDim2.new(0, 210, 0, 40)
farmBtn.Position = UDim2.new(0, 15, 0, 180) -- Adjust position as needed
farmBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
farmBtn.Text = "START FARM"
farmBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    farmBtn.Text = isFarming and "STOP FARM" or "START FARM"
    if isFarming then task.spawn(farmBestFish) end
end)
