local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch = require(
    ReplicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Conch")
        :WaitForChild("lib")
        :WaitForChild("conch") -- must be a ModuleScript!
)

conch.mount()
