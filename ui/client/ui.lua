UISystem = {}
UISystem.IsUIOpen = false
UISystem.DepotPed = nil
UISystem.DepotBlip = nil

local function loadModel(model)
    local modelHash = type(model) == 'string' and joaat(model) or model

    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 200 do
        Wait(50)
        timeout = timeout + 1
    end

    return HasModelLoaded(modelHash), modelHash
end

local function drawHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function UISystem.Initialize()
    Utils.DebugLog("UI System initialized")

    UISystem.CreateDepotBlip()
    UISystem.CreateDepotPed()
    UISystem.CreateDirtyDepotBlip()
    UISystem.CreateDirtyDepotPed()

    if Config.UI.interaction.enable_command then
        RegisterCommand(Config.UI.interaction.command_name, function()
            UISystem.Toggle()
        end, false)

        if Config.UI.interaction.keybind_enabled then
            RegisterKeyMapping(
                Config.UI.interaction.command_name,
                'Open Trucking Menu',
                'keyboard',
                Config.UI.interaction.keybind
            )
        end
    end

    RegisterCommand('truckhud', function()
        SendNUIMessage({ type = 'toggleHud' })
    end, false)
    RegisterKeyMapping('truckhud', 'Toggle Trucking HUD', 'keyboard', 'K')
end

function UISystem.Toggle()
    if UISystem.IsUIOpen then
        UISystem.Close()
    else
        UISystem.Open()
    end
end

function UISystem.Open(mode)
    if UISystem.IsUIOpen then return end

    UISystem.IsUIOpen = true
    UISystem.CurrentMode = mode or 'legit'

    SetNuiFocus(true, true)

    TriggerServerEvent('trucking:getPlayerProgression')

    if ProgressionClient then
        local stats = ProgressionClient.GetFormattedStats()
        TruckingUI.UpdatePlayerData(stats)
    end

    TriggerServerEvent('trucking:getAvailableJobs', UISystem.CurrentMode)

    if UISystem.CurrentMode == 'dirty' then
        TriggerServerEvent('trucking:requestCriminalData')
    end

    SendNUIMessage({ type = 'openUI', mode = UISystem.CurrentMode })
end

function UISystem.Close()
    if not UISystem.IsUIOpen then return end

    UISystem.IsUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeUI' })
end

function UISystem.CreateDepotBlip()
    if UISystem.DepotBlip or not Config.JobLocations.depot.blip then
        return
    end

    local blipConfig = Config.JobLocations.depot.blip
    local coords = Config.JobLocations.depot.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipDisplay(blip, blipConfig.display)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipColour(blip, blipConfig.color)
    SetBlipAsShortRange(blip, blipConfig.short_range or false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipConfig.label)
    EndTextCommandSetBlipName(blip)

    UISystem.DepotBlip = blip
end

function UISystem.CreateDepotPed()
    local pedConfig = Config.JobLocations.depot.ped
    if UISystem.DepotPed or not pedConfig or not pedConfig.enabled then
        return
    end

    local loaded, modelHash = loadModel(pedConfig.model)
    if not loaded then
        print('^1[trucking] Failed to load depot ped model.^7')
        return
    end

    local coords = Config.JobLocations.depot.coords
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, Config.JobLocations.depot.heading, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if pedConfig.scenario and pedConfig.scenario ~= '' then
        TaskStartScenarioInPlace(ped, pedConfig.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(modelHash)
    UISystem.DepotPed = ped
end

function UISystem.CreateDirtyDepotBlip()
    if UISystem.DirtyDepotBlip or not Config.DirtyDepot or not Config.DirtyDepot.blip then
        return
    end

    local blipConfig = Config.DirtyDepot.blip
    local coords = Config.DirtyDepot.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipDisplay(blip, blipConfig.display)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipColour(blip, blipConfig.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipConfig.label)
    EndTextCommandSetBlipName(blip)

    UISystem.DirtyDepotBlip = blip
end

function UISystem.CreateDirtyDepotPed()
    local pedConfig = Config.DirtyDepot and Config.DirtyDepot.ped
    if UISystem.DirtyDepotPed or not pedConfig or not pedConfig.enabled then
        return
    end

    local loaded, modelHash = loadModel(pedConfig.model)
    if not loaded then
        print('^1[trucking] Failed to load dirty depot ped model.^7')
        return
    end

    local coords = Config.DirtyDepot.coords
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, Config.DirtyDepot.heading, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if pedConfig.scenario and pedConfig.scenario ~= '' then
        TaskStartScenarioInPlace(ped, pedConfig.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(modelHash)
    UISystem.DirtyDepotPed = ped
end

function UISystem.ShowJobState(job)
    if not job then return end
    TruckingUI.UpdateJobHUD(job)
end

function UISystem.HideJobState()
    TruckingUI.UpdateJobHUD(nil)
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        if JobsClient and JobsClient.Working and VehiclesClient and VehiclesClient.CurrentVehicle then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle == VehiclesClient.CurrentVehicle and DoesEntityExist(vehicle) then
                local fuel = 100
                if GetResourceState('ox_fuel') == 'started' then
                    fuel = Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
                else
                    fuel = GetVehicleFuelLevel(vehicle)
                end

                local engineHealth = (GetVehicleEngineHealth(vehicle) / 1000) * 100
                local bodyHealth = GetVehicleBodyHealth(vehicle)
                local damage = 100 - (bodyHealth / 1000) * 100

                if TruckingUI and TruckingUI.UpdateVehicleHUD then
                    TruckingUI.UpdateVehicleHUD(fuel, engineHealth, damage)
                end

                local job = JobsClient.CurrentJob
                if job then
                    local speedMs = GetEntitySpeed(vehicle)
                    local speedMph = speedMs * 2.23694
                    local distance = nil
                    local payment = 0
                    local xp = 0
                    if job.destination and job.destination.coords then
                        local pcoords = GetEntityCoords(ped)
                        distance = #(pcoords - vector3(job.destination.coords.x, job.destination.coords.y, job.destination.coords.z))
                        local jobConfig = Config.Jobs[job.type] or (Config.DirtyJobs and Config.DirtyJobs[job.type])
                        if jobConfig then
                            payment = math.floor(jobConfig.base_pay + (distance * jobConfig.multiplier))
                            xp = jobConfig.xp_reward or 0
                        end
                    end

                    SendNUIMessage({
                        type = 'updateJobHUD',
                        jobData = {
                            active = true,
                            name = job.destination and job.destination.name or job.type,
                            isDirty = job.isDirty == true,
                            speedMph = speedMph,
                            distance = distance,
                            payment = payment,
                            xp = xp
                        }
                    })
                end
            else
                SendNUIMessage({
                    type = 'updateJobHUD',
                    jobData = { active = false }
                })
            end
        else
            SendNUIMessage({
                type = 'updateJobHUD',
                jobData = { active = false }
            })
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(500)
        if JobsClient and JobsClient.Working and VehiclesClient and VehiclesClient.CurrentVehicle then
            local vehicle = VehiclesClient.CurrentVehicle
            if vehicle == VehiclesClient.CurrentVehicle then
                local attached = JobsClient.CurrentJob and JobsClient.CurrentJob.trailerAttached or false
                if TruckingUI and TruckingUI.UpdateTrailerStatus then
                    TruckingUI.UpdateTrailerStatus(attached)
                end
            end
        end
    end
end)

AddEventHandler('trucking:jobCreated', function(jobData)
    UISystem.ShowJobState(jobData)
end)

AddEventHandler('trucking:jobStarted', function(job)
    UISystem.ShowJobState(job)
end)

AddEventHandler('trucking:jobCompleted', function()
    UISystem.HideJobState()
end)

AddEventHandler('trucking:jobFailed', function()
    UISystem.HideJobState()
end)

AddEventHandler('trucking:jobCancelled', function()
    UISystem.HideJobState()
end)

AddEventHandler('trucking:progressionUpdated', function(progressionData)
    if ProgressionClient then
        local stats = ProgressionClient.GetFormattedStats()
        TruckingUI.UpdatePlayerData(stats)
    else
        TruckingUI.UpdatePlayerData(progressionData)
    end
end)

RegisterNetEvent('trucking:updateAvailableJobs', function(availableJobs)
    TruckingUI.UpdateAvailableJobs(availableJobs)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        UISystem.Initialize()
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if UISystem.DepotPed then
        DeleteEntity(UISystem.DepotPed)
    end
    if UISystem.DirtyDepotPed then
        DeleteEntity(UISystem.DirtyDepotPed)
    end
    if UISystem.DepotBlip then
        RemoveBlip(UISystem.DepotBlip)
    end
    if UISystem.DirtyDepotBlip then
        RemoveBlip(UISystem.DirtyDepotBlip)
    end
    UISystem.DirtyDepotBlip = nil
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = UISystem.DepotPed

        if ped and DoesEntityExist(ped) and not UISystem.IsUIOpen then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(ped)
            local distance = Utils.GetDistance(playerCoords, pedCoords)
            local interactDistance = Config.JobLocations.depot.interaction_distance or 2.0

            if distance <= 10.0 then
                sleep = 0
            end

            if distance <= interactDistance then
                drawHelpText(Config.UI.interaction.prompt)

                if IsControlJustReleased(0, 38) then
                    UISystem.Open('legit')
                end
            end
        end

        Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = UISystem.DirtyDepotPed

        if ped and DoesEntityExist(ped) and not UISystem.IsUIOpen then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(ped)
            local distance = Utils.GetDistance(playerCoords, pedCoords)
            local interactDistance = (Config.DirtyDepot and Config.DirtyDepot.interaction_distance) or 2.0

            if distance <= 10.0 then
                sleep = 0
            end

            if distance <= interactDistance then
                drawHelpText('Press ~INPUT_CONTEXT~ to talk to the fence')

                if IsControlJustReleased(0, 38) then
                    UISystem.Open('dirty')
                end
            end
        end

        Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if JobsClient and JobsClient.Working and VehiclesClient and VehiclesClient.CurrentVehicle and DoesEntityExist(VehiclesClient.CurrentVehicle) then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == VehiclesClient.CurrentVehicle and IsControlJustReleased(0, 289) then 
                UISystem.Toggle()
            end
        end
    end
end)

RegisterCommand('truckhud', function()
    UISystem.Open()
    return true
end)

exports('OpenTruckingUI', function()
    UISystem.Open()
    return true
end)

exports('CloseTruckingUI', function()
    UISystem.Close()
    return true
end)

exports('IsTruckingUIOpen', function()
    return UISystem.IsUIOpen
end)

return UISystem
