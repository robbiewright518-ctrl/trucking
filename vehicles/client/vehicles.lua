VehiclesClient = {}
VehiclesClient.CurrentVehicle = nil
VehiclesClient.CurrentTrailer = nil
VehiclesClient.TrailerAttached = false
VehiclesClient.FuelLevel = 100
VehiclesClient.EngineHealth = 1000
VehiclesClient.LastFuelWarning = 0
VehiclesClient.LastDamageWarning = 0

local function isNearDepot()
    local playerCoords = GetEntityCoords(PlayerPedId())
    return Utils.IsNearLocation(playerCoords, Config.JobLocations.depot.coords, 30.0)
end

local function findFreeSpawn(coords, heading, checkRadius)
    checkRadius = checkRadius or 4.0
    local offsets = {
        { 0.0,  0.0 },
        { 7.0,  0.0 }, { -7.0,  0.0 },
        { 0.0,  7.0 }, {  0.0, -7.0 },
        { 7.0,  7.0 }, { -7.0, -7.0 },
        { 7.0, -7.0 }, { -7.0,  7.0 },
        {14.0,  0.0 }, {-14.0,  0.0 },
        { 0.0, 14.0 }, {  0.0,-14.0 }
    }
    for _, off in ipairs(offsets) do
        local cx = coords.x + off[1]
        local cy = coords.y + off[2]
        local cz = coords.z
        local _, nearest = GetClosestVehicle(cx, cy, cz, checkRadius, 0, 70)
        if not nearest or nearest == 0 or not DoesEntityExist(nearest) then
            return vector3(cx, cy, cz), heading
        end
    end
    return coords, heading
end

function VehiclesClient.SpawnCompanyTruck(truckIndex)
    truckIndex = truckIndex or 1

    local isDirtyJob = JobsClient and JobsClient.CurrentJob and JobsClient.CurrentJob.isDirty
    local truckConfig = Config.Vehicles.company_trucks[truckIndex] or Config.Vehicles.company_trucks[1]
    
    if not truckConfig then
        FrameworkBridge.Notify("Trucking", "Invalid truck selection", Constants.NOTIFICATION.ERROR)
        return nil
    end

    if isDirtyJob and Config.DirtySpawn then
        truckConfig = {
            model = truckConfig.model,
            name = truckConfig.name,
            trailer = truckConfig.trailer,
            spawn_loc = Config.DirtySpawn.coords,
            heading = Config.DirtySpawn.heading or truckConfig.heading,
            fuel = truckConfig.fuel,
            condition = truckConfig.condition
        }
    end

    if not JobsClient or not JobsClient.Working or not JobsClient.CurrentJob then
        FrameworkBridge.Notify("Trucking", "Accept a delivery job before taking a truck.", Constants.NOTIFICATION.ERROR)
        return nil
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local depotCoords = isDirtyJob and Config.DirtyDepot.coords or Config.JobLocations.depot.coords
    if #(playerCoords - depotCoords) > 30.0 then
        FrameworkBridge.Notify("Trucking", "You need to be at the " .. (isDirtyJob and "underground" or "trucking") .. " depot.", Constants.NOTIFICATION.ERROR)
        return nil
    end

    VehiclesClient.CleanupVehicles()

    if not FrameworkBridge.RequestModel(truckConfig.model) then
        FrameworkBridge.Notify("Trucking", "Failed to load truck model", Constants.NOTIFICATION.ERROR)
        return nil
    end

    if truckConfig.trailer and not FrameworkBridge.RequestModel(truckConfig.trailer) then
        FrameworkBridge.Notify("Trucking", "Failed to load trailer model", Constants.NOTIFICATION.ERROR)
        return nil
    end
    
    local spawnCoords, spawnHeading = findFreeSpawn(truckConfig.spawn_loc, truckConfig.heading, 4.0)

    local vehicle = FrameworkBridge.CreateVehicle(
        truckConfig.model,
        spawnCoords,
        spawnHeading,
        'TRUCK' .. GetGameTimer()
    )
    
    if not vehicle or not DoesEntityExist(vehicle) then
        FrameworkBridge.Notify("Trucking", "Failed to spawn vehicle", Constants.NOTIFICATION.ERROR)
        return nil
    end
    
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, 'TRUCK' .. math.random(1000, 9999))
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleFixed(vehicle)
    
    if GetResourceState('ox_fuel') == 'started' then
        Entity(vehicle).state.fuel = 100.0
    else
        SetVehicleFuelLevel(vehicle, 100.0)
    end
    
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    NetworkRequestControlOfEntity(vehicle)
    
    Citizen.CreateThread(function()
        local timeout = GetGameTimer() + 3000
        while not NetworkGetEntityIsNetworked(vehicle) and GetGameTimer() < timeout do
            Citizen.Wait(50)
        end
        Citizen.Wait(250)
        
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('trucking:giveVehicleKeys', netId, plate)
    end)
    
    VehiclesClient.CurrentVehicle = vehicle
    JobsClient.CurrentJob.vehicle = vehicle
    
    if truckConfig.trailer then
        local truckCoords = GetEntityCoords(vehicle)
        local truckHeading = GetEntityHeading(vehicle)
        local backOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -15.0, 0.0)
        
        local trailer = CreateVehicle(
            GetHashKey(truckConfig.trailer),
            backOffset.x,
            backOffset.y,
            backOffset.z,
            truckHeading,
            true,
            false
        )
        
        if trailer and DoesEntityExist(trailer) then
            SetVehicleOnGroundProperly(trailer)
            SetVehicleNumberPlateText(trailer, 'TRAIL' .. math.random(1000, 9999))
            VehiclesClient.CurrentTrailer = trailer
            if JobsClient and JobsClient.CurrentJob then
                JobsClient.CurrentJob.trailer = trailer
                JobsClient.CurrentJob.trailerModel = truckConfig.trailer
            end

            Citizen.CreateThread(function()
                local timeout = GetGameTimer() + 3000
                while not NetworkGetEntityIsNetworked(trailer) and GetGameTimer() < timeout do
                    Citizen.Wait(50)
                end
                if DoesEntityExist(trailer) and NetworkGetEntityIsNetworked(trailer) then
                    TriggerServerEvent('trucking:updateTrailerReference', NetworkGetNetworkIdFromEntity(trailer))
                end
            end)

            FrameworkBridge.Notify("Trucking", "Truck and trailer spawned! Drive near trailer and press E to attach.", Constants.NOTIFICATION.SUCCESS)
        end
    else
        FrameworkBridge.Notify("Trucking", "Truck spawned!", Constants.NOTIFICATION.SUCCESS)
    end
    
    if JobsClient and JobsClient.CurrentJob then
        TriggerServerEvent('trucking:updateVehicleReference', VehToNet(vehicle))
    end
    
    return vehicle
end

function VehiclesClient.SpawnTrailer(trailerIndex)
    FrameworkBridge.Notify("Trucking", "Trailer is spawned automatically with the truck!", Constants.NOTIFICATION.INFO)
    return VehiclesClient.CurrentTrailer
end

function VehiclesClient.AttachTrailer()
    local truck = VehiclesClient.CurrentVehicle
    local trailer = VehiclesClient.CurrentTrailer
    
    if not truck or not DoesEntityExist(truck) then
        FrameworkBridge.Notify("Trucking", "No truck found", Constants.NOTIFICATION.ERROR)
        return false
    end
    
    if not trailer or not DoesEntityExist(trailer) then
        FrameworkBridge.Notify("Trucking", "No trailer found", Constants.NOTIFICATION.ERROR)
        return false
    end
    
    if VehiclesClient.TrailerAttached then
        FrameworkBridge.Notify("Trucking", "Trailer already attached!", Constants.NOTIFICATION.INFO)
        return false
    end
    
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= truck then
        FrameworkBridge.Notify("Trucking", "You must be in the truck to attach the trailer", Constants.NOTIFICATION.ERROR)
        return false
    end
    
    local truckCoords = GetEntityCoords(truck)
    local trailerCoords = GetEntityCoords(trailer)
    local distance = Utils.GetDistance(truckCoords, trailerCoords)
    
    if distance > 15 then
        FrameworkBridge.Notify("Trucking", "Drive closer to the trailer (within 15m)", Constants.NOTIFICATION.ERROR)
        return false
    end
    
    AttachVehicleToTrailer(truck, trailer, 10.0)
    
    Citizen.Wait(500)
    
    if IsVehicleAttachedToTrailer(truck) then
        VehiclesClient.TrailerAttached = true
        if JobsClient and JobsClient.CurrentJob then
            JobsClient.CurrentJob.trailorAttached = true
        end
        
        FrameworkBridge.Notify("Trucking", "Trailer attached! Drive to the delivery location.", Constants.NOTIFICATION.SUCCESS)
        
        TriggerServerEvent('trucking:updateTrailerAttachment', true)
        TriggerServerEvent('trucking:startJobDelivery')

        if JobsClient and JobsClient.CurrentJob and JobsClient.CurrentJob.destination and Config.GPS.enabled and Config.GPS.show_waypoint then
            SetNewWaypoint(JobsClient.CurrentJob.destination.coords.x, JobsClient.CurrentJob.destination.coords.y)
        end
        
        return true
    else
        FrameworkBridge.Notify("Trucking", "Failed to attach trailer. Try reversing closer.", Constants.NOTIFICATION.ERROR)
        return false
    end
end

function VehiclesClient.DetachTrailer()
    local trailer = VehiclesClient.CurrentTrailer
    
    if not trailer or not DoesEntityExist(trailer) then
        return false
    end
    
    if IsEntityAttachedToEntity(trailer, VehiclesClient.CurrentVehicle) then
        DetachEntity(trailer, true, true)
        VehiclesClient.TrailerAttached = false
        if JobsClient and JobsClient.CurrentJob then
            JobsClient.CurrentJob.trailorAttached = false
        end
        
        FrameworkBridge.Notify("Trucking", "Trailer detached", Constants.NOTIFICATION.INFO)
        TriggerServerEvent('trucking:updateTrailerAttachment', false)
        
        return true
    end
    
    return false
end

function VehiclesClient.CleanupVehicles()
    if VehiclesClient.CurrentVehicle and DoesEntityExist(VehiclesClient.CurrentVehicle) then
        FrameworkBridge.DeleteVehicle(VehiclesClient.CurrentVehicle)
    end
    
    if VehiclesClient.CurrentTrailer and DoesEntityExist(VehiclesClient.CurrentTrailer) then
        FrameworkBridge.DeleteVehicle(VehiclesClient.CurrentTrailer)
    end
    
    VehiclesClient.CurrentVehicle = nil
    VehiclesClient.CurrentTrailer = nil
    VehiclesClient.TrailerAttached = false
end

function VehiclesClient.GetFuelLevel()
    if not VehiclesClient.CurrentVehicle or not DoesEntityExist(VehiclesClient.CurrentVehicle) then
        return 100
    end
    
    if GetResourceState('ox_fuel') == 'started' then
        return Entity(VehiclesClient.CurrentVehicle).state.fuel or GetVehicleFuelLevel(VehiclesClient.CurrentVehicle)
    else
        return GetVehicleFuelLevel(VehiclesClient.CurrentVehicle)
    end
end

function VehiclesClient.GetEngineHealth()
    if not VehiclesClient.CurrentVehicle or not DoesEntityExist(VehiclesClient.CurrentVehicle) then
        return 100
    end
    
    return (GetVehicleEngineHealth(VehiclesClient.CurrentVehicle) / 1000) * 100
end

function VehiclesClient.NeedsRepair()
    return VehiclesClient.GetEngineHealth() < 50
end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local vehicle = VehiclesClient.CurrentVehicle
        if vehicle and DoesEntityExist(vehicle) and JobsClient and JobsClient.Working then
            local currentTime = GetGameTimer()
            
            local fuelLevel = VehiclesClient.GetFuelLevel()
            
            local engineHealth = GetVehicleEngineHealth(vehicle)
            
            if fuelLevel < 10 and (currentTime - VehiclesClient.LastFuelWarning) > 30000 then
                FrameworkBridge.Notify("Trucking", "CRITICAL: Low fuel! Refuel soon.", Constants.NOTIFICATION.ERROR)
                VehiclesClient.LastFuelWarning = currentTime
            end
            
            if engineHealth < 300 and (currentTime - VehiclesClient.LastDamageWarning) > 30000 then
                FrameworkBridge.Notify("Trucking", "WARNING: Engine damaged! Repair needed.", Constants.NOTIFICATION.WARNING)
                VehiclesClient.LastDamageWarning = currentTime
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        if VehiclesClient.CurrentVehicle and VehiclesClient.CurrentTrailer then
            local trailer = VehiclesClient.CurrentTrailer
            local truck = VehiclesClient.CurrentVehicle
            
            if DoesEntityExist(trailer) and DoesEntityExist(truck) then
                local wasAttached = VehiclesClient.TrailerAttached
                local isAttached = IsVehicleAttachedToTrailer(truck)
                
                if wasAttached and not isAttached then
                    VehiclesClient.TrailerAttached = false
                    TriggerServerEvent('trucking:updateTrailerAttachment', false)
                    FrameworkBridge.Notify("Trucking", "WARNING: Trailer detached!", Constants.NOTIFICATION.WARNING)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle == VehiclesClient.CurrentVehicle and VehiclesClient.CurrentTrailer and not VehiclesClient.TrailerAttached then
            if DoesEntityExist(VehiclesClient.CurrentTrailer) then
                local truckCoords = GetEntityCoords(vehicle)
                local trailerCoords = GetEntityCoords(VehiclesClient.CurrentTrailer)
                local distance = Utils.GetDistance(truckCoords, trailerCoords)
                
                if distance < 15 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to attach trailer')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        VehiclesClient.AttachTrailer()
                    end
                end
            end
        end
        
        if IsControlJustReleased(0, 167) then
            if JobsClient and JobsClient.Working then
                if VehiclesClient.TrailerAttached then
                    VehiclesClient.DetachTrailer()
                end
            end
        end
    end
end)

return VehiclesClient
