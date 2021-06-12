ESX = nil
TriggerEvent('esx:getSharedObject', function(a)
    ESX = a 
end)

RegisterServerEvent("cCall:SendCallMsg")
AddEventHandler("cCall:SendCallMsg", function(msg, coords, job, tel)
    local xPlayers = ESX.GetPlayers()
    local xSource = ESX.GetPlayerFromId(source)
    for k, v in pairs(xPlayers) do 
        local xPlayer = ESX.GetPlayerFromId(v)

        if xPlayer.job.name == job then
            TriggerClientEvent("cCall:SendMessageCall", xPlayer.source, msg, coords, job, source, tel)
        end
    end
end)

RegisterServerEvent("cCall:TookServerCall")
AddEventHandler("cCall:TookServerCall", function(xTarget, pPos, pos)
    TriggerClientEvent("cCall:TookCall", xTarget, pPos, pos)
end)