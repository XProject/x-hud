local vehicle = {}
local utils = require("modules.utility.client")
local menuConfig = require("modules.menuConfig.client")

menuConfig:set("isLowFuelChecked", true) -- default value

utils.NuiCallback("showFuelAlert", function(data)
    if data.checked then
        menuConfig:set("isLowFuelChecked", true)
    else
        menuConfig:set("isLowFuelChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

---@param vehicleHash number
---@return boolean
local function isVehicleModelElectric(vehicleHash)
    local electric = false

    for i = 1, #Config.FuelBlacklist do
        local vehicleName = Config.FuelBlacklist[i]

        if vehicleHash == joaat(vehicleName) then
            electric = true
            break
        end
    end

    return electric
end

local cachedFuel = 0
local lastFuelCheckTime = 0

---@param vehicleEntity number
---@return number
function vehicle.getFuelLevel(vehicleEntity)
    local currentTime = GetGameTimer()

    if (currentTime - lastFuelCheckTime) > 5000 then
        lastFuelCheckTime = currentTime

        local fuelLevel = GetVehicleFuelLevel(vehicleEntity)

        if Config.FuelScript == "LegacyFuel" then
            fuelLevel = exports["LegacyFuel"]:GetFuel(vehicleEntity)
        elseif Config.FuelScript == "lj-fuel" then
            fuelLevel = exports["lj-fuel"]:GetFuel(vehicleEntity)
        end

        cachedFuel = math.floor(fuelLevel)
    end

    return cachedFuel
end

local vehiclePedIsIn = false
local isLowFuelAlertThreadActive = false

local function lowFuelAlertThread()
    if isLowFuelAlertThreadActive or not vehiclePedIsIn then return end

    isLowFuelAlertThreadActive = true

    CreateThread(function()
        while vehiclePedIsIn do
            local vehicleModel = GetEntityModel(vehiclePedIsIn)

            if not IsThisModelABicycle(vehicleModel) and not isVehicleModelElectric(vehicleModel) then
                if vehicle.getFuelLevel(vehiclePedIsIn) <= Config.LowFuel then
                    if menuConfig:get("isLowFuelChecked") then
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)

                        utils.showNotification(locale("low_fuel"))

                        Wait(60000) -- repeats every 1 min until empty
                    end
                end
            end

            Wait(10000)
        end

        isLowFuelAlertThreadActive = false
    end)
end

AddEventHandler("ox_lib:cache:vehicle", function(value)
    vehiclePedIsIn = value

    if Config.EnableLowFuelAlert then
        lowFuelAlertThread()
    end
end)

if Config.EnableEngineToggle then
    local function toggleEngine()
        if not vehiclePedIsIn or GetPedInVehicleSeat(vehiclePedIsIn, -1) ~= cache.ped then return end

        local isVehicleEngineRunning = GetIsVehicleEngineRunning(vehiclePedIsIn)

        SetVehicleEngineOn(vehiclePedIsIn, not isVehicleEngineRunning, false, true)
        utils.showNotification(isVehicleEngineRunning and locale("engine_off") or locale("engine_on"))
    end

    lib.addKeybind({
        name = "toggle_engine",
        description = locale("toggle_engine"),
        defaultKey = Config.ToggleEngineKey,
        defaultMapper = "keyboard",
        onPressed = toggleEngine,
    })
end

local cachedVehicleStats = {
    nil, --[1] show,
    nil, --[2] isPaused,
    nil, --[3] seatbelt
    nil, --[4] speed
    nil, --[5] fuel
    nil, --[6] altitude
    nil, --[7] showAltitude
    nil, --[8] showSeatbelt
    nil, --[9] showSquareB
    nil  --[10] showCircleB
}

function vehicle.hideHud()
    cachedVehicleStats[1] = false
    cachedVehicleStats[3] = false

    SendNUIMessage({
        action = "car",
        topic = "display",
        show = false,
        seatbelt = false,
    })
end

---@param data table<number, any>
function vehicle.updateHud(data)
    local shouldUpdate = false

    for i = 1, #data do
        if cachedVehicleStats[i] ~= data[i] then
            shouldUpdate = true
            break
        end
    end

    if shouldUpdate then
        cachedVehicleStats = data

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

return vehicle
