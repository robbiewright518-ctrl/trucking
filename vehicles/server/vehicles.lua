VehiclesServer = {}
VehiclesServer.PlayerVehicles = {}

function VehiclesServer.SpawnCompanyTruck(source, truckIndex)
    truckIndex = truckIndex or 1
    local truckConfig = Config.Vehicles.company_trucks[truckIndex]
    
    if not truckConfig then
        return false, "Invalid truck"
    end
    
    return true, truckConfig
end

function VehiclesServer.PurchaseVehicle(source, vehicleType)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false end
    
    local vehicleConfig = nil
    for _, v in ipairs(Config.Vehicles.purchasable) do
        if v.id == vehicleType then
            vehicleConfig = v
            break
        end
    end
    
    if not vehicleConfig then
        return false, "Vehicle not found"
    end
    
    local money = FrameworkBridge.GetPlayer(source)
    if not money then return false, "Player not found" end
    
    if money.Functions.GetMoney('bank') < vehicleConfig.price then
        return false, "Not enough money"
    end
    
    FrameworkBridge.RemoveMoney(source, vehicleConfig.price, 'bank', 'Vehicle Purchase: ' .. vehicleConfig.name)
    
    local plate = 'VEH' .. string.upper(string.sub(GetPlayerIdentifier(source, 0), 1, 3)) .. math.random(100, 999)
    local success = Database.AddPlayerVehicle(identifier, vehicleConfig.model, 100, 1000, plate)
    
    if success then
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Trucking', 'Vehicle purchased! Plate: ' .. plate }
        })
        return true, { plate = plate, model = vehicleConfig.model }
    end
    
    return false, "Database error"
end

function VehiclesServer.GetPlayerVehicles(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return {} end
    
    return Database.GetPlayerVehicles(identifier)
end

function VehiclesServer.UpdateVehicleCondition(plate, fuel, health)
    return Database.UpdateVehicleCondition(plate, fuel, health)
end

function VehiclesServer.VerifyTrailerAttachment(source)
    local job = JobsSystem.PlayerJobs[source]
    if not job then return false end
    
    return job.trailorAttached == true
end

RegisterNetEvent('trucking:spawnCompanyTruck', function(truckIndex)
    local source = source
    local success, truckConfig = VehiclesServer.SpawnCompanyTruck(source, truckIndex)
    TriggerClientEvent('trucking:companyTruckSpawned', source, success, truckConfig)
end)

RegisterNetEvent('trucking:purchaseVehicle', function(vehicleType)
    local source = source
    local success, data = VehiclesServer.PurchaseVehicle(source, vehicleType)
    TriggerClientEvent('trucking:vehiclePurchased', source, success, data)
end)

RegisterNetEvent('trucking:getPlayerVehicles', function()
    local source = source
    local vehicles = VehiclesServer.GetPlayerVehicles(source)
    TriggerClientEvent('trucking:playerVehiclesData', source, vehicles)
end)

RegisterNetEvent('trucking:updateVehicleCondition', function(plate, fuel, health)
    VehiclesServer.UpdateVehicleCondition(plate, fuel, health)
end)

RegisterNetEvent('trucking:giveVehicleKeys', function(netId, plate)
    local src = source
    if not src then return end
    
    if GetResourceState('qbx_vehiclekeys') ~= 'started' then
        print('[trucking] qbx_vehiclekeys not started - cannot give keys')
        return
    end
    
    Citizen.CreateThread(function()
        local attempts = 0
        while attempts < 10 do
            if netId and netId ~= 0 then
                local vehicle = NetworkGetEntityFromNetworkId(netId)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    local ok, err = pcall(function()
                        exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)
                    end)
                    if ok then
                        print('[trucking] Keys given to source ' .. src .. ' (plate: ' .. (plate or 'unknown') .. ')')
                        return
                    else
                        print('[trucking] GiveKeys error: ' .. tostring(err))
                    end
                end
            end
            attempts = attempts + 1
            Citizen.Wait(200)
        end
        print('[trucking] Failed to give keys to source ' .. src .. ' after ' .. attempts .. ' attempts')
    end)
end)

return VehiclesServer
