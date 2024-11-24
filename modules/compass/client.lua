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
