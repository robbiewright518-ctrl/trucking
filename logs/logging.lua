Logger = {}

function Logger.LogJobCompletion(source, jobRecord)
    if not Config.Logging.enabled or not Config.Logging.webhook_url then return end

    local playerName = FrameworkBridge.GetPlayerName(source)
    local identifier = FrameworkBridge.GetIdentifier(source)

    if not Config.Logging.log_job_completion then return end

    local isDirty = jobRecord.isDirty == true
    local title = isDirty and "Dirty Job Completed" or "Job Completed"
    local color = isDirty and 0xFF0000 or Config.Logging.embed_color

    local embed = {
        title = title,
        description = "Player: **" .. playerName .. "** (`" .. identifier .. "`)",
        color = color,
        fields = {
            {
                name = "Job Type",
                value = jobRecord.jobType,
                inline = true
            },
            {
                name = "Distance",
                value = string.format("%.2f km", jobRecord.distance / 1000),
                inline = true
            },
            {
                name = "Payment",
                value = "$" .. jobRecord.payment,
                inline = true
            },
            {
                name = "XP Earned",
                value = jobRecord.xpEarned,
                inline = true
            },
            {
                name = "Damage",
                value = jobRecord.damagePercent .. "%",
                inline = true
            },
            {
                name = "Time Taken",
                value = Utils.FormatTime(jobRecord.timeTaken),
                inline = true
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    Logger.SendDiscordWebhook(embed)
end

function Logger.LogPayment(source, amount, reason)
    if not Config.Logging.enabled or not Config.Logging.webhook_url then return end
    if not Config.Logging.log_payments then return end
    
    local playerName = FrameworkBridge.GetPlayerName(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    
    local embed = {
        title = "Payment Processed",
        description = "Player: **" .. playerName .. "** (`" .. identifier .. "`)",
        color = 0x00FF00,
        fields = {
            {
                name = "Amount",
                value = "$" .. amount,
                inline = true
            },
            {
                name = "Reason",
                value = reason,
                inline = true
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    Logger.SendDiscordWebhook(embed)
end

function Logger.LogExploit(source, exploitFlag)
    if not Config.Logging.enabled or not Config.Logging.webhook_url then return end
    if not Config.Logging.log_exploits then return end
    
    local playerName = FrameworkBridge.GetPlayerName(source)
    local identifier = FrameworkBridge.GetIdentifier(source)
    
    local embed = {
        title = "⚠️ EXPLOIT DETECTED",
        description = "Player: **" .. playerName .. "** (`" .. identifier .. "`)",
        color = 0xFF0000,
        fields = {
            {
                name = "Exploit Type",
                value = exploitFlag,
                inline = false
            },
            {
                name = "Action",
                value = "Job cancelled and logged for review",
                inline = false
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    Logger.SendDiscordWebhook(embed)
end

function Logger.LogLevelUp(source, newLevel)
    if not Config.Logging.enabled or not Config.Logging.webhook_url then return end
    
    local playerName = FrameworkBridge.GetPlayerName(source)
    
    local embed = {
        title = "⬆️ Level Up",
        description = "Player: **" .. playerName .. "**",
        color = 0xFFFF00,
        fields = {
            {
                name = "New Level",
                value = newLevel,
                inline = true
            }
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    Logger.SendDiscordWebhook(embed)
end

function Logger.SendDiscordWebhook(embed)
    local webhook_url = Config.Logging.webhook_url
    
    if not webhook_url or webhook_url == 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE' then
        Utils.DebugLog("^1Webhook not configured. Please set Config.Logging.webhook_url^7")
        return
    end
    
    local payload = {
        username = "Trucking System",
        avatar_url = "https://cdn-icons-png.flaticon.com/512/2381/2381197.png",
        embeds = { embed }
    }
    
    PerformHttpRequest(webhook_url, function(err, text, headers)
        if err ~= 204 then
            Utils.DebugLog("^1Failed to send Discord webhook: " .. err .. "^7")
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('trucking:logJobCompletion', function(source, jobRecord)
    Logger.LogJobCompletion(source, jobRecord)
end)

AddEventHandler('trucking:logPayment', function(source, amount, reason)
    Logger.LogPayment(source, amount, reason)
end)

AddEventHandler('trucking:logExploit', function(source, exploitFlag)
    Logger.LogExploit(source, exploitFlag)
end)

AddEventHandler('trucking:logLevelUp', function(source, newLevel)
    Logger.LogLevelUp(source, newLevel)
end)

return Logger
