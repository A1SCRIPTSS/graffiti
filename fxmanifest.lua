fx_version 'cerulean'
game 'gta5'

author 'Kalajiqta - Matrix Development'
description 'QBCore Graffiti - Updated for ox_lib'
version '1.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client_main.lua',
    'client/client_functions.lua',
    'client/client_admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server_main.lua',
    'server/server_functions.lua',
    'server/server_admin.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qb-core'
}

lua54 'yes'