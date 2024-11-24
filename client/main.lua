local QBCore = exports["qb-core"]:GetCoreObject()
local serverId = GetPlayerServerId(PlayerId())
local PlayerData = QBCore.Functions.GetPlayerData()
local config = Config
local UIConfig = UIConfig
local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local next = next
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = false
local hp = 100
local armed = false
local parachute = -1
local oxygen = 100
local engine = 0
local dev = false
local isAdmin = false
local playerDead = false
local isMenuShowing = false
local radioTalking = false


lib.locale()
lib.load("modules.sound.client")
local radar = require("modules.radar.client")
local utils = require("modules.utility.client")
local framework = lib.load("modules.bridge.main")
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

RegisterCommand("hud", function()
    if isMenuShowing then return end

    isMenuShowing = true

    TriggerEvent("hud:client:playOpenMenuSounds")

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end, false)

utils.NuiCallback("closeMenu", function()
    TriggerEvent("hud:client:playCloseMenuSounds")

    isMenuShowing = false
    SetNuiFocus(false, false)
end)

RegisterKeyMapping("hud", locale("open_menu"), "keyboard", Config.OpenMenu)

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

RegisterNUICallback("saveUISettings", function(data, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
    TriggerServerEvent("hud:server:saveUIData", data)
end)

RegisterNUICallback("showOutCompass", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOutCompassChecked = true
    else
        Menu.isOutCompassChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("showFollowCompass", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isCompassFollowChecked = true
    else
        Menu.isCompassFollowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("showFuelAlert", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isLowFuelChecked = true
    else
        Menu.isLowFuelChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Status
RegisterNUICallback("dynamicChange", function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Compass
RegisterNUICallback("showCompassBase", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isCompassShowChecked = true
    else
        Menu.isCompassShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("showStreetsNames", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isShowStreetsChecked = true
    else
        Menu.isShowStreetsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("showPointerIndex", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isPointerShowChecked = true
    else
        Menu.isPointerShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("showDegreesNum", function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isDegreesShowChecked = true
    else
        Menu.isDegreesShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("changeCompassFPS", function(data, cb)
    cb({})
    Wait(50)
    if data.fps == "optimized" then
        Menu.isChangeCompassFPSChecked = true
    else
        Menu.isChangeCompassFPSChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback("updateMenuSettingsToClient", function(data, cb)
    menuConfig:set("isOutMapChecked", data.isOutMapChecked)
    Menu.isOutCompassChecked = data.isOutCompassChecked
    Menu.isCompassFollowChecked = data.isCompassFollowChecked
    menuConfig:set("isOpenMenuSoundsChecked", data.isOpenMenuSoundsChecked)
    menuConfig:set("isResetSoundsChecked", data.isResetSoundsChecked)
    menuConfig:set("isListSoundsChecked", data.isListSoundsChecked)
    menuConfig:set("isMapNotifChecked", data.isMapNotifyChecked)
    Menu.isLowFuelChecked = data.isLowFuelAlertChecked
    menuConfig:set("isCinematicNotifChecked", data.isCinematicNotifyChecked)
    menuConfig:set("isMapEnabledChecked", data.isMapEnabledChecked)
    menuConfig:set("isToggleMapShapeChecked", data.isToggleMapShapeChecked)
    menuConfig:set("isToggleMapBordersChecked", data.isToggleMapBordersChecked)
    Menu.isCompassShowChecked = data.isShowCompassChecked
    Menu.isShowStreetsChecked = data.isShowStreetsChecked
    Menu.isPointerShowChecked = data.isPointerShowChecked
    radar.cinematicMode(data.isCineamticModeChecked)
    cb({})
end)

RegisterNetEvent("hud:client:EngineHealth", function(newEngine)
    engine = newEngine
end)

RegisterNetEvent("hud:client:ToggleAirHud", function()
    showAltitude = not showAltitude
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

RegisterCommand("+engine", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then return end
    if GetIsVehicleEngineRunning(vehicle) then
        QBCore.Functions.Notify(locale("engine_off"))
    else
        QBCore.Functions.Notify(locale("engine_on"))
    end
    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
end, false)

RegisterKeyMapping("+engine", locale("toggle_engine"), "keyboard", "G")

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponArmed) do
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

local lastFuelUpdate = 0
local lastFuelCheck = 0

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        lastFuelCheck = math.floor(exports[Config.FuelScript]:GetFuel(vehicle))
    end
    return lastFuelCheck
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
            parachute = GetPedParachuteState(player)

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

            local vehicle = GetVehiclePedIsIn(player, false)

            if not (IsPedInAnyVehicle(player, false) and not IsThisModelABicycle(vehicle)) then
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
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    -1,
                    Menu.isCineamticModeChecked,
                    dev,
                })
            end

            -- Vehicle hud

            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showAltitude = true
                showSeatbelt = false
            end

            if IsPedInAnyVehicle(player, false) and not IsThisModelABicycle(vehicle) then
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
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(vehicle) / 10),
                    Menu.isCineamticModeChecked,
                    dev,
                })

                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    seatbeltOn,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    getFuelLevel(vehicle),
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

function isElectric(vehicle)
    local noBeeps = false
    for k, v in pairs(Config.FuelBlacklist) do
        if GetEntityModel(vehicle) == GetHashKey(v) then
            noBeeps = true
        end
    end
    return noBeeps
end

-- Low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) and not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(ped, false))) and not isElectric(GetVehiclePedIsIn(ped, false)) then
                if exports[Config.FuelScript]:GetFuel(GetVehiclePedIsIn(ped, false)) <= 20 then -- At 20% Fuel Left
                    if Menu.isLowFuelChecked then
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                        QBCore.Functions.Notify(locale("low_fuel"), "error")
                        Wait(60000) -- repeats every 1 min until empty
                    end
                end
            end
        end
        Wait(10000)
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

RegisterNetEvent("hud:client:OnMoneyChange", function(type, amount, isMinus)
    cashAmount = PlayerData.money["cash"]
    bankAmount = PlayerData.money["bank"]
    if type == "cash" and amount == 0 then return end
    SendNUIMessage({
        action = "updatemoney",
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
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
        for _, v in pairs(config.WhitelistedWeaponStress) do
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
                    if math.random() < config.StressChance then
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
    for k, v in pairs(config.Intensity["blur"]) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for k, v in pairs(config.EffectInterval) do
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
            elseif stress >= config.MinimumStress then
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
    local lastIsOutCompassCheck = Menu.isOutCompassChecked
    local lastInVehicle = false
    while true do
        if LocalPlayer.state.isLoggedIn then
            Wait(400)
            local show = true
            local player = PlayerPedId()
            local camRot = GetGameplayCamRot(0)

            if Menu.isCompassFollowChecked then
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
                        Menu.isCompassShowChecked,
                        Menu.isShowStreetsChecked,
                        Menu.isPointerShowChecked,
                        Menu.isDegreesShowChecked,
                    })
                    lastInVehicle = true
                else
                    if not Menu.isOutCompassChecked then
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
            if lastIsOutCompassCheck ~= Menu.isOutCompassChecked and not IsPedInAnyVehicle(player, false) then
                if not Menu.isOutCompassChecked then
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
                lastIsOutCompassCheck = Menu.isOutCompassChecked
            end
        else
            Wait(1000)
        end
    end
end)
