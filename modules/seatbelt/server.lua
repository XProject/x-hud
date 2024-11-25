if not Config.EnableSeatbelt then return end

-- credits to (https://github.com/Qbox-project/qbx_seatbelt)
SetConvarReplicated("game_enableFlyThroughWindscreen", "true")

local function onHarnessUse(source, item)
    TriggerClientEvent("seatbelt:client:UseHarness", source, item)
end

if GetResourceState("es_extended"):find("start") then
    exports["es_extended"]:getSharedObject().RegisterUsableItem("harness", onHarnessUse)
elseif GetResourceState("qb-core"):find("start") then
    exports["qb-core"]:GetCoreObject().Functions.CreateUseableItem("harness", onHarnessUse)
elseif GetResourceState("qbx_core"):find("start") then
    exports["qbx_core"]:CreateUseableItem("harness", onHarnessUse)
end

RegisterNetEvent("seatbelt:server:EquipHarness", function(slotId)
    local item = exports["ox_inventory"]:GetSlot(source, slotId)

    if not item then return end

    local itemData = item.metadata
    local newDurability = (itemData.durability or 100) - 5

    if newDurability <= 0 then
        exports["ox_inventory"]:RemoveItem(source, item.name, 1, itemData, slotId)
    else
        itemData.durability = newDurability
        exports["ox_inventory"]:SetMetadata(source, slotId, itemData)
    end
end)
