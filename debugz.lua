--[[ 
Movement Clamp Auditor (Client-side, read-only)
- In Studio: scans script Source in replicated containers for keywords (WalkSpeed, JumpPower, CFrame, etc.)
- In Live Play: scans names/types only (no Source access)
- Always: lists remotes that look movement-related

Place as a LocalScript for Studio testing your own place.
This does NOT read ServerScriptService/ServerStorage (not replicated).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local StarterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer
local IS_STUDIO = RunService:IsStudio()

-- ========= UI =========
local gui = Instance.new("ScreenGui")
gui.Name = "MovementClampAuditor"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local frame = Instance.new("Frame", gui)
frame.Name = "Main"
frame.Size = UDim2.new(0, 600, 0, 420)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(24,24,28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local header = Instance.new("TextLabel", frame)
header.Size = UDim2.new(1, -10, 0, 32)
header.Position = UDim2.new(0, 10, 0, 8)
header.BackgroundTransparency = 1
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamSemibold
header.TextSize = 18
header.TextColor3 = Color3.new(1,1,1)
header.Text = "Movement Clamp Auditor  •  "..(IS_STUDIO and "Studio: deep scan" or "Live: shallow scan")

local rescan = Instance.new("TextButton", frame)
rescan.Size = UDim2.new(0, 100, 0, 28)
rescan.Position = UDim2.new(1, -110, 0, 10)
rescan.BackgroundColor3 = Color3.fromRGB(48,48,56)
rescan.TextColor3 = Color3.new(1,1,1)
rescan.BorderSizePixel = 0
rescan.AutoButtonColor = true
rescan.Font = Enum.Font.GothamSemibold
rescan.TextSize = 14
rescan.Text = "Rescan"

local list = Instance.new("ScrollingFrame", frame)
list.Name = "Results"
list.Size = UDim2.new(1, -20, 1, -60)
list.Position = UDim2.new(0, 10, 0, 50)
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(30,30,36)
list.BorderSizePixel = 0
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 6)

local function addLine(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 24)
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = 14
    l.TextWrapped = false
    l.TextColor3 = color or Color3.fromRGB(200, 230, 255)
    l.Text = text
    l.Parent = list
end

local function clearList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end

-- ========= Scan config =========

-- Names or substrings that often indicate movement/server checks or speed logic
local REMOTE_NAME_HINTS = {
    "move", "speed", "walk", "run", "sprint", "dash", "jump", "teleport", "tp",
    "root", "humanoid", "character", "anticheat", "antiexploit", "noclip"
}

-- Source keywords we’ll search when in Studio
local SOURCE_KEYWORDS = {
    "WalkSpeed", "JumpPower", "UseJumpPower", "HipHeight",
    "HumanoidRootPart", "RootPart", "CFrame", "Velocity",
    "GetPropertyChangedSignal", "Running", "MoveDirection",
    "PathfindingService", "Humanoid:MoveTo", "Seat", "Seated",
    "Heartbeat", "Stepped", "RenderStepped", "delta", "magnitude >",
    "teleport", "SetPrimaryPartCFrame", "PivotTo"
}

-- Containers we can actually see on the client
local SCAN_CONTAINERS = {
    RS,
    game:GetService("StarterGui"),
    StarterPlayerScripts,
    StarterCharacterScripts,
    game:GetService("ReplicatedFirst"),
    workspace -- sometimes devs put shared modules here
}

-- ========= Utilities =========

local function anyMatch(str, needles)
    str = string.lower(str)
    for _, n in ipairs(needles) do
        if string.find(str, string.lower(n), 1, true) then
            return true
        end
    end
    return false
end

local function tryGetSource(scr)
    -- Source is only readable in Studio (proper security context)
    if not IS_STUDIO then return nil end
    local ok, src = pcall(function() return scr.Source end)
    if ok and typeof(src) == "string" then return src end
    return nil
end

-- ========= Scanner =========

local function scan()
    clearList()

    addLine("▼ Remotes that look movement-related", Color3.fromRGB(255, 220, 140))
    local remoteCount = 0
    for _, container in ipairs(SCAN_CONTAINERS) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                local className = obj.ClassName
                if className == "RemoteEvent" or className == "RemoteFunction" then
                    if anyMatch(obj.Name, REMOTE_NAME_HINTS) then
                        remoteCount = remoteCount + 1
                        addLine(("[%d] %s (%s)"):format(remoteCount, obj:GetFullName(), className))
                    end
                end
            end
        end
    end
    if remoteCount == 0 then
        addLine("(none found)")
    end

    addLine("", Color3.new(1,1,1))
    addLine("▼ Possible config values in replicated containers", Color3.fromRGB(255, 220, 140))
    local configCount = 0
    local function maybeConfig(val)
        local lower = val.Name:lower()
        if lower:find("speed") or lower:find("jump") or lower:find("walk")
            or lower:find("run") or lower:find("sprint") then
            return true
        end
        return false
    end
    for _, container in ipairs(SCAN_CONTAINERS) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("BoolValue") then
                    if maybeConfig(obj) then
                        configCount = configCount + 1
                        local v = (obj:IsA("BoolValue") and tostring(obj.Value)) or tostring(obj.Value)
                        addLine(("[%d] %s  =  %s"):format(configCount, obj:GetFullName(), v))
                    end
                end
            end
        end
    end
    if configCount == 0 then
        addLine("(none found)")
    end

    addLine("", Color3.new(1,1,1))
    addLine("▼ Script sources mentioning movement keywords"..(IS_STUDIO and "" or " (Studio-only)"), Color3.fromRGB(255, 220, 140))
    local hitCount = 0
    for _, container in ipairs(SCAN_CONTAINERS) do
        if container then
            for _, scr in ipairs(container:GetDescendants()) do
                if scr:IsA("LocalScript") or scr:IsA("ModuleScript") or scr.ClassName == "Script" then
                    -- Avoid trying to read server Scripts in live games (not present anyway)
                    local src = tryGetSource(scr)
                    if src then
                        local lowered = src:lower()
                        local matched = false
                        for _, kw in ipairs(SOURCE_KEYWORDS) do
                            if lowered:find(kw:lower(), 1, true) then
                                matched = true
                                break
                            end
                        end
                        if matched then
                            hitCount = hitCount + 1
                            addLine(("[%d] %s"):format(hitCount, scr:GetFullName()), Color3.fromRGB(180, 220, 255))
                        end
                    end
                end
            end
        end
    end
    if hitCount == 0 then
        addLine(IS_STUDIO and "(no keyword hits in replicated scripts)" or "(cannot read Source outside Studio)")
    end

    addLine("", Color3.new(1,1,1))
    addLine("Notes:", Color3.fromRGB(255, 180, 180))
    addLine("- ServerScriptService/ServerStorage are not visible to clients; any true clamp likely runs there.")
    addLine("- Results show *interfaces* (remotes) and *client/shared* code only.")
    addLine("- For definitive auditing, open your place in Studio and search ServerScriptService.")
end

rescan.MouseButton1Click:Connect(scan)
scan()
