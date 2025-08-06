local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch_ui = require(ReplicatedStorage.Packages.Conch["alicesadihi+conch_ui"]["0.2.5-rc.1"].conch_ui)

print("Mount typeof:", typeof(conch_ui.mount))
if typeof(conch_ui.mount) == "function" then
    conch_ui.mount()
else
    warn("conch_ui.mount not callable")
end
