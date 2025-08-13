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

local originalMoveFunction = controls and controls.moveFunction or nil

-- Wrap the original moveFunction to respect FreezeLocalMovement attribute
if controls and originalMoveFunction then
    controls.moveFunction = function(self, moveVector, input)
        -- Check if FreezeLocalMovement attribute is set on controls object
        if not self:GetAttribute("FreezeLocalMovement") then
            -- Call the original move function to allow movement
            originalMoveFunction(self, moveVector, input)
        else
            -- Movement is frozen, so skip calling originalMoveFunction
            -- (You can add optional logic here if needed)
        end
    end
end

function ControlModuleWrapper.RequestMove(_, controlsObj, moveVector, input)
    if not controlsObj:GetAttribute("FreezeLocalMovement") then
        controlsObj:Move(moveVector, input)
    end
end

function ControlModuleWrapper.WaitForCharacter(_, player)
    local character, humanoid, rootPart
    player = player or localPlayer
    while true do
        character, humanoid, rootPart = ControlModuleWrapper.GetCharacter(_, player)
        if character then break end
        task.wait()
    end
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
