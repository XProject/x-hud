local framework = {}
local ESX = lib.load("@es_extended.imports")

---@param playerId number
---@return table?
function framework.getPlayer(playerId)
    return ESX.GetPlayerFromId(playerId)
end

---@param playerId number
---@return boolean
function framework.addStressToPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    if next(Config.WhitelistedGroupsToGainStress) and xPlayer.canInteractWithGroup(Config.WhitelistedGroupsToGainStress) then return false end

    return exports["esx_status"]:increasePlayerStatus(playerId, "stress", amount)
end

---@param playerId number
---@return boolean
function framework.removeStressFromPlayer(playerId, amount)
    local xPlayer = framework.getPlayer(playerId)

    if not xPlayer then return false end

    return exports["esx_status"]:decreasePlayerStatus(playerId, "stress", amount)
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
    return IsPlayerAceAllowed(tostring(playerId), ("group."):format(adminRank))
end

return framework
