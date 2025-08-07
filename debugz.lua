--// After 'frame' is created, add this label to display base + tier
local baseInfoLabel = Instance.new("TextLabel", frame)
baseInfoLabel.Size = UDim2.new(1, -10, 0, 25)
baseInfoLabel.Position = UDim2.new(0, 5, 0, 165) -- Adjust if you insert more GUI above
baseInfoLabel.BackgroundTransparency = 1
baseInfoLabel.TextColor3 = Color3.new(1, 1, 1)
baseInfoLabel.Text = "🏠 Base: Unknown | Tier: ?"
baseInfoLabel.TextScaled = true
baseInfoLabel.Font = Enum.Font.GothamBold

--// Locate your plot and display info
local function findLocalPlayerBase()
    local playerName = game.Players.LocalPlayer.Name
    local LocalPlayerBase = nil
    local LocalBaseTier = nil

    for _, plotModel in ipairs(Workspace.Plots:GetChildren()) do
        local plotSign = plotModel:FindFirstChild("PlotSign")
        if plotSign and plotSign:FindFirstChild("SurfaceGui") then
            local gui = plotSign.SurfaceGui
            local frame = gui:FindFirstChild("Frame")
            local textLabel = frame and frame:FindFirstChild("TextLabel")

            if textLabel and typeof(textLabel.Text) == "string" then
                local baseOwner = textLabel.Text:match("^(.-)'s Base") -- strip "'s Base"

                if baseOwner == playerName then
                    LocalPlayerBase = plotModel
                    LocalBaseTier = plotModel:GetAttribute("Tier")

                    -- ✅ Update GUI
                    baseInfoLabel.Text = "🏠 Base: " .. (plotModel.Name or "Unknown") .. " | Tier: " .. tostring(LocalBaseTier or "?")
                    break
                end
            end
        end
    end
end

-- Run once after GUI is created
findLocalPlayerBase()
