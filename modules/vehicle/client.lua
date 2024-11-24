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
    if isLowFuelAlertThreadActive then return end

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

    if value then
        lowFuelAlertThread()
    end
end)

return vehicle
