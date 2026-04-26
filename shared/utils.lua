Utils = {}

function Utils.GetDistance(coord1, coord2)
    if not coord1 or not coord2 then return 0 end
    local dx = coord1.x - coord2.x
    local dy = coord1.y - coord2.y
    local dz = coord1.z - coord2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function Utils.IsNearLocation(playerCoord, location, distance)
    return Utils.GetDistance(playerCoord, location) <= distance
end

function Utils.FormatMoney(amount)
    return string.format("$%,.2f", amount)
end

function Utils.FormatXP(xp)
    if xp >= 1000000 then
        return string.format("%.1fM", xp / 1000000)
    elseif xp >= 1000 then
        return string.format("%.1fK", xp / 1000)
    end
    return tostring(xp)
end

function Utils.ParseJSON(data)
    if type(data) == 'string' then
        return json.decode(data)
    end
    return data
end

function Utils.EncodeJSON(data)
    return json.encode(data)
end

function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Utils.CalculatePayment(distance, jobType, isDamaged, isLate)
    local job = Config.Jobs[jobType] or (Config.DirtyJobs and Config.DirtyJobs[jobType])
    if not job then return 0 end
    local basePay = job.base_pay + (distance * job.multiplier)
    local finalPay = basePay
    
    if isDamaged then
        finalPay = finalPay * (1 - Config.Payment.damage_reduction)
    end
    
    if isLate then
        finalPay = finalPay * (1 - Config.Payment.late_delivery_penalty)
    end
    
    finalPay = math.max(Config.Payment.min_payment, finalPay)
    finalPay = math.min(Config.Payment.max_payment, finalPay)
    
    return math.floor(finalPay)
end

function Utils.CalculateXP(distance, jobType, efficiency)
    local job = Config.Jobs[jobType] or (Config.DirtyJobs and Config.DirtyJobs[jobType])
    if not job then return 0 end
    local baseXP = job.xp_reward
    local efficiencyBonus = efficiency * 0.5
    
    return math.floor(baseXP + (distance * 0.01) + efficiencyBonus)
end

function Utils.FormatTime(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

function Utils.GetVehicleHealthPercent(vehicleHealth)
    return (vehicleHealth / 1000) * 100
end

function Utils.CalculateFuelUsage(distance, baseConsumption)
    return (distance / 1000) * baseConsumption
end

function Utils.IsValidEmail(email)
    return email and email:match("^[a-zA-Z0-9._%%-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]{2,}$") ~= nil
end

function Utils.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utils.IsValidVector(v)
    return v and type(v) == 'vector3' and v.x and v.y and v.z
end

function Utils.MergeTables(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

function Utils.Wait(ms, callback)
    SetTimeout(ms, callback)
end

function Utils.GetTimestamp()
    return os.time()
end

function Utils.DebugLog(message, ...)
    if Config.Framework.debug then
        print("^2[TRUCKING DEBUG]^7 " .. message)
    end
end

function Utils.CoordToString(coord)
    if not Utils.IsValidVector(coord) then return "Invalid" end
    return string.format("%.2f, %.2f, %.2f", coord.x, coord.y, coord.z)
end

function Utils.CalculateDamagePercent(bodyHealth, engineHealth)
    local bodyPercent = (bodyHealth / 1000) * 100
    local enginePercent = (engineHealth / 400) * 100
    return (bodyPercent + enginePercent) / 2
end

return Utils
