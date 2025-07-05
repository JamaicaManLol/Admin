-- Admin System Core Server Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local StarterGui = game:GetService("StarterGui")

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
    
    -- Initialize secure executor
    self.secureExecutor = SecureExecutor.new(self)
    
    -- Load ban data
    self:loadBanData()
    
    -- Connect events
    self:connectEvents()
    
    -- Setup player events
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeaving(player)
    end)
    
    return self
end

-- Check if user is banned
function AdminCore:isBanned(userId)
    return Config.BannedUsers[userId] ~= nil
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

-- Log admin action
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

-- Handle player joining
function AdminCore:onPlayerJoined(player)
    -- Check if player is banned
    if self:isBanned(player.UserId) then
        local banInfo = Config.BannedUsers[player.UserId]
        player:Kick("You are banned from this game. Reason: " .. (banInfo.reason or "No reason provided"))
        return
    end
    
    -- Setup admin GUI for admins
    if self:getPermissionLevel(player) > 0 then
        player.CharacterAdded:Connect(function()
            wait(1) -- Wait for character to fully load
            self:setupAdminGUI(player)
        end)
        
        if player.Character then
            self:setupAdminGUI(player)
        end
    end
end

-- Handle player leaving
function AdminCore:onPlayerLeaving(player)
    -- Remove from god mode if active
    if self.godPlayers[player] then
        self.godPlayers[player] = nil
    end
end

-- Setup admin GUI
function AdminCore:setupAdminGUI(player)
    -- This will be called by the client script
    LogRemote:FireClient(player, "admin_status", {
        isAdmin = true,
        level = self:getPermissionLevel(player),
        commands = self:getAvailableCommands(player)
    })
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

-- Connect remote events
function AdminCore:connectEvents()
    -- Handle command execution
    ExecuteRemote.OnServerEvent:Connect(function(player, commandType, ...)
        if commandType == "chat_command" then
            self:handleChatCommand(player, ...)
        elseif commandType == "console_execute" then
            self:handleConsoleExecute(player, ...)
        end
    end)
    
    -- Handle console toggle
    ConsoleRemote.OnServerEvent:Connect(function(player, action)
        if action == "request_console" then
            if self:hasPermission(player, "console") then
                LogRemote:FireClient(player, "console_access", true)
            else
                LogRemote:FireClient(player, "console_access", false)
            end
        end
    end)
    
    -- Handle client replication authentication and heartbeat
    LogRemote.OnServerEvent:Connect(function(player, eventType, data)
        if eventType == "request_auth" then
            self:handleAuthenticationRequest(player, data)
        elseif eventType == "heartbeat" then
            self:handleClientHeartbeat(player, data)
        end
    end)
    
    -- Handle chat commands
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            if message:sub(1, 1) == Config.Settings.CommandPrefix then
                self:handleChatCommand(player, message:sub(2))
            end
        end)
    end)
end

-- Handle chat commands
function AdminCore:handleChatCommand(player, command)
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
    
    -- Execute command
    if Commands[cmd] then
        local success, result = pcall(Commands[cmd], self, player, unpack(args))
        
        if not success then
            self:sendMessage(player, "Command error: " .. tostring(result), "Error")
            self:logAction(player, "ERROR", cmd, tostring(result))
        elseif result then
            self:sendMessage(player, result, "Success")
        end
    else
        self:sendMessage(player, "Unknown command: " .. cmd, "Error")
    end
end

-- Handle console code execution
function AdminCore:handleConsoleExecute(player, code, replicateToClient)
    if not self:hasPermission(player, "execute") then
        self:sendMessage(player, "You don't have permission to execute code.", "Error")
        return
    end
    
    -- Use secure executor for advanced script execution
    local success, result = self.secureExecutor:executeScript(player, code, replicateToClient)
    
    if success then
        -- Send success result to client console
        LogRemote:FireClient(player, "console_output", "Execution successful: " .. tostring(result))
    else
        -- Send error result to client console
        LogRemote:FireClient(player, "console_output", "Execution failed: " .. tostring(result))
    end
end

-- Send message to player
function AdminCore:sendMessage(player, message, messageType)
    LogRemote:FireClient(player, "admin_message", {
        message = message,
        type = messageType or "Info",
        timestamp = tick()
    })
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

-- Handle authentication request from client replicator
function AdminCore:handleAuthenticationRequest(player, data)
    -- Validate player permissions
    local permissionLevel = self:getPermissionLevel(player)
    
    if permissionLevel > 0 then
        -- Send authentication success with admin status
        LogRemote:FireClient(player, "admin_status", {
            isAdmin = true,
            level = permissionLevel,
            commands = self:getAvailableCommands(player),
            timestamp = tick()
        })
        
        self:logAction(player, "CLIENT_AUTH", "replicator", "Authentication granted")
        print("[ADMIN SYSTEM] Client replicator authentication granted for", player.Name, "Level:", permissionLevel)
    else
        -- Send authentication failure
        LogRemote:FireClient(player, "admin_status", {
            isAdmin = false,
            level = 0,
            commands = {},
            timestamp = tick()
        })
        
        print("[ADMIN SYSTEM] Client replicator authentication denied for", player.Name)
    end
end

-- Handle client heartbeat
function AdminCore:handleClientHeartbeat(player, data)
    -- Validate heartbeat data
    if not data or not data.authToken or not data.timestamp then
        return
    end
    
    -- Validate player still has permissions
    local permissionLevel = self:getPermissionLevel(player)
    
    if permissionLevel > 0 then
        -- Log heartbeat
        self:logAction(player, "CLIENT_HEARTBEAT", "replicator", "Heartbeat received")
        
        -- Send heartbeat acknowledgment if needed
        -- Can add additional validation or session management here
    else
        -- Revoke authentication
        LogRemote:FireClient(player, "auth_revoked", {
            reason = "Permissions changed",
            timestamp = tick()
        })
        
        self:logAction(player, "CLIENT_AUTH_REVOKED", "replicator", "Permissions changed")
    end
end

-- Enhanced console execute with replication option
function AdminCore:executeScriptWithReplication(player, scriptCode, replicateToClient)
    return self.secureExecutor:executeScript(player, scriptCode, replicateToClient)
end

-- Get execution statistics from secure executor
function AdminCore:getExecutionStats()
    return self.secureExecutor:getExecutionStats()
end

-- Get execution history from secure executor
function AdminCore:getExecutionHistory(limit)
    return self.secureExecutor:getExecutionHistory(limit)
end

-- Initialize the admin system
local adminSystem = AdminCore.new()

-- Global access for commands
_G.AdminSystem = adminSystem

print("[ADMIN SYSTEM] Server-side admin system loaded successfully!")
print("[ADMIN SYSTEM] Configured admins:", #Config.Admins)
print("[ADMIN SYSTEM] Available commands:", #Config.CommandPermissions)
print("[ADMIN SYSTEM] Secure executor initialized with client replication support")