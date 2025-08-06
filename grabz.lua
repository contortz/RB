-- Require Conch UI
local ConchUI = require(ReplicatedStorage.Packages.Conch.roblox_packages.ui)

-- Floating Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
ToggleBtn.Position = UDim2.new(0.85, 0, 0.05, 0) -- top right corner
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Text = "Conch"
ToggleBtn.TextScaled = true
ToggleBtn.Parent = CoreGui

-- Button click toggles Conch UI
local isMounted = false
ToggleBtn.MouseButton1Click:Connect(function()
    if not isMounted then
        ConchUI.mount() -- open console
        isMounted = true
    else
        -- There’s no official close, but we can toggle `opened` state
        ConchUI.opened(not ConchUI.opened())
    end
end)
