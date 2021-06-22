ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

Bill = Bill or {}
Bill.Data = {}
Bill.UnemployedJob = "unemployed"

function GetPlayers() -- Get Les joueurs
	local players = {}

	for _,player in ipairs(GetActivePlayers()) do
		local ped = GetPlayerPed(player)

		if DoesEntityExist(ped) then
			table.insert(players, player)
		end
	end

	return players
end

function GetNearbyPlayers(distance) -- Get des joueurs dans la zone
	local ped = GetPlayerPed(-1)
	local playerPos = GetEntityCoords(ped)
	local nearbyPlayers = {}

	for _,v in pairs(GetPlayers()) do
		local otherPed = GetPlayerPed(v)
		local otherPedPos = otherPed ~= ped and IsEntityVisible(otherPed) and GetEntityCoords(otherPed)

		if otherPedPos and GetDistanceBetweenCoords(otherPedPos, playerPos) <= (distance or max) then
			nearbyPlayers[#nearbyPlayers + 1] = v
		end
	end
	return nearbyPlayers
end

local cWait = false;
local xWait = false
function GetNearbyPlayer(solo, other) -- Sélectionner un joueur si plusieurs sont collé à vous
    if cWait then
        xWait = true
        while cWait do
            Citizen.Wait(5)
        end
    end
    xWait = false
    local cTimer = GetGameTimer() + 10000;
    local oPlayer = GetNearbyPlayers(2)
    if solo then
        oPlayer[#oPlayer + 1] = PlayerId()
    end
    if #oPlayer == 0 then
        ESX.ShowNotification("~b~Distance\n~w~Rapprochez-vous.")
        return false
    end
    if #oPlayer == 1 and other then
        return oPlayer[1]
    end
    ESX.ShowNotification("~r~Appuyer sur ~g~E~r~ pour valider.~n~~r~Appuyer sur ~b~A~r~ pour changer de cible.~n~~r~Appuyer sur ~b~X~r~ pour annuler.")
    Citizen.Wait(100)
    local cBase = 1
    cWait = true
    while GetGameTimer() <= cTimer and not xWait do
        Citizen.Wait(0)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 73, true)
        DisableControlAction(0, 44, true)
        if IsDisabledControlJustPressed(0, 38) then
            cWait = false
            return oPlayer[cBase]
        elseif IsDisabledControlJustPressed(0, 73) then
            ESX.ShowNotification("~r~Vous avez annulé.")
            break
        elseif IsDisabledControlJustPressed(0, 44) then
            cBase = (cBase == #oPlayer) and 1 or (cBase + 1)
        end
        local cPed = GetPlayerPed(oPlayer[cBase])
        local cCoords = GetEntityCoords(cPed)
        DrawMarker(0, cCoords.x, cCoords.y, cCoords.z + 1.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.1, 0.1, 0.1, 0, 180, 10, 30, 1, 1, 0, 0, 0, 0, 0)
    end
    cWait = false
    return false
end

function AskEntry(callback, name, lim, default)
	AddTextEntry('FMMC_KEY_TIP8', name or "Montant")
	DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", default, "", "", "", lim or 60)

	while UpdateOnscreenKeyboard() == 0 do
		Citizen.Wait(10)
		if UpdateOnscreenKeyboard() >= 1 then
			callback(GetOnscreenKeyboardResult())
			break
		end
	end
end

RegisterNetEvent("cBill:BillPlayer")
AddEventHandler("cBill:BillPlayer", function(data)
    local player = PlayerPedId()
    local pPed = player

    local closestPly = GetNearbyPlayer(false, true)

    if not closestPly then 
        return
    end

    TaskStartScenarioInPlace(player, "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, true)

    if data ~= 2 and ESX.PlayerData.job.name == Bill.UnemployedJob then return ESX.ShowNotification("Votre métier n'accepte pas les facture.") end

    AskEntry(function(motif)
        if motif then
            AskEntry(function(count)
                count = tonumber(count)
                print(count)
                if count then
                    Bill.Data = {
                        title = motif,
                        price = count,
                        playerId = GetPlayerServerId(closestPly),
                        solo = data == 2 and true or false,
                        account = data ~= 2 and "society_"..ESX.PlayerData.job.name
                    }
                    TriggerServerEvent("cBill:SendBill", Bill.Data)
                    ClearPedTasks(pPed)
                else
                    ESX.ShowNotification("~r~Veuillez renseigner un montant.")
                    ClearPedTasks(pPed)
                end
            end, "Entrez le prix de la facture.")
        else
            ESX.ShowNotification("~r~Veuillez renseigner un motif.")
            ClearPedTasks(pPed)
        end
    end, "Entrez le motif de la facture.")
end)

TriggerPlayerEvent = function(name, source, ...)
    TriggerServerEvent("clp_facture:PlayerEvent",name,source,...)
end

function TaskPlayAnimToPlayer(a,b,c,d,e)if type(a)~="table"then a={a}end;d,c=d or GetPlayerPed(-1),c and tonumber(c)or false;if not a or not a[1]or string.len(a[1])<1 then return end;if IsEntityPlayingAnim(d,a[1],a[2],3)or IsPedActiveInScenario(d)then ClearPedTasks(d)return end;Citizen.CreateThread(function()TaskForceAnimPlayer(a,c,{ped=d,time=b,pos=e})end)end;local f={"WORLD_HUMAN_MUSICIAN","WORLD_HUMAN_CLIPBOARD"}local g={["WORLD_HUMAN_BUM_WASH"]={"amb@world_human_bum_wash@male@high@idle_a","idle_a"},["WORLD_HUMAN_SIT_UPS"]={"amb@world_human_sit_ups@male@idle_a","idle_a"},["WORLD_HUMAN_PUSH_UPS"]={"amb@world_human_push_ups@male@base","base"},["WORLD_HUMAN_BUM_FREEWAY"]={"amb@world_human_bum_freeway@male@base","base"},["WORLD_HUMAN_CLIPBOARD"]={"amb@world_human_clipboard@male@base","base"},["WORLD_HUMAN_VEHICLE_MECHANIC"]={"amb@world_human_vehicle_mechanic@male@base","base"}}function TaskForceAnimPlayer(a,c,h)c,h=c and tonumber(c)or false,h or{}local d,b,i,j,k,l=h.ped or GetPlayerPed(-1),h.time,h.clearTasks,h.pos,h.ang;if IsPedInAnyVehicle(d)and(not c or c<40)then return end;if not i then ClearPedTasks(d)end;if not a[2]and g[a[1]]and GetEntityModel(d)==-1667301416 then a=g[a[1]]end;if a[2]and not HasAnimDictLoaded(a[1])then if not DoesAnimDictExist(a[1])then return end;RequestAnimDict(a[1])while not HasAnimDictLoaded(a[1])do Citizen.Wait(10)end end;if not a[2]then ClearAreaOfObjects(GetEntityCoords(d),1.0)TaskStartScenarioInPlace(d,a[1],-1,not TableHasValue(f,a[1]))else if not j then TaskPlayAnim(d,a[1],a[2],8.0,-8.0,-1,c or 44,1,0,0,0,0)else TaskPlayAnimAdvanced(d,a[1],a[2],j.x,j.y,j.z,k.x,k.y,k.z,8.0,-8.0,-1,1,1,0,0,0)end end;if b and type(b)=="number"then Citizen.Wait(b)ClearPedTasks(d)end;if not h.dict then RemoveAnimDict(a[1])end end;function TableHasValue(m,n,o)if not m or not n or type(m)~="table"then return end;for p,q in pairs(m)do if o and q[o]==n or q==n then return true,p end end end

RegisterCommand("facture", function(user, args)
    local type = args[1]
    if type == "solo" then 
        TriggerEvent("cBill:BillPlayer", 2)
    elseif type == "entreprise" then 
        TriggerEvent("cBill:BillPlayer", 1)
    else
        ESX.ShowNotification("~r~Le type de la facture invalide.")
    end
end)

RegisterNetEvent("cBill:GetBill")
AddEventHandler("cBill:GetBill", function(bill)
    local player = PlayerPedId()
    local pPed = player
    local price = bill.price.

    ESX.ShowNotification("Facture: ~b~"..bill.title.."~s~.\nMontant: ~g~"..price.."$~s~.")
    ESX.ShowNotification("Accepter: ~b~E ~s~ou Refuser: ~r~X~s~.")

    Bill.OnThread = false
    Bill.HavePayed = false
    Bill.OnThread = true
    Citizen.CreateThread(function()
        while true do 
            Wait(1)
            if Bill.OnThread and IsControlJustPressed(1, 51) then 
                Bill.OnThread = false
                TriggerServerEvent("cBill:PayBills", bill, price)

                TaskPlayAnimToPlayer({"mp_common", "givetake2_a"}, 2500, 51)
                PlaySoundFrontend(-1, 'Bus_Schedule_Pickup', 'DLC_PRISON_BREAK_HEIST_SOUNDS', false)
                Bill.HavePayed = true
            end
            if Bill.OnThread and IsControlJustPressed(1, 73) then 
                Bill.OnThread = false
                ESX.ShowNotification("~r~Vous avez refusé de payé la facture.")
                TriggerPlayerEvent("esx:showNotification", bill.source, "~r~La personne a refusé de payé la facture.")
                Bill.HavePayed = true
            end
        end
    end)
    Wait(6000)
    if not Bill.HavePayed then
        ESX.ShowNotification("~r~Vous avez refusé de payé la facture.")
        TriggerPlayerEvent("esx:showNotification", bill.source, "~r~La personne n'a pas payé.")
    end
    Bill.OnThread = false
    Bill.Data = {}
end)

RegisterNetEvent('cBill:AlertBill')
AddEventHandler('cBill:AlertBill', function(data)
    if data == 1 then 
        ESX.ShowNotification("~b~La personne a payé la facture.")
    elseif data == 2 then 
        ESX.ShowNotification("~r~La personne n'a pas assez d'argent.")
    end
end)