fx_version 'cerulean'
game 'gta5'

author 'croky18'
description 'Car Showroom with oxib and SQL'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependency 'qb-menu' -- alleen als je qb-menu wilt gebruiken!!
