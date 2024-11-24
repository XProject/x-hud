local framework = {}
local playerData = {}
local QBCore = exports["qb-core"]:GetCoreObject()
QBCore = {
    Functions = {
        GetPlayerData = QBCore.Functions.GetPlayerData
    }
}

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    playerData = QBCore.Functions.GetPlayerData()

    framework.playerLoaded()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    playerData = {}

    framework.playerUnloaded()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    playerData = val
end)

---@return boolean
function framework.isPlayerLoaded()
    return LocalPlayer.state.isLoggedIn
end

---@return boolean
function framework.isPlayerDead()
    return IsEntityDead(cache.ped) or playerData.metadata?["inlaststand"] or playerData.metadata?["isdead"] or false
end

return framework
