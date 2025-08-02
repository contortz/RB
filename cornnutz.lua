--// Setup
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FuseLoggerUI"
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui

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

-- Utility: Add log line
local function addLog(message)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = message
    label.Parent = logBox

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

-- Hook Each
for _, name in ipairs(rfNames) do
    local rf = game.ReplicatedStorage.Packages.Net:FindFirstChild(name)
    if rf and rf:IsA("RemoteFunction") then
        local oldInvoke = rf.InvokeServer
        rf.InvokeServer = function(self, ...)
            local args = {...}
            local argsText = ""
            for i,v in ipairs(args) do
                argsText = argsText .. tostring(v) .. (i < #args and ", " or "")
            end
            addLog("["..name.."] Args: "..argsText)
            return oldInvoke(self, ...)
        end
    else
        addLog("[!] Could not find: "..name)
    end
end
