-- 🛠 SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local localplr = player

-- 🌀 BLUR EFFECT
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0
TweenService:Create(blur, TweenInfo.new(0.5), { Size = 24 }):Play()

-- 🖥 UI LOADER
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "StellarLoader"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundTransparency = 1

local bg = Instance.new("Frame", frame)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
bg.BackgroundTransparency = 1
bg.ZIndex = 0

TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 0.3 }):Play()

-- ✨ LOADING WORD
local word = "STELLAR"
local letters = {}

local function tweenOutAndDestroy()
    for _, label in ipairs(letters) do
        TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1, TextSize = 20 }):Play()
    end
    TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(blur, TweenInfo.new(0.5), { Size = 0 }):Play()
    wait(0.6)
    screenGui:Destroy()
    blur:Destroy()
end

for i = 1, #word do
    local char = word:sub(i, i)
    local label = Instance.new("TextLabel")
    label.Text = char
    label.Font = Enum.Font.GothamBlack
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 1
    label.TextTransparency = 1
    label.TextScaled = false
    label.TextSize = 30
    label.Size = UDim2.new(0, 60, 0, 60)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.new(0.5, (i - (#word / 2 + 0.5)) * 65, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Parent = frame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 160))
    })
    gradient.Rotation = 90
    gradient.Parent = label

    TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0, TextSize = 60 }):Play()
    table.insert(letters, label)
    wait(0.25)
end

wait(2)
tweenOutAndDestroy()

repeat task.wait() until player and player.Character
if not game:IsLoaded() then game.Loaded:Wait() end

-- 📦 LOAD LIBRARIES
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/Lib"))()
local FlagsManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/ConfigManager"))()

-- 🎯 FORCE PREMIUM MODE (No RoleChecker needed)
local function AlwaysPremium()
    return "Premium Version"
end

-- 🛠 MAIN UI
local main = lib:Load({
    Title = MarketplaceService:GetProductInfo(109983668079237).Name ..
            ' 〢 discord.gg/stellar 〢 ' .. AlwaysPremium(),
    ToggleButton = "rbxassetid://105059922903197",
    BindGui = Enum.KeyCode.RightControl,
})

-- 📑 TABS
local tabs = {
    Information = main:AddTab("Information"),
    General = main:AddTab("General"),
    Config = main:AddTab("Config"),
}
main:SelectTab()

-- 📦 SECTIONS (all unlocked, no Locked=true)
local Sections = {
    Welcome = tabs.Information:AddSection({ Defualt = true }),
    Discord = tabs.Information:AddSection({ Defualt = true }),
    Main = tabs.General:AddSection({ Title = "Instant Proximity" }),
    Teleport = tabs.General:AddSection({ Title = "Teleport" }),
    MiscTabs = tabs.General:AddSection({ Title = "Character" }),
    Shop = tabs.General:AddSection({ Title = "Shop" }),
    VisualTabs = tabs.General:AddSection({ Title = "Visual" }),
}

-- 📢 INFO
Sections.Discord:AddParagraph({
    Title = "Found a bug?",
    Description = "Please report by joining our Discord."
})
Sections.Discord:AddButton({
    Title = "Copy Discord Invite",
    Callback = function()
        setclipboard("https://discord.gg/FmMuvkaWvG")
        lib:Notification("Discord", "Copied invite to clipboard.", 5)
    end,
})
Sections.Welcome:AddParagraph({
    Title = "Information",
    Description = "Welcome to StellarHub Premium! All features unlocked."
})
