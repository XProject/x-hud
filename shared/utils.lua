local utils = {}

---@param eventName string
---@param callback function
function utils.NuiCallback(eventName, callback)
    RegisterNUICallback(eventName, function(data, cb)
        cb({})
        callback(data)
    end)
end

---@param data string | table
function utils.showNotification(data)
    if type(data) == "string" then
        data = { description = data }
    end

    lib.notify({
        title = "HUD",
        description = data.title or data.description,
        position = "center-right",
        duration = 5000,
        showDuration = true,
        icon = data.icon,
        iconColor = data.iconColor,
        -- iconAnimation = "beat",
        style = {
            backgroundColor = "#2c3e50",                    -- Dark blue-gray background for contrast
            color = "#ecf0f1",                              -- Light color for text (title and description)
            borderRadius = "10px",                          -- Slightly rounded corners
            boxShadow = "0 0 25px 10px rgba(0, 0, 0, 0.4)", -- Soft shadow on all 4 sides
            fontSize = "15px",                              -- General font size
            [".description"] = {
                color = "#f1c40f",                          -- Golden yellow for description text
                fontWeight = "bold",                        -- Bold description for emphasis
                fontSize = "13px",                          -- Slightly smaller description text
            },
        },
    })
end

return utils
