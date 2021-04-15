ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function GetProperty(name)

	for i=1, #Config.Zones, 1 do
	
		if Config.Zones[i].name == name then
		
			return Config.Zones[i]
			
		end
		
	end
	
end

function SetPropertyOwned(name, price, rented, owner, type)

	MySQL.Async.execute('INSERT INTO owned_properties (name, price, rented, owner, type) VALUES (@name, @price, @rented, @owner, @type)',
	
	{
		
		['@name']   = name,
		
		['@price']  = price,
		
		['@rented'] = (rented and 1 or 0),
		
		['@owner']  = owner,
		
		['@type'] = type
		
	}, function(rowsChanged)
	
		local xPlayer = ESX.GetPlayerFromIdentifier(owner)

		if xPlayer then
		
			TriggerClientEvent('ons_rental_room:setPropertyOwned', xPlayer.source, name, true)

			if rented then
			
				if type == 'rental' then
				
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('rented_room', ESX.Math.GroupDigits(price)))
				
				end
				
			end
			
		end
		
	end)
	
end

function RemoveOwnedProperty(name, owner)

	local property = GetProperty(name)
	
	MySQL.Async.execute('DELETE FROM owned_properties WHERE name = @name AND owner = @owner',
	
	{
		
		['@name']  = name,
		
		['@owner'] = owner
		
	}, function(rowsChanged)
	
		local xPlayer = ESX.GetPlayerFromIdentifier(owner)

		if xPlayer then
			
			if property.rentalroom == 'property' then
			
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('made_room'))
			
			end
			
		end
		
	end)
	
end

ESX.RegisterServerCallback('ons_rental_room:getLastProperty', function(source, cb)

	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT last_rental FROM users WHERE identifier = @identifier', {
		
		['@identifier'] = xPlayer.identifier
		
	}, function(users)
	
		cb(users[1].last_rental)
		
	end)
	
end)

ESX.RegisterServerCallback('ons_rental_room:GetOwnerShip', function(source, cb)

	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_properties WHERE owner = @owner', {
		
	['@owner'] = xPlayer.identifier
	
	}, function(ownedProperties)
	
		local properties = {}

		for i=1, #ownedProperties, 1 do
		
			table.insert(properties, ownedProperties[i].name)
			
		end

		cb(properties)
		
	end)
	
end)

ESX.RegisterServerCallback('ons_rental_room:getPlayerDressing', function(source, cb)

	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
	
		local count  = store.count('dressing')
		
		local labels = {}

		for i=1, count, 1 do
		
			local entry = store.get('dressing', i)
			
			table.insert(labels, entry.label)
			
		end

		cb(labels)
		
	end)
	
end)

ESX.RegisterServerCallback('ons_rental_room:getPlayerOutfit', function(source, cb, num)

	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
	
		local outfit = store.get('dressing', num)
		
		cb(outfit.skin)
		
	end)
	
end)

ESX.RegisterServerCallback('ons_rental_room:getRentalInventory', function(source, cb, owner)

	local xPlayer    = ESX.GetPlayerFromIdentifier(owner)
	
	local blackMoney = 0
	
	local items      = {}
	
	local weapons    = {}

	TriggerEvent('esx_addonaccount:getAccount', 'property_black_money', xPlayer.identifier, function(account)
	
		blackMoney = account.money
		
	end)

	TriggerEvent('esx_addoninventory:getInventory', 'property', xPlayer.identifier, function(inventory)
	
		items = inventory.items
		
	end)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
	
		weapons = store.get('weapons') or {}
		
	end)

	cb({
		
		blackMoney = blackMoney,
		
		items      = items,
		
		weapons    = weapons
		
	})
	
end)

RegisterServerEvent('ons_rental_room:deleteLastProperty')
AddEventHandler('ons_rental_room:deleteLastProperty', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE users SET last_rental = NULL WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	})
end)

RegisterServerEvent('ons_rental_room:removeOutfit')
AddEventHandler('ons_rental_room:removeOutfit', function(label)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local dressing = store.get('dressing') or {}

		table.remove(dressing, label)
		store.set('dressing', dressing)
	end)
end)

function PayRent(d, h, m)

	MySQL.Async.fetchAll('SELECT * FROM owned_properties WHERE rented = 1', {}, function (result)
	
		for i=1, #result, 1 do
		
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)

			-- message player if connected
			
			if xPlayer then
			
				xPlayer.removeAccountMoney('bank', result[i].price)
				
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('paid_rent', ESX.Math.GroupDigits(result[i].price)))
				
			else -- pay rent either way
			
				MySQL.Sync.execute('UPDATE users SET bank = bank - @bank WHERE identifier = @identifier',
				
				{
					
					['@bank']       = result[i].price,
					
					['@identifier'] = result[i].owner
					
				})
				
			end

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_realestateagent', function(account)
			
				account.addMoney(result[i].price)
				
			end)
			
		end
		
	end)
	
end

TriggerEvent('cron:runAt', 22, 0, PayRent)