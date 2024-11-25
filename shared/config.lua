lib.locale()

Config = {}

Config.Framework = "qb"            -- "esx" or "qb"

Config.OpenMenu = "I"              -- keybind to toggle hud settings menu (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)
Config.UseMPH = false              -- If true speed math will be done as MPH, if false KPH will be used (YOU HAVE TO CHANGE CONTENT IN STYLES.CSS TO DISPLAY THE CORRECT TEXT)
Config.DisablePoliceStress = false -- Default: false, If true will disable stress for people with the police job

-- admin
Config.AdminOnly = false   -- whether admins only are able to change the hud's icons/shapes for all players
Config.AdminRank = "admin" -- the minimum admin rank that are able to change the hud's icons/shapes for all players (it requires Config.AdminOnly to be "true")

-- vehicle
Config.EnableEngineToggle = true -- whether this script should handle vehicle engine on/off (this is required to be "true" if you want Config.ToggleEngineKey to work)
Config.ToggleEngineKey = "G"     -- keybind to toggle engine (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/) (it requires Config.EnableEngineToggle to be "true")

-- fuel
Config.FuelScript = "ox_fuel"    -- "ox_fuel" or "LegcyFuel" or "lj-fuel"
Config.EnableLowFuelAlert = true -- whether this script should handle and send alert on low vehicle fuel (this is required to be "true" if you want Config.LowFuel to work)
Config.LowFuel = 20              -- minimum fuel level to trigger the low fuel alert to the pasengers which repeats every 1 minute until empty or refuel (it requires Config.EnableLowFuelAlert to be "true")

-- seatbelt
Config.EnableSeatbelt = true               -- whether this script should run its built-in seatbelt handler module
Config.SeatbeltKeybind = "B"               -- keybind to toggle seatbelt (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/) (it requires Config.EnableSeatbelt to be "true")
Config.SeatbeltUnbuckledAlert = true       -- whether this script should handle and send sound alert on unbuckled seatbelt (it requires Config.EnableSeatbelt to be "true")
Config.SeatbeltUnbuckledAlertSpeed = 10.0  -- minimum vehicle speed to trigger the alert if seatbelt is not buckled in (it requires Config.SeatbeltUnbuckledAlert to be "true")
Config.MinimumUnbuckledSpeedToEject = 20.0 -- minimum speed to fly through windscreen when seatbelt is off (it requires Config.EnableSeatbelt to be "true")
Config.MinimumBuckledSpeedToEject = 160.0  -- minimum speed to fly through windscreen when seatbelt is on (it requires Config.EnableSeatbelt to be "true")
Config.Harness = {
    DisableFlyingThroughWindscreen = true, -- disables flying through windscreen when harness is on (it requires Config.EnableSeatbelt to be "true")
    MinimumSpeed = 200.0                   -- if the above (Config.Harness.DisableFlyingThroughWindscreen) is set to false, minimum speed to fly through windscreen when harness is on (it requires Config.EnableSeatbelt to be "true")
}

-- stress status
Config.EnableStressEffects = true             -- whether this script should run its built-in effects on stress increasing
Config.MinimumStressForEffects = 50           -- minimum stress level for screen blurring effects to take place (it requires Config.EnableStressEffects to be "true")
Config.EnableStressOnSpeeding = true          -- whether this script should run its built-in vehicle speed monitoring to increase stress periodically (it requires Config.EnableSeatbelt to be "true")
Config.MinimumUnbuckledSpeedToGainStress = 50 -- going over this speed while having seatbelt unbuckled will cause stress (it requires Config.EnableStressOnSpeeding and Config.EnableSeatbelt to be "true")
Config.MinimumBuckledSpeedToGainStress = 180  -- going over this speed even while having seatbelt buckled will cause stress (it requires Config.EnableStressOnSpeeding and Config.EnableSeatbelt to be "true")
Config.GainStressWhileShooting = true         -- whether this script should increase player stress while shooting
Config.StressWhileShootingChance = 0.1        -- chance to gain stress while shooting (accepted valid values are any number between 0 and 1 (%0 and %100)) (it requires Config.GainStressWhileShooting to be "true")

-- Stress
Config.WhitelistedWeaponArmed = { -- weapons specifically whitelisted to not show armed mode
    -- miscellaneous
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`,
    -- melee
    `weapon_dagger`,
    `weapon_bat`,
    `weapon_bottle`,
    `weapon_crowbar`,
    `weapon_flashlight`,
    `weapon_golfclub`,
    `weapon_hammer`,
    `weapon_hatchet`,
    `weapon_knuckle`,
    `weapon_knife`,
    `weapon_machete`,
    `weapon_switchblade`,
    `weapon_nightstick`,
    `weapon_wrench`,
    `weapon_battleaxe`,
    `weapon_poolcue`,
    `weapon_briefcase`,
    `weapon_briefcase_02`,
    `weapon_garbagebag`,
    `weapon_handcuffs`,
    `weapon_bread`,
    `weapon_stone_hatchet`,
    -- throwables
    `weapon_grenade`,
    `weapon_bzgas`,
    `weapon_molotov`,
    `weapon_stickybomb`,
    `weapon_proxmine`,
    `weapon_snowball`,
    `weapon_pipebomb`,
    `weapon_ball`,
    `weapon_smokegrenade`,
    `weapon_flare`
}

Config.WhitelistedWeaponStress = {
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

Config.BlurLevels = {
    [1] = {
        min = 50,
        max = 60,
        intensity = 2000,
        timeout = math.random(50000, 60000)
    },
    [2] = {
        min = 60,
        max = 70,
        intensity = 2500,
        timeout = math.random(40000, 50000)
    },
    [3] = {
        min = 70,
        max = 80,
        intensity = 3000,
        timeout = math.random(30000, 40000)
    },
    [4] = {
        min = 80,
        max = 90,
        intensity = 3500,
        timeout = math.random(20000, 30000)
    },
    [5] = {
        min = 90,
        max = 100,
        intensity = 4000,
        timeout = math.random(10000, 20000)
    }
}

Config.FuelBlacklist = {
    "surge",
    "iwagen",
    "voltic",
    "voltic2",
    "raiden",
    "cyclone",
    "tezeract",
    "neon",
    "omnisegt",
    "iwagen",
    "caddy",
    "caddy2",
    "caddy3",
    "airtug",
    "rcbandito",
    "imorgon",
    "dilettante",
    "khamelion",
    "wheelchair",
}

Config.VehClassStress = { -- Enable/Disable gaining stress from vehicle classes in this table
    ["0"] = true,         -- Compacts
    ["1"] = true,         -- Sedans
    ["2"] = true,         -- SUVs
    ["3"] = true,         -- Coupes
    ["4"] = true,         -- Muscle
    ["5"] = true,         -- Sports Classics
    ["6"] = true,         -- Sports
    ["7"] = true,         -- Super
    ["8"] = false,        -- Motorcycles
    ["9"] = true,         -- Off Road
    ["10"] = true,        -- Industrial
    ["11"] = true,        -- Utility
    ["12"] = true,        -- Vans
    ["13"] = false,       -- Cycles
    ["14"] = false,       -- Boats
    ["15"] = false,       -- Helicopters
    ["16"] = false,       -- Planes
    ["18"] = false,       -- Emergency
    ["19"] = false,       -- Military
    ["20"] = false,       -- Commercial
    ["21"] = false        -- Trains
}
