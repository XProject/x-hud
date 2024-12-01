local framework = {}
local ESX = exports["es_extended"]:getSharedObject()
ESX = {
    GetPlayerFromId = ESX.GetPlayerFromId
}

---@param playerId number
---@return table?
function framework.getPlayer(playerId)
    return ESX.GetPlayerFromId(playerId)
end

---@param xPlayer table
---@return boolean
local function isStressWhitelistedForPlayer(xPlayer)
    local jobName = xPlayer.job.name
    local jobGrade = xPlayer.job.grade
    local potentialGrade = Config.WhitelistedGroupsToGainStress[jobName]

    if potentialGrade then
        return jobGrade >= potentialGrade and xPlayer.job.onDuty
    end

    return false
end

local addStressEvent = ("%s:addStress"):format(cache.resource)

---@param playerId number
---@return boolean
function framework.addStressToPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    if isStressWhitelistedForPlayer(xPlayer) then return false end

    return lib.callback.await(addStressEvent, playerId, amount)
end

local removeStressEvent = ("%s:removeStress"):format(cache.resource)

---@param playerId number
---@return boolean
function framework.removeStressFromPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    return lib.callback.await(removeStressEvent, playerId, amount)
end

---@param playerId number
---@return number?
function framework.getCashBalance(playerId)
    local xPlayer = framework.getPlayer(playerId)

    if xPlayer then
        for i = 1, #xPlayer.accounts do
            if xPlayer.accounts[i].name == "money" then
                return xPlayer.accounts[i].money
            end
        end
    end

    return 0
end

---@param playerId number
---@return number?
function framework.getBankBalance(playerId)
    local xPlayer = framework.getPlayer(playerId)

    if xPlayer then
        for i = 1, #xPlayer.accounts do
            if xPlayer.accounts[i].name == "bank" then
                return xPlayer.accounts[i].money
            end
        end
    end

    return 0
end

---@param playerId number | string
---@param adminRank string
---@return boolean
function framework.hasAdminPermission(playerId, adminRank)
    return IsPlayerAceAllowed(tostring(playerId), adminRank) or IsPlayerAceAllowed(tostring(playerId), "command")
end

return framework
