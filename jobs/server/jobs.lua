JobsSystem = {}
JobsSystem.PlayerJobs = {}
JobsSystem.ActiveJobs = {}

function JobsSystem.Initialize()
    Utils.DebugLog("Jobs System initialized")
end

function JobsSystem.CreateJob(source, jobType)
    local jobConfig = Config.Jobs[jobType] or (Config.DirtyJobs and Config.DirtyJobs[jobType])
    if not jobConfig then
        return false, "Invalid job type"
    end

    local isDirty = jobConfig.is_dirty == true

    if JobsSystem.PlayerJobs[source] then
        return false, "Player already has an active job"
    end

    if JobsSystem.LastJobTime and JobsSystem.LastJobTime[source] then
        local timeSinceLastJob = (GetGameTimer() - JobsSystem.LastJobTime[source]) / 1000
        if timeSinceLastJob < 2 then
            return false, "Please wait before taking another job"
        end
    end

    if not JobsSystem.LastJobTime then
        JobsSystem.LastJobTime = {}
    end
    JobsSystem.LastJobTime[source] = GetGameTimer()

    local zonePool = isDirty and Config.DirtyDeliveryZones or Config.DeliveryZones
    local depotCoords = isDirty and Config.DirtyDepot.coords or Config.JobLocations.depot.coords
    local destination = zonePool[math.random(#zonePool)]
    local distance = Utils.GetDistance(depotCoords, destination.coords)

    local jobData = {
        id = source .. '_' .. GetGameTimer(),
        source = source,
        type = jobType,
        isDirty = isDirty,
        state = Constants.JOB_STATE.ACCEPTED,
        startTime = GetGameTimer(),
        startCoords = depotCoords,
        destination = destination,
        distance = distance,
        vehicle = nil,
        trailer = nil,
        isDamaged = false,
        damagePercent = 0,
        isCancelled = false,
        trailorAttached = false,
        trailerModel = nil
    }

    JobsSystem.PlayerJobs[source] = jobData
    JobsSystem.ActiveJobs[jobData.id] = jobData

    TriggerClientEvent('trucking:jobCreated', source, jobData)
    FrameworkBridge.Notify(source, "Job accepted! Drive to the depot.", Constants.NOTIFICATION.SUCCESS)

    return true, jobData
end

function JobsSystem.StartJobDelivery(source)
    local job = JobsSystem.PlayerJobs[source]
    if not job then
        return false, "No active job"
    end

    if job.state ~= Constants.JOB_STATE.ACCEPTED then
        return false, "Invalid job state"
    end

    local vehicle = job.vehicleNetId and NetworkGetEntityFromNetworkId(job.vehicleNetId) or 0
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false, "Vehicle not found"
    end

    job.vehicle = vehicle

    if not job.trailorAttached then
        return false, "Trailer must be attached"
    end

    job.state = Constants.JOB_STATE.IN_PROGRESS
    job.deliveryStartTime = GetGameTimer()

    TriggerClientEvent('trucking:jobStarted', source, job)
    FrameworkBridge.Notify(source, "Delivery started! Drive to: " .. job.destination.name, Constants.NOTIFICATION.SUCCESS)

    return true
end

function JobsSystem.CompleteJobDelivery(source, finalData)
    local job = JobsSystem.PlayerJobs[source]
    if not job then
        return false, "No active job"
    end

    if job.state ~= Constants.JOB_STATE.IN_PROGRESS then
        return false, "Invalid job state"
    end

    local vehicle = job.vehicleNetId and NetworkGetEntityFromNetworkId(job.vehicleNetId) or job.vehicle
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false, "Vehicle not found"
    end

    job.vehicle = vehicle

    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = Utils.GetDistance(vehicleCoords, job.destination.coords)

    if distance > Config.GPS.distance_check then
        FrameworkBridge.Notify(source, "Vehicle not in delivery zone (distance: " .. math.floor(distance) .. "m)", Constants.NOTIFICATION.ERROR)
        return false, "Vehicle not at destination"
    end

    job.state = Constants.JOB_STATE.DELIVERING
    job.endTime = GetGameTimer()
    job.timeTaken = (job.endTime - job.startTime) / 1000
    job.isDamaged = finalData.isDamaged or false
    job.damagePercent = finalData.damagePercent or 0

    local payment = Utils.CalculatePayment(job.distance, job.type, job.isDamaged, false)
    local xpEarned = Utils.CalculateXP(job.distance, job.type, 0.8)

    if job.isDirty and CriminalServer and CriminalServer.GetPayMultiplier then
        payment = math.floor(payment * CriminalServer.GetPayMultiplier(source))
    end

    if PerksServer then
        if job.isDirty then
            local b = PerksServer.GetEffect(source, 'dirty_pay_bonus')
            if b > 0 then payment = math.floor(payment * (1 + b)) end
        else
            local b = PerksServer.GetEffect(source, 'pay_bonus')
            if b > 0 then payment = math.floor(payment * (1 + b)) end
            local x = PerksServer.GetEffect(source, 'xp_bonus')
            if x > 0 then xpEarned = math.floor(xpEarned * (1 + x)) end
        end
    end

    local paid = false
    if job.isDirty then
        local dirtyType = Config.DirtyMoneyType or 'black_money'
        local dirtyItem = Config.DirtyMoneyItem

        if GetResourceState('ox_inventory') == 'started' and dirtyItem then
            paid = exports.ox_inventory:AddItem(source, dirtyItem, payment) ~= false
        end

        if not paid then
            paid = FrameworkBridge.AddMoney(source, payment, dirtyType, 'Dirty Job: ' .. job.type)
        end

        if not paid then
            paid = FrameworkBridge.AddMoney(source, payment, 'cash', 'Dirty Job: ' .. job.type)
        end
    else
        if GetResourceState('ox_inventory') == 'started' then
            paid = exports.ox_inventory:AddItem(source, 'money', payment)
            if not paid then
                paid = FrameworkBridge.AddMoney(source, payment, 'cash', 'Trucking Job: ' .. job.type)
            end
        else
            paid = FrameworkBridge.AddMoney(source, payment, 'cash', 'Trucking Job: ' .. job.type)
        end
    end

    if not paid then
        FrameworkBridge.Notify(source, "Failed to process payment. Contact admin.", Constants.NOTIFICATION.ERROR)
        return false, "Payment failed"
    end

    if job.isDirty then
        if CriminalServer and CriminalServer.AddRep then
            local rep = math.floor(xpEarned * (Config.CriminalProgression.rep_multiplier or 1.0))
            if PerksServer then
                local rb = PerksServer.GetEffect(source, 'rep_bonus')
                if rb > 0 then rep = math.floor(rep * (1 + rb)) end
            end
            CriminalServer.AddRep(source, rep)
            CriminalServer.RecordCompletion(source, payment)
        end
    else
        TriggerEvent('trucking:addXP', source, xpEarned)
    end

    local jobRecord = {
        jobType = job.type,
        isDirty = job.isDirty,
        distance = job.distance,
        payment = payment,
        xpEarned = xpEarned,
        wasDamaged = job.isDamaged,
        damagePercent = job.damagePercent,
        wasLate = false,
        timeTaken = job.timeTaken,
        vehicleUsed = finalData.vehicleUsed or 'unknown'
    }

    TriggerEvent('trucking:recordJobCompletion', source, jobRecord)

    job.state = Constants.JOB_STATE.DELIVERING
    job.payment = payment
    job.xpEarned = xpEarned

    TriggerClientEvent('trucking:jobCompleted', source, {
        payment = payment,
        xp = xpEarned,
        distance = job.distance,
        damage = job.damagePercent
    })

    TriggerEvent('trucking:logJobCompletion', source, jobRecord)

    return true
end

function JobsSystem.FailJob(source, reason)
    local job = JobsSystem.PlayerJobs[source]
    if not job then return false end

    job.state = Constants.JOB_STATE.FAILED
    job.isCancelled = true

    JobsSystem.PlayerJobs[source] = nil

    TriggerClientEvent('trucking:jobFailed', source, reason)
    FrameworkBridge.Notify(source, "Job failed: " .. reason, Constants.NOTIFICATION.ERROR)

    return true
end

function JobsSystem.CancelJob(source)
    local job = JobsSystem.PlayerJobs[source]
    if not job then return false end

    job.state = Constants.JOB_STATE.CANCELLED
    JobsSystem.PlayerJobs[source] = nil

    TriggerClientEvent('trucking:jobCancelled', source)
    FrameworkBridge.Notify(source, "Job cancelled", Constants.NOTIFICATION.INFO)

    return true
end

function JobsSystem.GetPlayerJob(source)
    return JobsSystem.PlayerJobs[source]
end

function JobsSystem.SetPlayerVehicle(source, vehicle)
    if JobsSystem.PlayerJobs[source] then
        JobsSystem.PlayerJobs[source].vehicleNetId = vehicle
    end
end

function JobsSystem.SetPlayerTrailer(source, trailer, attached)
    if JobsSystem.PlayerJobs[source] then
        JobsSystem.PlayerJobs[source].trailer = trailer
        JobsSystem.PlayerJobs[source].trailorAttached = attached
    end
end

function JobsSystem.SetPlayerTrailerNetId(source, trailerNetId)
    if JobsSystem.PlayerJobs[source] then
        JobsSystem.PlayerJobs[source].trailerNetId = trailerNetId
    end
end

function JobsSystem.CleanupJobVehicles(job)
    if not job then return end
    local function deleteByNetId(netId)
        if not netId or netId == 0 then return end
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    deleteByNetId(job.vehicleNetId)
    deleteByNetId(job.trailerNetId)
end

function JobsSystem.UpdateTrailerAttachmentStatus(source, attached)
    if JobsSystem.PlayerJobs[source] then
        JobsSystem.PlayerJobs[source].trailorAttached = attached
    end
end

function JobsSystem.GetAvailableJobs(source, category)
    category = category or 'legit'
    local availableJobs = {}

    local level = 1
    if category == 'dirty' and CriminalServer and CriminalServer.GetLevel then
        level = CriminalServer.GetLevel(source) or 1
    elseif ProgressionServer and ProgressionServer.GetPlayerLevel then
        level = ProgressionServer.GetPlayerLevel(source) or 1
    end

    local jobPool = (category == 'dirty') and (Config.DirtyJobs or {}) or Config.Jobs
    local unlockTable = (category == 'dirty') and (Config.DirtyUnlocks or {}) or Config.Progression.unlocks

    for jobType, jobConfig in pairs(jobPool) do
        local isUnlocked = true

        for requiredLevel, unlockedJob in pairs(unlockTable) do
            if unlockedJob == jobType and level < requiredLevel then
                isUnlocked = false
                break
            end
        end

        if isUnlocked then
            table.insert(availableJobs, {
                id = jobConfig.id,
                name = jobConfig.name,
                description = jobConfig.description,
                basePay = jobConfig.base_pay,
                xpReward = jobConfig.xp_reward,
                isDirty = jobConfig.is_dirty == true
            })
        end
    end

    table.sort(availableJobs, function(a, b)
        return a.basePay < b.basePay
    end)

    TriggerClientEvent('trucking:updateAvailableJobs', source, availableJobs, category)
    return availableJobs
end

exports('CreateJob', function(source, jobType)
    return JobsSystem.CreateJob(source, jobType)
end)

exports('CompleteJob', function(source, data)
    return JobsSystem.CompleteJobDelivery(source, data)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local job = JobsSystem.PlayerJobs[source]
    if job then
        local jobRef = job
        SetTimeout(2000, function()
            JobsSystem.CleanupJobVehicles(jobRef)
        end)
    end
    JobsSystem.CancelJob(source)
end)

RegisterNetEvent('trucking:updateTrailerReference', function(trailerNetId)
    local source = source
    JobsSystem.SetPlayerTrailerNetId(source, trailerNetId)
end)

RegisterNetEvent('trucking:createJob', function(jobType)
    local source = source
    local success, jobData = JobsSystem.CreateJob(source, jobType)
    TriggerClientEvent('trucking:createJobResult', source, success, jobData)
end)

RegisterNetEvent('trucking:startJobDelivery', function()
    local source = source
    local success, message = JobsSystem.StartJobDelivery(source)
    TriggerClientEvent('trucking:startJobResult', source, success, message)
end)

RegisterNetEvent('trucking:completeJobDelivery', function(finalData)
    local source = source
    local success = JobsSystem.CompleteJobDelivery(source, finalData)
    TriggerClientEvent('trucking:completeJobResult', source, success)
end)

RegisterNetEvent('trucking:cancelJob', function()
    local source = source
    JobsSystem.CancelJob(source)
end)

RegisterNetEvent('trucking:updateVehicleReference', function(vehicle)
    local source = source
    JobsSystem.SetPlayerVehicle(source, vehicle)
end)

RegisterNetEvent('trucking:updateTrailerAttachment', function(attached)
    local source = source
    JobsSystem.UpdateTrailerAttachmentStatus(source, attached)
end)

RegisterNetEvent('trucking:getAvailableJobs', function(category)
    local source = source
    JobsSystem.GetAvailableJobs(source, category)
end)

RegisterNetEvent('trucking:finalizeJob', function()
    local source = source
    local job = JobsSystem.PlayerJobs[source]

    if not job then
        FrameworkBridge.Notify(source, "No active job to finalize.", Constants.NOTIFICATION.ERROR)
        return
    end

    if job.state ~= Constants.JOB_STATE.DELIVERING then
        FrameworkBridge.Notify(source, "Job not ready to finalize.", Constants.NOTIFICATION.ERROR)
        return
    end

    job.state = Constants.JOB_STATE.COMPLETED
    JobsSystem.PlayerJobs[source] = nil

    TriggerClientEvent('trucking:jobFinalized', source)

    local message = string.format("Job finalized! You earned $%d and %d XP", job.payment or 0, job.xpEarned or 0)
    FrameworkBridge.Notify(source, message, Constants.NOTIFICATION.SUCCESS)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        JobsSystem.Initialize()
    end
end)

return JobsSystem
