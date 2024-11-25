if not Config.EnableSeatbelt then return end

-- credits to (https://github.com/Qbox-project/qbx_seatbelt)
local seatbelt = {}

local playerState = LocalPlayer.state
local utils = require("modules.utility.client")
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6
local minSpeeds = {
    unbuckled = Config.MinimumUnbuckledSpeedToEject / speedMultiplier,
    buckled = Config.MinimumBuckledSpeedToEject / speedMultiplier,
    harness = Config.Harness.MinimumSpeed / speedMultiplier
}

CreateThread(function()
    playerState.seatbelt = false
    playerState.harness = false

    SetPedConfigFlag(cache.ped, 32, true) -- PED_FLAG_CAN_FLY_THRU_WINDSCREEN
    SetFlyThroughWindscreenParams(minSpeeds.unbuckled, 1.0, 17.0, 10.0)
end)

local function playBuckleSound(on)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5.0, on and "carbuckle" or "carunbuckle", 0.25)
end

local function toggleSeatbelt()
    if playerState.harness then
        return utils.showNotification(locale("harnessOn"))
    end

    local seatbeltOn = not playerState.seatbelt
    playerState.seatbelt = seatbeltOn

    SetFlyThroughWindscreenParams(seatbeltOn and minSpeeds.buckled or minSpeeds.unbuckled, 1.0, 17.0, 10.0)
    TriggerEvent("seatbelt:client:ToggleSeatbelt", seatbeltOn)
    playBuckleSound(seatbeltOn)
end

local function toggleHarness()
    local harnessOn = not playerState.harness
    playerState.harness = harnessOn

    TriggerEvent("seatbelt:client:ToggleSeatbelt", harnessOn)
    playBuckleSound(harnessOn)

    local canFlyThroughWindscreen = not (harnessOn and Config.Harness.DisableFlyingThroughWindscreen)

    SetPedConfigFlag(cache.ped, 32, canFlyThroughWindscreen) -- PED_FLAG_CAN_FLY_THRU_WINDSCREEN

    if canFlyThroughWindscreen then
        SetFlyThroughWindscreenParams(harnessOn and minSpeeds.harness or (playerState.seatbelt and minSpeeds.buckled or minSpeeds.unbuckled), 1.0, 17.0, 10.0)
    end
end

local isSeatbeltThreadActive = false

local function seatbeltThread()
    if isSeatbeltThreadActive or not cache.vehicle then return end

    isSeatbeltThreadActive = true

    CreateThread(function()
        local sleep

        while cache.vehicle do
            sleep = 1000

            if playerState.seatbelt or playerState.harness then
                sleep = 0
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
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

return seatbelt
