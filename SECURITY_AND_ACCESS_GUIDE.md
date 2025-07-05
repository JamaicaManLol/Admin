# Security and Access Guide

## 🔒 Admin Level Access Matrix

| Feature | Moderator (1) | Admin (2) | SuperAdmin (3) | Owner (4) |
|---------|---------------|-----------|----------------|-----------|
| **Basic Commands** | ✅ | ✅ | ✅ | ✅ |
| **Console Access** | ❌ | ✅ | ✅ | ✅ |
| **Script Execution** | ❌ | ✅ | ✅ | ✅ |
| **Client Replication** | ❌ | ✅ | ✅ | ✅ |
| **require() Function** | ❌ | ✅ (Safe) | ✅ (Sensitive) | ✅ (Full) |
| **System Statistics** | ❌ | ❌ | ✅ | ✅ |
| **Execution History** | ❌ | ❌ | ✅ | ✅ |
| **Server Shutdown** | ❌ | ❌ | ❌ | ✅ |

## 🛡️ Security Features by Component

### Server-Side Executor

#### ✅ Security Features
- **Sandboxed Execution**: Isolated environments for each script
- **Rate Limiting**: 10 executions per 60 seconds per user
- **Timeout Protection**: 5-second maximum execution time
- **Memory Limits**: Configurable memory usage restrictions
- **Service Restrictions**: Only safe Roblox services accessible
- **require() Validation**: Path-based security checks for ModuleScripts

#### ❌ Blocked Operations
```lua
-- These operations are blocked for security:
game:GetService("DataStoreService")        -- Data access blocked
game:GetService("HttpService")             -- HTTP access restricted  
require(game.ServerScriptService.AdminSystem) -- Admin system protected
require(game.ServerStorage.*)              -- Server storage blocked
```

#### ✅ Allowed Operations
```lua
-- These operations are permitted:
game:GetService("Players")                 -- Player management
game:GetService("Workspace")               -- Workspace access
game:GetService("Lighting")                -- Lighting control
require(game.ReplicatedStorage.MyModule)   -- Safe module loading
```

### Client-Side Replicator

#### 🔐 Authentication Requirements
- **Minimum Level**: Admin (Level 2)
- **Token-Based**: Secure session tokens
- **Heartbeat System**: 30-second validation intervals
- **Auto-Revocation**: Lost permissions = immediate disconnect

#### 📡 Replication Security
- **Encrypted Data**: XOR encryption with player-specific keys
- **Size Limits**: 512KB maximum replication size
- **Checksum Validation**: Data integrity verification
- **Concurrent Limits**: Maximum 5 simultaneous executions

## 🎮 Console Interface Security

### Execution Modes

#### Server-Only (`Ctrl + Enter`)
- **Available To**: All admin levels (1+)
- **Execution**: Server-side only
- **Logging**: Full server-side logging
- **Security**: Standard sandbox restrictions

#### Server + Client (`Ctrl + Shift + Enter`)
- **Available To**: Admin level 2+ only
- **Execution**: Server first, then replicated to client
- **Logging**: Both server and client execution logged
- **Security**: Enhanced validation + encryption

### Console Security Features

```lua
-- Automatic security validation
if not _G.ClientReplicator then
    -- Replication not available for this user
    print("Client replication requires Admin Level 2+")
end

-- Permission checking
local canExecute = admin:hasPermission(player, "execute")
local canReplicate = admin:getPermissionLevel(player) >= 2
```

## 📋 Module Access Security

### require() Function Security

#### ✅ Allowed Paths
```lua
-- Safe module locations
require(game.ReplicatedStorage.UserModules.*)
require(game.Workspace.PublicModules.*)
require(game.StarterPack.ToolModules.*)
```

#### ❌ Restricted Paths
```lua
-- Protected locations (blocked for all)
require(game.ServerScriptService.AdminSystem.*)  -- Admin system
require(game.ServerStorage.*)                     -- Server storage
require(game.HttpService)                         -- HTTP service
```

#### 🔒 Sensitive Paths (SuperAdmin+ Only)
```lua
-- Requires permission level 3+
require(game.ReplicatedStorage.AdminModules.*)
require(game.ServerScriptService.GameSystems.*)
require(game.Workspace.SecurityModules.*)
```

### Module Security Validation

```lua
-- Example of secure module loading
local function secureRequire(modulePath)
    -- 1. Validate module is actually a ModuleScript
    -- 2. Check if path is in restricted locations
    -- 3. Verify admin permissions for sensitive modules
    -- 4. Log the require attempt
    -- 5. Execute with error handling
end
```

## 🚨 Security Monitoring

### Automatic Logging

#### Server-Side Events
```
[SECURE EXECUTOR] PlayerName ATTEMPT Script execution started
[SECURE EXECUTOR] PlayerName SUCCESS Execution completed in 0.5s
[SECURE EXECUTOR] PlayerName MODULE_REQUIRE TestModule loaded
[SECURE EXECUTOR] PlayerName REPLICATED Script sent to client
[SECURE EXECUTOR] PlayerName ERROR Restricted module access denied
```

#### Client-Side Events
```
[CLIENT REPLICATOR] Authentication successful - Level: 3
[CLIENT REPLICATOR] Script replication received: exec-id-123
[CLIENT EXEC] Client-side script output
[CLIENT REPLICATOR] Replication rejected - Not authenticated
```

### Security Alerts

#### Rate Limiting Triggered
```
[SECURITY] Player exceeded execution rate limit (10/minute)
[SECURITY] Rate limit enforced for UserID: 123456789
```

#### Unauthorized Access Attempts
```
[SECURITY] Non-admin attempted console access
[SECURITY] Invalid replication request from Level 1 admin
[SECURITY] Restricted module access denied: ServerStorage
```

## ⚠️ Best Practices

### For Game Developers

1. **Regular Permission Audits**
   ```lua
   -- Check who has admin access
   for userId, role in pairs(Config.Admins) do
       print("Admin:", userId, "Role:", role)
   end
   ```

2. **Monitor Execution Logs**
   ```lua
   -- Review recent admin activity
   local history = admin:getExecutionHistory(50)
   for _, entry in ipairs(history) do
       if entry.action == "ERROR" then
           warn("Failed execution:", entry.details)
       end
   end
   ```

3. **Test Security Boundaries**
   ```lua
   -- Verify security restrictions work
   local success, error = pcall(function()
       return require(game.ServerScriptService.AdminSystem.Config)
   end)
   assert(not success, "Security breach: Admin config accessible!")
   ```

### For Server Administrators

1. **Principle of Least Privilege**
   - Start users at Moderator level (1)
   - Promote only when necessary
   - Regularly review and demote inactive admins

2. **Monitor High-Risk Activities**
   - Client replication usage
   - Sensitive module access
   - Statistical data access
   - System shutdown attempts

3. **Regular Security Checks**
   - Review execution statistics weekly
   - Check for unusual rate limiting triggers
   - Monitor failed authentication attempts

## 🔍 Troubleshooting Security Issues

### Common Access Denied Scenarios

#### "Insufficient permissions for client replication"
```
Cause: User is Moderator level (1)
Solution: Promote to Admin level (2+) if appropriate
```

#### "Access denied: Cannot require modules from restricted locations"
```
Cause: Attempting to load protected module
Solution: Use modules from safe locations or get SuperAdmin access
```

#### "Rate limit exceeded"
```
Cause: Too many executions in short time
Solution: Wait 60 seconds or adjust rate limits in config
```

#### "Console access denied"
```
Cause: User doesn't have console permission
Solution: Verify admin level is 2+ and has "console" permission
```

### Debug Commands

```lua
-- Check your permissions
print("Admin Level:", admin:getPermissionLevel(executor_player))
print("Has Console:", admin:hasPermission(executor_player, "console"))
print("Available Commands:", #admin:getAvailableCommands(executor_player))

-- Check replicator status
if _G.ClientReplicator then
    local stats = _G.ClientReplicator:getReplicationStats()
    print("Replicator authenticated:", stats.isAuthenticated)
    print("Admin level:", stats.adminLevel)
else
    print("Client replicator not available")
end

-- Test require access
local testPaths = {
    game.ReplicatedStorage,      -- Should work
    game.ServerStorage,          -- Should fail
    game.ServerScriptService     -- Should fail
}

for _, path in ipairs(testPaths) do
    local success = pcall(function() return require(path) end)
    print(path.Name .. " access:", success and "ALLOWED" or "DENIED")
end
```

## 📊 Security Metrics

### Key Performance Indicators

- **Authentication Success Rate**: >95%
- **Failed Access Attempts**: <5% of total
- **Rate Limit Triggers**: <1% of users
- **Security Violations**: 0 successful breaches

### Monitoring Dashboard

```lua
-- Get comprehensive security overview
local stats = admin:getExecutionStats()
print("=== Security Overview ===")
print("Total Executions:", stats.totalExecutions)
print("Success Rate:", math.floor(stats.successRate) .. "%")
print("Active Sessions:", stats.activeExecutions)

-- Check client replicator stats
local repStats = _G.ClientReplicator and _G.ClientReplicator:getReplicationStats()
if repStats then
    print("Client Success Rate:", math.floor(repStats.successRate) .. "%")
    print("Data Transferred:", repStats.bytesReceived .. " bytes")
end
```

---

**Remember**: This security system is designed for legitimate game development and administration. Always use responsibly and maintain proper authorization for all admin activities.