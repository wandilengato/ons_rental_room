resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

game 'gta5'

description 'Motels Rental Room Made Wandilengato'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'config.lua',
	'ons_rental_room_sv.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'config.lua',
	'ons_rental_room_cl.lua'
}
