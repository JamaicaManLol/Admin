-- Admin System Core Server Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- Load configuration
local Config = require(script.Parent.Config)
local Commands = require(script.Parent.Commands)
local SecureExecutor = require(script.Parent.SecureExecutor)

-- Admin System Class
local AdminCore = {}
AdminCore.__index = AdminCore

-- Data storage
local BanDataStore = DataStoreService:GetDataStore("AdminBans_v1")
local LogDataStore = DataStoreService:GetDataStore("AdminLogs_v1")

-- Create remote events folder
local AdminRemotes = Instance.new("Folder")
AdminRemotes.Name = "AdminRemotes"
AdminRemotes.Parent = ReplicatedStorage

-- Create remote events
local ExecuteRemote = Instance.new("RemoteEvent")
ExecuteRemote.Name = "ExecuteCommand"
ExecuteRemote.Parent = AdminRemotes

local ConsoleRemote = Instance.new("RemoteEvent")
ConsoleRemote.Name = "ConsoleToggle"
ConsoleRemote.Parent = AdminRemotes

local LogRemote = Instance.new("RemoteEvent")
LogRemote.Name = "AdminLog"
LogRemote.Parent = AdminRemotes

-- Create additional remote events for secure executor
local ExecutorResultRemote = Instance.new("RemoteEvent")
ExecutorResultRemote.Name = "ExecutorResult"
ExecutorResultRemote.Parent = AdminRemotes

local ClientReplicationRemote = Instance.new("RemoteEvent")
ClientReplicationRemote.Name = "ClientReplication"
ClientReplicationRemote.Parent = AdminRemotes

-- Initialize the admin system
function AdminCore.new()
    local self = setmetatable({}, AdminCore)
    
    self.logs = {}
    self.godPlayers = {}
    
    -- Rate limiting storage
    self.rateLimitData = {}
    self.tempBannedUsers = {}
    
    -- Webhook integration
    self.webhookQueue = {}
    self.lastWebhookTime = {}
    self.retryQueue = {}
    
    -- Enhanced security tracking
    self.securityEvents = {}
    self.suspiciousActivity = {}
    self.playerSessions = {}
    
    -- Initialize secure executor
    self.secureExecutor = SecureExecutor.new(self)
    
    -- Load ban data
    self:loadBanData()
    
    -- Connect events
    self:connectEvents()
    
    -- Start background services
    self:startRateLimitCleanup()
    self:startWebhookProcessor()
    self:startSecurityMonitoring()
    
    -- Setup player events
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeaving(player)
    end)
    
    -- Send startup notification
    if Config.Webhooks.Enabled then
        self:notifySystemStatus("startup", "Admin system initialized successfully", {
            version = "Enhanced v2.0",
            adminCount = self:getAdminCount(),
            featuresEnabled = self:getEnabledFeatures()
        })
    end
    
    return self
end

-- Rate Limiting Implementation
function AdminCore:checkRateLimit(player, actionType)
    if not Config.RateLimiting.Enabled then
        return true
    end
    
    local userId = player.UserId
    local currentTime = tick()
    
    -- Check if player is temporarily banned for rate limit abuse
    if self.tempBannedUsers[userId] and currentTime < self.tempBannedUsers[userId] then
        return false, "You are temporarily banned for rate limit abuse"
    end
    
    -- Initialize rate limit data for player
    if not self.rateLimitData[userId] then
        self.rateLimitData[userId] = {
            commands = {},
            executions = {},
            remoteEvents = {},
            violations = 0
        }
    end
    
    local playerData = self.rateLimitData[userId]
    local actionData = playerData[actionType] or {}
    
    -- Clean old entries (older than 1 minute)
    local cleanedData = {}
    for _, timestamp in ipairs(actionData) do
        if currentTime - timestamp < 60 then
            table.insert(cleanedData, timestamp)
        end
    end
    playerData[actionType] = cleanedData
    
    -- Get rate limits based on action type
    local rateLimit, burstLimit
    if actionType == "commands" then
        rateLimit = Config.RateLimiting.CommandsPerMinute
        burstLimit = Config.RateLimiting.CommandBurstLimit
    elseif actionType == "executions" then
        rateLimit = Config.RateLimiting.ExecutionsPerMinute
        burstLimit = Config.RateLimiting.ExecutionBurstLimit
    elseif actionType == "remoteEvents" then
        rateLimit = Config.RateLimiting.RemoteEventsPerMinute
        burstLimit = Config.RateLimiting.RemoteBurstLimit
    else
        return true -- Unknown action type, allow
    end
    
    -- Check burst limit (last 10 seconds)
    local recentActions = 0
    for _, timestamp in ipairs(cleanedData) do
        if currentTime - timestamp < 10 then
            recentActions = recentActions + 1
        end
    end
    
    if recentActions >= burstLimit then
        self:handleRateLimitViolation(player, actionType, "burst", recentActions)
        return false, "Rate limit exceeded (burst limit)"
    end
    
    -- Check rate limit (per minute)
    if #cleanedData >= rateLimit then
        self:handleRateLimitViolation(player, actionType, "rate", #cleanedData)
        return false, "Rate limit exceeded (per minute limit)"
    end
    
    -- Record this action
    table.insert(playerData[actionType], currentTime)
    return true
end

function AdminCore:handleRateLimitViolation(player, actionType, violationType, attempts)
    local userId = player.UserId
    
    -- Increment violation count
    if not self.rateLimitData[userId] then
        self.rateLimitData[userId] = {violations = 0}
    end
    self.rateLimitData[userId].violations = (self.rateLimitData[userId].violations or 0) + 1
    
    local violations = self.rateLimitData[userId].violations
    
    -- Log the violation
    self:logAction(player, "RATE_LIMIT_VIOLATION", actionType, 
        string.format("%s limit exceeded - %d attempts in window", violationType, attempts))
    
    -- Send webhook notification
    if Config.Webhooks.Enabled then
        self:notifyRateLimitViolation(player, actionType, attempts, 60)
    end
    
    -- Apply escalating punishments
    if violations >= Config.RateLimiting.ViolationThreshold then
        -- Temporary ban for rate limit abuse
        self.tempBannedUsers[userId] = tick() + Config.RateLimiting.TempBanDuration
        
        self:logAction(player, "TEMP_BAN", "rate_limit_abuse", 
            string.format("Temporary ban for %d seconds due to %d violations", 
                Config.RateLimiting.TempBanDuration, violations))
        
        -- Send security alert
        if Config.Webhooks.Enabled then
            self:notifySecurityEvent("Rate Limit Abuse", player, 
                string.format("Player temp-banned for %d violations", violations), "high")
        end
        
        -- Kick the player
        pcall(function()
            player:Kick("Temporary ban: Rate limit abuse detected. Duration: " .. 
                math.ceil(Config.RateLimiting.TempBanDuration / 60) .. " minutes")
        end)
    end
end

function AdminCore:startRateLimitCleanup()
    spawn(function()
        while true do
            wait(Config.RateLimiting.CleanupInterval)
            local currentTime = tick()
            
            -- Clean up old rate limit data
            for userId, data in pairs(self.rateLimitData) do
                -- Clean up old action timestamps
                for actionType, timestamps in pairs(data) do
                    if type(timestamps) == "table" then
                        local cleaned = {}
                        for _, timestamp in ipairs(timestamps) do
                            if currentTime - timestamp < 3600 then -- Keep 1 hour of data
                                table.insert(cleaned, timestamp)
                            end
                        end
                        data[actionType] = cleaned
                    end
                end
                
                -- Reset violations if player has been good for an hour
                if data.violations and data.violations > 0 then
                    local hasRecentViolations = false
                    for actionType, timestamps in pairs(data) do
                        if type(timestamps) == "table" and #timestamps > 0 then
                            hasRecentViolations = true
                            break
                        end
                    end
                    
                    if not hasRecentViolations then
                        data.violations = 0
                    end
                end
            end
            
            -- Clean up expired temp bans
            for userId, expireTime in pairs(self.tempBannedUsers) do
                if currentTime >= expireTime then
                    self.tempBannedUsers[userId] = nil
                end
            end
        end
    end)
end

-- Webhook Integration Implementation
function AdminCore:createDiscordEmbed(title, description, color, fields)
    local embed = {
        title = title,
        description = description,
        color = color or 3447003, -- Default blue
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        footer = {
            text = "Admin System Enhanced",
            icon_url = "https://cdn.discordapp.com/emojis/1234567890.png"
        }
    }
    
    if fields then
        embed.fields = fields
    end
    
    return embed
end

function AdminCore:sendWebhook(webhookType, embed, priority)
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

function AdminCore:executeWebhook(webhookUrl, embed)
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
        if Config.Settings.LogErrors then
            warn("[ADMIN SYSTEM] Webhook failed: " .. errorMsg)
            self:logAction(
                {Name = "SYSTEM", UserId = 0}, 
                "WEBHOOK_ERROR", 
                "Discord", 
                errorMsg
            )
        end
        return false, errorMsg
    end
end

function AdminCore:addToRetryQueue(webhookType, embed, attempt)
    if attempt > Config.Webhooks.MaxRetries then
        warn("[ADMIN SYSTEM] Max webhook retries exceeded for: " .. webhookType)
        return
    end
    
    table.insert(self.retryQueue, {
        webhookType = webhookType,
        embed = embed,
        attempt = attempt,
        retryTime = tick() + (Config.Webhooks.RetryDelay * attempt)
    })
end

function AdminCore:startWebhookProcessor()
    spawn(function()
        while true do
            self:processWebhookQueue()
            self:processRetryQueue()
            wait(1)
        end
    end)
end

function AdminCore:processWebhookQueue()
    local currentTime = tick()
    local newQueue = {}
    
    for _, webhookData in ipairs(self.webhookQueue) do
        if currentTime >= webhookData.scheduledTime then
            local success, result = self:sendWebhook(
                webhookData.webhookType, 
                webhookData.embed, 
                webhookData.priority
            )
            
            if not success and not result:find("Queued") then
                warn("[ADMIN SYSTEM] Failed to send queued webhook: " .. result)
            end
        else
            table.insert(newQueue, webhookData)
        end
    end
    
    self.webhookQueue = newQueue
end

function AdminCore:processRetryQueue()
    local currentTime = tick()
    local newRetryQueue = {}
    
    for _, retryData in ipairs(self.retryQueue) do
        if currentTime >= retryData.retryTime then
            local webhookUrl = Config.Webhooks.DiscordWebhooks[retryData.webhookType]
            local success, result = self:executeWebhook(webhookUrl, retryData.embed)
            
            if success then
                print("[ADMIN SYSTEM] Webhook retry successful for " .. retryData.webhookType)
                self.lastWebhookTime[retryData.webhookType] = currentTime
            else
                self:addToRetryQueue(
                    retryData.webhookType, 
                    retryData.embed, 
                    retryData.attempt + 1
                )
            end
        else
            table.insert(newRetryQueue, retryData)
        end
    end
    
    self.retryQueue = newRetryQueue
end

-- Webhook notification methods
function AdminCore:notifyAdminAction(admin, action, target, details)
    if not Config.Webhooks.Enabled then return end
    
    local color = 3447003 -- Blue
    local shouldNotify = false
    
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

function AdminCore:notifySecurityEvent(eventType, player, details, severity)
    if not Config.Webhooks.NotifyOnSecurityEvent then return end
    
    local color = 15158332 -- Red for security events
    local priority = "normal"
    
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

function AdminCore:notifyRateLimitViolation(player, violationType, attempts, timeWindow)
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

function AdminCore:notifySystemStatus(statusType, message, data)
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

-- Enhanced Security Monitoring
function AdminCore:startSecurityMonitoring()
    spawn(function()
        while true do
            wait(300) -- Check every 5 minutes
            self:performSecurityScan()
        end
    end)
end

function AdminCore:performSecurityScan()
    if not Config.Security.MonitorSuspiciousActivity then return end
    
    local currentTime = tick()
    
    for userId, playerData in pairs(self.rateLimitData) do
        local totalCommands = 0
        
        -- Count recent command usage
        for actionType, timestamps in pairs(playerData) do
            if type(timestamps) == "table" then
                for _, timestamp in ipairs(timestamps) do
                    if currentTime - timestamp < 3600 then -- Last hour
                        totalCommands = totalCommands + 1
                    end
                end
            end
        end
        
        -- Check for suspicious activity
        if totalCommands > Config.Security.SuspiciousCommandThreshold then
            local player = Players:GetPlayerByUserId(userId)
            if player then
                self:notifySecurityEvent("Suspicious Activity", player, 
                    string.format("Excessive command usage: %d commands in 1 hour", totalCommands), 
                    "medium")
                
                self:logAction(player, "SUSPICIOUS_ACTIVITY", "high_command_usage", 
                    string.format("%d commands in 1 hour", totalCommands))
            end
        end
    end
end

-- Check if user is banned (enhanced with temp bans)
function AdminCore:isBanned(userId)
    -- Check permanent bans
    if Config.BannedUsers[userId] ~= nil then
        return true
    end
    
    -- Check temporary bans
    if self.tempBannedUsers[userId] and tick() < self.tempBannedUsers[userId] then
        return true
    end
    
    return false
end

-- Get player permission level
function AdminCore:getPermissionLevel(player)
    local userId = player.UserId
    local role = Config.Admins[userId]
    
    if role then
        return Config.PermissionLevels[role] or 0
    end
    
    return 0 -- Guest level
end

-- Check if player has permission for command
function AdminCore:hasPermission(player, command)
    local playerLevel = self:getPermissionLevel(player)
    local requiredLevel = Config.CommandPermissions[command] or 999
    
    return playerLevel >= requiredLevel
end

-- Enhanced log action with webhook integration
function AdminCore:logAction(admin, action, target, details)
    local logEntry = {
        admin = admin.Name,
        adminId = admin.UserId,
        action = action,
        target = target or "N/A",
        details = details or "",
        timestamp = os.time()
    }
    
    table.insert(self.logs, logEntry)
    
    -- Save to DataStore if enabled
    if Config.Settings.EnableLogging then
        pcall(function()
            LogDataStore:SetAsync("log_" .. os.time() .. "_" .. math.random(1000, 9999), logEntry)
        end)
    end
    
    print("[ADMIN LOG]", admin.Name, action, target or "", details or "")
    
    -- Send webhook notification for important actions
    if Config.Webhooks.Enabled then
        self:notifyAdminAction(admin, action, target, details)
    end
end

-- Load ban data from DataStore
function AdminCore:loadBanData()
    pcall(function()
        local success, banData = pcall(function()
            return BanDataStore:GetAsync("banned_users")
        end)
        
        if success and banData then
            Config.BannedUsers = banData
        end
    end)
end

-- Save ban data to DataStore
function AdminCore:saveBanData()
    if Config.Settings.AutoSaveBans then
        pcall(function()
            BanDataStore:SetAsync("banned_users", Config.BannedUsers)
        end)
    end
end

-- Handle player joining (enhanced with security checks)
function AdminCore:onPlayerJoined(player)
    -- Check if player is banned
    if self:isBanned(player.UserId) then
        local banInfo = Config.BannedUsers[player.UserId] or {reason = "Temporary ban active"}
        pcall(function()
            player:Kick("You are banned from this game. Reason: " .. banInfo.reason)
        end)
        return
    end
    
    -- Initialize session tracking
    self.playerSessions[player.UserId] = {
        joinTime = tick(),
        lastActivity = tick(),
        commandCount = 0
    }
    
    -- Setup admin GUI for admins
    if self:getPermissionLevel(player) > 0 then
        player.CharacterAdded:Connect(function()
            wait(1)
            pcall(function()
                self:setupAdminGUI(player)
            end)
        end)
        
        if player.Character then
            pcall(function()
                self:setupAdminGUI(player)
            end)
        end
    end
end

-- Handle player leaving
function AdminCore:onPlayerLeaving(player)
    -- Remove from god mode if active
    if self.godPlayers[player] then
        self.godPlayers[player] = nil
    end
    
    -- Clean up session data
    if self.playerSessions[player.UserId] then
        self.playerSessions[player.UserId] = nil
    end
    
    -- Clean up rate limit data after some time
    spawn(function()
        wait(3600) -- Keep data for 1 hour after leaving
        if self.rateLimitData[player.UserId] then
            self.rateLimitData[player.UserId] = nil
        end
    end)
end

-- Setup admin GUI
function AdminCore:setupAdminGUI(player)
    pcall(function()
        LogRemote:FireClient(player, "admin_status", {
            isAdmin = true,
            level = self:getPermissionLevel(player),
            commands = self:getAvailableCommands(player)
        })
    end)
end

-- Get available commands for player
function AdminCore:getAvailableCommands(player)
    local available = {}
    local playerLevel = self:getPermissionLevel(player)
    
    for command, requiredLevel in pairs(Config.CommandPermissions) do
        if playerLevel >= requiredLevel then
            table.insert(available, command)
        end
    end
    
    return available
end

-- Enhanced event connections with rate limiting and error handling
function AdminCore:connectEvents()
    -- Handle command execution with rate limiting
    ExecuteRemote.OnServerEvent:Connect(function(player, commandType, ...)
        pcall(function()
            -- Check rate limit for remote events
            local canProceed, limitMsg = self:checkRateLimit(player, "remoteEvents")
            if not canProceed then
                self:sendMessage(player, limitMsg, "Error")
                return
            end
            
            if commandType == "chat_command" then
                self:handleChatCommand(player, ...)
            elseif commandType == "console_execute" then
                self:handleConsoleExecute(player, ...)
            end
        end)
    end)
    
    -- Handle console toggle with enhanced error handling
    ConsoleRemote.OnServerEvent:Connect(function(player, action)
        pcall(function()
            if action == "request_console" then
                if self:hasPermission(player, "console") then
                    pcall(function()
                        LogRemote:FireClient(player, "console_access", true)
                    end)
                else
                    pcall(function()
                        LogRemote:FireClient(player, "console_access", false)
                    end)
                end
            end
        end)
    end)
    
    -- Handle client replication authentication and heartbeat
    LogRemote.OnServerEvent:Connect(function(player, eventType, data)
        pcall(function()
            if eventType == "request_auth" then
                self:handleAuthenticationRequest(player, data)
            elseif eventType == "heartbeat" then
                self:handleClientHeartbeat(player, data)
            end
        end)
    end)
    
    -- Handle chat commands with rate limiting
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            pcall(function()
                if message:sub(1, 1) == Config.Settings.CommandPrefix then
                    self:handleChatCommand(player, message:sub(2))
                end
            end)
        end)
    end)
end

-- Enhanced chat command handling with rate limiting
function AdminCore:handleChatCommand(player, command)
    -- Check rate limit for commands
    local canProceed, limitMsg = self:checkRateLimit(player, "commands")
    if not canProceed then
        self:sendMessage(player, limitMsg, "Error")
        return
    end
    
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return end
    
    local cmd = args[1]:lower()
    table.remove(args, 1)
    
    -- Check permission
    if not self:hasPermission(player, cmd) then
        self:sendMessage(player, "You don't have permission to use this command.", "Error")
        return
    end
    
    -- Execute command with enhanced error handling
    if Commands[cmd] then
        local success, result = pcall(Commands[cmd], self, player, unpack(args))
        
        if not success then
            local errorMsg = "Command error: " .. tostring(result)
            self:sendMessage(player, errorMsg, "Error")
            self:logAction(player, "ERROR", cmd, tostring(result))
            
            -- Send security alert for repeated command errors
            if Config.Webhooks.Enabled then
                self:notifySecurityEvent("Command Error", player, errorMsg, "low")
            end
        elseif result then
            self:sendMessage(player, result, "Success")
        end
    else
        self:sendMessage(player, "Unknown command: " .. cmd, "Error")
    end
end

-- Enhanced console execution with rate limiting
function AdminCore:handleConsoleExecute(player, code, replicateToClient)
    -- Check rate limit for executions
    local canProceed, limitMsg = self:checkRateLimit(player, "executions")
    if not canProceed then
        self:sendMessage(player, limitMsg, "Error")
        return
    end
    
    if not self:hasPermission(player, "execute") then
        self:sendMessage(player, "You don't have permission to execute code.", "Error")
        return
    end
    
    -- Use secure executor for advanced script execution
    local success, result = pcall(function()
        return self.secureExecutor:executeScript(player, code, replicateToClient)
    end)
    
    if success and result then
        -- Send success result to client console
        pcall(function()
            LogRemote:FireClient(player, "console_output", "Execution successful: " .. tostring(result))
        end)
    else
        -- Send error result to client console
        local errorMsg = "Execution failed: " .. tostring(result or "Unknown error")
        pcall(function()
            LogRemote:FireClient(player, "console_output", errorMsg)
        end)
        
        -- Log execution error
        self:logAction(player, "EXECUTION_ERROR", "console", errorMsg)
    end
end

-- Enhanced message sending with error handling
function AdminCore:sendMessage(player, message, messageType)
    pcall(function()
        LogRemote:FireClient(player, "admin_message", {
            message = message,
            type = messageType or "Info",
            timestamp = tick()
        })
    end)
end

-- Find players by partial name
function AdminCore:findPlayers(name)
    local players = {}
    name = name:lower()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(name) or player.DisplayName:lower():find(name) then
            table.insert(players, player)
        end
    end
    
    return players
end

-- Enhanced authentication request handling
function AdminCore:handleAuthenticationRequest(player, data)
    pcall(function()
        local permissionLevel = self:getPermissionLevel(player)
        
        if permissionLevel > 0 then
            pcall(function()
                LogRemote:FireClient(player, "admin_status", {
                    isAdmin = true,
                    level = permissionLevel,
                    commands = self:getAvailableCommands(player),
                    timestamp = tick()
                })
            end)
            
            self:logAction(player, "CLIENT_AUTH", "replicator", "Authentication granted")
            print("[ADMIN SYSTEM] Client replicator authentication granted for", player.Name, "Level:", permissionLevel)
        else
            pcall(function()
                LogRemote:FireClient(player, "admin_status", {
                    isAdmin = false,
                    level = 0,
                    commands = {},
                    timestamp = tick()
                })
            end)
            
            print("[ADMIN SYSTEM] Client replicator authentication denied for", player.Name)
        end
    end)
end

-- Enhanced client heartbeat handling
function AdminCore:handleClientHeartbeat(player, data)
    pcall(function()
        if not data or not data.authToken or not data.timestamp then
            return
        end
        
        -- Update session activity
        if self.playerSessions[player.UserId] then
            self.playerSessions[player.UserId].lastActivity = tick()
        end
        
        local permissionLevel = self:getPermissionLevel(player)
        
        if permissionLevel > 0 then
            self:logAction(player, "CLIENT_HEARTBEAT", "replicator", "Heartbeat received")
        else
            pcall(function()
                LogRemote:FireClient(player, "auth_revoked", {
                    reason = "Permissions changed",
                    timestamp = tick()
                })
            end)
            
            self:logAction(player, "CLIENT_AUTH_REVOKED", "replicator", "Permissions changed")
        end
    end)
end

-- Enhanced script execution with replication option
function AdminCore:executeScriptWithReplication(player, scriptCode, replicateToClient)
    local success, result = pcall(function()
        return self.secureExecutor:executeScript(player, scriptCode, replicateToClient)
    end)
    
    return success, result
end

-- Get execution statistics from secure executor
function AdminCore:getExecutionStats()
    local success, result = pcall(function()
        return self.secureExecutor:getExecutionStats()
    end)
    
    if success then
        return result
    else
        return {error = "Failed to get execution stats: " .. tostring(result)}
    end
end

-- Get execution history from secure executor
function AdminCore:getExecutionHistory(limit)
    local success, result = pcall(function()
        return self.secureExecutor:getExecutionHistory(limit)
    end)
    
    if success then
        return result
    else
        return {error = "Failed to get execution history: " .. tostring(result)}
    end
end

-- Helper methods for system information
function AdminCore:getAdminCount()
    local count = 0
    for _ in pairs(Config.Admins) do
        count = count + 1
    end
    return count
end

function AdminCore:getEnabledFeatures()
    local features = {}
    
    if Config.RateLimiting.Enabled then
        table.insert(features, "Rate Limiting")
    end
    
    if Config.Webhooks.Enabled then
        table.insert(features, "Webhook Integration")
    end
    
    if Config.Security.MonitorSuspiciousActivity then
        table.insert(features, "Security Monitoring")
    end
    
    if Config.Settings.EnableLogging then
        table.insert(features, "Action Logging")
    end
    
    if Config.Settings.EnableConsole then
        table.insert(features, "Console Access")
    end
    
    return table.concat(features, ", ")
end

-- Get comprehensive system statistics
function AdminCore:getSystemStatistics()
    return {
        rateLimiting = {
            activeTracking = self:countActivePlayers(self.rateLimitData),
            tempBannedUsers = self:countActivePlayers(self.tempBannedUsers),
            enabled = Config.RateLimiting.Enabled
        },
        webhooks = {
            queuedWebhooks = #self.webhookQueue,
            retryQueue = #self.retryQueue,
            enabled = Config.Webhooks.Enabled
        },
        security = {
            activeSessions = self:countActivePlayers(self.playerSessions),
            securityEvents = #self.securityEvents,
            monitoring = Config.Security.MonitorSuspiciousActivity
        },
        general = {
            totalLogs = #self.logs,
            adminCount = self:getAdminCount(),
            uptime = tick() - (self.startTime or tick())
        }
    }
end

function AdminCore:countActivePlayers(dataTable)
    local count = 0
    for _ in pairs(dataTable) do
        count = count + 1
    end
    return count
end

-- Initialize the admin system
local adminSystem = AdminCore.new()

-- Global access for commands
_G.AdminSystem = adminSystem

print("[ADMIN SYSTEM] Enhanced server-side admin system loaded successfully!")
print("[ADMIN SYSTEM] Features: Rate Limiting, Webhook Integration, Enhanced Security")
print("[ADMIN SYSTEM] Configured admins:", adminSystem:getAdminCount())
print("[ADMIN SYSTEM] Available commands:", #Config.CommandPermissions)
print("[ADMIN SYSTEM] Secure executor initialized with client replication support")