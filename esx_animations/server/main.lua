ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
local keywords = {}
 for _, group in ipairs(Config.Animations) do
    for _, anim in ipairs(group.items) do
        if anim.keyword then
             keywords[anim.keyword] = anim
            end
          end
     end

TriggerEvent('es:addCommand', 'e', function(source, args, user)
           if not args[1] or args [1] == '' then
        return
 end
       local anim = keywords[args[1]]
            if anim then
              TriggerClientEvent('esx_animations:trigger', source, anim)
          end 
     end)

RegisterServerEvent('esx_animations:load')
AddEventHandler('esx_animations:load', function()
      TriggerEvent('esx_datastore:getDataStore', 'animations', GetPlayerIdentifiers(source)[1], function(data)
     local list = data.get('list') or {}
         TriggerClientEvent('esx_animations:bind', source, list)
      end)
  end)


RegisterServerEvent('esx_animations:save')
 AddEventHandler('esx_animations:save', function(array)
    local xPlayer = ESX.GetPlayerFromId(source)
      TriggerEvent('esx_datastore:getDataStore', 'animations', xPlayer.identifier, function(data)
         data.set('list', array)
      end)
  end)


  RegisterServerEvent('esx_animations:synchroContinue')
  AddEventHandler('esx_animations:synchroContinue', function(target, anim)
    local targetPlayer = ESX.GetPlayerFromId(target)
  
    TriggerClientEvent('esx_animations:synchroAllow', targetPlayer.source, source, anim)
  end)


RegisterServerEvent('esx_animations:synchroAccept')
AddEventHandler('esx_animations:synchroAccept', function(target, anim)
	local targetPlayer = ESX.GetPlayerFromId(target)
	TriggerClientEvent('esx_animationsPlaySynchroSource', targetPlayer.source, source, anim)
  TriggerClientEvent('esx_animationsPlaySynchroTarget', source, targetPlayer.source, anim)
end)

RegisterServerEvent('esx_animations:denyPodnies')
AddEventHandler('esx_animations:denyPodnies', function(target)
	local targetPlayer = ESX.GetPlayerFromId(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent("FeedM:showNotification", targetPlayer.source, '~r~Osoba się nie zgodziła!', 5000, 'primary')
end)