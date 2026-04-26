FrameworkBridge = {}
FrameworkBridge.Framework = nil

function FrameworkBridge.Initialize()
    if not Config.Framework.auto_detect and Config.Framework.manual_framework then
        FrameworkBridge.Framework = Config.Framework.manual_framework
        Utils.DebugLog("Using manually configured framework on server: " .. tostring(FrameworkBridge.Framework))
    else
        if GetResourceState('qbx_core') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.QBX
            Utils.DebugLog("Detected QBX Framework (Server)")
        elseif GetResourceState('qb-core') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.QBCORE
            Utils.DebugLog("Detected QBCore Framework (Server)")
        elseif GetResourceState('es_extended') == 'started' then
            FrameworkBridge.Framework = Constants.FRAMEWORK.ESX
            Utils.DebugLog("Detected ESX Framework (Server)")
        else
            FrameworkBridge.Framework = Constants.FRAMEWORK.STANDALONE
            Utils.DebugLog("Using Standalone Framework (Server)")
        end
    end
end

function FrameworkBridge.GetPlayer(source)
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayer(source)
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        return exports.qbx_core:GetPlayer(source)
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        return ESX.GetPlayerFromId(source)
    else
        return {
            source = source,
            license = GetPlayerIdentifier(source, 0),
            money = 0,
            bank = 0
        }
    end
end

function FrameworkBridge.AddMoney(source, amount, moneyType, reason)
    if not amount or amount <= 0 then return false end

    moneyType = moneyType or 'cash'
    reason = reason or 'Trucking Job Payment'

    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        Player.Functions.AddMoney(moneyType, amount, reason)
        return true
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        return exports.qbx_core:AddMoney(source, moneyType, amount, reason) == true
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return false end
        if moneyType == 'bank' then
            Player.addAccountMoney('bank', amount)
        else
            Player.addMoney(amount)
        end
        return true
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Trucking', 'You earned $' .. amount }
        })
        return true
    end
end

function FrameworkBridge.RemoveMoney(source, amount, moneyType, reason)
    if not amount or amount <= 0 then return false end

    moneyType = moneyType or 'cash'
    reason = reason or 'Trucking Job Cost'

    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        Player.Functions.RemoveMoney(moneyType, amount, reason)
        return true
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason) == true
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return false end
        if moneyType == 'bank' then
            Player.removeAccountMoney('bank', amount)
        else
            Player.removeMoney(amount)
        end
        return true
    else
        return true
    end
end

function FrameworkBridge.GetIdentifier(source)
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return nil end
        return Player.PlayerData.citizenid
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return nil end
        return Player.PlayerData.citizenid
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return nil end
        return Player.identifier
    else
        return GetPlayerIdentifier(source, 0)
    end
end

function FrameworkBridge.GetPlayerName(source)
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 'Unknown' end
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return 'Unknown' end
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return 'Unknown' end
        return Player.getName()
    else
        return GetPlayerName(source)
    end
end

function FrameworkBridge.GetPlayerJob(source)
    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return nil end
        return Player.PlayerData.job
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        local Player = exports.qbx_core:GetPlayer(source)
        if not Player then return nil end
        return Player.PlayerData.job
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return nil end
        return Player.getJob()
    else
        return 'none'
    end
end

function FrameworkBridge.HasItem(source, item, amount)
    amount = amount or 1

    if Config.Inventory.use_ox_inventory and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:Search(source, 'count', item) >= amount
    end

    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.GetItemByName(item) ~= nil and Player.Functions.GetItemByName(item).amount >= amount
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if not Player then return false end
        local item_data = Player.getInventoryItem(item)
        return item_data and item_data.count >= amount
    end
    
    return false
end

function FrameworkBridge.GetFramework()
    return FrameworkBridge.Framework
end

function FrameworkBridge.Notify(source, message, notifyType)
    if not source or not message then return end
    notifyType = notifyType or 'info'

    if FrameworkBridge.Framework == Constants.FRAMEWORK.QBX then
        exports.qbx_core:Notify(source, message, notifyType)
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.QBCORE then
        TriggerClientEvent('QBCore:Notify', source, message, notifyType)
    elseif FrameworkBridge.Framework == Constants.FRAMEWORK.ESX then
        TriggerClientEvent('esx:showNotification', source, message)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Trucking', message }
        })
    end
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        FrameworkBridge.Initialize()
        Utils.DebugLog("Framework Bridge initialized on server")
    end
end)

exports('GetFramework', function()
    return FrameworkBridge.GetFramework()
end)

return FrameworkBridge
