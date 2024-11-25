local framework = {}
local QBCore = exports["qb-core"]:GetCoreObject()
QBCore = {
    Functions = {
        GetPlayerData = QBCore.Functions.GetPlayerData
    }
}
local playerState = LocalPlayer.state
local playerData = QBCore.Functions.GetPlayerData() or {}
local statuses = {
    hunger = playerData.metadata and playerData.metadata.hunger or 100,
    thirst = playerData.metadata and playerData.metadata.thirst or 100,
    stress = playerData.metadata and playerData.metadata.stress or 0
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
---@param isMinus boolean
RegisterNetEvent("hud:client:OnMoneyChange", function(type, amount, isMinus)
    if amount == 0 then return end

    local cashAmount = playerData.money["cash"]
    local bankAmount = playerData.money["bank"]

    exports[cache.resource]:showMoney(type, amount, cashAmount, bankAmount, isMinus)
end)

RegisterNetEvent("hud:client:UpdateNeeds", function(newHunger, newThirst)
    statuses.hunger = newHunger
    statuses.thirst = newThirst
end)

RegisterNetEvent("hud:client:UpdateStress", function(newStress)
    statuses.stress = newStress
end)

--[[ -- add these to qbox bridge
AddStateBagChangeHandler("hunger", ("player:%s"):format(serverId), function(_, _, value)
    hunger = value
end)

AddStateBagChangeHandler("thirst", ("player:%s"):format(serverId), function(_, _, value)
    thirst = value
end)

AddStateBagChangeHandler("stress", ("player:%s"):format(serverId), function(_, _, value)
    stress = value
end)
]]

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
