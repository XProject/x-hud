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

RegisterNetEvent("QBCore:Player:SetPlayerData", function(value)
    playerData = value
end)

---@param type string
---@param amount number
---@param action "add" | "remove" | "set"
RegisterNetEvent("QBCore:Client:OnMoneyChange", function(type, amount, action)
    if amount == 0 then return end

    local isMinus = false
    local cashAmount = playerData.money["cash"]
    local bankAmount = playerData.money["bank"]

    if action == "remove" then
        isMinus = true
    end

    exports[cache.resource]:showMoney(type, amount, cashAmount, bankAmount, isMinus)
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
