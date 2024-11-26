local framework = {}
local playerState = LocalPlayer.state
local playerData = exports["qbx_core"]:GetPlayerData() or {}
local statuses = {
    hunger = playerState.hunger or 100,
    thirst = playerState.thirst or 100,
    stress = playerState.stress or 0
}

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    playerData = exports["qbx_core"]:GetPlayerData()

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
---@param isMinus boolean
RegisterNetEvent("hud:client:OnMoneyChange", function(type, amount, isMinus)
    if amount == 0 then return end

    local cashAmount = playerData.money["cash"]
    local bankAmount = playerData.money["bank"]

    exports[cache.resource]:showMoney(type, amount, cashAmount, bankAmount, isMinus)
end)

AddStateBagChangeHandler("hunger", ("player:%s"):format(serverId), function(_, _, value)
    statuses.hunger = value
end)

AddStateBagChangeHandler("thirst", ("player:%s"):format(serverId), function(_, _, value)
    statuses.thirst = value
end)

AddStateBagChangeHandler("stress", ("player:%s"):format(serverId), function(_, _, value)
    statuses.stress = value
end)

---@return boolean
function framework.isPlayerLoaded()
    return playerState.isLoggedIn
end

---@return boolean
function framework.isPlayerDead()
    return IsEntityDead(cache.ped) or playerData.metadata?["inlaststand"] or playerData.metadata?["isdead"] or false
end

---@return number
function framework.getHunger()
    return statuses.hunger
end

---@return number
function framework.getThirst()
    return statuses.thirst
end

---@return number
function framework.getStress()
    return statuses.stress
end

return framework
