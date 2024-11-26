local compass = {}
local utils = require("modules.utility.client")
local menuConfig = require("modules.menuConfig.client")

menuConfig:set("isOutCompassChecked", true) -- default value

utils.NuiCallback("showOutCompass", function(data)
    if data.checked then
        menuConfig:set("isOutCompassChecked", true)
    else
        menuConfig:set("isOutCompassChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isCompassFollowChecked", true) -- default value

utils.NuiCallback("showFollowCompass", function(data)
    if data.checked then
        menuConfig:set("isCompassFollowChecked", true)
    else
        menuConfig:set("isCompassFollowChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isCompassShowChecked", true) -- default value

utils.NuiCallback("showCompassBase", function(data)
    if data.checked then
        menuConfig:set("isCompassShowChecked", true)
    else
        menuConfig:set("isCompassShowChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isShowStreetsChecked", true) -- default value

utils.NuiCallback("showStreetsNames", function(data)
    if data.checked then
        menuConfig:set("isShowStreetsChecked", true)
    else
        menuConfig:set("isShowStreetsChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isPointerShowChecked", true) -- default value

utils.NuiCallback("showPointerIndex", function(data)
    if data.checked then
        menuConfig:set("isPointerShowChecked", true)
    else
        menuConfig:set("isPointerShowChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isDegreesShowChecked", true) -- default value

utils.NuiCallback("showDegreesNum", function(data)
    if data.checked then
        menuConfig:set("isDegreesShowChecked", true)
    else
        menuConfig:set("isDegreesShowChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isChangeCompassFPSChecked", true) -- default value

utils.NuiCallback("changeCompassFPS", function(data)
    if data.fps == "optimized" then
        menuConfig:set("isChangeCompassFPSChecked", true)
    else
        menuConfig:set("isChangeCompassFPSChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)


local cachedCompassStats = {
    nil, --[1] show,
    nil, --[2] street1,
    nil, --[3] street2,
    nil, --[4] showCompass,
    nil, --[5] showStreets,
    nil, --[6] showPointer,
    nil  --[7] showDegrees,
}

function compass.hideHud()
    cachedCompassStats[1] = false

    SendNUIMessage({
        action = "baseplate",
        topic = "closecompass",
        show = false,
    })
end

---@param data table<number, any>
function compass.updateHud(data)
    local shouldUpdate = false

    for i = 1, #data do
        if cachedCompassStats[i] ~= data[i] then
            shouldUpdate = true
            break
        end
    end

    if shouldUpdate then
        cachedCompassStats = data

        SendNUIMessage({
            action = "baseplate",
            topic = "opencompass",
            show = true,
            showCompass = true,
        })
        SendNUIMessage({
            action = "baseplate",
            topic = "compassupdate",
            show = data[1],
            street1 = data[2],
            street2 = data[3],
            showCompass = data[4],
            showStreets = data[5],
            showPointer = data[6],
            showDegrees = data[7],
        })
    end
end

local cachedCrossroads = {}
local lastCrossroadsCheckTime = 0

---@param coords vector3
---@return table
function compass.getCrossroadsAtCoords(coords)
    local currentTime = GetGameTimer()

    if (currentTime - lastCrossroadsCheckTime) > 2500 then
        lastCrossroadsCheckTime = currentTime

        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

        cachedCrossroads = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end

    return cachedCrossroads
end

return compass
