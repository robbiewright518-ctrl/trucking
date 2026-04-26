Database = {}
Database.Enabled = false
Database.Initialized = false
Database.Adapter = 'memory'
Database.Memory = {
    progression = {},
    jobs = {},
    vehicles = {}
}

local function isResourceStarted(resourceName)
    return GetResourceState(resourceName) == 'started'
end

local function cloneData(data)
    if not data then return nil end
    return Utils.DeepCopy(data)
end

local function createDefaultProgression(identifier)
    return {
        identifier = identifier,
        level = 1,
        xp = 0,
        total_xp = 0,
        jobs_completed = 0,
        distance_traveled = 0,
        money_earned = 0,
        skill_distance_driving = 0,
        skill_fragile_handling = 0,
        skill_speed_efficiency = 0
    }
end

local function ensureProgressionRecord(identifier)
    if not Database.Memory.progression[identifier] then
        Database.Memory.progression[identifier] = createDefaultProgression(identifier)
    end

    return Database.Memory.progression[identifier]
end

local function getVehicleBucket(identifier)
    Database.Memory.vehicles[identifier] = Database.Memory.vehicles[identifier] or {}
    return Database.Memory.vehicles[identifier]
end

local function queryAwait(query, params)
    params = params or {}

    if Database.Adapter == 'mysql_object' then
        return MySQL.query.await(query, params)
    elseif Database.Adapter == 'oxmysql' then
        return exports.oxmysql:query_async(query, params)
    end
end

local function insertAwait(query, params)
    params = params or {}

    if Database.Adapter == 'mysql_object' then
        return MySQL.insert.await(query, params)
    elseif Database.Adapter == 'oxmysql' then
        return exports.oxmysql:insert_async(query, params)
    end
end

local function updateAwait(query, params)
    params = params or {}

    if Database.Adapter == 'mysql_object' then
        return MySQL.update.await(query, params)
    elseif Database.Adapter == 'oxmysql' then
        return exports.oxmysql:update_async(query, params)
    end
end

function Database.DetectAdapter()
    if type(MySQL) == 'table' and MySQL.query and MySQL.insert and MySQL.update then
        Database.Enabled = true
        Database.Adapter = 'mysql_object'
        return true
    end

    if isResourceStarted('oxmysql') and exports.oxmysql then
        Database.Enabled = true
        Database.Adapter = 'oxmysql'
        return true
    end

    Database.Enabled = false
    Database.Adapter = 'memory'
    return false
end

function Database.Initialize()
    if Database.Initialized then return end

    Database.DetectAdapter()

    if not Database.Enabled then
        Utils.DebugLog("^3No supported MySQL adapter detected. Using in-memory storage for trucking.^7")
        return
    end

    if Database.Adapter == 'mysql_object' and type(MySQL.ready) == 'function' then
        MySQL.ready(function()
            Database.CreateTables()
            Database.Initialized = true
        end)
        return
    end

    Database.CreateTables()
    Database.Initialized = true
end

function Database.CreateTables()
    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_progression` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) UNIQUE NOT NULL,
            `level` INT DEFAULT 1,
            `xp` INT DEFAULT 0,
            `total_xp` INT DEFAULT 0,
            `jobs_completed` INT DEFAULT 0,
            `distance_traveled` INT DEFAULT 0,
            `money_earned` INT DEFAULT 0,
            `skill_distance_driving` INT DEFAULT 0,
            `skill_fragile_handling` INT DEFAULT 0,
            `skill_speed_efficiency` INT DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_jobs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `job_type` VARCHAR(50) NOT NULL,
            `distance` INT DEFAULT 0,
            `payment` INT DEFAULT 0,
            `xp_earned` INT DEFAULT 0,
            `was_damaged` BOOLEAN DEFAULT FALSE,
            `damage_percent` INT DEFAULT 0,
            `was_late` BOOLEAN DEFAULT FALSE,
            `time_taken` INT DEFAULT 0,
            `vehicle_used` VARCHAR(50),
            `completed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `identifier_idx` (`identifier`),
            INDEX `job_type_idx` (`job_type`),
            INDEX `completed_at_idx` (`completed_at`)
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_perks` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `perk_id` VARCHAR(64) NOT NULL,
            `rank` INT DEFAULT 0,
            UNIQUE KEY `uniq_player_perk` (`identifier`, `perk_id`),
            INDEX `identifier_idx` (`identifier`)
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_perk_points` (
            `identifier` VARCHAR(255) PRIMARY KEY,
            `available` INT DEFAULT 0,
            `spent` INT DEFAULT 0
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_achievements` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `achievement_id` VARCHAR(64) NOT NULL,
            `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uniq_player_ach` (`identifier`, `achievement_id`),
            INDEX `identifier_idx` (`identifier`)
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_criminal` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) UNIQUE NOT NULL,
            `level` INT DEFAULT 1,
            `rep` INT DEFAULT 0,
            `total_rep` INT DEFAULT 0,
            `dirty_jobs_completed` INT DEFAULT 0,
            `dirty_money_earned` INT DEFAULT 0,
            `times_busted` INT DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    queryAwait([[
        CREATE TABLE IF NOT EXISTS `trucking_vehicles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `vehicle_type` VARCHAR(50) NOT NULL,
            `fuel` INT DEFAULT 100,
            `health` INT DEFAULT 1000,
            `plate` VARCHAR(20) UNIQUE,
            `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `identifier_idx` (`identifier`)
        )
    ]])

    Utils.DebugLog("Database tables initialized using " .. Database.Adapter)
end

function Database.GetPlayerProgression(identifier)
    if not identifier then return {} end

    if Database.Enabled then
        return queryAwait('SELECT * FROM trucking_progression WHERE identifier = ?', { identifier }) or {}
    end

    local row = Database.Memory.progression[identifier]
    if not row then return {} end

    return { cloneData(row) }
end

function Database.CreatePlayerProgression(identifier)
    if not identifier then return nil end

    if Database.Enabled then
        return insertAwait('INSERT INTO trucking_progression (identifier) VALUES (?)', { identifier })
    end

    ensureProgressionRecord(identifier)
    return identifier
end

function Database.ResetPlayerProgression(identifier)
    if not identifier then return false end

    if Database.Enabled then
        queryAwait([[
            UPDATE trucking_progression
               SET level = 1, xp = 0, total_xp = 0,
                   driving_skill = 1, fuel_efficiency = 1, time_management = 1,
                   safe_delivery = 1, total_jobs = 0, total_distance = 0,
                   total_earnings = 0, perfect_deliveries = 0
             WHERE identifier = ?
        ]], { identifier })
        queryAwait('DELETE FROM trucking_jobs WHERE identifier = ?', { identifier })
        return true
    end

    if Database.MemoryProgression and Database.MemoryProgression[identifier] then
        Database.MemoryProgression[identifier] = nil
    end
    return true
end

function Database.AddPlayerXP(identifier, xp)
    if not identifier or not xp then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_progression (identifier, xp, total_xp)
              VALUES (?, ?, ?)
              ON DUPLICATE KEY UPDATE xp = xp + VALUES(xp), total_xp = total_xp + VALUES(total_xp)]],
            { identifier, xp, xp }
        )
    end

    local row = ensureProgressionRecord(identifier)
    row.xp = row.xp + xp
    row.total_xp = row.total_xp + xp
    return true
end

function Database.SetPlayerLevel(identifier, level)
    if not identifier or not level then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_progression (identifier, level)
              VALUES (?, ?)
              ON DUPLICATE KEY UPDATE level = VALUES(level)]],
            { identifier, level }
        )
    end

    local row = ensureProgressionRecord(identifier)
    row.level = level
    return true
end

function Database.RecordJobCompletion(identifier, jobData)
    if not identifier or not jobData then return false end

    if Database.Enabled then
        return insertAwait(
            'INSERT INTO trucking_jobs (identifier, job_type, distance, payment, xp_earned, was_damaged, damage_percent, was_late, time_taken, vehicle_used) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {
                identifier,
                jobData.jobType,
                jobData.distance,
                jobData.payment,
                jobData.xpEarned,
                jobData.wasDamaged,
                jobData.damagePercent,
                jobData.wasLate,
                jobData.timeTaken,
                jobData.vehicleUsed
            }
        )
    end

    Database.Memory.jobs[identifier] = Database.Memory.jobs[identifier] or {}
    table.insert(Database.Memory.jobs[identifier], cloneData(jobData))
    return true
end

function Database.GetPlayerJobHistory(identifier, limit)
    limit = limit or 50

    if Database.Enabled then
        return queryAwait(
            'SELECT * FROM trucking_jobs WHERE identifier = ? ORDER BY completed_at DESC LIMIT ?',
            { identifier, limit }
        ) or {}
    end

    local jobs = Database.Memory.jobs[identifier] or {}
    local results = {}

    for i = #jobs, math.max(1, #jobs - limit + 1), -1 do
        table.insert(results, cloneData(jobs[i]))
    end

    return results
end

function Database.UpdatePlayerStats(identifier, stats)
    if not identifier or not stats then return false end

    local statFields = {
        jobs_completed = stats.jobs_completed,
        distance_traveled = stats.distance_traveled,
        money_earned = stats.money_earned,
        skill_distance_driving = stats.skill_distance_driving or stats.distance_driving,
        skill_fragile_handling = stats.skill_fragile_handling or stats.fragile_handling,
        skill_speed_efficiency = stats.skill_speed_efficiency or stats.speed_efficiency
    }

    if Database.Enabled then
        local fields = {}
        local placeholders = {}
        local updateClauses = {}
        local insertParams = { identifier }

        for field, value in pairs(statFields) do
            if value ~= nil then
                table.insert(fields, field)
                table.insert(placeholders, '?')
                table.insert(updateClauses, field .. ' = VALUES(' .. field .. ')')
                table.insert(insertParams, value)
            end
        end

        if #fields == 0 then
            return false
        end

        local query = 'INSERT INTO trucking_progression (identifier, ' .. table.concat(fields, ', ') ..
            ') VALUES (?, ' .. table.concat(placeholders, ', ') ..
            ') ON DUPLICATE KEY UPDATE ' .. table.concat(updateClauses, ', ')

        return queryAwait(query, insertParams)
    end

    local row = ensureProgressionRecord(identifier)
    for field, value in pairs(statFields) do
        if value ~= nil then
            row[field] = value
        end
    end

    return true
end

function Database.AddPlayerVehicle(identifier, vehicleType, fuel, health, plate)
    if not identifier or not vehicleType then return false end

    if Database.Enabled then
        return insertAwait(
            'INSERT INTO trucking_vehicles (identifier, vehicle_type, fuel, health, plate) VALUES (?, ?, ?, ?, ?)',
            { identifier, vehicleType, fuel, health, plate }
        )
    end

    local vehicles = getVehicleBucket(identifier)
    table.insert(vehicles, {
        identifier = identifier,
        vehicle_type = vehicleType,
        fuel = fuel or 100,
        health = health or 1000,
        plate = plate
    })
    return true
end

function Database.GetPlayerVehicles(identifier)
    if not identifier then return {} end

    if Database.Enabled then
        return queryAwait('SELECT * FROM trucking_vehicles WHERE identifier = ?', { identifier }) or {}
    end

    return cloneData(getVehicleBucket(identifier))
end

function Database.GetLeaderboard(sortColumn, limit)
    limit = limit or 25
    local validColumns = {
        total_xp = true,
        level = true,
        jobs_completed = true,
        money_earned = true,
        distance_traveled = true
    }
    if not validColumns[sortColumn] then sortColumn = 'total_xp' end
    
    if Database.Enabled then
        return queryAwait(
            'SELECT identifier, level, total_xp, jobs_completed, money_earned, distance_traveled FROM trucking_progression ORDER BY ' .. sortColumn .. ' DESC LIMIT ?',
            { limit }
        ) or {}
    end
    
    local rows = {}
    for _, row in pairs(Database.Memory.progression) do
        table.insert(rows, cloneData(row))
    end
    
    table.sort(rows, function(a, b)
        return (a[sortColumn] or 0) > (b[sortColumn] or 0)
    end)
    
    local result = {}
    for i = 1, math.min(limit, #rows) do
        result[i] = rows[i]
    end
    return result
end

function Database.UpdateVehicleCondition(plate, fuel, health)
    if not plate then return false end

    if Database.Enabled then
        return updateAwait(
            'UPDATE trucking_vehicles SET fuel = ?, health = ? WHERE plate = ?',
            { fuel, health, plate }
        )
    end

    for _, vehicles in pairs(Database.Memory.vehicles) do
        for _, vehicle in ipairs(vehicles) do
            if vehicle.plate == plate then
                vehicle.fuel = fuel
                vehicle.health = health
                return true
            end
        end
    end

    return false
end

function Database.DeleteVehicle(plate)
    if not plate then return false end

    if Database.Enabled then
        return updateAwait('DELETE FROM trucking_vehicles WHERE plate = ?', { plate })
    end

    for identifier, vehicles in pairs(Database.Memory.vehicles) do
        for index, vehicle in ipairs(vehicles) do
            if vehicle.plate == plate then
                table.remove(Database.Memory.vehicles[identifier], index)
                return true
            end
        end
    end

    return false
end

function Database.GetTopEarners(limit)
    limit = limit or 10

    if Database.Enabled then
        return queryAwait(
            'SELECT identifier, level, total_xp, money_earned, jobs_completed FROM trucking_progression ORDER BY money_earned DESC LIMIT ?',
            { limit }
        ) or {}
    end

    local rows = {}
    for _, row in pairs(Database.Memory.progression) do
        table.insert(rows, cloneData(row))
    end

    table.sort(rows, function(a, b)
        return (a.money_earned or 0) > (b.money_earned or 0)
    end)

    while #rows > limit do
        table.remove(rows)
    end

    return rows
end

function Database.GetTopDrivers(limit)
    limit = limit or 10

    if Database.Enabled then
        return queryAwait(
            'SELECT identifier, level, total_xp, distance_traveled FROM trucking_progression ORDER BY distance_traveled DESC LIMIT ?',
            { limit }
        ) or {}
    end

    local rows = {}
    for _, row in pairs(Database.Memory.progression) do
        table.insert(rows, cloneData(row))
    end

    table.sort(rows, function(a, b)
        return (a.distance_traveled or 0) > (b.distance_traveled or 0)
    end)

    while #rows > limit do
        table.remove(rows)
    end

    return rows
end

function Database.GetPlayerEarnings(identifier)
    if not identifier then return {} end

    if Database.Enabled then
        return queryAwait(
            'SELECT SUM(payment) as total_earnings FROM trucking_jobs WHERE identifier = ?',
            { identifier }
        ) or {}
    end

    local total = 0
    for _, job in ipairs(Database.Memory.jobs[identifier] or {}) do
        total = total + (job.payment or 0)
    end

    return {
        { total_earnings = total }
    }
end

local function shouldInitializeForResource(resourceName)
    return resourceName == 'oxmysql' or resourceName == 'ghmattimysql' or resourceName == 'mysql-async'
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Database.Initialize()
    elseif shouldInitializeForResource(resourceName) and GetResourceState(GetCurrentResourceName()) == 'started' then
        Database.Initialize()
    end
end)

function Database.GetCriminalProgression(identifier)
    if not identifier then return nil end

    if Database.Enabled then
        local rows = queryAwait('SELECT * FROM trucking_criminal WHERE identifier = ?', { identifier })
        if rows and #rows > 0 then return rows[1] end
        queryAwait('INSERT IGNORE INTO trucking_criminal (identifier) VALUES (?)', { identifier })
        rows = queryAwait('SELECT * FROM trucking_criminal WHERE identifier = ?', { identifier })
        if rows and #rows > 0 then return rows[1] end
        return { identifier = identifier, level = 1, rep = 0, total_rep = 0,
                 dirty_jobs_completed = 0, dirty_money_earned = 0, times_busted = 0 }
    end

    Database.Memory.criminal = Database.Memory.criminal or {}
    if not Database.Memory.criminal[identifier] then
        Database.Memory.criminal[identifier] = {
            identifier = identifier, level = 1, rep = 0, total_rep = 0,
            dirty_jobs_completed = 0, dirty_money_earned = 0, times_busted = 0
        }
    end
    return Database.Memory.criminal[identifier]
end

function Database.AddCriminalRep(identifier, rep)
    if not identifier or not rep then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_criminal (identifier, rep, total_rep)
              VALUES (?, ?, ?)
              ON DUPLICATE KEY UPDATE rep = rep + VALUES(rep), total_rep = total_rep + VALUES(total_rep)]],
            { identifier, rep, rep }
        )
    end

    local row = Database.GetCriminalProgression(identifier)
    row.rep = (row.rep or 0) + rep
    row.total_rep = (row.total_rep or 0) + rep
    return true
end

function Database.SetCriminalRep(identifier, rep, total_rep)
    if not identifier then return false end

    if Database.Enabled then
        return queryAwait(
            'UPDATE trucking_criminal SET rep = ?, total_rep = ? WHERE identifier = ?',
            { rep or 0, total_rep or rep or 0, identifier }
        )
    end

    local row = Database.GetCriminalProgression(identifier)
    row.rep = rep or 0
    row.total_rep = total_rep or rep or 0
    return true
end

function Database.SetCriminalLevel(identifier, level)
    if not identifier or not level then return false end

    if Database.Enabled then
        return queryAwait('UPDATE trucking_criminal SET level = ? WHERE identifier = ?', { level, identifier })
    end

    local row = Database.GetCriminalProgression(identifier)
    row.level = level
    return true
end

function Database.RecordDirtyJobCompletion(identifier, payment)
    if not identifier then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_criminal (identifier, dirty_jobs_completed, dirty_money_earned)
              VALUES (?, 1, ?)
              ON DUPLICATE KEY UPDATE
                  dirty_jobs_completed = dirty_jobs_completed + 1,
                  dirty_money_earned   = dirty_money_earned + VALUES(dirty_money_earned)]],
            { identifier, payment or 0 }
        )
    end

    local row = Database.GetCriminalProgression(identifier)
    row.dirty_jobs_completed = (row.dirty_jobs_completed or 0) + 1
    row.dirty_money_earned   = (row.dirty_money_earned or 0) + (payment or 0)
    return true
end

function Database.GetUnlockedAchievements(identifier)
    if not identifier then return {} end

    if Database.Enabled then
        local rows = queryAwait('SELECT achievement_id, unlocked_at FROM trucking_achievements WHERE identifier = ?', { identifier })
        return rows or {}
    end

    Database.Memory.achievements = Database.Memory.achievements or {}
    Database.Memory.achievements[identifier] = Database.Memory.achievements[identifier] or {}
    local out = {}
    for id, ts in pairs(Database.Memory.achievements[identifier]) do
        out[#out + 1] = { achievement_id = id, unlocked_at = ts }
    end
    return out
end

function Database.UnlockAchievement(identifier, achievementId)
    if not identifier or not achievementId then return false end

    if Database.Enabled then
        return queryAwait(
            'INSERT IGNORE INTO trucking_achievements (identifier, achievement_id) VALUES (?, ?)',
            { identifier, achievementId }
        )
    end

    Database.Memory.achievements = Database.Memory.achievements or {}
    Database.Memory.achievements[identifier] = Database.Memory.achievements[identifier] or {}
    if Database.Memory.achievements[identifier][achievementId] then return false end
    Database.Memory.achievements[identifier][achievementId] = os.time()
    return true
end

function Database.GetPlayerPerks(identifier)
    if not identifier then return {} end

    if Database.Enabled then
        return queryAwait('SELECT perk_id, rank FROM trucking_perks WHERE identifier = ?', { identifier }) or {}
    end

    Database.Memory.perks = Database.Memory.perks or {}
    Database.Memory.perks[identifier] = Database.Memory.perks[identifier] or {}
    local out = {}
    for id, rank in pairs(Database.Memory.perks[identifier]) do
        out[#out + 1] = { perk_id = id, rank = rank }
    end
    return out
end

function Database.SetPerkRank(identifier, perkId, rank)
    if not identifier or not perkId then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_perks (identifier, perk_id, rank)
              VALUES (?, ?, ?)
              ON DUPLICATE KEY UPDATE rank = VALUES(rank)]],
            { identifier, perkId, rank }
        )
    end

    Database.Memory.perks = Database.Memory.perks or {}
    Database.Memory.perks[identifier] = Database.Memory.perks[identifier] or {}
    Database.Memory.perks[identifier][perkId] = rank
    return true
end

function Database.GetPerkPoints(identifier)
    if not identifier then return { available = 0, spent = 0 } end

    if Database.Enabled then
        local rows = queryAwait('SELECT available, spent FROM trucking_perk_points WHERE identifier = ?', { identifier })
        if rows and rows[1] then return rows[1] end
        queryAwait('INSERT INTO trucking_perk_points (identifier) VALUES (?)', { identifier })
        return { available = 0, spent = 0 }
    end

    Database.Memory.perk_points = Database.Memory.perk_points or {}
    Database.Memory.perk_points[identifier] = Database.Memory.perk_points[identifier] or { available = 0, spent = 0 }
    return Database.Memory.perk_points[identifier]
end

function Database.AddPerkPoints(identifier, amount)
    if not identifier or not amount or amount == 0 then return false end

    if Database.Enabled then
        return queryAwait(
            [[INSERT INTO trucking_perk_points (identifier, available)
              VALUES (?, ?)
              ON DUPLICATE KEY UPDATE available = available + VALUES(available)]],
            { identifier, amount }
        )
    end

    local row = Database.GetPerkPoints(identifier)
    row.available = (row.available or 0) + amount
    return true
end

function Database.SpendPerkPoints(identifier, amount)
    if not identifier or not amount or amount <= 0 then return false end

    if Database.Enabled then
        local rows = queryAwait('SELECT available FROM trucking_perk_points WHERE identifier = ?', { identifier })
        if not rows or not rows[1] or (rows[1].available or 0) < amount then return false end
        queryAwait(
            'UPDATE trucking_perk_points SET available = available - ?, spent = spent + ? WHERE identifier = ?',
            { amount, amount, identifier }
        )
        return true
    end

    local row = Database.GetPerkPoints(identifier)
    if (row.available or 0) < amount then return false end
    row.available = row.available - amount
    row.spent = (row.spent or 0) + amount
    return true
end

return Database
