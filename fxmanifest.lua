fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'lsn-evidence a Evidence Script by LeSiiN'
version '0.1.2'

shared_scripts {
	'config.lua',
	'@qb-core/shared/locale.lua',
	'@ox_lib/init.lua', -- For Later Locale addition maybe ( but no need )
	'locales/en.lua',
	'locales/*.lua'
}

client_scripts {
	'client/evidence.lua'
}

server_scripts {
	'server/main.lua'
}
