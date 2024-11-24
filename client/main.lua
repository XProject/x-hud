local QBCore = exports["qb-core"]:GetCoreObject()
local serverId = GetPlayerServerId(PlayerId())
local UIConfig = UIConfig
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local next = next
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local nitroActive = 0
local harness = false
local hp = 100
local armed = false
local oxygen = 100
local dev = false
local isAdmin = false
local playerDead = false
local isMenuShowing = false
local radioTalking = false


local sound = require("modules.sound.client")
local radar = require("modules.radar.client")
local utils = require("modules.utility.client")
local framework = require("modules.bridge.main")
local vehicle = require("modules.vehicle.client")
local menuConfig = require("modules.menuConfig.client")

radar.toggleMinimap(false)

RegisterNetEvent("hud:client:LoadMap", radar.loadMap)

---TODO
local function hasHarness()
    if not cache.vehicle then return end

    harness = false
end

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

function framework.playerLoaded()
    setupResource()
end

function framework.playerUnloaded()
    isAdmin = false
    sendAdminStatus()
end

---Setup the resource on resource restart on live server
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= cache.resource then return end

    Wait(1000)

    if framework.isPlayerLoaded() then
        setupResource()
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

    if cache.vehicle then
        SendNUIMessage({
            action = "car",
            topic = "display",
            show = false,
            seatbelt = false,
        })

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

RegisterNetEvent("hud:client:ToggleAirHud", function()
    showAltitude = not showAltitude
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

RegisterNetEvent("hud:client:UpdateNeeds", function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

AddStateBagChangeHandler("hunger", ("player:%s"):format(serverId), function(_, _, value)
    hunger = value
end)

AddStateBagChangeHandler("thirst", ("player:%s"):format(serverId), function(_, _, value)
    thirst = value
end)

AddStateBagChangeHandler("stress", ("player:%s"):format(serverId), function(_, _, value)
    stress = value
end)

RegisterNetEvent("hud:client:UpdateStress", function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

RegisterNetEvent("hud:client:ToggleShowSeatbelt", function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent("seatbelt:client:ToggleSeatbelt", function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent("seatbelt:client:ToggleCruise", function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent("hud:client:UpdateNitrous", function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent("hud:client:UpdateHarness", function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-isAdmin:client:ToggleDevmode", function()
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

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(Config.WhitelistedWeaponArmed) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updateShowPlayerHud(show)
    if prevPlayerStats["show"] ~= show then
        prevPlayerStats["show"] = show
        SendNUIMessage({
            action = "hudtick",
            topic = "display",
            show = show
        })
    end
end

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    if shouldUpdate then
        -- Since we found updated data, replace player cache with data
        prevPlayerStats = data
        SendNUIMessage({
            action = "hudtick",
            topic = "status",
            show = data[1],
            health = data[2],
            playerDead = data[3],
            armor = data[4],
            thirst = data[5],
            hunger = data[6],
            stress = data[7],
            voice = data[8],
            radioChannel = data[9],
            radioTalking = data[10],
            talking = data[11],
            armed = data[12],
            oxygen = data[13],
            parachute = data[14],
            nos = data[15],
            cruise = data[16],
            nitroActive = data[17],
            harness = data[18],
            hp = data[19],
            speed = data[20],
            engine = data[21],
            cinematic = data[22],
            dev = data[23],
        })
    end
end

local prevVehicleStats = {
    nil, --[1] show,
    nil, --[2] isPaused,
    nil, --[3] seatbelt
    nil, --[4] speed
    nil, --[5] fuel
    nil, --[6] altitude
    nil, --[7] showAltitude
    nil, --[8] showSeatbelt
    nil, --[9] showSquareBorder
    nil  --[10] showCircleBorder
}

local function updateShowVehicleHud(show)
    if prevVehicleStats[1] ~= show then
        prevVehicleStats[1] = show
        prevVehicleStats[3] = false
        SendNUIMessage({
            action = "car",
            topic = "display",
            show = false,
            seatbelt = false,
        })
    end
end

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = "car",
            topic = "status",
            show = data[1],
            isPaused = data[2],
            seatbelt = data[3],
            speed = data[4],
            fuel = data[5],
            altitude = data[6],
            showAltitude = data[7],
            showSeatbelt = data[8],
            showSquareB = data[9],
            showCircleB = data[10],
        })
    end
end

-- HUD Update loop
CreateThread(function()
    local wasInVehicle = false
    while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(500)

            local show = true
            local player = PlayerPedId()
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(player)

            -- Player hud
            if not IsWhitelistedWeaponArmed(weapon) then
                -- weapon ~= 0 fixes unarmed on Offroad vehicle Blzer Aqua showing armed bug
                if weapon ~= `WEAPON_UNARMED` and weapon ~= 0 then
                    armed = true
                else
                    armed = false
                end
            end

            playerDead = framework.isPlayerDead()

            -- Stamina
            if not IsEntityInWater(player) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end

            -- Oxygen
            if IsEntityInWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end

            -- Voice setup
            local talking = NetworkIsPlayerTalking(playerId)
            local voice = 0
            if LocalPlayer.state["proximity"] then
                voice = LocalPlayer.state["proximity"].distance
                -- Player enters server with Voice Chat off, will not have a distance (nil)
                if voice == nil then
                    voice = 0
                end
            end

            if IsPauseMenuActive() then
                show = false
            end

            if not (cache.vehicle and not IsThisModelABicycle(cache.vehicle)) then
                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state["radioChannel"],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    -1,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    -1,
                    menuConfig:get("isCineamticModeChecked"),
                    dev,
                })
            end

            -- Vehicle hud

            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showAltitude = true
                showSeatbelt = false
            end

            if cache.vehicle and not IsThisModelABicycle(cache.vehicle) then
                if not wasInVehicle then
                    radar.toggleMinimap(menuConfig:get("isMapEnabledChecked"))
                end

                wasInVehicle = true

                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state["radioChannel"],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(cache.vehicle) / 10),
                    menuConfig:get("isCineamticModeChecked"),
                    dev,
                })

                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    seatbeltOn,
                    math.ceil(GetEntitySpeed(cache.vehicle) * speedMultiplier),
                    vehicle.getFuelLevel(cache.vehicle),
                    math.ceil(GetEntityCoords(player).z * 0.5),
                    showAltitude,
                    showSeatbelt,
                    radar.isBorderSquare(),
                    radar.isBorderCircle(),
                })
                showAltitude = false
                showSeatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    updateShowVehicleHud(false)
                    prevVehicleStats[1] = false
                    prevVehicleStats[3] = false
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end

                radar.toggleMinimap(not menuConfig:get("isOutMapChecked"))
            end
        else
            -- Not logged in, dont show Status/Vehicle UI (cached)
            updateShowPlayerHud(false)
            updateShowVehicleHud(false)
            DisplayRadar(false)
            Wait(1000)
        end
    end
end)



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

-- Harness Check / Seatbelt Check

CreateThread(function()
    while true do
        Wait(1500)
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                hasHarness()
                local veh = GetEntityModel(GetVehiclePedIsIn(ped, false))
                if seatbeltOn ~= true and IsThisModelACar(veh) then
                    TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                end
            end
        end
    end
end)


-- Stress Gain

CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * speedMultiplier
                local stressSpeed = seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled
                local vehClass = GetVehicleClass(GetVehiclePedIsIn(ped, false))
                if Config.VehClassStress[tostring(vehClass)] then
                    if speed >= stressSpeed then
                        TriggerServerEvent("hud:server:GainStress", math.random(1, 3))
                    end
                end
            end
        end
        Wait(10000)
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

-- Stress Screen Effects

local function GetBlurIntensity(stresslevel)
    for k, v in pairs(Config.Intensity["blur"]) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for k, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local effectInterval = GetEffectInterval(stress)
            if stress >= 100 then
                local BlurIntensity = GetBlurIntensity(stress)
                local FallRepeat = math.random(2, 4)
                local RagdollTimeout = FallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)

                if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                    SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped) --[[@as number]], 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end

                Wait(1000)
                for i = 1, FallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif stress >= Config.MinimumStress then
                local BlurIntensity = GetBlurIntensity(stress)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
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
        Wait(500)
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
            local player = PlayerPedId()
            local camRot = GetGameplayCamRot(0)

            if menuConfig:get("isCompassFollowChecked") then
                heading = tostring(round(360.0 - ((camRot.z + 360.0) % 360.0)))
            else
                heading = tostring(round(360.0 - GetEntityHeading(player)))
            end

            if heading == "360" then
                heading = "0"
            end

            local playerInVehcile = IsPedInAnyVehicle(player, false)

            if heading ~= lastHeading or lastInVehicle ~= playerInVehcile then
                if playerInVehcile then
                    local crossroads = getCrossroads(player)
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
            if lastIsOutCompassCheck ~= menuConfig:get("isOutCompassChecked") and not IsPedInAnyVehicle(player, false) then
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
