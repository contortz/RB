local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the real Conch UI module
local conch_ui = require(ReplicatedStorage.Packages.Conch["alicesaidhi+conch_ui"]["0.2.5-rc.1"].conch_ui)

-- Build basic UI
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ConchLauncher"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(1, -20, 0, 50)
Button.Position = UDim2.new(0, 10, 0, 25)
Button.Text = "Launch Conch"
Button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 16

-- Hook up the actual conch_ui.mount
Button.MouseButton1Click:Connect(function()
    print("Launching conch_ui.mount...")
    local success, err = pcall(function()
        conch_ui.mount()
    end)
    if not success then
        warn("❌ Failed to mount Conch UI:", err)
    end
end)
