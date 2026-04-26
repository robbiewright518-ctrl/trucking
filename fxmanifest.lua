fx_version 'cerulean'
game 'gta5'

author 'Riley202020'
description 'Trucking'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'shared/config.lua',
    'shared/constants.lua',
    'shared/utils.lua'
}

client_scripts {
    'core/client/framework.lua',
    'jobs/client/jobs.lua',
    'vehicles/client/vehicles.lua',
    'progression/client/progression.lua',
    'ui/client/ui.lua',
    'ui/client/nui.lua'
}

server_scripts {
    'core/server/framework.lua',
    'shared/database.lua',
    'jobs/server/jobs.lua',
    'vehicles/server/vehicles.lua',
    'progression/server/progression.lua',
    'progression/server/criminal.lua',
    'progression/server/achievements.lua',
    'progression/server/perks.lua',
    'logs/logging.lua'
}

files {
    'ui/html/index.html',
    'ui/html/css/style.css',
    'ui/html/js/app.js',
    'ui/html/js/ui.js',
    'locale/en.json',
    'locale/es.json'
}

ui_page 'ui/html/index.html'

dependencies {
    '/server:5104',
    '/onesync'
}

exports {
    'GetFramework',
    'IsPlayerWorking',
    'GetPlayerLevel',
    'GetPlayerXP',
    'CompleteJob'
}
