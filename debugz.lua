local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages.Signal)

local localPlayer = Players.LocalPlayer

local controls
if RunService:IsClient() then
    local playerScripts = localPlayer:WaitForChild("PlayerScripts")
    controls = require(playerScripts:WaitForChild("PlayerModule")):GetControls()
else
    controls = nil
end

local ControlModuleWrapper = {
    OnCharacterAdded = Signal.new(),
    OnSetCFrame = Signal.new()
}

if not controls then
    warn("[ControlModuleWrapper] Controls not found, aborting moveFunction override")
    return ControlModuleWrapper
end

local originalMoveFunction = controls.moveFunction
if not originalMoveFunction then
    warn("[ControlModuleWrapper] Original moveFunction not found!")
    return ControlModuleWrapper
end

print("[ControlModuleWrapper] Wrapping moveFunction")

-- Wrap moveFunction to allow toggling movement freeze
controls.moveFunction = function(self, moveVector, input)
    local freeze = self:GetAttribute and self:GetAttribute("FreezeLocalMovement")
    if freeze then
        -- Movement frozen: do not call originalMoveFunction
        -- Debug print so we know this is triggered
        -- print("[ControlModuleWrapper] Movement frozen, skipping moveFunction call")
        return
    else
        -- Movement allowed: call original move function
        originalMoveFunction(self, moveVector, input)
    end
end

function ControlModuleWrapper.RequestMove(_, controlsObj, moveVector, input)
    local freeze = controlsObj:GetAttribute and controlsObj:GetAttribute("FreezeLocalMovement")
    if not freeze then
        controlsObj:Move(moveVector, input)
    end
end

function ControlModuleWrapper.WaitForCharacter(_, player)
    player = player or localPlayer
    local character, humanoid, rootPart
    repeat
        character, humanoid, rootPart = ControlModuleWrapper.GetCharacter(_, player)
        task.wait()
    until character
    return character, humanoid, rootPart
end

function ControlModuleWrapper.GetCharacter(_, player)
    player = player or localPlayer
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            return character, humanoid, rootPart
        end
    end
    return nil
end

function ControlModuleWrapper.SetCFrame(_, cf)
    local character, _, rootPart = ControlModuleWrapper.GetCharacter()
    if character and rootPart then
        rootPart.CFrame = cf
        ControlModuleWrapper.OnSetCFrame:Fire(cf)
    end
end

function ControlModuleWrapper.Start(_)
    local defaultHipHeight = 2.08

    local function onCharacterAdded(character)
        workspace.Gravity = 196.2
        ControlModuleWrapper.OnCharacterAdded:Fire(character)

        local humanoid = character:WaitForChild("Humanoid")
        if humanoid then
            defaultHipHeight = humanoid.HipHeight

            local jumpCount = 0
            humanoid.StateChanged:Connect(function(oldState, newState)
                if humanoid.Health > 0 then
                    if (oldState == Enum.HumanoidStateType.Jumping and newState == Enum.HumanoidStateType.Jumping) or
                       (oldState == Enum.HumanoidStateType.Freefall and newState == Enum.HumanoidStateType.Jumping) then
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
    end

    localPlayer.CharacterAdded:Connect(onCharacterAdded)
    if localPlayer.Character then
        task.spawn(onCharacterAdded, localPlayer.Character)
    end

    RunService.PreSimulation:Connect(function()
        local character, humanoid = ControlModuleWrapper.GetCharacter()
        if character and humanoid then
            humanoid.HipHeight = defaultHipHeight
        end
    end)
end

return ControlModuleWrapper
