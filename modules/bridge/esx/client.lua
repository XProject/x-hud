local framework = {}
local ESX = exports["es_extended"]:getSharedObject()
ESX = {
    GetPlayerData = ESX.GetPlayerData,
    PlayerData = ESX.GetPlayerData(),
    PlayerLoaded = ESX.IsPlayerLoaded()
}
local statuses = {
    hunger = 100,
    thirst = 100,
    stress = 0
}
local esx_status_config_statusmax = 1000000 -- should match the esx_status's Config.StatusMax
local esx_status_multiplier = #tostring(math.floor(esx_status_config_statusmax / 100)) - 1

RegisterNetEvent("esx:playerLoaded", function(playerData)
    ESX.PlayerData = playerData
    ESX.PlayerLoaded = true

    framework.playerLoaded()
end)

RegisterNetEvent("esx:onPlayerLogout", function()
    ESX.PlayerData = {}
    ESX.PlayerLoaded = false

    framework.playerUnloaded()
end)

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias accountData { index: integer, name: string, money: number, label: string, round: boolean }

---@param key string
---@param val any
---@param last any
AddEventHandler("esx:setPlayerData", function(key, val, last)
    if GetInvokingResource() ~= "es_extended" then return end

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
end)

AddEventHandler("esx_status:onTick", function(data)
    for i = 1, #data do
        if statuses[data[i].name] then
            statuses[data[i].name] = data[i].percent
        end
    end
end)

local function registerStatus()
    SetTimeout(0, function()
        TriggerEvent("esx_status:getAllStatus", function(allStatuses)
            local isStressRegistered = false

            for i = 1, #allStatuses do
                if allStatuses[i].name == "stress" then
                    isStressRegistered = true
                    break
                end
            end

            if not isStressRegistered then
                TriggerEvent("esx_status:registerStatus", "stress", 0, "#B81111", function(_)
                    return true
                end, function(status)
                    status.remove(25)
                end)
            end
        end)
    end)
end

AddEventHandler("esx_status:loaded", registerStatus)

do if ESX.PlayerLoaded then registerStatus() end end -- in case this resource was restarted on live server

---@param resource string
local function onResourceStop(resource)
    if resource ~= cache.resource then return end

    TriggerEvent("esx_status:unregisterStatus", "stress") -- to avoid function reference error from esx_status in case this resource was stopped
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)

lib.callback.register(("%s:addStress"):format(cache.resource), function(amount)
    TriggerEvent("esx_status:add", "stress", amount * (10 ^ esx_status_multiplier))
    return true
end)

lib.callback.register(("%s:removeStress"):format(cache.resource), function(amount)
    TriggerEvent("esx_status:remove", "stress", amount * (10 ^ esx_status_multiplier))
    return true
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
