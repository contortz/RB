--// Services
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

--// Get Conch module
local success, conch = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Conch"))
end)

if not success then
    warn("❌ Failed to require Conch module")
    return
end

--// Destroy old UI
if CoreGui:FindFirstChild("ConchExplorerUI") then
    CoreGui.ConchExplorerUI:Destroy()
end

--// Create GUI
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "ConchExplorerUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(0.5, -200, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = "🔧 Conch Function Viewer"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

-- Scrollable list
local scrollingFrame = Instance.new("ScrollingFrame", frame)
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.Size = UDim2.new(1, 0, 1, -70)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollingFrame.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scrollingFrame)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Populate function list
for name, func in pairs(conch) do
    if typeof(func) == "function" then
        local button = Instance.new("TextButton", scrollingFrame)
        button.Size = UDim2.new(1, -10, 0, 30)
        button.Position = UDim2.new(0, 5, 0, 0)
        button.Text = "📋 Copy: " .. name
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.SourceSans
        button.TextSize = 16

        button.MouseButton1Click:Connect(function()
            setclipboard(name)
            StarterGui:SetCore("SendNotification", {
                Title = "Copied",
                Text = name .. " copied to clipboard!",
                Duration = 2
            })
        end)
    end
end

-- Update canvas size
task.wait()
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

-- Mount Conch button
local mountBtn = Instance.new("TextButton", frame)
mountBtn.Size = UDim2.new(1, -10, 0, 30)
mountBtn.Position = UDim2.new(0, 5, 1, -35)
mountBtn.Text = "🚀 Launch conch.mount()"
mountBtn.TextColor3 = Color3.new(1, 1, 1)
mountBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
mountBtn.BorderSizePixel = 0
mountBtn.Font = Enum.Font.SourceSansBold
mountBtn.TextSize = 16

mountBtn.MouseButton1Click:Connect(function()
    if typeof(conch.mount) == "function" then
        pcall(conch.mount)
    else
        warn("conch.mount() is not available")
    end
end)
