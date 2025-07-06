-- Admin System Configuration
local Config = {}

-- Admin User IDs and Permissions
Config.Admins = {
    -- Replace these with actual Roblox User IDs
    [123456789] = "Owner",      -- Full permissions
    [987654321] = "SuperAdmin", -- Most permissions
    [456789123] = "Admin",      -- Basic admin permissions
    [789123456] = "Moderator"   -- Limited permissions
}

-- Permission Levels (higher number = more permissions)
Config.PermissionLevels = {
    ["Guest"] = 0,
    ["Moderator"] = 1,
    ["Admin"] = 2,
    ["SuperAdmin"] = 3,
    ["Owner"] = 4
}

-- Command Permissions (minimum level required)
Config.CommandPermissions = {
    ["tp"] = 1,
    ["bring"] = 1,
    ["kick"] = 1,
    ["ban"] = 2,
    ["unban"] = 2,
    ["god"] = 2,
    ["ungod"] = 2,
    ["speed"] = 1,
    ["jump"] = 1,
    ["respawn"] = 1,
    ["announce"] = 2,
    ["console"] = 3,
    ["execute"] = 4,
    ["shutdown"] = 4
}

-- Rate Limiting Configuration
Config.RateLimiting = {
    -- Enable rate limiting
    Enabled = true,
    
    -- Commands rate limiting (commands per minute)
    CommandsPerMinute = 30,
    CommandBurstLimit = 10, -- Allow burst of commands
    
    -- Console execution rate limiting 
    ExecutionsPerMinute = 15,
    ExecutionBurstLimit = 5,
    
    -- Remote events rate limiting
    RemoteEventsPerMinute = 60,
    RemoteBurstLimit = 20,
    
    -- Escalation settings
    ViolationThreshold = 3, -- Number of violations before escalation
    TempBanDuration = 300, -- 5 minutes temp ban for rate limit abuse
    
    -- Cleanup interval (seconds)
    CleanupInterval = 60
}

-- Webhook Integration Configuration
Config.Webhooks = {
    -- Enable webhook notifications
    Enabled = true,
    
    -- Discord webhook URLs (replace with your actual webhook URLs)
    DiscordWebhooks = {
        AdminLogs = "YOUR_ADMIN_LOGS_WEBHOOK_URL_HERE",
        ModeratorAlerts = "YOUR_MODERATOR_ALERTS_WEBHOOK_URL_HERE",
        SecurityAlerts = "YOUR_SECURITY_ALERTS_WEBHOOK_URL_HERE"
    },
    
    -- Webhook notification settings
    NotifyOnBan = true,
    NotifyOnKick = true,
    NotifyOnCodeExecution = true,
    NotifyOnRateLimitViolation = true,
    NotifyOnSecurityEvent = true,
    
    -- Retry settings
    MaxRetries = 3,
    RetryDelay = 2, -- seconds
    
    -- Webhook rate limiting
    WebhookCooldown = 1 -- seconds between webhook calls
}

-- Security Enhancement Settings
Config.Security = {
    -- Enhanced logging
    EnableDetailedLogging = true,
    LogRetentionDays = 30,
    
    -- Session management
    SessionTimeout = 3600, -- 1 hour
    RequireReauthentication = true,
    
    -- IP tracking (if available)
    TrackPlayerIPs = false,
    
    -- Suspicious activity detection
    MonitorSuspiciousActivity = true,
    SuspiciousCommandThreshold = 50, -- Commands per hour
    
    -- Automatic security responses
    AutoBanOnExcessiveViolations = true,
    ViolationThresholdForBan = 10
}

-- Performance and Monitoring
Config.Performance = {
    -- Memory monitoring
    EnableMemoryMonitoring = true,
    MemoryWarningThreshold = 1024 * 1024 * 100, -- 100MB
    
    -- Execution time monitoring
    ExecutionTimeWarningThreshold = 3, -- seconds
    
    -- Automatic cleanup
    AutoCleanupInterval = 300, -- 5 minutes
    
    -- Cache settings
    CacheSize = 1000, -- Maximum cached items
    CacheExpiration = 1800 -- 30 minutes
}

-- General Settings
Config.Settings = {
    -- Prefix for commands in chat
    CommandPrefix = "/",
    
    -- Maximum ban duration in seconds (0 = permanent)
    MaxBanDuration = 86400 * 7, -- 7 days
    
    -- Log all admin actions
    EnableLogging = true,
    
    -- Allow console access
    EnableConsole = true,
    
    -- Auto-save ban list
    AutoSaveBans = true,
    
    -- Announcement settings
    AnnouncementColor = Color3.fromRGB(255, 255, 0),
    AnnouncementDuration = 5,
    
    -- Error handling
    EnableEnhancedErrorHandling = true,
    LogErrors = true,
    
    -- Testing mode
    TestingMode = false -- Set to true for development/testing
}

-- Banned users (persists across server restarts if DataStore is configured)
Config.BannedUsers = {
    -- [userId] = {reason = "Reason", bannedBy = "Admin", timestamp = tick()}
}

return Config