CriminalServer = {}

local function getRow(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return nil, nil end
    return Database.GetCriminalProgression(identifier), identifier
end

function CriminalServer.GetLevel(source)
    local row = getRow(source)
    return row and row.level or 1
end

function CriminalServer.GetRep(source)
    local row = getRow(source)
    if not row then return 0, 0 end
    return row.rep or 0, row.total_rep or 0
end

function CriminalServer.GetRankTitle(level)
    local title = 'Street Runner'
    for lvl, name in pairs(Config.CriminalProgression.rank_titles or {}) do
        if level >= lvl then title = name end
    end
    return title
end

function CriminalServer.AddRep(source, amount)
    local row, identifier = getRow(source)
    if not row or not identifier then return false end

    local newRep = (row.rep or 0) + amount
    local newTotalRep = (row.total_rep or 0) + amount

    Database.SetCriminalRep(identifier, newRep, newTotalRep)

    local level = row.level or 1
    local repPerLevel = Config.CriminalProgression.rep_per_level or 750
    local newLevel = math.floor(newTotalRep / repPerLevel) + 1

    if newLevel > level and newLevel <= Config.CriminalProgression.max_level then
        CriminalServer.LevelUp(source, identifier, newLevel)
    end

    return true
end

function CriminalServer.LevelUp(source, identifier, newLevel)
    local row = getRow(source)
    if not row then return false end

    Database.SetCriminalLevel(identifier, newLevel)

    local unlockedJob = Config.DirtyUnlocks[newLevel]
    if unlockedJob then
        TriggerClientEvent('trucking:dirtyJobUnlocked', source, unlockedJob)
        FrameworkBridge.Notify(source, "New dirty job unlocked: " .. unlockedJob, Constants.NOTIFICATION.SUCCESS)
    end

    local title = CriminalServer.GetRankTitle(newLevel)
    FrameworkBridge.Notify(source, "Criminal level up! You are now: " .. title, Constants.NOTIFICATION.SUCCESS)
    TriggerClientEvent('trucking:criminalLevelUp', source, newLevel, title)
    TriggerEvent('trucking:onCriminalLevelUp', source, newLevel)

    return true
end

function CriminalServer.SendData(source)
    local row = getRow(source)
    if not row then return end
    TriggerClientEvent('trucking:updateCriminalData', source, {
        level = row.level or 1,
        rep = row.rep or 0,
        total_rep = row.total_rep or 0,
        rank = CriminalServer.GetRankTitle(row.level or 1),
        nextLevelRep = (row.level or 1) * Config.CriminalProgression.rep_per_level,
        jobs = row.dirty_jobs_completed or 0,
        earned = row.dirty_money_earned or 0
    })
end

function CriminalServer.RecordCompletion(source, payment)
    local _, identifier = getRow(source)
    if not identifier then return end
    Database.RecordDirtyJobCompletion(identifier, payment or 0)
end

function CriminalServer.GetPayMultiplier(source)
    local lvl = CriminalServer.GetLevel(source)
    return 1.0 + ((lvl - 1) * (Config.CriminalProgression.pay_per_level or 0))
end

AddEventHandler('trucking:onPlayerLoaded', function(source)
    CriminalServer.SendData(source)
end)

RegisterNetEvent('trucking:requestCriminalData', function()
    CriminalServer.SendData(source)
end)

exports('GetCriminalLevel', function(source)
    return CriminalServer.GetLevel(source)
end)

return CriminalServer
