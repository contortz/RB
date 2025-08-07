local playerName = game.Players.LocalPlayer.Name
local Workspace = game:GetService("Workspace")
local LocalPlayerBase = nil
local LocalBaseTier = nil

for _, plotModel in ipairs(Workspace.Plots:GetChildren()) do
    local plotSign = plotModel:FindFirstChild("PlotSign")
    if plotSign and plotSign:FindFirstChild("SurfaceGui") then
        local gui = plotSign.SurfaceGui
        local textLabel = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("TextLabel")

        if textLabel and typeof(textLabel.Text) == "string" then
            local baseOwner = textLabel.Text:match("^(.-)'s Base") -- strip "'s Base"

            if baseOwner == playerName then
                LocalPlayerBase = plotModel
                LocalBaseTier = plotModel:GetAttribute("Tier")

                print("✅ Found your base:", plotModel.Name)
                print("🏷️ Tier:", LocalBaseTier)
                break
            end
        end
    end
end
