local utils = require("modules.utility.client")
local menuConfig = require("modules.menuConfig.client")

-- Open/Close sound of the hud menu

menuConfig:set("isOpenMenuSoundsChecked", true) -- default value

utils.NuiCallback("openMenuSounds", function(data)
    if data.checked then
        menuConfig:set("isOpenMenuSoundsChecked", true)
    else
        menuConfig:set("isOpenMenuSoundsChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playOpenMenuSounds", function()
    if not menuConfig:get("isOpenMenuSoundsChecked") then return end

    TriggerServerEvent("InteractSound_SV:PlayOnSource", "monkeyopening", 0.5)
end)

RegisterNetEvent("hud:client:playCloseMenuSounds", function()
    if not menuConfig:get("isOpenMenuSoundsChecked") then return end

    TriggerServerEvent("InteractSound_SV:PlayOnSource", "catclosing", 0.05)
end)


-- Reset sound of the hud settings

menuConfig:set("isResetSoundsChecked", true) -- default value

utils.NuiCallback("resetHudSounds", function(data)
    if data.checked then
        menuConfig:set("isResetSoundsChecked", true)
    else
        menuConfig:set("isResetSoundsChecked", false)
    end

    TriggerEvent("hud:client:playResetHudSounds")
end)

RegisterNetEvent("hud:client:playResetHudSounds", function()
    if not menuConfig:get("isResetSoundsChecked") then return end

    TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
end)


-- Interaction sound of the hud checklist buttons

menuConfig:set("isListSoundsChecked", true) -- default value

utils.NuiCallback("checklistSounds", function(data)
    if data.checked then
        menuConfig:set("isListSoundsChecked", true)
    else
        menuConfig:set("isListSoundsChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playHudChecklistSound", function()
    if not menuConfig:get("isListSoundsChecked") then return end

    TriggerServerEvent("InteractSound_SV:PlayOnSource", "shiftyclick", 0.5)
end)
