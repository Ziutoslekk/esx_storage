ESX = nil

IsAdmin = nil
Blacklist = {
	`adder`,
    `prototipo`,
}

SavedVehicles = {}
SavedClothes = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while true do
		if IsControlJustPressed(0, 182) then
			OpenMenu()
		end

		Citizen.Wait(10)
	end
end)

OpenMenu = function()
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'main', {
		title    = "Storage",
		align    = 'right',
		elements = {
			{ label = "Pojazdy", value = "vehicles" },
			{ label = "Ubrania", value = "clothes" }
		}
	}, function(data, menu)
		if (data.current.value == "vehicles") then
			OpenVehiclesMenu()
		elseif (data.current.value == "clothes") then
			OpenClothesMenu()
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenVehiclesMenu = function()
	local elements = {}
	table.insert(elements, { label = "Zapisz aktualny pojazd", value = "save" })

	for index,vehicle in ipairs(SavedVehicles) do
		table.insert(elements, { label = vehicle.label, vehicle = vehicle, index = index })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicles', {
		title    = "Zapisane pojazdy",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		menu.close()

		if (data.current.value ~= "save") then
			OpenVehicleMenu(data.current.vehicle, data.current.index)
		else
			SaveVehicle()
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenVehicleMenu = function(vehicle, index)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		title    = vehicle.label,
		align    = 'right',
		elements = {
			{ label = "Wczytaj", value = "load" },
			{ label = "Usuń", value = "delete" }
		}
	}, function(data, menu)
		menu.close()

		if (data.current.value == "load") then
			if IsBlacklisted(vehicle.props.model) then
				if IsAdmin == nil then
					ESX.TriggerServerCallback("esx_storage:isAdmin", function(isAdmin)
						IsAdmin = isAdmin
					end)

					while IsAdmin == nil do
						Citizen.Wait(0)
					end
				end

				if not IsAdmin then
					ESX.ShowNotification("Nie możesz wczytać tego pojazdu!")

					table.remove(SavedVehicles, index)
					SaveVehicles()

					Citizen.SetTimeout(100, function()
						OpenVehiclesMenu()
					end)

					return
				end
			end

			LoadVehicle(vehicle)
		else
			table.remove(SavedVehicles, index)
			SaveVehicles()

			Citizen.Wait(100)
			OpenVehiclesMenu()
		end
	end, function(data, menu)
		menu.close()
	end)
end

SaveVehicle = function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

	if DoesEntityExist(vehicle) then
		if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
			local props = ESX.Game.GetVehicleProperties(vehicle)

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'vehicle_save', {
				title = "Wpisz nazwę pojazdu"
			}, function(data, menu)
				menu.close()

				if IsBlacklisted(GetEntityModel(vehicle)) then
					if IsAdmin == nil then
						ESX.TriggerServerCallback("esx_storage:isAdmin", function(isAdmin)
							IsAdmin = isAdmin
						end)

						while IsAdmin == nil do
							Citizen.Wait(0)
						end
					end

					if not IsAdmin then
						ESX.ShowNotification("Nie możesz zapisać tego pojazdu!")

						return
					end
				end

				if not data.value or data.value:len() > 15 then
					ESX.ShowNotification("Przekorczyłeś limit znaków (15)!")
					return
				end

				table.insert(SavedVehicles, {
					label = data.value,
					props = props
				})
				SaveVehicles()
				ESX.ShowNotification("Zapisano pojazd.")

				Citizen.Wait(100)
				OpenVehiclesMenu()
			end, function(data, menu)
				menu.close()
			end)
		else
			ESX.ShowNotification("Musisz być kierowcą pojazdu.")
		end
	else
		ESX.ShowNotification("Musisz znajdować się w pojeździe.")
	end
end

LoadVehicle = function(vehicle)
	local oldVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

	if DoesEntityExist(oldVehicle) then
		if GetPedInVehicleSeat(oldVehicle, -1) == PlayerPedId() then
			if GetEntityModel(oldVehicle) == vehicle.props.model then
				ESX.Game.SetVehicleProperties(oldVehicle, vehicle.props)

				ESX.ShowNotification("Wczytano pojazd.")
				ESX.UI.Menu.CloseAll()
			else
				ESX.Game.DeleteVehicle(oldVehicle)

				ESX.Game.SpawnVehicle(vehicle.props.model, GetEntityCoords(PlayerPedId()), GetEntityHeading(), function(veh)
					ESX.Game.SetVehicleProperties(veh, vehicle.props)
					TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

					ESX.ShowNotification("Wczytano pojazd.")
					ESX.UI.Menu.CloseAll()
				end)
			end
		else
			ESX.ShowNotification("Musisz być kierowcą pojazdu.")
			return
		end
	else
		local lastVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
		if DoesEntityExist(lastVehicle) then
			if IsVehicleSeatFree(lastVehicle, -1) then
				ESX.Game.DeleteVehicle(lastVehicle)
			end
		end

		ESX.Game.SpawnVehicle(vehicle.props.model, GetEntityCoords(PlayerPedId()), GetEntityHeading(), function(veh)
			ESX.Game.SetVehicleProperties(veh, vehicle.props)
			TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)

			ESX.ShowNotification("Wczytano pojazd.")
			ESX.UI.Menu.CloseAll()		
		end)
	end
end

OpenClothesMenu = function()
	local elements = {}
	table.insert(elements, { label = "Zapisz aktualny strój", value = "save" })

	for index,clothes in ipairs(SavedClothes) do
		table.insert(elements, { label = clothes.label, clothes = clothes, index = index })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'clothes', {
		title    = "Zapisane stroje",
		align    = 'right',
		elements = elements
	}, function(data, menu)
		menu.close()

		if (data.current.value ~= "save") then
			OpenClothesMenu_2(data.current.clothes, data.current.index)
		else
			SaveClothe()
		end
	end, function(data, menu)
		menu.close()
	end)
end

OpenClothesMenu_2 = function(clothes, index)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'clothes_2', {
		title    = clothes.label,
		align    = 'right',
		elements = {
			{ label = "Wczytaj", value = "load" },
			{ label = "Usuń", value = "delete" }
		}
	}, function(data, menu)
		menu.close()

		if (data.current.value == "load") then
			LoadClothes(clothes)
		else
			table.remove(SavedClothes, index)
			SaveClothes()

			Citizen.Wait(100)
			OpenClothesMenu()
		end
	end, function(data, menu)
		menu.close()
	end)
end

SaveClothe = function()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'clothes_save', {
		title = "Wpisz nazwę stroju"
	}, function(data, menu)
		menu.close()

		if not data.value or data.value:len() > 15 then
			ESX.ShowNotification("Przekorczyłeś limit znaków (15)!")
			return
		end

		TriggerEvent('skinchanger:getSkin', function(skin)
			table.insert(SavedClothes, { label = data.value, skin = skin })
			SaveClothes()

			ESX.ShowNotification("Zapisano strój.")

			Citizen.Wait(100)
			OpenClothesMenu()
		end)
	end, function(data, menu)
		menu.close()
	end)
end

LoadClothes = function(clothes)
	TriggerEvent('skinchanger:loadSkin', clothes.skin)
	
	ESX.ShowNotification("Wczytano strój.")
	ESX.UI.Menu.CloseAll()
end

IsBlacklisted = function(model)
	for _,mdl in ipairs(Blacklist) do
		if model == mdl then
			return true
		end
	end

	return false
end

--[[ HTML Storage ]]--
RegisterNUICallback("setVehicles", function(data)
	if data.vehicles then
		SavedVehicles = data.vehicles
		table.sort(SavedVehicles, function(a, b) return a.label < b.label end)
	end
end)

RegisterNUICallback("setClothes", function(data)
	if data.clothes then
		SavedClothes = data.clothes
		table.sort(SavedClothes, function(a, b) return a.label < b.label end)
	end
end)

SaveVehicles = function(overwrite)
	SendNUIMessage({ action = "updateVehicles", json = json.encode(overwrite or SavedVehicles) })
	table.sort(SavedVehicles, function(a, b) return a.label < b.label end)
end

SaveClothes = function(overwrite)
	SendNUIMessage({ action = "updateClothes", json = json.encode(overwrite or SavedClothes) })
	table.sort(SavedClothes, function(a, b) return a.label < b.label end)
end