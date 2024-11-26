fx_version "cerulean"
use_experimental_fxv2_oal "yes"
lua54 "yes"
game "gta5"

name "ps-hud"
version "2.1.2"
description "HUD"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/*.lua",
    "uiconfig.lua"
}

server_scripts {
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}

ui_page "html/index.html"

files {
    "html/*",
    "locales/*.json",
    "modules/**/*.lua"
}
