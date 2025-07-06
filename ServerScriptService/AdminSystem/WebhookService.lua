-- Webhook Service for Admin System
-- Handles Discord webhook notifications and external integrations

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local WebhookService = {}
WebhookService.__index = WebhookService

-- Initialize webhook service
function WebhookService.new(adminSystem)
    local self = setmetatable({}, WebhookService)
    
    self.adminSystem = adminSystem
    self.webhookQueue = {}
    self.lastWebhookTime = {}
    self.retryQueue = {}
    
    -- Start webhook processing
    self:startWebhookProcessor()
    
    return self
end

-- Format embed for Discord webhook
function WebhookService:createDiscordEmbed(title, description, color, fields)
    local embed = {
        title = title,
        description = description,
        color = color or 3447003, -- Default blue
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = {
            text = "Admin System",
            icon_url = "https://cdn.discordapp.com/emojis/1234567890.png" -- Optional server icon
        }
    }
    
    if fields then
        embed.fields = fields
    end
    
    return embed
end

-- Send webhook with rate limiting and retry logic
function WebhookService:sendWebhook(webhookType, embed, priority)
    if not Config.Webhooks.Enabled then
        return false, "Webhooks disabled"
    end
    
    local webhookUrl = Config.Webhooks.DiscordWebhooks[webhookType]
    if not webhookUrl or webhookUrl == "" or webhookUrl:find("YOUR_") then
        return false, "Webhook URL not configured for " .. webhookType
    end
    
    -- Check cooldown
    local currentTime = tick()
    local lastTime = self.lastWebhookTime[webhookType] or 0
    
    if currentTime - lastTime < Config.Webhooks.WebhookCooldown then
        -- Queue for later if not urgent
        if priority ~= "urgent" then
            table.insert(self.webhookQueue, {
                webhookType = webhookType,
                embed = embed,
                scheduledTime = lastTime + Config.Webhooks.WebhookCooldown,
                priority = priority or "normal"
            })
            return true, "Queued for delivery"
        end
    end
    
    -- Send webhook
    local success, result = self:executeWebhook(webhookUrl, embed)
    
    if success then
        self.lastWebhookTime[webhookType] = currentTime
        return true, "Webhook sent successfully"
    else
        -- Add to retry queue
        self:addToRetryQueue(webhookType, embed, 1)
        return false, "Webhook failed, added to retry queue: " .. tostring(result)
    end
end

-- Execute webhook HTTP request with enhanced error handling
function WebhookService:executeWebhook(webhookUrl, embed)
    local payload = {
        embeds = {embed}
    }
    
    local success, result = pcall(function()
        return HttpService:PostAsync(
            webhookUrl,
            HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson
        )
    end)
    
    if success then
        return true, result
    else
        -- Enhanced error logging
        local errorMsg = tostring(result)
        warn("[WEBHOOK SERVICE] Webhook failed: " .. errorMsg)
        
        -- Log the error if logging is enabled
        if Config.Settings.LogErrors then
            self.adminSystem:logAction(
                {Name = "SYSTEM", UserId = 0}, 
                "WEBHOOK_ERROR", 
                "Discord", 
                errorMsg
            )
        end
        
        return false, errorMsg
    end
end

-- Add webhook to retry queue
function WebhookService:addToRetryQueue(webhookType, embed, attempt)
    if attempt > Config.Webhooks.MaxRetries then
        warn("[WEBHOOK SERVICE] Max retries exceeded for webhook type: " .. webhookType)
        return
    end
    
    table.insert(self.retryQueue, {
        webhookType = webhookType,
        embed = embed,
        attempt = attempt,
        retryTime = tick() + (Config.Webhooks.RetryDelay * attempt) -- Exponential backoff
    })
end

-- Start webhook processing coroutine
function WebhookService:startWebhookProcessor()
    spawn(function()
        while true do
            self:processWebhookQueue()
            self:processRetryQueue()
            wait(1) -- Process every second
        end
    end)
end

-- Process queued webhooks
function WebhookService:processWebhookQueue()
    local currentTime = tick()
    local newQueue = {}
    
    for _, webhookData in ipairs(self.webhookQueue) do
        if currentTime >= webhookData.scheduledTime then
            -- Try to send
            local success, result = self:sendWebhook(
                webhookData.webhookType, 
                webhookData.embed, 
                webhookData.priority
            )
            
            if not success and not result:find("Queued") then
                -- Failed to send, will be in retry queue
                warn("[WEBHOOK SERVICE] Failed to send queued webhook: " .. result)
            end
        else
            -- Keep in queue
            table.insert(newQueue, webhookData)
        end
    end
    
    self.webhookQueue = newQueue
end

-- Process retry queue
function WebhookService:processRetryQueue()
    local currentTime = tick()
    local newRetryQueue = {}
    
    for _, retryData in ipairs(self.retryQueue) do
        if currentTime >= retryData.retryTime then
            local webhookUrl = Config.Webhooks.DiscordWebhooks[retryData.webhookType]
            local success, result = self:executeWebhook(webhookUrl, retryData.embed)
            
            if success then
                print("[WEBHOOK SERVICE] Retry successful for " .. retryData.webhookType)
                self.lastWebhookTime[retryData.webhookType] = currentTime
            else
                -- Retry again if attempts remaining
                self:addToRetryQueue(
                    retryData.webhookType, 
                    retryData.embed, 
                    retryData.attempt + 1
                )
            end
        else
            -- Keep in retry queue
            table.insert(newRetryQueue, retryData)
        end
    end
    
    self.retryQueue = newRetryQueue
end

-- Admin action notifications
function WebhookService:notifyAdminAction(admin, action, target, details)
    if not Config.Webhooks.Enabled then return end
    
    local color = 3447003 -- Blue
    local shouldNotify = false
    
    -- Determine if we should notify and set color
    if action == "BAN" and Config.Webhooks.NotifyOnBan then
        color = 15158332 -- Red
        shouldNotify = true
    elseif action == "KICK" and Config.Webhooks.NotifyOnKick then
        color = 15105570 -- Orange
        shouldNotify = true
    elseif action:find("EXECUTE") and Config.Webhooks.NotifyOnCodeExecution then
        color = 10181046 -- Purple
        shouldNotify = true
    end
    
    if not shouldNotify then return end
    
    local embed = self:createDiscordEmbed(
        "🛡️ Admin Action: " .. action,
        "An admin action has been performed",
        color,
        {
            {name = "Admin", value = admin.Name .. " (" .. admin.UserId .. ")", inline = true},
            {name = "Action", value = action, inline = true},
            {name = "Target", value = target or "N/A", inline = true},
            {name = "Details", value = details or "No additional details", inline = false},
            {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = true}
        }
    )
    
    self:sendWebhook("AdminLogs", embed, "normal")
end

-- Security event notifications
function WebhookService:notifySecurityEvent(eventType, player, details, severity)
    if not Config.Webhooks.NotifyOnSecurityEvent then return end
    
    local color = 15158332 -- Red for security events
    local priority = "normal"
    
    -- Set priority based on severity
    if severity == "critical" then
        priority = "urgent"
        color = 10038562 -- Dark red
    elseif severity == "high" then
        color = 15158332 -- Red
    elseif severity == "medium" then
        color = 15105570 -- Orange
    else
        color = 16776960 -- Yellow
    end
    
    local embed = self:createDiscordEmbed(
        "🚨 Security Event: " .. eventType,
        "A security event has been detected",
        color,
        {
            {name = "Event Type", value = eventType, inline = true},
            {name = "Severity", value = severity or "medium", inline = true},
            {name = "Player", value = player and (player.Name .. " (" .. player.UserId .. ")") or "Unknown", inline = true},
            {name = "Details", value = details or "No additional details", inline = false},
            {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = true}
        }
    )
    
    self:sendWebhook("SecurityAlerts", embed, priority)
end

-- Rate limit violation notifications
function WebhookService:notifyRateLimitViolation(player, violationType, attempts, timeWindow)
    if not Config.Webhooks.NotifyOnRateLimitViolation then return end
    
    local embed = self:createDiscordEmbed(
        "⚠️ Rate Limit Violation",
        "A player has exceeded rate limits",
        15105570, -- Orange
        {
            {name = "Player", value = player.Name .. " (" .. player.UserId .. ")", inline = true},
            {name = "Violation Type", value = violationType, inline = true},
            {name = "Attempts", value = tostring(attempts), inline = true},
            {name = "Time Window", value = timeWindow .. " seconds", inline = true},
            {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = true}
        }
    )
    
    self:sendWebhook("ModeratorAlerts", embed, "normal")
end

-- System status notifications
function WebhookService:notifySystemStatus(statusType, message, data)
    local color = 3447003 -- Blue
    
    if statusType == "startup" then
        color = 5763719 -- Green
    elseif statusType == "shutdown" then
        color = 15158332 -- Red
    elseif statusType == "error" then
        color = 10038562 -- Dark red
    end
    
    local fields = {
        {name = "Status", value = statusType, inline = true},
        {name = "Message", value = message, inline = false},
        {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S UTC"), inline = true}
    }
    
    -- Add additional data fields if provided
    if data then
        for key, value in pairs(data) do
            table.insert(fields, {
                name = tostring(key), 
                value = tostring(value), 
                inline = true
            })
        end
    end
    
    local embed = self:createDiscordEmbed(
        "📊 System Status: " .. statusType:upper(),
        "Admin system status update",
        color,
        fields
    )
    
    self:sendWebhook("AdminLogs", embed, statusType == "error" and "urgent" or "normal")
end

-- Get webhook service statistics
function WebhookService:getStatistics()
    return {
        queuedWebhooks = #self.webhookQueue,
        retryQueueSize = #self.retryQueue,
        webhookTypes = {
            AdminLogs = self.lastWebhookTime["AdminLogs"] or 0,
            ModeratorAlerts = self.lastWebhookTime["ModeratorAlerts"] or 0,
            SecurityAlerts = self.lastWebhookTime["SecurityAlerts"] or 0
        },
        configStatus = {
            enabled = Config.Webhooks.Enabled,
            maxRetries = Config.Webhooks.MaxRetries,
            cooldown = Config.Webhooks.WebhookCooldown
        }
    }
end

return WebhookService