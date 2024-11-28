local framework = {}
local playerState = LocalPlayer.state
local ESX = exports["es_extended"]:getSharedObject()
ESX = {
    GetPlayerData = ESX.GetPlayerData,
    PlayerData = ESX.GetPlayerData(),
    PlayerLoaded = ESX.IsPlayerLoaded()
}
local statuses = {
    hunger = playerState.hunger or 100,
    thirst = playerState.thirst or 100,
    stress = playerState.stress or 0
}

local getInvokingResource = GetInvokingResource

---@param eventName string
---@param cb function
local function eventHandler(eventName, cb)
    AddEventHandler(eventName, function(...)
        local invokingResource = getInvokingResource()

        if invokingResource == "es_extended" then
            return cb(...)
        end

        lib.print.error(("Event (%s) was triggered, but not from the framework! Invoked from (%s)"):format(eventName, invokingResource))
    end)
end

eventHandler("esx:playerLoaded", function(playerData)
    ESX.PlayerData = playerData
    ESX.PlayerLoaded = true

    framework.playerLoaded()
end)

eventHandler("esx:onPlayerLogout", function()
    playerData = {}
    ESX.PlayerLoaded = false

    framework.playerUnloaded()
end)

eventHandler("esx:setPlayerData", function(key, val, last)
    ESX.PlayerData[key] = val

    if key ~= "accounts" then return end

    ---TODO
    -- if amount == 0 then return end

    -- local cashAmount = playerData.money["cash"]
    -- local bankAmount = playerData.money["bank"]

    -- exports[cache.resource]:showMoney(type, amount, cashAmount, bankAmount, isMinus)
end)

AddStateBagChangeHandler("hunger", ("player:%s"):format(cache.serverId), function(_, _, value)
    statuses.hunger = value
end)

AddStateBagChangeHandler("thirst", ("player:%s"):format(cache.serverId), function(_, _, value)
    statuses.thirst = value
end)

AddStateBagChangeHandler("stress", ("player:%s"):format(cache.serverId), function(_, _, value)
    statuses.stress = value
end)

---@return boolean
function framework.isPlayerLoaded()
    return ESX.PlayerLoaded
end

---@return boolean
function framework.isPlayerDead()
    return ESX.PlayerData?.dead or false
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
