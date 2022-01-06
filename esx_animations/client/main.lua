local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ragdoll = false
isDead = false
prop = nil
window = nil
loop = {
	status = nil,
	current = nil,
	finish = nil,
	delay = 0,
	dettach = false,
	last = 0
}
binds = nil
binding = nil

ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(5000)
	if not binds then
		TriggerServerEvent('esx_animations:load')
	end
end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
end)

AddEventHandler('esx:onPlayerDeath', function()
	isDead = true
	ragdoll = false
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	TriggerServerEvent('esx_animations:load')
end)

RegisterNetEvent('esx_animations:bind')
AddEventHandler('esx_animations:bind', function(list)
	binds = list
end)

RegisterNetEvent('esx_animations:trigger')
AddEventHandler('esx_animations:trigger', function(anim)
	if anim.type == 'ragdoll' then
		ragdoll = true
	elseif anim.type == 'attitude' then
		startAttitude(anim.data.lib, anim.data.anim)
	elseif anim.type == 'scenario' then
		startScenario(anim.data.anim, anim.data.offset)
	elseif anim.type == 'anim' then
		startAnim(anim.data.lib, anim.data.anim, anim.data.mode, anim.data.prop)
	elseif anim.type == 'facial' then
		TriggerEvent('esx_voice:facial', anim.data)
	else
		startAnimLoop(anim.data)
	end
end)

function startAttitude(lib, anim)
	Citizen.CreateThread(function()
		RequestAnimSet(anim)
		while not HasAnimSetLoaded(anim) do
			Citizen.Wait(0)
		end

		SetPedMovementClipset(PlayerPedId(), anim, true)
	end)
end

function startScenario(anim, offset)
	if loop.status == true then
		finishLoop(function()
			startScenario(anim, offset)
		end)
	else
		local ped = PlayerPedId()
		if offset then
			local coords = GetEntityCoords(ped, true)
			TaskStartScenarioAtPosition(ped, anim, coords.x, coords.y, coords.z + offset, GetEntityHeading(ped), 0, true, true)
		else
			TaskStartScenarioInPlace(ped, anim, 0, false)
		end
	end
end

function startAnim(lib, anim, mode, obj)
	if loop.status == true then
		finishLoop(function()
			startAnim(lib, anim, mode, obj)
		end)
	else
		mode = mode or 0
		Citizen.CreateThread(function()
			RequestAnimDict(lib)
			while not HasAnimDictLoaded(lib) do
				Citizen.Wait(0)
			end

			local ped = PlayerPedId()
			TaskPlayAnim(ped, lib, anim, 8.0, -8.0, -1, mode, 0, false, false, false)
			if obj then
				if type(prop) == 'table' then
					DeleteObject(prop.obj)
				end

				local coords = GetEntityCoords(ped)
				local boneIndex = GetPedBoneIndex(ped, obj.bone)
				ESX.Game.SpawnObject(obj.object, {
					x = coords.x,
					y = coords.y,
					z = coords.z + 2
				}, function(object)
					AttachEntityToEntity(object, ped, boneIndex, obj.offset.x + 0.0, obj.offset.y + 0.0, obj.offset.z + 0.0, obj.rotation.x + 0.0, obj.rotation.y + 0.0, obj.rotation.z + 0.0, true, true, false, true, 1, true)
					prop = {obj = object, lib = lib, anim = anim}
				end)
			end
		end)
	end
end

function startAnimLoop(data)
	if loop.status == true then
		finishLoop(function()
			startAnimLoop(data)
		end)
	else
		Citizen.CreateThread(function()
			while loop.status ~= nil do
				Citizen.Wait(0)
			end

			RequestAnimDict(data.base.lib)
			while not HasAnimDictLoaded(data.base.lib) do
				Citizen.Wait(0)
			end

			RequestAnimDict(data.idle.lib)
			while not HasAnimDictLoaded(data.idle.lib) do
				Citizen.Wait(0)
			end

			RequestAnimDict(data.finish.lib)
			while not HasAnimDictLoaded(data.finish.lib) do
				Citizen.Wait(0)
			end

			local playerPed = PlayerPedId()
			if data.prop then
				local coords	= GetEntityCoords(playerPed)
				local boneIndex = GetPedBoneIndex(playerPed, data.prop.bone)
				ESX.Game.SpawnObject(data.prop.object, {
					x = coords.x,
					y = coords.y,
					z = coords.z + 2
				}, function(object)
					AttachEntityToEntity(object, playerPed, boneIndex, data.prop.offset.x + 0.0, data.prop.offset.y + 0.0, data.prop.offset.z + 0.0, data.prop.rotation.x + 0.0, data.prop.rotation.y + 0.0, data.prop.rotation.z + 0.0, true, true, false, true, 1, true)
					prop = object
				end)
			end

			TaskPlayAnim(PlayerPedId(), data.base.lib, data.base.anim, 8.0, -8.0, -1, data.mode, 0, false, false, false)
			loop = {status = true, current = nil, finish = data.finish, delay = (GetGameTimer() + 100), last = 0}

			loop.finish.mode = data.mode
			if data.prop then
				loop.dettach = data.prop.dettach
			else
				loop.dettach = false
			end

			Citizen.Wait(data.base.length)
			while loop.status do
				local rng = #data.idle.anims
				if rng > 1 then
					repeat
						rng = math.random((data.base.entering and 1 or 0), #data.idle.anims)
					until rng ~= loop.last
				end

				loop.delay = GetGameTimer() + 100
				loop.last = rng
				if rng == 0 then
					TaskPlayAnim(PlayerPedId(), data.base.lib, data.base.anim, 8.0, -8.0, -1, data.mode, 0, false, false, false)
					loop.current = data.base
					Citizen.Wait(data.base.length)
				else
					TaskPlayAnim(PlayerPedId(), data.idle.lib, data.idle.anims[rng][1], 8.0, -8.0, -1, data.mode, 0, false, false, false)
					loop.current = {lib = data.idle.lib, anim = data.idle.anims[rng][1]}
					Citizen.Wait(data.idle.anims[rng][2])
				end
			end
		end)
	end
end

function finishLoop(cb)
	loop.status = false
	Citizen.CreateThread(function()
		TaskPlayAnim(PlayerPedId(), loop.finish.lib, loop.finish.anim, 8.0, 8.0, -1, loop.finish.mode, 0, false, false, false)

		Citizen.Wait(loop.finish.length)
		if loop.status == false and prop and type(prop) ~= 'table' then
			if loop.dettach then
				DetachEntity(prop, true, false)
			else
				DeleteObject(prop)
			end

			prop = nil
		end

		loop.status = nil
		if cb then
			cb()
		end
	end)
end

function OpenAnimationsMenu()
	local elements = {}
	if not binding then
		if binds then
			table.insert(elements, {label = "Ulubione (SHIFT+#)", value = "binds"})
		end

		table.insert(elements, {label = "- PRZERWIJ -", value = "cancel"})
	end

	for _, group in ipairs(Config.Animations) do
		if not group.resource or GetResourceState(group.resource) == 'started' then
			table.insert(elements, {label = group.label, value = group.name})
		end
	end

	window = ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'animations', {
		title    = 'Animacje',
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		if data.current.value == "binds" then
			menu.close()
			window = nil
			OpenBindsSubMenu()
		elseif data.current.value ~= "cancel" then
			menu.close()
			window = nil
			OpenAnimationsSubMenu(data.current.value)
			clearTask()
		end
	end, function(data, menu)
		menu.close()

		window = nil
		if binding then
			binding = nil
			OpenBindsSubMenu()
		end
	end)
end

function OpenBindsSubMenu()
	local elements = {}
	for i = 1, 9 do
		local bind = binds[i]
		if bind then
			table.insert(elements, {label = i .. ' - ' .. bind.label, value = i, assigned = true})
		else
			table.insert(elements, {label = i .. ' - PRZYPISZ', value = i, assigned = false})
		end
	end

	window = ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'animations_binds', {
		title    = 'Animacje - ulubione',
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		menu.close()
		window = nil

		local index = tonumber(data.current.value)
		if data.current.assigned then
			binds[index] = nil
			TriggerServerEvent('esx_animations:save', binds)
			OpenBindsSubMenu()
		else
			binding = tonumber(data.current.value)
			OpenAnimationsMenu()
		end
	end, function(data, menu)
		menu.close()
		window = nil
		OpenAnimationsMenu()
	end)
end

function OpenAnimationsSubMenu(menu)
	local title, elements = nil, {}
	for _, group in ipairs(Config.Animations) do
		if group.name == menu then
			for _, item in ipairs(group.items) do
				table.insert(elements, {label = item.label .. (item.keyword and ' <span style="font-size: 11px; color: #fff000;">/e ' .. item.keyword .. '</span>' or ''), short = item.label, type = item.type, data = item.data})
			end

			title = group.label
			break
		end
	end

	window = ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'animations_' .. menu, {
		title    = title,
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		if binding then
			menu.close()

			window = nil
			if not binds then
				binds = {}
			end

			binds[binding] = {
				label = '[' .. title .. '] ' .. data.current.short,
				type = data.current.type,
				data = data.current.data
			}
			TriggerServerEvent('esx_animations:save', binds)

			binding = nil
			OpenBindsSubMenu()
		else
			TriggerEvent('esx_animations:trigger', data.current)
		end
	end, function(data, menu)
		menu.close()
		window = nil
		OpenAnimationsMenu()
	end)
end

local prone = false
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(200)
		local last = prone

		prone = exports['central_stance']:isPlayerProne()
		if last ~= prone and prone then
			loop.status = nil
			if window then
				window.close()
				window = nil
			end

			ragdoll = false
			if prop then
				if type(prop) == 'table' then
					DeleteObject(prop.obj)
				elseif loop.dettach then
					DetachEntity(prop, true, false)
				else
					DeleteObject(prop)
				end

				prop = nil
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local ped = PlayerPedId()
		if ragdoll then
			SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
		end

		if loop.status and loop.current and loop.delay < GetGameTimer() and not IsEntityPlayingAnim(ped, loop.current.lib, loop.current.anim, 3) then
			loop.status = nil
			if prop and type(prop) ~= 'table' then
				if loop.dettach then
					DetachEntity(prop, true, false)
				else
					DeleteObject(prop)
				end

				prop = nil
			end
		end

		if type(prop) == 'table' and not IsEntityPlayingAnim(ped, prop.lib, prop.anim, 3) then
			DeleteObject(prop.obj)
			prop = nil
		end

		if IsControlPressed(0, Keys['LEFTSHIFT']) and not IsPedSprinting(ped) and not IsPedRunning(ped) then
			local bind = nil
			for i, key in ipairs({157, 158, 160, 164, 165, 159, 161, 162, 163}) do
				DisableControlAction(0, key, true)
				if IsDisabledControlJustPressed(0, key) and binds[i] then
					bind = i
					break
				end
			end

			if bind and not isDead and not prone then
				TriggerEvent('esx_animations:trigger', binds[bind])
			end
		end
	end
end)

RegisterCommand("AnimationsMenu", function()
	if not isDead and not prone then
		binding = nil
		OpenAnimationsMenu()
	end	
end)

RegisterKeyMapping("AnimationsMenu", "Menu Animacji", "keyboard", "F3")

RegisterCommand("ClearAnim", function()
	if not isDead and not prone then
		clearTask()
	end	
end)

RegisterKeyMapping("ClearAnim", "Zakonczenie animacji", "keyboard", "X")

function clearTask()
	if loop.status == true then
		finishLoop()
	elseif ragdoll then
		ragdoll = false
	else
		ClearPedTasks(PlayerPedId())
		if loop.status ~= nil then
			loop.status = nil
			if prop and type(prop) ~= 'table' then
				if loop.dettach then
					DetachEntity(prop, true, false)
				else
					DeleteObject(prop)
				end

				prop = nil
			end
		elseif type(prop) == 'table' then
			DeleteObject(prop.obj)
			prop = nil
		end
	end
end