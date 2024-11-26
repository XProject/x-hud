local framework = {}
local QBCore = exports["qb-core"]:GetCoreObject()
QBCore = {
    Functions = {
        GetPlayer = QBCore.Functions.GetPlayer,
        HasPermission = QBCore.Functions.HasPermission
    }
}

---@param playerId number
---@return table?
function framework.getPlayer(playerId)
    return QBCore.Functions.GetPlayer(playerId)
end

---@param xPlayer table
---@return boolean
local function isStressWhitelistedForPlayer(xPlayer)
    local jobName = xPlayer.PlayerData.job.name
    local jobGrade = xPlayer.PlayerData.job.grade.level
    local potentialGrade = Config.WhitelistedGroupsToGainStress[jobName]

    if potentialGrade then
        return jobGrade >= potentialGrade and xPlayer.PlayerData.job.onduty
    end

    return false
end

---@param playerId number
---@return boolean
function framework.addStressToPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    if isStressWhitelistedForPlayer(xPlayer) then return false end

    local currentStress = xPlayer.PlayerData.metadata["stress"]

    if not currentStress then
        currentStress = 0
        xPlayer.PlayerData.metadata["stress"] = 0
    end

    local newStress = currentStress + amount

    if newStress < 0 then newStress = 0 end
    if newStress > 100 then newStress = 100 end

    xPlayer.Functions.SetMetaData("stress", newStress)
    TriggerClientEvent("hud:client:UpdateStress", playerId, newStress)

    return true
end

---@param playerId number
---@return boolean
function framework.removeStressFromPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    local currentStress = xPlayer.PlayerData.metadata["stress"]

    if not currentStress then
        currentStress = 0
        xPlayer.PlayerData.metadata["stress"] = 0
    end

    local newStress = currentStress - amount

    if newStress < 0 then newStress = 0 end
    if newStress > 100 then newStress = 100 end

    xPlayer.Functions.SetMetaData("stress", newStress)
    TriggerClientEvent("hud:client:UpdateStress", playerId, newStress)

    return true
end

---@param playerId number
---@return number?
function framework.getCashBalance(playerId)
    local xPlayer = framework.getPlayer(playerId)

    return xPlayer and xPlayer.PlayerData.money.cash or 0
end

---@param playerId number
---@return number?
function framework.getBankBalance(playerId)
    local xPlayer = framework.getPlayer(playerId)

    return xPlayer and xPlayer.PlayerData.money.bank or 0
end

---@param playerId number | string
---@param adminRank string
---@return boolean
function framework.hasAdminPermission(playerId, adminRank)
    return QBCore.Functions.HasPermission(playerId, adminRank) or IsPlayerAceAllowed(tostring(playerId), "command")
end

return framework
