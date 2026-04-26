ProgressionServer = {}
ProgressionServer.PlayerData = {}

function ProgressionServer.InitializePlayer(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false end

    local progressionData = Database.GetPlayerProgression(identifier)

    if not progressionData or #progressionData == 0 then
        Database.CreatePlayerProgression(identifier)
        progressionData = Database.GetPlayerProgression(identifier)
    end

    if progressionData and #progressionData > 0 then
        ProgressionServer.PlayerData[source] = progressionData[1]
        return true
    end

    return false
end

function ProgressionServer.AddXP(source, xpAmount)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false end
    
    local existing = Database.GetPlayerProgression(identifier)
    if not existing or #existing == 0 then
        Database.CreatePlayerProgression(identifier)
    end
    
    Database.AddPlayerXP(identifier, xpAmount)
    
    local progressionData = Database.GetPlayerProgression(identifier)
    if progressionData and #progressionData > 0 then
        local playerData = progressionData[1]
        local level = playerData.level
        local totalXP = playerData.total_xp
        local nextLevelXP = level * Config.Progression.xp_per_level
        
        if totalXP >= nextLevelXP and level < Config.Progression.max_level then
            ProgressionServer.LevelUp(source, identifier)
        end
    end
    
    ProgressionServer.SendProgressionData(source)
    
    return true
end

function ProgressionServer.LevelUp(source, identifier)
    local progressionData = Database.GetPlayerProgression(identifier)
    if not progressionData or #progressionData == 0 then return false end
    
    local newLevel = progressionData[1].level + 1
    
    if newLevel > Config.Progression.max_level then
        newLevel = Config.Progression.max_level
    end
    
    Database.SetPlayerLevel(identifier, newLevel)

    local unlockedJob = Config.Progression.unlocks[newLevel]
    if unlockedJob then
        TriggerClientEvent('trucking:jobUnlocked', source, unlockedJob)
        FrameworkBridge.Notify(source, "New job unlocked: " .. unlockedJob, Constants.NOTIFICATION.SUCCESS)
    end

    FrameworkBridge.Notify(source, "Level up! You are now level " .. newLevel, Constants.NOTIFICATION.SUCCESS)
    TriggerClientEvent('trucking:levelUp', source, newLevel)
    TriggerEvent('trucking:onLevelUp', source, newLevel)

    if Config.Logging.enabled then
        TriggerEvent('trucking:logLevelUp', source, newLevel)
    end

    return true
end

function ProgressionServer.GetPlayerProgression(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return nil end
    
    local progressionData = Database.GetPlayerProgression(identifier)
    if progressionData and #progressionData > 0 then
        return progressionData[1]
    end
    
    return nil
end

function ProgressionServer.SendProgressionData(source)
    local progressionData = ProgressionServer.GetPlayerProgression(source)
    if progressionData then
        TriggerClientEvent('trucking:updateProgression', source, progressionData)
    end
end

function ProgressionServer.UpdateSkill(source, skillName, increase)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false end

    local validSkill = false
    for _, skill in ipairs(Config.Progression.skill_categories) do
        if skill == skillName then
            validSkill = true
            break
        end
    end

    if not validSkill then return false end

    local skillColumn = 'skill_' .. skillName
    local stats = {}
    stats[skillName] = 10

    Database.UpdatePlayerStats(identifier, stats)

    return true
end

function ProgressionServer.GetPlayerLevel(source)
    local progressionData = ProgressionServer.GetPlayerProgression(source)
    if progressionData then
        return progressionData.level
    end
    return 1
end

function ProgressionServer.GetPlayerXP(source)
    local progressionData = ProgressionServer.GetPlayerProgression(source)
    if progressionData then
        return progressionData.xp, progressionData.total_xp
    end
    return 0, 0
end

function ProgressionServer.RecordJobCompletion(source, jobRecord)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false end

    Database.RecordJobCompletion(identifier, jobRecord)

    local progressionData = Database.GetPlayerProgression(identifier)
    if progressionData and #progressionData > 0 then
        local newStats = {
            jobs_completed = progressionData[1].jobs_completed + 1,
            distance_traveled = progressionData[1].distance_traveled + jobRecord.distance,
            money_earned = progressionData[1].money_earned + jobRecord.payment
        }

        Database.UpdatePlayerStats(identifier, newStats)
    end

    ProgressionServer.SendProgressionData(source)

    return true
end

AddEventHandler('trucking:addXP', function(source, xpAmount)
    ProgressionServer.AddXP(source, xpAmount)
end)

AddEventHandler('trucking:recordJobCompletion', function(source, jobRecord)
    ProgressionServer.RecordJobCompletion(source, jobRecord)
end)

RegisterNetEvent('trucking:getPlayerProgression', function()
    local src = source
    ProgressionServer.SendProgressionData(src)
end)

local function getNameForIdentifier(identifier)
    if not identifier then return 'Unknown' end

    for _, playerId in ipairs(GetPlayers()) do
        local Player
        if GetResourceState('qbx_core') == 'started' then
            Player = exports.qbx_core:GetPlayer(tonumber(playerId))
        elseif GetResourceState('qb-core') == 'started' then
            Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(tonumber(playerId))
        end
        if Player and Player.PlayerData and Player.PlayerData.citizenid == identifier then
            local charinfo = Player.PlayerData.charinfo
            if charinfo and charinfo.firstname then
                return charinfo.firstname .. ' ' .. (charinfo.lastname or '')
            end
            return GetPlayerName(tonumber(playerId)) or identifier
        end
    end

    if GetResourceState('oxmysql') == 'started' then
        local result = exports.oxmysql:query_async(
            'SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1',
            { identifier }
        )
        if result and result[1] and result[1].charinfo then
            local ok, charinfo = pcall(json.decode, result[1].charinfo)
            if ok and charinfo and charinfo.firstname then
                return charinfo.firstname .. ' ' .. (charinfo.lastname or '')
            end
        end
    end

    return 'Trucker ' .. string.sub(identifier, -4)
end

RegisterNetEvent('trucking:getLeaderboard', function(sortBy)
    local src = source
    
    local sortColumn = ({
        xp = 'total_xp',
        jobs = 'jobs_completed',
        money = 'money_earned',
        distance = 'distance_traveled'
    })[sortBy] or 'total_xp'
    
    local rows = Database.GetLeaderboard(sortColumn, 25) or {}
    local myIdentifier = FrameworkBridge.GetIdentifier(src)
    
    local result = {}
    for i, row in ipairs(rows) do
        result[i] = {
            name = getNameForIdentifier(row.identifier),
            level = row.level or 1,
            total_xp = row.total_xp or 0,
            jobs_completed = row.jobs_completed or 0,
            money_earned = row.money_earned or 0,
            distance_traveled = row.distance_traveled or 0,
            is_me = (row.identifier == myIdentifier)
        }
    end
    
    TriggerClientEvent('trucking:leaderboardData', src, result)
end)

AddEventHandler('playerJoining', function()
    local source = source
    ProgressionServer.InitializePlayer(source)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, playerId in ipairs(GetPlayers()) do
            ProgressionServer.InitializePlayer(tonumber(playerId))
        end
    end
end)

exports('GetPlayerLevel', function(source)
    return ProgressionServer.GetPlayerLevel(source)
end)

exports('GetPlayerXP', function(source)
    return ProgressionServer.GetPlayerXP(source)
end)

return ProgressionServer
