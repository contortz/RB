--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

--// Require Conch UI
local ConchUI = require(
    ReplicatedStorage.Packages.Conch
        .roblox_packages["alicesaidhi+conch_ui"]["0.2.5-rc.1"]
        .conch_ui.src.lib
)

--// UI Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 30)
toggleBtn.Position = UDim2.new(0.35, 0, 0.05, 0)
toggleBtn.Text = "🖥 Toggle Conch"
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 130)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Parent = CoreGui

--// Actual Toggle Logic
toggleBtn.MouseButton1Click:Connect(function()
    -- force-mount first
    ConchUI.mount()

    -- flip visibility state
    local opened = ConchUI.opened
    opened(not opened()) -- true ↔ false
end)
