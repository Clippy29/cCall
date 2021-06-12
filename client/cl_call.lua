Call = Call or {}
Call.blip = nil
Call.calls = {
    { name = "~r~Vider les appels" },
}
Call.notif = nil
Call.notif1 = nil

Call.InService = false

ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

-- List calls details
Call.Jobs = {
	{ name = "cardealer", label = "Premium Deluxe Motorsport", image = "CHAR_CARSITE", msg = "~b~Appel Entreprise"},
	{ name = "mechanic", label = "Hayes Auto", image = "CHAR_CARSITE3", msg = "~b~Appel Entreprise"},
	{ name = "realestateagent", label = "Agence immobilière", image = "CHAR_PLANESITE", msg = "~b~Appel Entreprise"},
	{ name = "ambulance", label = "Los Santos Medical Center", image = "CHAR_CALL911", msg = "~r~Appel d'urgence"},
	{ name = "police", label = "Los Santos Police Department", image = "CHAR_CALL911", msg = "~r~Appel d'urgence"},
	{ name = "unicorn", label = "Vanilla Unicorn", image = "CHAR_MP_STRIPCLUB_PR", msg = "~b~Appel Entreprise"},
	{ name = "casino", label = "Diamond Casino & Resort", image = "CHAR_CASINO", msg = "~b~Appel Entreprise"},
}

RegisterNetEvent("cCall:TookCall")
AddEventHandler("cCall:TookCall", function(pos)
    local player = PlayerPedId()
    local pPed = player 
    local pPos = GetEntityCoords(player)
    local dist = math.floor(Vdist(pPos, pos))
    ESX.ShowNotification("Votre appel a été enregistré. (~b~"..dist.."m~s~)")
end)

-- Trigger to take his service
RegisterNetEvent("cCall:OnService")
AddEventHandler("cCall:OnService", function()
    if Call.InService then 
        Call.InService = false 
        if NotifId then RemoveNotification(NotifId) end 
        NotifId = ESX.ShowNotification("~r~Vous avez désactivé votre service.")
    else
        Call.InService = true 
        if NotifId then RemoveNotification(NotifId) end 
        NotifId = ESX.ShowNotification("~b~Vous avez activé votre service.")
    end
end)

-- Block EULEN Triggers
function Rsv(name, ...)
	TriggerServerEvent(name, ...)
end

-- Notification
function ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
	if saveToBrief == nil then saveToBrief = true end
	AddTextEntry('STRINGSS', msg)
	BeginTextCommandThefeedPost('STRINGSS')
	if hudColorIndex then ThefeedNextPostBackgroundColor(hudColorIndex) end
	EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
	EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

-- Blips
function CreateBlips(vector3Pos, intSprite, intColor, stringText, boolRoad, floatScale, intDisplay, intAlpha) -- Créer un blips
	local blip = AddBlipForCoord(vector3Pos.x, vector3Pos.y, vector3Pos.z)
	SetBlipSprite(blip, intSprite)
	SetBlipAsShortRange(blip, true)
	if intColor then 
		SetBlipColour(blip, intColor) 
	end
	if floatScale then 
		SetBlipScale(blip, floatScale) 
	end
	if boolRoad then 
		SetBlipRoute(blip, boolRoad) 
	end
	if intDisplay then 
		SetBlipDisplay(blip, intDisplay) 
	end
	if intAlpha then 
		SetBlipAlpha(blip, intAlpha) 
	end
	if stringText and (not intDisplay or intDisplay ~= 8) then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(stringText)
		EndTextCommandSetBlipName(blip)
	end
	return blip
end

RegisterNetEvent("cCall:SendMessageCall")
AddEventHandler("cCall:SendMessageCall", function(msg, coords, job, source, tel)
    local player = PlayerPedId()
    local pPed = player 
    local pPos = GetEntityCoords(player)
    local multiplier = math.random(50, 100)
    coords = tel and coords or vector3(coords.x + multiplier, coords.y + multiplier, coords.z)
    if source ~= GetPlayerServerId(PlayerId()) and Call.InService then
        Call.calls[#Call.calls+1] = { name = "Appel N°" .. #Call.calls, coords = coords, player = source, Description = msg, tel = tel }

        local dist = math.floor(Vdist(pPos, coords))
        local namestreet = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)).." ("..math.ceil(dist).."m)"
        msg = "Rue: ~b~"..namestreet.."~s~.\nSujet: ~b~"..msg.."~s~."
        for k,v in pairs(Call.Jobs) do 
            if v.name == job then 
                if Call.notif then RemoveNotification(Call.notif) end
                Call.notif = ShowAdvancedNotification(v.label, v.smg or "Dispatch", msg, v.image or "CHAR_CALL911", 1)
            end
        end
        if Call.notif then RemoveNotification(Call.notif) end
        Call.notif = ESX.ShowNotification("Accepter: ~b~W~s~. Refuser: ~r~X~s~.")
 
        Citizen.CreateThread(function()
            while true do
                breakThread = nil
                Wait(5)
                time = 6000
                time = time - 5
                pPos = GetEntityCoords(player)
 
                if IsControlJustPressed(0, 20) then
                    if Call.blip then
                        RemoveBlip(Call.blip)
                        Call.blip = nil
                    end
                    if Call.notif1 then RemoveNotification(Call.notif1) end
                    Call.notif1 = ESX.ShowNotification("~g~Vous avez accepté l'appel.")
                    if tel then 
                        Rsv("cCall:TookServerCall", source, pPos)
                    end
                    Call.blip = CreateBlips(coords, 4, 66, "Appel en cours", true, 0.7)
                    while Call.blip do
                        local dist = Vdist(pPos, coords)
                        pPos = GetEntityCoords(player)
                        local size = IsPedInAnyVehicle(player, false) and 50.0 or 25.0
 
                        if dist < size then
                            if Call.notif1 then RemoveNotification(Call.notif1) end
                            Call.notif1 = ESX.ShowNotification("~g~Vous êtes arrivé à destination.")
                            RemoveBlip(Call.blip)
                            Call.blip = nil    
                            break
                        end
                        Wait(500)
                    end
                    break
                end
 
                if IsControlJustPressed(0, 252) then
                    if Call.notif1 then RemoveNotification(Call.notif1) end
                    Call.notif1 = ESX.ShowNotification("~r~Vous avez refusé l'appel.")
                    break
                end
 
                if time <= 0 then
                    breakThread = true
                    break
                end
 
                if breakThread then
                    break
                end
            end
        end)
    end
end)

-- Menu calls
Call.Menu = {
    Base = { Title = "Liste des appels" },
    Data = { currentMenu = "Liste des appels" },
    Events = {
        onSelected = function(self, menuData, btnData, currentSlt, allButtons)
            local slide = btnData.slidenum
            local btn = btnData.name

            if btnData.coords then
                Citizen.CreateThread(function()
                    if btnData.tel then 
                        Rsv("cCall:TookServerCall", btnData.player, GetEntityCoords(PlayerPedId()))
                    end
                    Call.blip = CreateBlips(btnData.coords, 4, 66, "Appel en cours", true, 0.7)
                    while Call.blip do
                        local player = PlayerPedId()
                        local pPos = GetEntityCoords(player)
                        local dist = Vdist(pPos, btnData.coords)
                        local size = IsPedInAnyVehicle(player, false) and 50.0 or 25.0

                        if dist < size then
                            if Call.notif1 then RemoveNotification(Call.notif1) end
                            Call.notif1 = ESX.ShowNotification("~g~Vous êtes arrivé à destination.")
                            RemoveBlip(Call.blip)
                            Call.blip = nil    
                            break
                        end
                        Wait(500)
                    end
                end)
            else
                Call.calls = {
                    { name = "~r~Vider les appels" },
                }
                CloseMenu(true)
                CreateMenu(menuAppel)
            end                
        end,
    },
    Menu = {
        ["Liste des appels"] = {
            b = function() return Call.calls end
        },
    }
}

-- Trigger for stop call
RegisterNetEvent('cCall:StopCall')
AddEventHandler('cCall:StopCall', function()
    if Call.blip then 
        RemoveBlip(Call.blip)
        Call.blip = nil  
        ESX.ShowNotification("~r~Vous avez annulé l'appel.")
    else
        ESX.ShowNotification("~r~Vous n'avez aucun appel en cours.")
    end
end)

RegisterCommand("appel", function()
    local pPos = GetEntityCoords(PlayerPedId())
    Rsv("cCall:SendCallMsg", "Vol de véhicule", pPos, "police", true)
end)

RegisterKeyMapping('+menucall', "Ouvrir le menu des appels", "keyboard", "F9")
RegisterCommand("+menucall", function()
    CreateMenu(Call.Menu)
end)

RegisterKeyMapping('+stopcall', "Stopper un appel", "keyboard", "F10")
RegisterCommand("+stopcall", function()
    TriggerEvent("cCall:StopCall")
end)