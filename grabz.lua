--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

--// Conch UI
local ConchUI = require(
    ReplicatedStorage.Packages.Conch
        .roblox_packages["alicesaidhi+conch_ui"]["0.2.5-rc.1"]
        .conch_ui.src.lib
)

--// State
local conchOpen = false

--// Create Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 150, 0, 30)
ToggleBtn.Position = UDim2.new(0.4, 0, 0.05, 0)
ToggleBtn.Text = "🖥 Toggle Conch"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Parent = CoreGui

--// Toggle Function
ToggleBtn.MouseButton1Click:Connect(function()
    conchOpen = not conchOpen
    if conchOpen then
        ConchUI.mount()
    else
        -- If Conch has a close/unmount, call it here
        if ConchUI.close then
            ConchUI.close()
        elseif ConchUI.unmount then
            ConchUI.unmount()
        else
            warn("⚠ No close function in ConchUI, might stay open")
        end
    end
end)
