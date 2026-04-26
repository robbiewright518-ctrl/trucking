ProgressionClient = {}
ProgressionClient.PlayerData = {
    level = 1,
    xp = 0,
    total_xp = 0,
    jobs_completed = 0,
    distance_traveled = 0,
    money_earned = 0,
    skills = {
        distance_driving = 0,
        fragile_handling = 0,
        speed_efficiency = 0
    }
}

function ProgressionClient.RequestProgressionData()
    TriggerServerEvent('trucking:getPlayerProgression')
end

local function normalizeProgressionData(progressionData)
    if not progressionData then
        return ProgressionClient.PlayerData
    end

    progressionData.skills = progressionData.skills or {
        distance_driving = progressionData.skill_distance_driving or 0,
        fragile_handling = progressionData.skill_fragile_handling or 0,
        speed_efficiency = progressionData.skill_speed_efficiency or 0
    }

    return progressionData
end

RegisterNetEvent('trucking:updateProgression', function(progressionData)
    ProgressionClient.PlayerData = normalizeProgressionData(progressionData)
    TriggerEvent('trucking:progressionUpdated', ProgressionClient.PlayerData)
end)

RegisterNetEvent('trucking:playerProgressionData', function(progressionData)
    if progressionData then
        ProgressionClient.PlayerData = normalizeProgressionData(progressionData)
        TriggerEvent('trucking:progressionUpdated', ProgressionClient.PlayerData)
    end
end)

RegisterNetEvent('trucking:jobUnlocked', function(jobType)
    local jobConfig = Config.Jobs[jobType]
    if jobConfig then
        FrameworkBridge.Notify("Trucking", "New job unlocked: " .. jobConfig.name, Constants.NOTIFICATION.SUCCESS)
    end
end)

function ProgressionClient.GetLevel()
    return ProgressionClient.PlayerData.level or 1
end

function ProgressionClient.GetXP()
    return ProgressionClient.PlayerData.xp or 0
end

function ProgressionClient.GetXPForNextLevel()
    local level = ProgressionClient.GetLevel()
    return (level + 1) * Config.Progression.xp_per_level
end

function ProgressionClient.GetXPProgress()
    local currentXP = ProgressionClient.GetXP()
    local nextLevelXP = ProgressionClient.GetXPForNextLevel()
    
    if nextLevelXP <= 0 then return 100 end
    
    return math.floor((currentXP / nextLevelXP) * 100)
end

function ProgressionClient.GetDistanceTraveled()
    return ProgressionClient.PlayerData.distance_traveled or 0
end

function ProgressionClient.GetMoneyEarned()
    return ProgressionClient.PlayerData.money_earned or 0
end

function ProgressionClient.GetJobsCompleted()
    return ProgressionClient.PlayerData.jobs_completed or 0
end

function ProgressionClient.GetSkillLevel(skillName)
    if ProgressionClient.PlayerData.skills then
        return ProgressionClient.PlayerData.skills[skillName] or 0
    end
    return 0
end

function ProgressionClient.GetFormattedStats()
    return {
        level = ProgressionClient.GetLevel(),
        xp = ProgressionClient.GetXP(),
        total_xp = ProgressionClient.PlayerData.total_xp or 0,
        distance_traveled = ProgressionClient.GetDistanceTraveled(),
        money_earned = ProgressionClient.GetMoneyEarned(),
        jobs_completed = ProgressionClient.GetJobsCompleted(),
        skills = {
            distance_driving = ProgressionClient.GetSkillLevel('distance_driving'),
            fragile_handling = ProgressionClient.GetSkillLevel('fragile_handling'),
            speed_efficiency = ProgressionClient.GetSkillLevel('speed_efficiency')
        }
    }
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.Wait(1000, function()
            ProgressionClient.RequestProgressionData()
        end)
        Utils.DebugLog("Progression Client System initialized")
    end
end)

exports('GetPlayerLevel', function()
    return ProgressionClient.GetLevel()
end)

exports('GetPlayerXP', function()
    return ProgressionClient.GetXP()
end)

exports('GetFormattedStats', function()
    return ProgressionClient.GetFormattedStats()
end)

return ProgressionClient
