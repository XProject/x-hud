local framework = {}
local playerState = LocalPlayer.state
local ESX = lib.load("@es_extended.imports")
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

eventHandler("esx:playerLoaded", function() framework.playerLoaded() end)
eventHandler("esx:onPlayerLogout", function() framework.playerUnloaded() end)

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias accountData { index: integer, name: string, money: number, label: string, round: boolean }

---@param key string
---@param val any
---@param last any
OnPlayerData = function(key, val, last) -- triggered in es_extended/imports.lua
    ESX.PlayerData[key] = val

    if key ~= "accounts" then return end
    ---@cast val accountData[]
    ---@cast last accountData[]

    ---TODO: technically the account index should remain the same, meaning we might be able to use 1 loop only instead of 2!
    local currentCash, currentBank
    local previousCash, previousBank

    for i = 1, #val do
        if val[i].name == "money" then
            currentCash = val[i].money
        elseif last[i].name == "bank" then
            currentBank = val[i].money
        end
    end

    for i = 1, #last do
        if last[i].name == "money" then
            previousCash = last[i].money
        elseif last[i].name == "bank" then
            previousBank = last[i].money
        end
    end

    if not currentCash or not currentBank or not previousCash or not previousBank then return end

    if currentCash ~= previousCash then
        local isCurrentHigher = currentCash > previousCash
        local difference = isCurrentHigher and (currentCash - previousCash) or (previousCash - currentCash)

        return exports[cache.resource]:showMoney("cash", difference, currentCash, currentBank, not isCurrentHigher)
    elseif currentBank ~= previousBank then
        local isCurrentHigher = currentBank > previousBank
        local difference = isCurrentHigher and (currentBank - previousBank) or (previousBank - currentBank)

        return exports[cache.resource]:showMoney("bank", difference, currentCash, currentBank, not isCurrentHigher)
    end
end

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
    return ESX.PlayerData.dead or false
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
