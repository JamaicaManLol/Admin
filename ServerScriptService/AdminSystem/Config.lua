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

-- Role Descriptions for UI Display (God-Tier Enhancement)
Config.RoleDescriptions = {
    ["Guest"] = "Regular player with no administrative privileges",
    ["Moderator"] = "Can moderate chat, kick players, and basic moderation tasks",
    ["Admin"] = "Can ban players, use advanced commands, and manage server settings",
    ["SuperAdmin"] = "Can execute code, manage other admins, and access sensitive features",
    ["Owner"] = "Full system access with all administrative capabilities"
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
    ["shutdown"] = 4,
    ["ipban"] = 3,
    ["reload"] = 4,
    ["analytics"] = 3
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
        SecurityAlerts = "YOUR_SECURITY_ALERTS_WEBHOOK_URL_HERE",
        Analytics = "YOUR_ANALYTICS_WEBHOOK_URL_HERE" -- God-Tier: Analytics reporting
    },
    
    -- Webhook notification settings
    NotifyOnBan = true,
    NotifyOnKick = true,
    NotifyOnCodeExecution = true,
    NotifyOnRateLimitViolation = true,
    NotifyOnSecurityEvent = true,
    NotifyOnConfigReload = true,        -- God-Tier: Config reload notifications
    NotifyOnAnalyticsReport = true,     -- God-Tier: Analytics reports
    
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
    
    -- IP tracking and banning (God-Tier Enhancement)
    TrackPlayerIPs = true,              -- Enable IP tracking
    EnableIPBans = true,                -- Allow IP-based bans
    IPBanDuration = 86400 * 7,          -- 7 days default IP ban
    MaxIPsPerPlayer = 3,                -- Max IPs to track per player
    
    -- Suspicious activity detection
    MonitorSuspiciousActivity = true,
    SuspiciousCommandThreshold = 50, -- Commands per hour
    
    -- Automatic security responses
    AutoBanOnExcessiveViolations = true,
    ViolationThresholdForBan = 10,
    
    -- Advanced security features
    DetectVPNUsage = false,             -- Experimental: VPN detection
    RequireAccountAge = 30,             -- Minimum account age in days
    MaxSimultaneousConnections = 5      -- Max connections per IP
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

-- Analytics and Tracking (God-Tier Enhancement)
Config.Analytics = {
    -- Enable analytics tracking
    Enabled = true,
    
    -- What to track
    TrackCommandUsage = true,           -- Track command usage patterns
    TrackErrors = true,                 -- Track error occurrences
    TrackLoginPatterns = true,          -- Track player login patterns
    TrackSecurityEvents = true,         -- Track security violations
    TrackPerformance = true,            -- Track system performance
    TrackWebhookDelivery = true,        -- Track webhook success rates
    
    -- Reporting settings
    ReportInterval = 3600,              -- Generate reports every hour
    DailyReports = true,                -- Generate daily summary reports
    WeeklyReports = true,               -- Generate weekly trend reports
    
    -- Data retention
    RetainDataDays = 90,                -- Keep analytics data for 90 days
    ExportToWebhook = true,             -- Send analytics via webhook
    
    -- Performance thresholds for alerts
    ErrorRateThreshold = 0.05,          -- Alert if error rate > 5%
    ResponseTimeThreshold = 1.0,        -- Alert if avg response time > 1s
    MemoryUsageThreshold = 0.8          -- Alert if memory usage > 80%
}

-- Dynamic Configuration (God-Tier Enhancement)
Config.DynamicConfig = {
    -- Enable dynamic reloading
    EnableReloading = true,
    
    -- What can be reloaded without restart
    ReloadableSettings = {
        "RateLimiting",
        "Webhooks", 
        "Security",
        "Performance",
        "Analytics"
    },
    
    -- Backup configurations
    CreateBackups = true,
    MaxBackups = 10,
    BackupInterval = 3600,              -- Backup every hour
    
    -- Validation settings
    ValidateOnReload = true,            -- Validate config before applying
    RollbackOnError = true,             -- Rollback to previous config on error
    
    -- Notifications
    NotifyAdminsOnReload = true,        -- Notify all admins of config changes
    LogConfigChanges = true             -- Log all configuration changes
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
    TestingMode = false, -- Set to true for development/testing
    
    -- System information
    Version = "Enhanced v3.0 - God-Tier",
    BuildNumber = 1001,
    LastUpdated = "2024-12-19"
}

-- Banned users (persists across server restarts if DataStore is configured)
-- Enhanced with IP ban support (God-Tier Enhancement)
Config.BannedUsers = {
    -- Enhanced ban structure:
    -- [userId] = {
    --     reason = "Reason", 
    --     bannedBy = "Admin", 
    --     timestamp = tick(),
    --     ip = "X.X.X.X",           -- Optional: IP address for IP bans
    --     ipBan = true,             -- Optional: True if this is an IP ban
    --     expires = tick() + 86400  -- Optional: Expiration time for temporary bans
    -- }
}

-- IP Ban Management (God-Tier Enhancement)
Config.IPBans = {
    -- Separate IP ban storage for better management
    -- ["X.X.X.X"] = {
    --     reason = "Reason",
    --     bannedBy = "Admin",
    --     timestamp = tick(),
    --     expires = tick() + 604800,  -- 7 days
    --     affectedUsers = {userId1, userId2} -- Users who used this IP
    -- }
}

-- Player IP Tracking (God-Tier Enhancement)
Config.PlayerIPs = {
    -- Track IPs for security analysis
    -- [userId] = {
    --     ips = {"X.X.X.X", "Y.Y.Y.Y"},
    --     lastSeen = tick(),
    --     accountAge = 365,
    --     riskScore = 0.2
    -- }
}

-- Configuration Validation Schema (God-Tier Enhancement)
Config.ValidationSchema = {
    RateLimiting = {
        required = {"Enabled", "CommandsPerMinute", "ViolationThreshold"},
        types = {
            Enabled = "boolean",
            CommandsPerMinute = "number",
            ViolationThreshold = "number"
        },
        ranges = {
            CommandsPerMinute = {min = 1, max = 1000},
            ViolationThreshold = {min = 1, max = 100}
        }
    },
    Security = {
        required = {"EnableDetailedLogging", "SessionTimeout"},
        types = {
            EnableDetailedLogging = "boolean",
            SessionTimeout = "number",
            TrackPlayerIPs = "boolean"
        },
        ranges = {
            SessionTimeout = {min = 60, max = 86400}
        }
    }
}

-- Export configuration with metadata
Config._metadata = {
    version = Config.Settings.Version,
    buildNumber = Config.Settings.BuildNumber,
    lastUpdated = Config.Settings.LastUpdated,
    features = {
        "Advanced Rate Limiting",
        "Discord Webhook Integration", 
        "Enhanced Security Monitoring",
        "Automated Testing Suite",
        "IP Ban Management",
        "Dynamic Configuration",
        "Analytics & Reporting",
        "Role-based Permissions"
    }
}

return Config