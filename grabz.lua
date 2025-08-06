local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the Conch UI module from the correct location
local conch = require(
    ReplicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Net")
        :WaitForChild("alicesaidhi+conch_ui")
        :WaitForChild("0.2.5-rc.1")
        :WaitForChild("conch_ui")
        :WaitForChild("src")
        :WaitForChild("lib")
)

-- Mount the UI
conch.mount()
