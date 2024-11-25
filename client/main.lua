local serverId = GetPlayerServerId(PlayerId())
local UIConfig = UIConfig
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local next = next
local nos = 0
local nitroActive = 0
local harness = false
local hp = 100
local dev = false
local isAdmin = false
local isMenuShowing = false
local radioTalking = false


local sound = require("modules.sound.client")
local radar = require("modules.radar.client")
local utils = require("modules.utility.client")
local player = require("modules.player.client")
local status = require("modules.status.client")
local framework = require("modules.bridge.main")
local vehicle = require("modules.vehicle.client")
local seatbelt = require("modules.seatbelt.client")
local menuConfig = require("modules.menuConfig.client")

radar.toggleMinimap(false)

RegisterNetEvent("hud:client:LoadMap", radar.loadMap)

local function loadRadar()
    if radar.loadMap() then
        Wait(1000)
        utils.showNotification(locale("hud_settings_loaded"))
    else
        lib.print.error("Radar could not be loaded!")
    end
end

local function sendAdminStatus()
    SendNUIMessage({
        action = "menu",
        topic = "adminonly",
        adminOnly = Config.AdminOnly,
        isAdmin = isAdmin,
    })
end

local function sendUIUpdateMessage(data)
    SendNUIMessage({
        action = "updateUISettings",
        icons = data.icons,
        layout = data.layout,
        colors = data.colors,
    })
end

local function sendUILang()
    SendNUIMessage({
        action = "setLang",
        lang = GetConvar("ox:locale", "en")
    })
end

local function setupResource()
    if lib.callback.await("hud:server:getRank", false) then
        isAdmin = true
    else
        isAdmin = false
    end

    sendUILang()
    sendAdminStatus()

    if Config.AdminOnly then
        -- Send the client what the saved ui config is (enforced by the server)
        if next(UIConfig) then
            sendUIUpdateMessage(UIConfig)
        end
    end

    loadRadar()
end

---Setup the resource on resource restart on live server
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= cache.resource then return end

    Wait(1000)

    if framework.isPlayerLoaded() then
        framework.playerLoaded()
    end
end)

AddEventHandler("pma-voice:radioActive", function(isRadioTalking)
    radioTalking = isRadioTalking
end)

local function hudSettingsMenu()
    if isMenuShowing then return end

    isMenuShowing = true

    TriggerEvent("hud:client:playOpenMenuSounds")

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end

lib.addKeybind({
    name = "hud_menu",
    description = locale("open_menu"),
    defaultKey = Config.OpenMenu,
    defaultMapper = "keyboard",
    onPressed = hudSettingsMenu,
})

utils.NuiCallback("closeMenu", function()
    TriggerEvent("hud:client:playCloseMenuSounds")

    isMenuShowing = false
    SetNuiFocus(false, false)
end)

local function restartHud()
    TriggerEvent("hud:client:playResetHudSounds")

    utils.showNotification(locale("hud_restart"))

    Wait(1500)

    SendNUIMessage({
        action = "car",
        topic = "display",
        show = false,
        seatbelt = false,
    })

    if cache.vehicle then
        Wait(500)

        SendNUIMessage({
            action = "car",
            topic = "display",
            show = true,
            seatbelt = false,
        })
    end

    SendNUIMessage({
        action = "hudtick",
        topic = "display",
        show = false,
    })

    Wait(500)

    SendNUIMessage({
        action = "hudtick",
        topic = "display",
        show = true,
    })

    Wait(500)

    SendNUIMessage({
        action = "menu",
        topic = "restart",
    })

    utils.showNotification(locale("hud_start"))
end

utils.NuiCallback("restartHud", function()
    restartHud()
end)

RegisterCommand("resethud", function()
    restartHud()
end, false)

utils.NuiCallback("resetStorage", function()
    TriggerEvent("hud:client:resetStorage")
end)

RegisterNetEvent("hud:client:resetStorage", function()
    TriggerEvent("hud:client:playResetHudSounds")

    loadRadar()
end)

utils.NuiCallback("saveUISettings", function(data)
    TriggerEvent("hud:client:playHudChecklistSound")
    TriggerServerEvent("hud:server:saveUIData", data)
end)

utils.NuiCallback("dynamicChange", function()
    TriggerEvent("hud:client:playHudChecklistSound")
end)

utils.NuiCallback("updateMenuSettingsToClient", function(data)
    -- radar
    menuConfig:set("isOutMapChecked", data.isOutMapChecked)
    menuConfig:set("isMapNotifChecked", data.isMapNotifyChecked)
    menuConfig:set("isMapEnabledChecked", data.isMapEnabledChecked)
    menuConfig:set("isCineamticModeChecked", data.isCineamticModeChecked)
    menuConfig:set("isToggleMapShapeChecked", data.isToggleMapShapeChecked)
    menuConfig:set("isCinematicNotifChecked", data.isCinematicNotifyChecked)
    menuConfig:set("isToggleMapBordersChecked", data.isToggleMapBordersChecked)
    radar.cinematicMode(data.isCineamticModeChecked)

    -- sounds
    menuConfig:set("isListSoundsChecked", data.isListSoundsChecked)
    menuConfig:set("isOutCompassChecked", data.isOutCompassChecked)
    menuConfig:set("isResetSoundsChecked", data.isResetSoundsChecked)
    menuConfig:set("isOpenMenuSoundsChecked", data.isOpenMenuSoundsChecked)

    -- compass
    menuConfig:set("isCompassShowChecked", data.isShowCompassChecked)
    menuConfig:set("isShowStreetsChecked", data.isShowStreetsChecked)
    menuConfig:set("isPointerShowChecked", data.isPointerShowChecked)
    menuConfig:set("isCompassFollowChecked", data.isCompassFollowChecked)

    -- fuel
    menuConfig:set("isLowFuelChecked", data.isLowFuelAlertChecked)
end)

---@param moneyType "cash" | "bank"
---@param moneyAmount number
---@param cashMoney number
---@param bankMoney number
---@param isMinus boolean
exports("showMoney", function(moneyType, moneyAmount, cashMoney, bankMoney, isMinus)
    SendNUIMessage({
        action = "updatemoney",
        cash = cashMoney,
        bank = bankMoney,
        amount = moneyAmount,
        minus = isMinus,
        type = moneyType
    })
end)

AddStateBagChangeHandler("harness", ("player:%s"):format(serverId), function(_, _, value)
    harness = value
end)

RegisterNetEvent("seatbelt:client:ToggleSeatbelt", function(forcedState) -- Triggered in smallresources
    if forcedState ~= nil then
        seatbeltOn = forcedState
    else
        seatbeltOn = not seatbeltOn
    end
end)

RegisterNetEvent("seatbelt:client:ToggleCruise", function(forcedState) -- Triggered in smallresources
    if forcedState ~= nil then
        cruiseOn = forcedState
    else
        cruiseOn = not cruiseOn
    end
end)

RegisterNetEvent("hud:client:UpdateNitrous", function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent("hud:client:UpdateHarness", function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

RegisterNetEvent("hud:client:UpdateUISettings", function(data)
    UIConfig = data
    sendUIUpdateMessage(data)
end)

--- Send player buff infomation to nui
--- @param data table - Buff data
--  {
--      display: boolean - Whether to show buff or not
--      iconName: string - which icon to use
--      name: string - buff name used to identify buff
--      progressValue: number(0 - 100) - current progress of buff shown on icon
--      progressColor: string (hex #ffffff) - progress color on icon
--  }
RegisterNetEvent("hud:client:BuffEffect", function(data)
    if data.progressColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            display = data.display,
            iconColor = data.iconColor,
            iconName = data.iconName,
            buffName = data.buffName,
            progressValue = data.progressValue,
            progressColor = data.progressColor,
        })
    elseif data.progressValue ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            progressValue = data.progressValue,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            display = data.display,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:BuffEffect")
    end
end)

RegisterNetEvent("hud:client:EnhancementEffect", function(data)
    if data.iconColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            iconColor = data.iconColor,
            enhancementName = data.enhancementName,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            enhancementName = data.enhancementName,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:EnhancementEffect")
    end
end)

---@param weaponHash number
---@return boolean
local function isWhitelistedWeaponArmed(weaponHash)
    for i = 1, #Config.WhitelistedWeaponArmed do
        if weaponHash == Config.WhitelistedWeaponArmed[i] then
            return true
        end
    end

    return false
end

local playerState = LocalPlayer.state
local isHudUpdateThreadActive = false

local function hudUpdateThread()
    if isHudUpdateThreadActive then return end

    isHudUpdateThreadActive = true

    CreateThread(function()
        local wasInVehicle = false

        while framework.isPlayerLoaded() do
            local shouldShowHud = not IsPauseMenuActive()

            if not shouldShowHud then
                player.hideHud()
                vehicle.hideHud()
            else
                -- player weapon
                local isPlayerArmed = false

                if not isWhitelistedWeaponArmed(cache.weapon) then
                    -- weapon ~= 0 fixes unarmed on Offroad vehicle Blzer Aqua showing armed bug
                    if cache.weapon and cache.weapon ~= `WEAPON_UNARMED` then
                        isPlayerArmed = true
                    end
                end

                -- player health
                local playerHealth = GetEntityHealth(cache.ped) - 100

                -- player armor
                local playerArmour = GetPedArmour(cache.ped)

                -- player dead state
                local isPlayerDead = framework.isPlayerDead()

                local playerOxygen = 100
                local isPlayerInWater = IsEntityInWater(cache.ped)

                -- player stamina
                if not isPlayerInWater then
                    playerOxygen = 100 - GetPlayerSprintStaminaRemaining(cache.playerId)
                end

                -- player oxygen
                if isPlayerInWater then
                    playerOxygen = GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10
                end

                -- player voice (based on pma-voice)
                local isPlayerTalking = NetworkIsPlayerTalking(cache.playerId)
                local playerRadioChannel = playerState["radioChannel"] or 0
                local playerVoiceDistance = playerState["proximity"]?.distance or 0 -- the state would return nil if player enters server with voice chat off, therefore 0 as fallback

                -- player parachute
                local playerParachuteState = GetPedParachuteState(cache.ped)

                if cache.vehicle and not IsThisModelABicycle(cache.vehicle) then
                    if not wasInVehicle then
                        radar.toggleMinimap(menuConfig:get("isMapEnabledChecked"))
                    end

                    wasInVehicle = true
                    local shouldShowAltitude = IsPedInAnyHeli(cache.ped) or IsPedInAnyPlane(cache.ped) or false
                    local shouldShowSeatbelt = not shouldShowAltitude
                    local vehicleSpeed = math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier)
                    local vehicleEngineHealth = GetVehicleEngineHealth(cache.vehicle) / 10

                    player.updateHud({
                        shouldShowHud,
                        playerHealth,
                        isPlayerDead,
                        playerArmour,
                        status.getThirst(),
                        status.getHunger(),
                        status.getStress(),
                        playerVoiceDistance,
                        playerRadioChannel,
                        radioTalking,
                        isPlayerTalking,
                        isPlayerArmed,
                        playerOxygen,
                        playerParachuteState,
                        nos,
                        cruiseOn,
                        nitroActive,
                        harness,
                        hp,
                        vehicleSpeed,
                        vehicleEngineHealth,
                        menuConfig:get("isCineamticModeChecked"),
                        dev,
                    })

                    vehicle.updateHud({
                        shouldShowHud,
                        false,
                        seatbeltOn,
                        vehicleSpeed,
                        vehicle.getFuelLevel(cache.vehicle),
                        math.ceil(GetEntityCoords(cache.ped).z * 0.5),
                        shouldShowAltitude,
                        shouldShowSeatbelt,
                        radar.isBorderSquare(),
                        radar.isBorderCircle(),
                    })
                else
                    if wasInVehicle then
                        wasInVehicle = false
                        vehicle.hideHud()
                        seatbeltOn = false
                        cruiseOn = false
                        harness = false
                    end

                    player.updateHud({
                        shouldShowHud,
                        playerHealth,
                        isPlayerDead,
                        playerArmour,
                        status.getThirst(),
                        status.getHunger(),
                        status.getStress(),
                        playerVoiceDistance,
                        playerRadioChannel,
                        radioTalking,
                        isPlayerTalking,
                        isPlayerArmed,
                        playerOxygen,
                        playerParachuteState,
                        -1,
                        cruiseOn,
                        nitroActive,
                        harness,
                        hp,
                        -1,
                        -1,
                        menuConfig:get("isCineamticModeChecked"),
                        dev,
                    })

                    radar.toggleMinimap(not menuConfig:get("isOutMapChecked"))
                end
            end

            Wait(500)
        end

        player.hideHud()
        vehicle.hideHud()
        radar.toggleMinimap(false)
        isHudUpdateThreadActive = false
    end)
end

function framework.playerLoaded()
    setupResource()
    hudUpdateThread()
end

function framework.playerUnloaded()
    isAdmin = false
    sendAdminStatus()
end

-- Money HUD
RegisterNetEvent("hud:client:ShowAccounts", function(type, amount)
    if type == "cash" then
        SendNUIMessage({
            action = "show",
            type = "cash",
            cash = amount
        })
    else
        SendNUIMessage({
            action = "show",
            type = "bank",
            bank = amount
        })
    end
end)


local function IsWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(Config.WhitelistedWeaponStress) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                if IsPedShooting(ped) and not IsWhitelistedWeaponStress(weapon) then
                    if math.random() < Config.StressChance then
                        TriggerServerEvent("hud:server:GainStress", math.random(1, 3))
                    end
                    Wait(100)
                else
                    Wait(500)
                end
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

-- Minimap update
CreateThread(function()
    while true do
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
        Wait(1000)
    end
end)

-- Compass
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

local prevBaseplateStats = { nil, nil, nil, nil, nil, nil, nil }

local function updateBaseplateHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevBaseplateStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    prevBaseplateStats = data
    if shouldUpdate then
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

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}

local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 5000 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return lastCrossroadCheck
end

-- Compass Update loop

CreateThread(function()
    local heading, lastHeading = "0", "1"
    local lastIsOutCompassCheck = menuConfig:get("isOutCompassChecked")
    local lastInVehicle = false
    while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(400)
            local show = true
            local camRot = GetGameplayCamRot(0)

            if menuConfig:get("isCompassFollowChecked") then
                heading = tostring(round(360.0 - ((camRot.z + 360.0) % 360.0)))
            else
                heading = tostring(round(360.0 - GetEntityHeading(cache.ped)))
            end

            if heading == "360" then
                heading = "0"
            end

            local playerInVehcile = IsPedInAnyVehicle(cache.ped, false)

            if heading ~= lastHeading or lastInVehicle ~= playerInVehcile then
                if playerInVehcile then
                    local crossroads = getCrossroads(cache.ped)
                    SendNUIMessage({
                        action = "update",
                        value = heading
                    })
                    updateBaseplateHud({
                        show,
                        crossroads[1],
                        crossroads[2],
                        menuConfig:get("isCompassShowChecked"),
                        menuConfig:get("isShowStreetsChecked"),
                        menuConfig:get("isPointerShowChecked"),
                        menuConfig:get("isDegreesShowChecked"),
                    })
                    lastInVehicle = true
                else
                    if not menuConfig:get("isOutCompassChecked") then
                        SendNUIMessage({
                            action = "update",
                            value = heading
                        })
                        SendNUIMessage({
                            action = "baseplate",
                            topic = "opencompass",
                            show = true,
                            showCompass = true,
                        })
                        prevBaseplateStats[1] = true
                        prevBaseplateStats[4] = true
                    else
                        SendNUIMessage({
                            action = "baseplate",
                            topic = "closecompass",
                            show = false,
                        })
                        prevBaseplateStats[1] = false
                    end
                    lastInVehicle = false
                end
            end
            lastHeading = heading
            if lastIsOutCompassCheck ~= menuConfig:get("isOutCompassChecked") and not IsPedInAnyVehicle(cache.ped, false) then
                if not menuConfig:get("isOutCompassChecked") then
                    SendNUIMessage({
                        action = "baseplate",
                        topic = "opencompass",
                        show = true,
                        showCompass = true,
                    })
                else
                    SendNUIMessage({
                        action = "baseplate",
                        topic = "closecompass",
                        show = false,
                    })
                end
                lastIsOutCompassCheck = menuConfig:get("isOutCompassChecked")
            end
        else
            Wait(1000)
        end
    end
end)
