local menuConfig = {
    -- isDynamicEngineChecked = true,
    -- isDynamicNitroChecked = true,
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
