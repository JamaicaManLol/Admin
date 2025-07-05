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
    AnnouncementDuration = 5
}

-- Banned users (persists across server restarts if DataStore is configured)
Config.BannedUsers = {
    -- [userId] = {reason = "Reason", bannedBy = "Admin", timestamp = tick()}
}

return Config