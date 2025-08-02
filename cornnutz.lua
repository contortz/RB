--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🔍 FuseMachine RF Logger"
title.Parent = mainFrame

-- Touch/Mouse Draggable Support
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

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

-- Add log row with copy button
local function addLog(rfName, argsTable)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 25)
    container.BackgroundTransparency = 1
    container.Parent = logBox

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -5, 1, 0) -- 70% for text
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = false
    label.TextSize = 12
    label.Text = "["..rfName.."] Args: "..table.concat(argsTable,", ")
    label.Parent = container

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.3, 0, 1, 0) -- 30% for button
    copyBtn.Position = UDim2.new(0.7, 0, 0, 0)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 12
    copyBtn.Text = "Copy"
    copyBtn.Parent = container

    copyBtn.MouseButton1Click:Connect(function()
        setclipboard(table.concat(argsTable,", "))
    end)

    logBox.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

-- Target RF Paths
local rfNames = {
    "RF/FuseMachine/ConfirmFusion",
    "RF/FuseMachine/ClaimBrainrot",
    "RF/FuseMachine/Delivery",
    "RF/FuseMachine/RemoveBrainrot",
    "RF/FuseMachine/RevealNow"
}

-- Hook RemoteFunctions
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
