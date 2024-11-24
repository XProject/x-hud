local framework = {}

---@param playerId number | string
---@param adminRank string
---@return boolean
function framework.hasAdminPermission(playerId, adminRank)
    return IsPlayerAceAllowed(tostring(playerId), ("group."):format(adminRank))
end

return framework
