if not Config.EnableSeatbelt then return end

-- credits to (https://github.com/Qbox-project/qbx_seatbelt)
local seatbelt = {}

local playerState = LocalPlayer.state
local utils = require("modules.utility.client")
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6
local minSpeeds = {
    unbuckled = Config.MinimumUnbuckledSpeedToEject / speedMultiplier,
    buckled = Config.MinimumBuckledSpeedToEject / speedMultiplier,
    harness = Config.MinimumHarnessBuckledSpeedToEject / speedMultiplier,
    seatbeltAlert = Config.SeatbeltUnbuckledAlertSpeed / speedMultiplier
}

local function playBuckleSound(on)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5.0, on and "carbuckle" or "carunbuckle", 0.25)
end

local function toggleSeatbelt()
    if playerState.harness then
        return utils.showNotification(locale("harnessOn"))
    end

    local seatbeltOn = not playerState.seatbelt
    playerState.seatbelt = seatbeltOn

    playBuckleSound(seatbeltOn)
    TriggerEvent("seatbelt:client:ToggleSeatbelt", seatbeltOn)

    SetFlyThroughWindscreenParams(seatbeltOn and minSpeeds.buckled or minSpeeds.unbuckled, 0.0, 10.0, 0.0)
end

local function toggleHarness()
    local harnessOn = not playerState.harness
    playerState.harness = harnessOn

    playBuckleSound(harnessOn)
    TriggerEvent("seatbelt:client:ToggleSeatbelt", harnessOn)

    SetFlyThroughWindscreenParams(harnessOn and minSpeeds.harness or minSpeeds.unbuckled, 0.0, 10.0, 0.0)
end

local isSeatbeltAlarmThreadActive = false

local function seatbeltAlarmThread()
    if isSeatbeltAlarmThreadActive or not Config.SeatbeltUnbuckledAlert or not cache.vehicle then return end

    isSeatbeltAlarmThreadActive = true

    CreateThread(function()
        local isVehicleACar = IsThisModelACar(GetEntityModel(cache.vehicle))

        if isVehicleACar then
            while cache.vehicle do
                if not playerState.seatbelt and not playerState.harness then
                    local speed = GetEntitySpeed(cache.vehicle)

                    if speed > minSpeeds.seatbeltAlert then
                        TriggerEvent("InteractSound_CL:PlayOnOne", "beltalarm", 0.6)
                    end
                end


                Wait(1500)
            end
        end

        isSeatbeltAlarmThreadActive = false
    end)
end

local isSeatbeltThreadActive = false

local function seatbeltThread()
    if isSeatbeltThreadActive or not cache.vehicle then return end

    isSeatbeltThreadActive = true

    seatbeltAlarmThread()
    CreateThread(function()
        local sleep

        while cache.vehicle do
            sleep = 1000

            if playerState.seatbelt or playerState.harness then
                sleep = 0
                DisableControlAction(0, 75, true)
                DisableControlAction(1, 75, true)
                DisableControlAction(2, 75, true)

                if IsDisabledControlJustReleased(0, 75) or IsDisabledControlJustReleased(1, 75) or IsDisabledControlJustReleased(2, 75) then
                    utils.showNotification(playerState.seatbelt and locale("seatbeltOn") or playerState.harness and locale("harnessOn"))
                end
            end

            Wait(sleep)
        end

        isSeatbeltThreadActive = false
        playerState.seatbelt = false
        playerState.harness = false
    end)
end

function seatbelt.hasSeatbelt()
    return playerState.seatbelt
end

--- @deprecated Use `state.seatbelt` instead
exports("HasSeatbelt", seatbelt.hasSeatbelt)

function seatbelt.hasHarness()
    return playerState.harness
end

--- @deprecated Use `state.seatbelt` instead
exports("HasHarness", seatbelt.hasHarness)

AddEventHandler("ox_lib:cache:vehicle", function()
    Wait(500)
    seatbeltThread()
end)

RegisterNetEvent("seatbelt:client:UseHarness", function(ItemData)
    if playerState.seatbelt then
        return utils.showNotification(locale("seatbeltOn"))
    end

    local class = GetVehicleClass(cache.vehicle)

    if not cache.vehicle or class == 8 or class == 13 or class == 14 then
        return utils.showNotification(locale("notInCar"))
    end

    if not playerState.harness then
        if lib.progressCircle({
                duration = 5000,
                label = locale("attachHarness"),
                position = "bottom",
                useWhileDead = false,
                canCancel = true,
                disable = {
                    combat = true
                }
            }) then
            TriggerServerEvent("seatbelt:server:EquipHarness", ItemData.slot)
            toggleHarness()
        end
    else
        if lib.progressCircle({
                duration = 5000,
                label = locale("removeHarness"),
                position = "bottom",
                useWhileDead = false,
                canCancel = true,
                disable = {
                    combat = true
                }
            }) then
            toggleHarness()
        end
    end
end)

lib.addKeybind({
    name = "toggle_seatbelt",
    description = locale("toggleCommand"),
    defaultKey = Config.SeatbeltKeybind,
    onPressed = function()
        if not cache.vehicle or IsPauseMenuActive() then return end
        local class = GetVehicleClass(cache.vehicle)
        if class == 8 or class == 13 or class == 14 then return end

        toggleSeatbelt()
    end
})

CreateThread(function()
    playerState:set("seatbelt", false, true)
    playerState:set("harness", false, true)

    Wait(1000)

    seatbeltThread()

    SetPedConfigFlag(cache.ped, 32, true) -- PED_FLAG_CAN_FLY_THRU_WINDSCREEN
    SetFlyThroughWindscreenParams(minSpeeds.unbuckled, 0.0, 10.0, 0.0)
end)

return seatbelt
