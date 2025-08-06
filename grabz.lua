--// Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Require Conch main lib
local ConchLib = require(ReplicatedStorage.Packages.Conch.lib)

-- Track if UI is mounted
local conchMounted = false

--// GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ConchToggleGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 60)
Frame.Position = UDim2.new(0.3, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(1, -10, 1, -10)
Button.Position = UDim2.new(0, 5, 0, 5)
Button.Text = "🖥 Toggle Conch UI"
Button.BackgroundColor3 = Color3.fromRGB(80, 80, 20)
Button.TextColor3 = Color3.new(1, 1, 1)

--// Toggle logic
Button.MouseButton1Click:Connect(function()
    if not conchMounted then
        pcall(function()
            ConchLib.mount() -- Mount Conch UI into PlayerGui
            print("✅ Conch UI Mounted")
        end)
        conchMounted = true
    else
        -- If Conch supports unmount (not always available)
        if ConchLib.unmount then
            pcall(function()
                ConchLib.unmount()
                print("❌ Conch UI Unmounted")
            end)
        else
            warn("⚠ No unmount method found — UI may persist")
        end
        conchMounted = false
    end
end)
