JobsClient = {}
JobsClient.CurrentJob = nil
JobsClient.JobStartCoord = nil
JobsClient.Working = false
JobsClient.LastJobTime = 0
JobsClient.DeliveryMarker = nil
JobsClient.ReturnToDepot = false

JobsClient.Sounds = {
    accept    = { 'WAYPOINT_SET',     'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    deliver   = { 'CHECKPOINT_PERFECT','HUD_MINI_GAME_SOUNDSET' },
    payment   = { 'PURCHASE',          'HUD_LIQUOR_STORE_SOUNDSET' },
    levelup   = { 'RANK_UP',           'HUD_AWARDS' },
    fail      = { 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET' }
}

function JobsClient.PlaySound(key)
    local s = JobsClient.Sounds[key]
    if not s then return end
    PlaySoundFrontend(-1, s[1], s[2], false)
end

function JobsClient.RequestJob(jobType)
    TriggerServerEvent('trucking:createJob', jobType)
end

RegisterNetEvent('trucking:jobCreated', function(jobData)
    JobsClient.CurrentJob = jobData
    JobsClient.Working = true
    JobsClient.JobStartCoord = (jobData.isDirty and Config.DirtyDepot) and Config.DirtyDepot.coords or Config.JobLocations.depot.coords
    
    Citizen.SetTimeout(500, function()
        if VehiclesClient and VehiclesClient.SpawnCompanyTruck then
            local truckIndex = jobData.truckIndex or 1
            VehiclesClient.SpawnCompanyTruck(truckIndex)
        end
    end)
    
    if Config.GPS.enabled and Config.GPS.show_waypoint then
        SetNewWaypoint(JobsClient.JobStartCoord.x, JobsClient.JobStartCoord.y)
    end
    
    FrameworkBridge.Notify("Trucking", "Job accepted! Truck and trailer spawning at depot.", Constants.NOTIFICATION.INFO)
    JobsClient.PlaySound('accept')
end)

RegisterNetEvent('trucking:jobStarted', function(job)
    JobsClient.CurrentJob = job
    JobsClient.ReturnToDepot = false
    
    if Config.GPS.enabled and Config.GPS.show_waypoint then
        SetNewWaypoint(job.destination.coords.x, job.destination.coords.y)
    end
    
    FrameworkBridge.Notify("Trucking", "Delivery started! Drive to: " .. job.destination.name, Constants.NOTIFICATION.SUCCESS)
end)

RegisterNetEvent('trucking:jobCompleted', function(result)
    FrameworkBridge.Notify("Trucking", "Delivery complete! Return truck to depot. Earned $" .. result.payment .. " and " .. result.xp .. " XP", Constants.NOTIFICATION.SUCCESS)
    JobsClient.PlaySound('deliver')
    Citizen.SetTimeout(600, function() JobsClient.PlaySound('payment') end)
    
    if VehiclesClient and VehiclesClient.CurrentVehicle and DoesEntityExist(VehiclesClient.CurrentVehicle) then
        if IsVehicleAttachedToTrailer(VehiclesClient.CurrentVehicle) then
            DetachVehicleFromTrailer(VehiclesClient.CurrentVehicle)
        end
    end
    
    if VehiclesClient and VehiclesClient.CurrentTrailer and DoesEntityExist(VehiclesClient.CurrentTrailer) then
        local trailer = VehiclesClient.CurrentTrailer
        SetEntityAsMissionEntity(trailer, true, true)
        Citizen.Wait(100)
        DeleteVehicle(trailer)
        VehiclesClient.CurrentTrailer = nil
        VehiclesClient.TrailerAttached = false
    end
    
    if JobsClient.CurrentJob then
        JobsClient.CurrentJob.trailorAttached = false
    end
    
    JobsClient.ReturnToDepot = true
    
    if Config.GPS.enabled and Config.GPS.show_waypoint then
        local returnLoc = JobsClient.GetReturnLocation()
        SetNewWaypoint(returnLoc.x, returnLoc.y)
    end
end)

RegisterNetEvent('trucking:completeJobResult', function(success)
    if not success then
        FrameworkBridge.Notify("Trucking", "Delivery failed - try again at the green zone", Constants.NOTIFICATION.ERROR)
    end
end)

RegisterNetEvent('trucking:jobFinalized', function()
    JobsClient.Working = false
    JobsClient.CurrentJob = nil
    JobsClient.ReturnToDepot = false
    
    SetWaypointOff()
    
    FrameworkBridge.Notify("Trucking", "Job finalized! Great work.", Constants.NOTIFICATION.SUCCESS)
    JobsClient.PlaySound('payment')
end)

RegisterNetEvent('trucking:jobFailed', function(reason)
    JobsClient.Working = false
    JobsClient.CurrentJob = nil
    
    SetWaypointOff()
    
    FrameworkBridge.Notify("Trucking", "Job failed: " .. reason, Constants.NOTIFICATION.ERROR)
    JobsClient.PlaySound('fail')
end)

RegisterNetEvent('trucking:levelUp', function()
    JobsClient.PlaySound('levelup')
end)

RegisterNetEvent('trucking:jobCancelled', function()
    JobsClient.Working = false
    JobsClient.CurrentJob = nil
    
    SetWaypointOff()
    
    FrameworkBridge.Notify("Trucking", "Job cancelled", Constants.NOTIFICATION.WARNING)
end)

RegisterNetEvent('trucking:createJobResult', function(success, data)
    if success then
        return
    end

    local message = type(data) == 'string' and data or 'Unable to accept that job right now.'
    FrameworkBridge.Notify("Trucking", message, Constants.NOTIFICATION.ERROR)
end)

RegisterNetEvent('trucking:startJobResult', function(success, message)
    if success then
        return
    end

    FrameworkBridge.Notify("Trucking", message or "Unable to start delivery.", Constants.NOTIFICATION.ERROR)
end)

function JobsClient.IsNearDepot()
    local playerCoord = GetEntityCoords(PlayerPedId())
    local depotCoords = (JobsClient.CurrentJob and JobsClient.CurrentJob.isDirty)
        and Config.DirtyDepot.coords
        or Config.JobLocations.depot.coords
    return Utils.IsNearLocation(playerCoord, depotCoords, 30)
end

function JobsClient.GetReturnLocation()
    if JobsClient.CurrentJob and JobsClient.CurrentJob.isDirty and Config.DirtySpawn then
        return Config.DirtySpawn.coords
    end
    
    local truckConfig = Config.Vehicles.company_trucks[1]
    if truckConfig and truckConfig.spawn_loc then
        return truckConfig.spawn_loc
    end
    return Config.JobLocations.depot.coords
end

function JobsClient.IsAtReturnLocation()
    local vehicle = VehiclesClient and VehiclesClient.CurrentVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    local coords = GetEntityCoords(vehicle)
    local returnLoc = JobsClient.GetReturnLocation()
    return #(coords - vector3(returnLoc.x, returnLoc.y, returnLoc.z)) < 10.0
end

function JobsClient.IsNearDestination()
    if not JobsClient.CurrentJob then return false end
    local playerCoord = GetEntityCoords(PlayerPedId())
    return Utils.IsNearLocation(playerCoord, JobsClient.CurrentJob.destination.coords, Config.GPS.distance_check)
end

function JobsClient.UpdateVehicleReference(vehicle)
    TriggerServerEvent('trucking:updateVehicleReference', vehicle)
end

function JobsClient.UpdateTrailerAttachment(attached)
    TriggerServerEvent('trucking:updateTrailerAttachment', attached)
end

function JobsClient.GetCurrentJob()
    return JobsClient.CurrentJob
end

function JobsClient.IsPlayerWorking()
    return JobsClient.Working == true
end

function JobsClient.CompleteJob()
    if not JobsClient.CurrentJob then
        FrameworkBridge.Notify("Trucking", "No active job!", Constants.NOTIFICATION.ERROR)
        return
    end
    
    if not JobsClient.IsNearDestination() then
        FrameworkBridge.Notify("Trucking", "You must be at the destination!", Constants.NOTIFICATION.ERROR)
        return
    end
    
    local vehicle = VehiclesClient.CurrentVehicle
    if not vehicle or not DoesEntityExist(vehicle) then
        FrameworkBridge.Notify("Trucking", "Vehicle not found!", Constants.NOTIFICATION.ERROR)
        return
    end
    
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local damagePercent = Utils.CalculateDamagePercent(bodyHealth, engineHealth)
    
    TriggerServerEvent('trucking:completeJobDelivery', {
        isDamaged = damagePercent > 5,
        damagePercent = damagePercent,
        vehicleUsed = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    })
end

function JobsClient.ReturnTruckToDepot()
    if not JobsClient.ReturnToDepot then
        return
    end
    
    if not JobsClient.IsAtReturnLocation() then
        FrameworkBridge.Notify("Trucking", "Park the truck at the spawn location to return it!", Constants.NOTIFICATION.ERROR)
        return
    end
    
    if VehiclesClient and VehiclesClient.CurrentVehicle and DoesEntityExist(VehiclesClient.CurrentVehicle) then
        local vehicle = VehiclesClient.CurrentVehicle
        local ped = PlayerPedId()
        
        if GetVehiclePedIsIn(ped, false) == vehicle then
            TaskLeaveVehicle(ped, vehicle, 0)
            Citizen.Wait(800)
        end
        
        NetworkRequestControlOfEntity(vehicle)
        local timeout = GetGameTimer() + 1000
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
            NetworkRequestControlOfEntity(vehicle)
            Citizen.Wait(50)
        end
        
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
        
        VehiclesClient.CurrentVehicle = nil
    end
    
    if VehiclesClient and VehiclesClient.CurrentTrailer and DoesEntityExist(VehiclesClient.CurrentTrailer) then
        NetworkRequestControlOfEntity(VehiclesClient.CurrentTrailer)
        SetEntityAsMissionEntity(VehiclesClient.CurrentTrailer, true, true)
        DeleteVehicle(VehiclesClient.CurrentTrailer)
        VehiclesClient.CurrentTrailer = nil
    end
    
    if VehiclesClient then
        VehiclesClient.TrailerAttached = false
    end
    
    TriggerServerEvent('trucking:finalizeJob')
end

function JobsClient.CancelJob()
    if JobsClient.CurrentJob then
        TriggerServerEvent('trucking:cancelJob')
    end
end

exports('IsPlayerWorking', function()
    return JobsClient.IsPlayerWorking()
end)

exports('GetPlayerCurrentJob', function()
    return JobsClient.GetCurrentJob()
end)

JobsClient.DeliveryBlip = nil

local function createDeliveryBlip(coords)
    if JobsClient.DeliveryBlip and DoesBlipExist(JobsClient.DeliveryBlip) then
        RemoveBlip(JobsClient.DeliveryBlip)
    end
    local isDirty = JobsClient.CurrentJob and JobsClient.CurrentJob.isDirty
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, isDirty and 1 or 2)
    SetBlipScale(blip, 1.2)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, isDirty and 1 or 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(isDirty and 'Drop-off (Dirty)' or 'Delivery Location')
    EndTextCommandSetBlipName(blip)
    JobsClient.DeliveryBlip = blip
end

local function removeDeliveryBlip()
    if JobsClient.DeliveryBlip and DoesBlipExist(JobsClient.DeliveryBlip) then
        RemoveBlip(JobsClient.DeliveryBlip)
        JobsClient.DeliveryBlip = nil
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        
        if JobsClient.CurrentJob and JobsClient.CurrentJob.destination and not JobsClient.ReturnToDepot and VehiclesClient and VehiclesClient.TrailerAttached then
            sleep = 0
            local destination = JobsClient.CurrentJob.destination
            local coords = destination.coords
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            
            if not JobsClient.DeliveryBlip or not DoesBlipExist(JobsClient.DeliveryBlip) then
                createDeliveryBlip(coords)
            end
            
            if distance < 200.0 then
                local isDirty = JobsClient.CurrentJob.isDirty
                local r = isDirty and 255 or 0
                local g = isDirty and 0 or 255
                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    20.0, 20.0, 5.0,
                    r, g, 0, 150,
                    false, false, 2, false, nil, nil, false
                )
            end
            
            if distance < 10.0 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to drop off trailer')
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                if IsControlJustReleased(0, 38) then
                    JobsClient.CompleteJob()
                end
            end
        else
            removeDeliveryBlip()
        end
        
        Wait(sleep)
    end
end)

AddEventHandler('trucking:jobCompleted', function()
    removeDeliveryBlip()
end)
AddEventHandler('trucking:jobFinalized', function()
    removeDeliveryBlip()
end)
AddEventHandler('trucking:jobFailed', function()
    removeDeliveryBlip()
end)
AddEventHandler('trucking:jobCancelled', function()
    removeDeliveryBlip()
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        
        if JobsClient.ReturnToDepot and VehiclesClient and VehiclesClient.CurrentVehicle and DoesEntityExist(VehiclesClient.CurrentVehicle) then
            sleep = 0
            local returnLoc = JobsClient.GetReturnLocation()
            local truckCoords = GetEntityCoords(VehiclesClient.CurrentVehicle)
            local distance = #(truckCoords - vector3(returnLoc.x, returnLoc.y, returnLoc.z))
            
            if distance < 100.0 then
                DrawMarker(
                    1,
                    returnLoc.x, returnLoc.y, returnLoc.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    8.0, 8.0, 3.0,
                    0, 100, 255, 150,
                    false, false, 2, false, nil, nil, false
                )
            end
            
            if distance < 10.0 then
                local ped = PlayerPedId()
                if GetVehiclePedIsIn(ped, false) == VehiclesClient.CurrentVehicle then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to return truck and finish job')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    if IsControlJustReleased(0, 38) then
                        JobsClient.ReturnTruckToDepot()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.DebugLog("Jobs Client System initialized")
    end
end)

return JobsClient
