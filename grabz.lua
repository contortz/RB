local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Full path to the Conch UI module
local conch_ui = require(
    ReplicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Conch")
        :WaitForChild("roblox_packages")
        :WaitForChild(".pesde")
        :WaitForChild("alicesaidhi+conch_ui")
        :WaitForChild("0.2.5-rc.1")
        :WaitForChild("conch")
)

-- Try to mount the UI
local success, err = pcall(function()
    conch_ui.mount()
end)

if success then
    print("✅ Conch UI mounted successfully!")
else
    warn("❌ Failed to mount Conch UI:", err)
end
