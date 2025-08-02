--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FuseLoggerUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 320)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true -- Make it draggable

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🔍 FuseMachine RF Logger"
title.Parent = mainFrame

-- Scrolling Log
local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, -10, 1, -40)
logBox.Position = UDim2.new(0, 5, 0, 35)
logBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
logBox.ScrollBarThickness = 6
logBox.CanvasSize = UDim2.new(0,0,0,0)
logBox.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = logBox
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Utility: Add log line with copy button
local function addLog(rfName, argsTable)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 25)
    container.BackgroundTransparency = 1
    container.Parent = logBox

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = false
    label.TextSize = 14
    label.Text = "["..rfName.."] Args: "..table.concat(argsTable,", ")
    label.Parent = container

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.25, 0, 1, 0)
    copyBtn.Position = UDim2.new(0.75, 0, 0, 0)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 14
    copyBtn.Text = "Copy Args"
    copyBtn.Parent = container

    copyBtn.MouseButton1Click:Connect(function()
        setclipboard(table.concat(argsTable,", "))
    end)

    logBox.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end


local rfNames = {
    "RF/FuseMachine/ConfirmFusion",
    "RF/FuseMachine/ClaimBrainrot",
    "RF/FuseMachine/Delivery",
    "RF/FuseMachine/RemoveBrainrot",
    "RF/FuseMachine/RevealNow"
}

for _, name in ipairs(rfNames) do
    local rf = game.ReplicatedStorage.Packages.Net:FindFirstChild(name)
    if rf and rf:IsA("RemoteFunction") then
        local oldInvoke = rf.InvokeServer
        rf.InvokeServer = function(self, ...)
            local args = {...}
            local argsText = {}
            for _,v in ipairs(args) do
                table.insert(argsText, tostring(v))
            end
            addLog(name, argsText)
            return oldInvoke(self, ...)
        end
    else
        addLog("[Init]", {name.." not found"})
    end
end
