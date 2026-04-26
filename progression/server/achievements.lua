AchievementsServer = {}

local function buildStats(identifier)
    local stats = {}
    local prog = Database.GetPlayerProgression(identifier)
    local progRow = (prog and prog[1]) or {}

    stats.level             = progRow.level or 1
    stats.total_xp          = progRow.total_xp or 0
    stats.jobs_completed    = progRow.jobs_completed or 0
    stats.distance_traveled = progRow.distance_traveled or 0
    stats.money_earned      = progRow.money_earned or 0

    local crim = Database.GetCriminalProgression(identifier) or {}
    stats.criminal_level    = crim.level or 1
    stats.criminal_rep      = crim.total_rep or 0
    stats.dirty_jobs_completed = crim.dirty_jobs_completed or 0
    stats.dirty_money_earned   = crim.dirty_money_earned or 0

    return stats
end

local function unlockedSet(identifier)
    local rows = Database.GetUnlockedAchievements(identifier)
    local set = {}
    for _, r in ipairs(rows or {}) do
        set[r.achievement_id] = r.unlocked_at or true
    end
    return set
end

function AchievementsServer.Check(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return end

    local stats = buildStats(identifier)
    local unlocked = unlockedSet(identifier)

    for _, ach in ipairs(Config.Achievements or {}) do
        if not unlocked[ach.id] and ach.check and ach.check(stats) then
            Database.UnlockAchievement(identifier, ach.id)
            local r = ach.reward or {}
            if r.xp and r.xp > 0 then
                TriggerEvent('trucking:addXP', source, r.xp)
            end
            if r.cash and r.cash > 0 then
                FrameworkBridge.AddMoney(source, r.cash, 'cash', 'Achievement: ' .. ach.name)
            end
            FrameworkBridge.Notify(source,
                ('Achievement unlocked: %s %s'):format(ach.icon or '🏆', ach.name),
                Constants.NOTIFICATION.SUCCESS)
            TriggerClientEvent('trucking:achievementUnlocked', source, {
                id = ach.id, name = ach.name, icon = ach.icon
            })
        end
    end
end

function AchievementsServer.OnUnlock(source, ach)
    FrameworkBridge.Notify(source,
        ('Achievement unlocked: %s %s'):format(ach.icon or '🏆', ach.name),
        Constants.NOTIFICATION.SUCCESS)

    local r = ach.reward or {}
    if r.xp and r.xp > 0 then
        TriggerEvent('trucking:addXP', source, r.xp)
    end
    if r.cash and r.cash > 0 then
        if GetResourceState('ox_inventory') == 'started' then
            local paid = exports.ox_inventory:AddItem(source, 'money', r.cash)
            if not paid then
                FrameworkBridge.AddMoney(source, r.cash, 'cash', 'Achievement: ' .. ach.name)
            end
        else
            FrameworkBridge.AddMoney(source, r.cash, 'cash', 'Achievement: ' .. ach.name)
        end
    end

    TriggerClientEvent('trucking:achievementUnlocked', source, {
        id = ach.id, name = ach.name, icon = ach.icon, description = ach.description
    })
end

function AchievementsServer.SendList(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return end

    local already = unlockedSet(identifier)
    local list = {}
    for _, ach in ipairs(Config.Achievements or {}) do
        list[#list + 1] = {
            id = ach.id,
            name = ach.name,
            icon = ach.icon,
            description = ach.description,
            unlocked = already[ach.id] ~= nil,
            unlocked_at = type(already[ach.id]) == 'string' and already[ach.id] or nil,
            reward = ach.reward
        }
    end

    TriggerClientEvent('trucking:updateAchievements', source, list)
end

RegisterNetEvent('trucking:requestAchievements', function()
    AchievementsServer.SendList(source)
end)

AddEventHandler('trucking:recordJobCompletion', function(source, jobRecord)
    SetTimeout(500, function()
        AchievementsServer.Check(source)
        AchievementsServer.SendList(source)
    end)
end)

return AchievementsServer
