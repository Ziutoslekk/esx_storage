ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("esx_storage:isAdmin", function(source, cb)
	cb( IsPlayerAceAllowed(source, "storage.blacklist") )
end)