
local ESX = nil
local speedBuffer = {}
local velBuffer = {}
local beltOn = false
local wasInCar  = false

Citizen.CreateThread(function()
	while not ESX do
		ESX = exports["es_extended"]:getSharedObject()
		Citizen.Wait(20)
	end
end)

IsCar = function(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end 

Fwv = function (entity)
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end
 
Citizen.CreateThread(function()
    while true do
    Citizen.Wait(0)
  
        local ped = GetPlayerPed(-1)
        local car = GetVehiclePedIsIn(ped)
        
        if car ~= 0 and (wasInCar or IsCar(car)) then
            wasInCar = true


            if beltOn then DisableControlAction(0, 75) end
        
                speedBuffer[2] = speedBuffer[1]
                speedBuffer[1] = GetEntitySpeed(car)
        
            if speedBuffer[2] ~= nil 
                and not beltOn
                and GetEntitySpeedVector(car, true).y > 1.0  
                and speedBuffer[1] > 19.95
                and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then
                
                local co = GetEntityCoords(ped)
                local fw = Fwv(ped)
                SetEntityCoords(ped, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
                SetEntityVelocity(ped, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
                Citizen.Wait(1)
                SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
            end
            
            velBuffer[2] = velBuffer[1]
            velBuffer[1] = GetEntityVelocity(car)
            if beltOn and IsControlJustReleased(0, 23) and GetLastInputMethod(0) then
                ESX.ShowNotification('Bältet tog i axeln')
            end
            if IsControlJustReleased(0, 29) and GetLastInputMethod(0) then
                beltOn = not beltOn 
                if beltOn then 
                    TriggerEvent("pNotify:SendNotification", {text = 'Säkerhetsbälte <span style="color:green;">på </span>', type = "success", timeout = 1400, layout = "bottomCenter"})

                else 
                    TriggerEvent("pNotify:SendNotification", {text = 'Säkerhetsbälte <span style="color:red;">av</span>', type = "error", timeout = 1400, layout = "bottomCenter"}) 
                end
            end
        
        elseif wasInCar then
            wasInCar = false
            beltOn = false
            speedBuffer[1], speedBuffer[2] = 0.0, 0.0
        end     
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedInAnyVehicle(PlayerPedId(), false) and IsRadarEnabled() then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local fuel    = math.ceil(round(GetVehicleFuelLevel(vehicle), 1))
            local Speed = GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6

            if fuel <= 20 then
                color = "~r~"
            elseif fuel <= 50 then
                color = "~y~"
            elseif fuel <= 100 then
                color = "~g~"
            end
            DrawRect(0.0855, 0.795, 0.1405, 0.03, 34, 35, 35, 220)
            drawTxt(0.521, 	1.277, 1.0,1.0,0.38, "~w~" .. math.ceil(Speed), 255, 255, 255, 255)
            drawTxt(0.532,  1.277, 1.0,1.0,0.38, "~w~ KM/H", 255, 255, 255, 255)
            drawTxt(0.602,  1.277, 1.0,1.0,0.38, "~w~ BRÄNSLE ".. color .." " .. fuel .. ' ~w~%', 255, 255, 255, 255)
            if beltOn then
                drawTxt(0.563,  1.277, 1.0,1.0,0.38, "~w~ BÄLTE  ~g~PÅ", 255, 255, 255, 255)
            elseif not beltOn then
                drawTxt(0.563,  1.277, 1.0,1.0,0.38, "~w~ BÄLTE  ~r~AV", 255, 255, 255, 255)
            end
        end
    end
end)

function round(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function drawTxt(x,y ,width,height,scale, text, r,g,b,a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end
