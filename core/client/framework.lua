FrameworkBridge = {}
FrameworkBridge.Framework = nil
FrameworkBridge.PlayerData = {}

local FrameworkObjects = {
    QBCore = nil,
    ESX = nil
}

local LOAD_MODEL_TIMEOUT = 1000
local LOAD_MODEL_INTERVAL = 10

local DEFAULT_NOTIFY_DURATION = 5000

local cachedPlayerServerId = nil

function FrameworkBridge.Initialize()
    if not Config.Framework.auto_detect and Config.Framework.manual_framework then
        FrameworkBridge.Framework = Config.Framework.manual_framework
        Utils.DebugLog("Using manually configured framework: " .. tostring(FrameworkBridge.Framework))
    else
        if GetResourceState('qbx_core') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.QBX
            Utils.DebugLog("Detected QBX Framework")
        elseif GetResourceState('qb-core') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.QBCORE
            Utils.DebugLog("Detected QBCore Framework")
        elseif GetResourceState('es_extended') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.ESX
            Utils.DebugLog("Detected ESX Framework")
        else
            FrameworkBridge.Framework = Constants.FRAMEWORK.STANDALONE
            Utils.DebugLog("Using Standalone Framework")
        end
    end

    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        FrameworkObjects.QBCore = exports['qb-core']:GetCoreObject()
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        FrameworkObjects.ESX = exports['es_extended']:getSharedObject()
    end

    cachedPlayerServerId = GetPlayerServerId(PlayerId())

    DEFAULT_NOTIFY_DURATION = Config.Notifications and Config.Notifications.duration or 5000
end

---@param accounts table Array of account objects
---@return number Bank amount
local function GetESXBankAmount(accounts)
    if not accounts then return 0 end
    for _, account in ipairs(accounts) do
        if account.name == 'bank' then
            return account.money or 0
        end
    end
    return 0
end

function FrameworkBridge.GetPlayerData()
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        FrameworkBridge.PlayerData = FrameworkObjects.QBCore and FrameworkObjects.QBCore.Functions.GetPlayerData() or {}
        return FrameworkBridge.PlayerData
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        return exports.qbx_core:GetPlayerData() or FrameworkBridge.PlayerData
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local PlayerData = FrameworkObjects.ESX and FrameworkObjects.ESX.PlayerData
        local bankAccount = GetESXBankAmount(PlayerData and PlayerData.accounts)
        return {
            job = PlayerData and PlayerData.job,
            money = PlayerData and PlayerData.money,
            bank = bankAccount,
            citizenid = PlayerData and PlayerData.identifier
        }
    else
        return {
            job = { name = 'none', label = 'None' },
            money = 0,
            bank = 0,
            citizenid = 'STANDALONE'
        }
    end
end

function FrameworkBridge.GetPlayerMoney(moneyType)
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local Player = FrameworkBridge.PlayerData
        if moneyType == 'cash' then
            return Player.money and Player.money.cash or 0
        elseif moneyType == 'bank' then
            return Player.money and Player.money.bank or 0
        else
            return (Player.money and Player.money.cash or 0) + (Player.money and Player.money.bank or 0)
        end
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        local Player = exports.qbx_core:GetPlayerData() or FrameworkBridge.PlayerData
        if moneyType == 'cash' then
            return Player.money.cash or 0
        elseif moneyType == 'bank' then
            return Player.money.bank or 0
        else
            return (Player.money.cash or 0) + (Player.money.bank or 0)
        end
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local PlayerData = FrameworkObjects.ESX and FrameworkObjects.ESX.PlayerData
        if moneyType and moneyType ~= 'cash' and moneyType ~= 'bank' then
            moneyType = nil
        end
        if moneyType == 'cash' then
            return PlayerData and PlayerData.money or 0
        elseif moneyType == 'bank' then
            return GetESXBankAmount(PlayerData and PlayerData.accounts)
        else
            return (PlayerData and PlayerData.money or 0) + GetESXBankAmount(PlayerData and PlayerData.accounts)
        end
    else
        return 0
    end
end

function FrameworkBridge.GetPlayerIdentifier()
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        return FrameworkBridge.PlayerData.citizenid
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        local Player = exports.qbx_core:GetPlayerData() or FrameworkBridge.PlayerData
        return Player.citizenid
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local PlayerData = FrameworkObjects.ESX and FrameworkObjects.ESX.PlayerData
        return PlayerData and PlayerData.identifier
    else
        return cachedPlayerServerId
    end
end

---@param title string|nil Notification title
---@param message string Notification message
---@param notificationType string|nil Notification type (from Constants.NOTIFICATION)
---@param duration number|nil Duration in milliseconds
function FrameworkBridge.Notify(title, message, notificationType, duration)
    notificationType = notificationType or Constants.NOTIFICATION.INFO
    duration = duration or DEFAULT_NOTIFY_DURATION
    
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        if FrameworkObjects.QBCore then
            FrameworkObjects.QBCore.Functions.Notify(message, notificationType, duration)
        end
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        exports.qbx_core:Notify(message, notificationType, duration)
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        TriggerEvent('esx:showNotification', message)
    else
        TriggerEvent('chat:addMessage', {
            args = { title or 'Trucking', message }
        })
    end
end

---@param model string|number Model name or hash
---@return boolean success Whether the model loaded successfully
function FrameworkBridge.RequestModel(model)
    if type(model) == 'string' then
        model = GetHashKey(model)
    end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < LOAD_MODEL_TIMEOUT do
        Wait(LOAD_MODEL_INTERVAL)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        Utils.DebugLog("Failed to load model: " .. model)
        return false
    end
    return true
end

---@param model string|number Model name or hash
---@param coords vector3|table Position {x, y, z}
---@param heading number Yaw rotation
---@param plate string|nil Optional plate text
---@return number|nil Vehicle handle
function FrameworkBridge.CreateVehicle(modelName, coords, heading, plate)
    local modelHash = type(modelName) == 'string' and GetHashKey(modelName) or modelName

    if not FrameworkBridge.RequestModel(modelHash) then
        return nil
    end
    
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    if plate then
        SetVehicleNumberPlateText(vehicle, plate)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    
    return vehicle
end

function FrameworkBridge.DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        return true
    end
    return false
end

exports('GetFrameworkType', function()
    return FrameworkBridge.Framework
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        FrameworkBridge.Initialize()
        FrameworkBridge.PlayerData = FrameworkBridge.GetPlayerData() or {}
        Utils.DebugLog("Framework Bridge initialized on client")
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    FrameworkBridge.PlayerData = playerData or {}
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    FrameworkBridge.PlayerData = {}
end)

RegisterNetEvent('qbx_core:client:onSetPlayerData', function(playerData)
    FrameworkBridge.PlayerData = playerData or {}
end)

RegisterNetEvent('esx:setPlayerData', function(key, value)
    if FrameworkObjects.ESX and FrameworkObjects.ESX.PlayerData then
        FrameworkObjects.ESX.PlayerData[key] = value
    end
end)

RegisterNetEvent('esx:playerLoaded', function(playerData)
    if FrameworkObjects.ESX then
        FrameworkObjects.ESX.PlayerData = playerData
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if FrameworkObjects.QBCore then
        FrameworkBridge.PlayerData = FrameworkObjects.QBCore.Functions.GetPlayerData() or {}
    end
end)

return FrameworkBridge
