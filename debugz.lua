local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages.Signal)

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer.PlayerScripts

local controls = nil
if RunService:IsClient() then
    controls = require(playerScripts:WaitForChild("PlayerModule")):GetControls()
else
    controls = nil
end

local ControlModuleWrapper = {
    OnCharacterAdded = Signal.new(),
    OnSetCFrame = Signal.new(),
}

local originalMoveFunction = nil
if controls then
    originalMoveFunction = controls.moveFunction
else
    originalMoveFunction = nil
end

ControlModuleWrapper.originalMoveFunction = originalMoveFunction

-- Override moveFunction to call our RequestMove
if controls then
    function controls.moveFunction(self, p12, p13)
        ControlModuleWrapper:RequestMove(p12, p13, p13) -- p12, p13 passed, just forwarding
    end
    ControlModuleWrapper.originalMoveFunction = controls.moveFunction
end

function ControlModuleWrapper:RequestMove(p14, p15, p16)
    if not p14:GetAttribute("FreezeLocalMovement") then
        p14:Move(p15, p16)
    end
end

function ControlModuleWrapper:WaitForCharacter(player)
    local character, humanoid, rootPart = nil, nil, nil
    while not character do
        character, humanoid, rootPart = self:GetCharacter(player)
        task.wait()
    end
    return character, humanoid, rootPart
end

function ControlModuleWrapper:GetCharacter(player)
    player = player or localPlayer
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                return character, humanoid, rootPart
            end
        end
    end
end

function ControlModuleWrapper:SetCFrame(cframe)
    local character, humanoid, rootPart = self:GetCharacter()
    if character and rootPart then
        rootPart.CFrame = cframe
        self.OnSetCFrame:Fire(cframe)
    end
end

-- ========== OUR TOGGLE VARIABLES ===========
local speedToggled = false
local jumpToggled = false

local DEFAULT_WALK_SPEED = 16
local BOOSTED_WALK_SPEED = 50

local DEFAULT_JUMP_POWER = 50
local BOOSTED_JUMP_POWER = 100

local currentHipHeight = 2.08
local currentHumanoid = nil

-- Function to apply speed and jump settings to humanoid
local function ApplyCurrentSettings()
    if currentHumanoid then
        currentHumanoid.WalkSpeed = speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED
        currentHumanoid.JumpPower = jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER
    end
end

-- Character added handler (also sets current humanoid)
local function OnCharacterAdded(character)
    ControlModuleWrapper.OnCharacterAdded:Fire(character)

    local humanoid = character:WaitForChild("Humanoid")
    currentHipHeight = humanoid.HipHeight
    currentHumanoid = humanoid

    -- Apply toggled speed/jump on new character
    ApplyCurrentSettings()

    -- Anti-cheat jump limiter logic from original
    local jumpCount = 0
    humanoid.StateChanged:Connect(function(oldState, newState)
        if humanoid.Health > 0 then
            if (oldState == Enum.HumanoidStateType.Jumping and newState == Enum.HumanoidStateType.Jumping)
            or (oldState == Enum.HumanoidStateType.Freefall and newState == Enum.HumanoidStateType.Jumping) then
                jumpCount = jumpCount + 1
                task.delay(60, function()
                    jumpCount = jumpCount - 1
                end)
                if jumpCount >= 5 then
                    humanoid.Health = 0
                end
            end
        end
    end)
end

-- Setup character added connections
local function Start()
    workspace.Gravity = 196.2 -- original script sets gravity to 196.2

    localPlayer.CharacterAdded:Connect(OnCharacterAdded)
    if localPlayer.Character then
        task.spawn(OnCharacterAdded, localPlayer.Character)
    end

    RunService.PreSimulation:Connect(function()
        local character, humanoid, rootPart = ControlModuleWrapper:GetCharacter()
        if character and humanoid and rootPart then
            humanoid.HipHeight = currentHipHeight
        end
    end)
end

-- Listen for user input to toggle speed and jump boosts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.K then
            speedToggled = not speedToggled
            ApplyCurrentSettings()
            print("Speed toggled. Now:", speedToggled and BOOSTED_WALK_SPEED or DEFAULT_WALK_SPEED)
        elseif input.KeyCode == Enum.KeyCode.L then
            jumpToggled = not jumpToggled
            ApplyCurrentSettings()
            print("Jump toggled. Now:", jumpToggled and BOOSTED_JUMP_POWER or DEFAULT_JUMP_POWER)
        end
    end
end)

-- Start the module
Start()

return ControlModuleWrapper
