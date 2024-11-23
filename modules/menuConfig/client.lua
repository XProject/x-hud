local menuConfig = {
    -- isOutMapChecked = true,
    -- isOutCompassChecked = true,
    -- isCompassFollowChecked = true,
    -- isOpenMenuSoundsChecked = true,
    -- isResetSoundsChecked = true,
    -- isListSoundsChecked = true,
    -- isLowFuelChecked = true,
    -- isDynamicEngineChecked = true,
    -- isDynamicNitroChecked = true,
    -- isChangeCompassFPSChecked = true,
    -- isCompassShowChecked = true,
    -- isShowStreetsChecked = true,
    -- isPointerShowChecked = true,
    -- isDegreesShowChecked = true,
    -- isCineamticModeChecked = false,
}
menuConfig.__index = menuConfig

setmetatable(__index, {
    __index = __index,
    __metatable = false
})

---@param config string
---@param value any
function menuConfig:set(config, value)
    self[config] = value
end

---@param config string
---@return any
function menuConfig:get(config)
    return self[config]
end

return menuConfig
