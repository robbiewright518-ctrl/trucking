TruckingUI = {}

function TruckingUI.Open(mode)
    SendNUIMessage({
        type = 'openUI',
        mode = mode or 'legit'
    })
    SetNuiFocus(true, true)
end

function TruckingUI.Close()
    SendNUIMessage({
        type = 'closeUI'
    })
    SetNuiFocus(false, false)
end

function TruckingUI.IsOpen()
    return IsNuiFocused()
end

function TruckingUI.UpdatePlayerData(playerData)
    SendNUIMessage({
        type = 'updatePlayerData',
        data = playerData
    })
end

function TruckingUI.UpdateAvailableJobs(jobs)
    SendNUIMessage({
        type = 'updateAvailableJobs',
        jobs = jobs
    })
end

function TruckingUI.UpdateJobHUD(jobData)
    SendNUIMessage({
        type = 'updateJobHUD',
        jobData = jobData
    })
end

function TruckingUI.UpdateVehicleHUD(fuel, engine, damage)
    SendNUIMessage({
        type = 'updateVehicleHUD',
        fuel = fuel,
        engine = engine,
        damage = damage
    })
end

function TruckingUI.UpdateTrailerStatus(attached)
    SendNUIMessage({
        type = 'updateTrailerStatus',
        attached = attached
    })
end

function TruckingUI.ShowNotification(title, message, notificationType)
    SendNUIMessage({
        type = 'showNotification',
        title = title,
        message = message,
        notificationType = notificationType
    })
end

RegisterNUICallback('acceptJob', function(data, cb)
    if data.jobType then
        TriggerServerEvent('trucking:createJob', data.jobType)
    end

    cb('ok')
end)

RegisterNUICallback('attachTrailer', function(_, cb)
    if VehiclesClient and VehiclesClient.AttachTrailer then
        VehiclesClient.AttachTrailer()
    end

    cb('ok')
end)

RegisterNUICallback('detachTrailer', function(_, cb)
    if VehiclesClient and VehiclesClient.DetachTrailer then
        VehiclesClient.DetachTrailer()
    end

    cb('ok')
end)

RegisterNUICallback('cancelJob', function(_, cb)
    if JobsClient and JobsClient.CancelJob then
        JobsClient.CancelJob()
    end

    TruckingUI.Close()
    cb('ok')
end)

RegisterNUICallback('requestAvailableJobs', function(data, cb)
    local category = (data and data.category) or 'legit'
    TriggerServerEvent('trucking:getAvailableJobs', category)
    cb('ok')
end)

RegisterNUICallback('requestAchievements', function(_, cb)
    TriggerServerEvent('trucking:requestAchievements')
    cb('ok')
end)

RegisterNUICallback('requestPerks', function(_, cb)
    TriggerServerEvent('trucking:requestPerks')
    cb('ok')
end)

RegisterNUICallback('rankUpPerk', function(data, cb)
    if data and data.perkId then
        TriggerServerEvent('trucking:rankUpPerk', data.perkId)
    end
    cb('ok')
end)

RegisterNetEvent('trucking:updatePerks', function(data)
    SendNUIMessage({ type = 'updatePerks', data = data })
end)

RegisterNetEvent('trucking:updateAchievements', function(list)
    SendNUIMessage({ type = 'updateAchievements', list = list })
end)

RegisterNetEvent('trucking:achievementUnlocked', function(ach)
    SendNUIMessage({ type = 'achievementUnlocked', ach = ach })
    PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', false)
end)

RegisterNetEvent('trucking:updateCriminalData', function(data)
    SendNUIMessage({ type = 'updateCriminalData', data = data })
end)

RegisterNUICallback('getPlayerData', function(_, cb)
    if ProgressionClient and ProgressionClient.GetFormattedStats then
        cb(ProgressionClient.GetFormattedStats())
        return
    end

    cb({})
end)

local pendingLeaderboardCb = nil

RegisterNetEvent('trucking:leaderboardData', function(rows)
    if pendingLeaderboardCb then
        local cb = pendingLeaderboardCb
        pendingLeaderboardCb = nil
        cb(rows or {})
    end
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    local sortBy = (data and data.sortBy) or 'xp'
    
    pendingLeaderboardCb = cb
    TriggerServerEvent('trucking:getLeaderboard', sortBy)
    
    Citizen.SetTimeout(5000, function()
        if pendingLeaderboardCb == cb then
            pendingLeaderboardCb = nil
            cb({})
        end
    end)
end)

RegisterNUICallback('getGarageData', function(_, cb)
    local companyTrucks = {}

    for index, truck in ipairs(Config.Vehicles.company_trucks) do
        companyTrucks[index] = {
            name = truck.name,
            model = truck.model,
            trailer = truck.trailer,
            fuel = truck.fuel,
            condition = truck.condition
        }
    end

    cb({
        companyTrucks = companyTrucks,
        purchasable = Config.Vehicles.purchasable,
        hasActiveJob = JobsClient and JobsClient.Working and JobsClient.CurrentJob ~= nil
    })
end)

RegisterNUICallback('spawnCompanyTruck', function(data, cb)
    local truckIndex = tonumber(data and data.truckIndex) or 1
    local vehicle = nil

    if VehiclesClient and VehiclesClient.SpawnCompanyTruck then
        vehicle = VehiclesClient.SpawnCompanyTruck(truckIndex)
    end

    cb({
        success = vehicle ~= nil
    })
end)

RegisterNUICallback('spawnTrailer', function(data, cb)
    local truckIndex = tonumber(data and data.truckIndex) or 1
    local trailer = nil

    if VehiclesClient and VehiclesClient.SpawnTrailer then
        trailer = VehiclesClient.SpawnTrailer(truckIndex)
    end

    cb({
        success = trailer ~= nil
    })
end)

RegisterNUICallback('uiClosed', function(_, cb)
    SetNuiFocus(false, false)

    if UISystem then
        UISystem.IsUIOpen = false
    end

    cb('ok')
end)

exports('OpenTruckingUI', function()
    TruckingUI.Open()
end)

exports('CloseTruckingUI', function()
    TruckingUI.Close()
end)

return TruckingUI
