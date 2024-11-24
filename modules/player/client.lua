local player = {}

local cachedPlayerStats = {
    nil, --[1] show,
    nil, --[2] health,
    nil, --[3] playerDead
    nil, --[4] armor
    nil, --[5] thirst
    nil, --[6] hunger
    nil, --[7] stress
    nil, --[8] voice
    nil, --[9] radioChannel
    nil, --[10] radioTalking
    nil, --[11] talking
    nil, --[12] armed
    nil, --[13] oxygen
    nil, --[14] parachute
    nil, --[15] nos
    nil, --[16] cruise
    nil, --[17] nitroActive
    nil, --[18] harness
    nil, --[19] hp
    nil, --[20] speed
    nil, --[21] engine
    nil, --[22] cinematic
    nil  --[23] dev
}
function player.hideHud()
    cachedPlayerStats[1] = false

    SendNUIMessage({
        action = "hudtick",
        topic = "display",
        show = false
    })
end

---@param data table<number, any>
function player.updateHud(data)
    local shouldUpdate = false

    for i = 1, #data do
        if cachedPlayerStats[i] ~= data[i] then
            shouldUpdate = true
            break
        end
    end

    if shouldUpdate then
        cachedPlayerStats = data

        SendNUIMessage({
            action = "hudtick",
            topic = "status",
            show = data[1],
            health = data[2],
            playerDead = data[3],
            armor = data[4],
            thirst = data[5],
            hunger = data[6],
            stress = data[7],
            voice = data[8],
            radioChannel = data[9],
            radioTalking = data[10],
            talking = data[11],
            armed = data[12],
            oxygen = data[13],
            parachute = data[14],
            nos = data[15],
            cruise = data[16],
            nitroActive = data[17],
            harness = data[18],
            hp = data[19],
            speed = data[20],
            engine = data[21],
            cinematic = data[22],
            dev = data[23],
        })
    end
end

return player
