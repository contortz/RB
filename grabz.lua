local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ✅ Get conch_ui table (which has .mount and .bind_to methods)
local conch_ui = require(
    ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("Conch")
        :WaitForChild("roblox_packages")
        :WaitForChild(".pesde")
        :WaitForChild("alicesaidhi+conch_ui")
        :WaitForChild("0.2.5-rc.1")
        :WaitForChild("conch")
)

-- ✅ Mount it
local success, err = pcall(function()
    conch_ui.mount()
end)

if success then
    print("✅ Conch UI mounted successfully!")
else
    warn("❌ Failed to mount Conch UI:", err)
end
