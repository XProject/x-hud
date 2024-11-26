local seatbelt = require("modules.seatbelt.server")

local framework = lib.load("modules.bridge.main")

lib.addCommand("cash", {
    help = locale("check_cash_balance")
}, function(source)
    local balance = framework.getCashBalance(source)

    TriggerClientEvent("hud:client:ShowAccounts", source, "cash", balance)
end)

lib.addCommand("bank", {
    help = locale("check_bank_balance")
}, function(source)
    local balance = framework.getBankBalance(source)

    TriggerClientEvent("hud:client:ShowAccounts", source, "bank", balance)
end)

lib.addCommand("dev", {
    help = locale("toggle_dev_mode"),
    restricted = ("group.%s"):format(Config.AdminRank)
}, function(source)
    TriggerClientEvent("qb-admin:client:ToggleDevmode", source)
end)

RegisterNetEvent("hud:server:GainStress", function(amount)
    if framework.addStressToPlayer(source, amount) then
        TriggerClientEvent("ox_lib:notify", source, { description = locale("stress_gain"), type = "error" })
    end
end)

RegisterNetEvent("hud:server:RelieveStress", function(amount)
    if framework.removeStressFromPlayer(source, amount) then
        TriggerClientEvent("ox_lib:notify", source, { description = locale("stress_removed"), type = "inform" })
    end
end)

RegisterNetEvent("hud:server:saveUIData", function(data)
    local src = source
    -- Check Permissions
    if not framework.hasAdminPermission(src, Config.AdminRank) then return end

    -- Ensure a player is invoking this net event
    if not framework.getPlayer(src) then return end

    local uiConfigData = {}
    uiConfigData.icons = {}

    local path = GetResourcePath(GetCurrentResourceName())
    path = path:gsub("//", "/") .. "/uiconfig.lua"
    local file = io.open(path, "w+")

    if not file then
        return error(("file at %s was not found!"):format(path))
    end

    local heading = "UIConfig = {}\n"
    file:write(heading)

    -- write out icons
    file:write("\nUIConfig.icons = {}\n")

    -- Sort the icons so its easier to find in the config file
    local iconKeys = {}
    for k, _ in pairs(data.icons) do
        table.insert(iconKeys, k)
    end
    table.sort(iconKeys)

    for _, iconName in ipairs(iconKeys) do
        uiConfigData.icons[iconName] = {}

        local iconLabel = "\nUIConfig.icons[\"" .. iconName .. "\"] = {"
        file:write(iconLabel)

        -- sort the values as well inside icons
        local iconValues = {}
        for k, _ in pairs(data.icons[iconName]) do
            table.insert(iconValues, k)
        end
        table.sort(iconValues)

        for _, iconValueName in ipairs(iconValues) do
            local str
            local v = data.icons[iconName][iconValueName]
            uiConfigData.icons[iconName][iconValueName] = v
            if type(v) == "string" then
                str = ("\n    %s = \"%s\","):format(iconValueName, v)
            else
                str = ("\n    %s = %s,"):format(iconValueName, v)
            end
            file:write(str)
        end
        file:write("\n}\n")
    end


    --local layoutLabel = "\nUIConfig.layout = ""..data.layout..""\n"
    local layoutLabel = "\nUIConfig.layout = {"
    file:write(layoutLabel)
    for layoutName, layoutVal in pairs(data.layout) do
        local str
        if type(layoutVal) == "string" then
            str = ("\n    %s = \"%s\","):format(layoutName, layoutVal)
        else
            str = ("\n    %s = %s,"):format(layoutName, layoutVal)
        end
        file:write(str)
    end
    file:write("\n}\n")
    uiConfigData.layout = data.layout


    -- write out color icons info
    file:write("\nUIConfig.colors = {}\n")
    uiConfigData.colors = {}

    -- Sort the color keys
    local colorKeys = {}
    for k, _ in pairs(data.colors) do
        table.insert(colorKeys, k)
    end
    table.sort(colorKeys)

    for _, colorName in ipairs(colorKeys) do
        uiConfigData.colors[colorName] = {}
        uiConfigData.colors[colorName].colorEffects = {}

        local colorLabel = "\nUIConfig.colors[\"" .. colorName .. "\"] = {"
        file:write(colorLabel)

        local colorEffectsLabel = "\n    colorEffects = {"
        file:write(colorEffectsLabel)

        for k, v in ipairs(data.colors[colorName].colorEffects) do
            local colorEffectIndexLabel = "\n        [" .. k .. "] = {"
            file:write(colorEffectIndexLabel)

            -- sort the values as well inside color effects
            local colorEffect = data.colors[colorName].colorEffects[k]
            local colorEffectkeys = {}
            for scekey, _ in pairs(colorEffect) do
                table.insert(colorEffectkeys, scekey)
            end
            table.sort(colorEffectkeys)

            table.insert(uiConfigData.colors[colorName].colorEffects, colorEffect)

            for _, CEKey in ipairs(colorEffectkeys) do
                local str
                if type(colorEffect[CEKey]) == "string" then
                    str = ("\n            %s = \"%s\","):format(CEKey, colorEffect[CEKey])
                else
                    str = ("\n            %s = %s,"):format(CEKey, colorEffect[CEKey])
                end
                file:write(str)
            end
            file:write("\n        },")
        end
        file:write("\n    },")
        file:write("\n}\n")
    end

    file:close()

    UIConfig = uiConfigData

    -- -1 to send to all players
    TriggerClientEvent("hud:client:UpdateUISettings", -1, uiConfigData)
end)

lib.callback.register("hud:server:getRank", function(source)
    return framework.hasAdminPermission(source, Config.AdminRank)
end)
