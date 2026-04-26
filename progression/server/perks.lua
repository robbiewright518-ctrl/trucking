PerksServer = {}

local function perkConfig(perkId)
    for _, p in ipairs(Config.Perks or {}) do
        if p.id == perkId then return p end
    end
    return nil
end

local function getRanks(identifier)
    local ranks = {}
    for _, row in ipairs(Database.GetPlayerPerks(identifier) or {}) do
        ranks[row.perk_id] = row.rank or 0
    end
    return ranks
end

function PerksServer.GetEffect(source, effectType)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return 0 end

    local ranks = getRanks(identifier)
    local total = 0
    for _, p in ipairs(Config.Perks or {}) do
        if p.effect and p.effect.type == effectType then
            local rank = ranks[p.id] or 0
            total = total + (rank * (p.effect.value or 0))
        end
    end
    return total
end

function PerksServer.SendData(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return end

    local ranks = getRanks(identifier)
    local pts = Database.GetPerkPoints(identifier)

    local list = {}
    for _, p in ipairs(Config.Perks or {}) do
        list[#list + 1] = {
            id = p.id, name = p.name, icon = p.icon, desc = p.desc,
            max_rank = p.max_rank, effect = p.effect,
            rank = ranks[p.id] or 0,
            cost = Config.PerkSettings.cost_per_rank or 1
        }
    end

    TriggerClientEvent('trucking:updatePerks', source, {
        perks = list,
        points = pts
    })
end

function PerksServer.RankUp(source, perkId)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if not identifier then return false, 'No identifier' end

    local cfg = perkConfig(perkId)
    if not cfg then return false, 'Unknown perk' end

    local ranks = getRanks(identifier)
    local current = ranks[perkId] or 0
    if current >= cfg.max_rank then
        return false, 'Already at max rank'
    end

    local cost = Config.PerkSettings.cost_per_rank or 1
    if not Database.SpendPerkPoints(identifier, cost) then
        FrameworkBridge.Notify(source, 'Not enough perk points', Constants.NOTIFICATION.ERROR)
        return false, 'Not enough points'
    end

    Database.SetPerkRank(identifier, perkId, current + 1)
    FrameworkBridge.Notify(source,
        ('%s ranked up to %d/%d'):format(cfg.name, current + 1, cfg.max_rank),
        Constants.NOTIFICATION.SUCCESS)
    PerksServer.SendData(source)
    return true
end

AddEventHandler('trucking:onLevelUp', function(source, newLevel)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if identifier then
        Database.AddPerkPoints(identifier, Config.PerkSettings.points_per_level or 1)
        PerksServer.SendData(source)
    end
end)

AddEventHandler('trucking:internalLevelUp', function(source, newLevel)
    TriggerEvent('trucking:onLevelUp', source, newLevel)
end)

RegisterNetEvent('trucking:requestPerks', function()
    PerksServer.SendData(source)
end)

RegisterNetEvent('trucking:rankUpPerk', function(perkId)
    PerksServer.RankUp(source, perkId)
end)

AddEventHandler('trucking:onCriminalLevelUp', function(source, newLevel)
    local identifier = FrameworkBridge.GetIdentifier(source)
    if identifier then
        Database.AddPerkPoints(identifier, Config.PerkSettings.points_per_criminal_level or 1)
        PerksServer.SendData(source)
    end
end)

exports('GetPerkEffect', function(source, effectType)
    return PerksServer.GetEffect(source, effectType)
end)

return PerksServer
