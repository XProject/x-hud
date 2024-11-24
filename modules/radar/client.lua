local radar = {}
local utils = require("modules.utility.client")
local menuConfig = require("modules.menuConfig.client")

menuConfig:set("isCinematicNotifChecked", true) -- default value

utils.NuiCallback("showCinematicNotif", function(data)
    menuConfig:set("isCinematicNotifChecked", data.checked and true or false)

    TriggerEvent("hud:client:playHudChecklistSound")
end)

---@param state boolean
function radar.toggleMinimap(state)
    DisplayRadar(state)
end

local defaultBarHeight = 0.0
local cinematicBarHeight = 0.2
local barHeight = defaultBarHeight
local isCinematicThreadActive = false
menuConfig:set("isCineamticModeChecked", false) -- default value

local function drawBlackBars()
    DrawRect(0.0, 0.0, 2.0, barHeight, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, barHeight, 0, 0, 0, 255)
end

local function cinematicModeThread()
    if isCinematicThreadActive or not menuConfig:get("isCineamticModeChecked") then return end

    isCinematicThreadActive = true

    CreateThread(function()
        while menuConfig:get("isCineamticModeChecked") do
            Wait(0)
            drawBlackBars()
            radar.toggleMinimap(false)
        end

        isCinematicThreadActive = false
    end)
end

---@param state boolean
---@return boolean
function radar.cinematicMode(state)
    SetRadarBigmapEnabled(true, false)
    SetRadarBigmapEnabled(false, false)

    if state then
        barHeight = cinematicBarHeight
        menuConfig:set("isCineamticModeChecked", true)

        if menuConfig:get("isCinematicNotifChecked") then
            utils.showNotification(locale("cinematic_on"))
        end
    else
        barHeight = defaultBarHeight
        menuConfig:set("isCineamticModeChecked", false)

        if menuConfig:get("isCinematicNotifChecked") then
            utils.showNotification(locale("cinematic_off"))
        end
    end

    cinematicModeThread()

    return state
end

utils.NuiCallback("cinematicMode", function(data)
    if not radar.cinematicMode(data.checked) then
        if (cache.vehicle and not IsThisModelABicycle(cache.vehicle)) or not Menu.isOutMapChecked then
            radar.toggleMinimap(true)
        end
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

menuConfig:set("isMapNotifChecked", true)           -- default value
menuConfig:set("isToggleMapBordersChecked", true)   -- default value
menuConfig:set("isToggleMapShapeChecked", "square") -- default value

utils.NuiCallback("showMapNotif", function(data)
    if data.checked then
        menuConfig:set("isMapNotifChecked", true)
    else
        menuConfig:set("isMapNotifChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

local squareBorder = false
local circleBorder = false

---@return boolean
function radar.loadMap()
    local loaded = false

    -- Credit to Dalrae for the solve.
    local defaultAspectRatio = 1920 / 1080 -- Don't change this.
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0

    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    if menuConfig:get("isToggleMapShapeChecked") == "square" then
        while not HasStreamedTextureDictLoaded("squaremap") do
            RequestStreamedTextureDict("squaremap", false)
            Wait(150)
        end

        if menuConfig:get("isMapNotifChecked") then
            utils.showNotification(locale("load_square_map"))
        end

        SetMinimapClipType(0)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
        -- 0.0 = nav symbol and icons left
        -- 0.1638 = nav symbol and icons stretched
        -- 0.216 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.047, 0.1638, 0.183)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)

        -- -0.01 = map pulled left
        -- 0.025 = map raised up
        -- 0.262 = map stretched
        -- 0.315 = map shorten
        SetMinimapComponentPosition("minimap_blur", "L", "B", -0.01 + minimapOffset, 0.025, 0.262, 0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetRadarBigmapEnabled(true, false)
        SetRadarBigmapEnabled(false, false)
        SetMinimapClipType(0)

        if menuConfig:get("isToggleMapBordersChecked") then
            circleBorder = false
            squareBorder = true
        end

        Wait(1200)

        if menuConfig:get("isMapNotifChecked") then
            utils.showNotification(locale("loaded_square_map"))
        end

        loaded = true
    elseif menuConfig:get("isToggleMapShapeChecked") == "circle" then
        while not HasStreamedTextureDictLoaded("circlemap") do
            RequestStreamedTextureDict("circlemap", false)
            Wait(150)
        end

        if menuConfig:get("isMapNotifChecked") then
            utils.showNotification(locale("load_circle_map"))
        end

        SetMinimapClipType(1)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasksm")
        -- -0.0100 = nav symbol and icons left
        -- 0.180 = nav symbol and icons stretched
        -- 0.258 = nav symbol and icons raised up
        SetMinimapComponentPosition("minimap", "L", "B", -0.0100 + minimapOffset, -0.030, 0.180, 0.258)

        -- icons within map
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.200 + minimapOffset, 0.0, 0.065, 0.20)

        -- -0.00 = map pulled left
        -- 0.015 = map raised up
        -- 0.252 = map stretched
        -- 0.338 = map shorten
        SetMinimapComponentPosition("minimap_blur", "L", "B", -0.00 + minimapOffset, 0.015, 0.252, 0.338)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetRadarBigmapEnabled(true, false)
        SetRadarBigmapEnabled(false, false)
        SetMinimapClipType(1)

        if menuConfig:get("isToggleMapBordersChecked") then
            squareBorder = false
            circleBorder = true
        end

        Wait(1200)

        if menuConfig:get("isMapNotifChecked") then
            utils.showNotification(locale("loaded_circle_map"))
        end

        loaded = true
    end

    return loaded
end

menuConfig:set("isMapEnabledChecked", false) -- default value

utils.NuiCallback("HideMap", function(data)
    if data.checked then
        menuConfig:set("isMapEnabledChecked", true)
    else
        menuConfig:set("isMapEnabledChecked", false)
    end

    radar.toggleMinimap(menuConfig:get("isMapEnabledChecked"))
    TriggerEvent("hud:client:playHudChecklistSound")
end)

utils.NuiCallback("ToggleMapShape", function(data)
    if menuConfig:get("isMapEnabledChecked") then
        menuConfig:set("isToggleMapShapeChecked", data.shape)
        radar.loadMap()
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

utils.NuiCallback("ToggleMapBorders", function(data)
    if data.checked then
        menuConfig:set("isToggleMapBordersChecked", true)
    else
        menuConfig:set("isToggleMapBordersChecked", false)
    end

    if menuConfig:get("isToggleMapBordersChecked") then
        if menuConfig:get("isToggleMapShapeChecked") == "square" then
            squareBorder = true
        else
            circleBorder = true
        end
    else
        squareBorder = false
        circleBorder = false
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

---@return boolean
function radar.isBorderSquare()
    return squareBorder
end

---@return boolean
function radar.isBorderCircle()
    return circleBorder
end

menuConfig:set("isOutMapChecked", true) -- default value

utils.NuiCallback("showOutMap", function(data)
    if data.checked then
        menuConfig:set("isOutMapChecked", true)
    else
        menuConfig:set("isOutMapChecked", false)
    end

    TriggerEvent("hud:client:playHudChecklistSound")
end)

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")

    while not HasScaleformMovieLoaded(minimap) do
        RequestScaleformMovie(minimap --[[@as string]])
        Wait(0)
    end
end)

return radar
