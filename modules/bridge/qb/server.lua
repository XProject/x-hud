local framework = {}
local QBCore = exports["qb-core"]:GetCoreObject()
QBCore = {
    Functions = {
        HasPermission = QBCore.Functions.HasPermission
    }
}

---@param playerId number | string
---@param adminRank string
---@return boolean
function framework.hasAdminPermission(playerId, adminRank)
    return QBCore.Functions.HasPermission(playerId, adminRank) or IsPlayerAceAllowed(tostring(playerId), "command")
end

return framework
