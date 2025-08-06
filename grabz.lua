--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

--// Require Conch UI directly
local ConchUI = require(
    ReplicatedStorage.Packages.Conch[".pesde"]["alicesaidhi+conch_ui"]["0.2.5-rc.1"].conch_ui.src.lib
)

--// Toggle state
local conchMounted = false

--// Button
local ScreenGui = Instance.new("ScreenGui", CoreGui)
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 180, 0, 40)
ToggleBtn.Position = UDim2.new(0.4, 0, 0.1, 0)
ToggleBtn.Text = "🖥 Toggle Conch"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)

--// Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    if not conchMounted then
        ConchUI.mount()
        conchMounted = true
    else
        if ConchUI.unmount then
            ConchUI.unmount()
        end
        conchMounted = false
    end
end)
