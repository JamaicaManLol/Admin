-- Secure Executor - Professional-Grade Script Execution System
-- Implements advanced security, performance, and monitoring features

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SecureExecutor = {}
SecureExecutor.__index = SecureExecutor

-- Enhanced security constants
local MAX_EXECUTION_TIME = 5 -- seconds per script
local MAX_MEMORY_USAGE = 1024 * 1024 -- 1MB
local RATE_LIMIT_WINDOW = 60 -- seconds
local MAX_EXECUTIONS_PER_WINDOW = 10
local MEMORY_CHECK_INTERVAL = 0.1 -- seconds
local ENCRYPTION_KEY_ROTATION_INTERVAL = 300 -- 5 minutes

-- Granular permission flags (Suggestion #7)
local PERMISSION_FLAGS = {
    canExecuteScripts = 1,
    canRequireModules = 2,
    canReplicate = 2,
    canConsoleAccess = 1,
    canMemoryMonitoring = 2,
    canAdvancedStats = 3,
    canSensitiveModules = 3,
    canSystemAccess = 4
}

-- Global execution tracking
local activeExecutions = {}
local encryptionKeys = {}

-- Suggestion #3: Readonly table protection
local function createReadonlyTable(tbl, name)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function()
            error("Attempt to modify read-only table: " .. (name or "unknown"))
        end,
        __metatable = false
    })
end

-- Suggestion #2: Memory monitoring with heuristics
local function getMemorySnapshot()
    collectgarbage("collect")
    return collectgarbage("count") * 1024
end

local function estimateTableMemory(tbl, visited, depth)
    visited = visited or {}
    depth = depth or 0
    
    if depth > 10 or visited[tbl] then
        return 0
    end
    
    visited[tbl] = true
    local size = 100 -- Base table overhead
    
    for k, v in pairs(tbl) do
        size = size + 50 -- Key-value pair overhead
        
        if type(k) == "string" then
            size = size + #k
        end
        
        if type(v) == "string" then
            size = size + #v
        elseif type(v) == "table" then
            size = size + estimateTableMemory(v, visited, depth + 1)
        end
    end
    
    return size
end

function SecureExecutor.new(adminSystem)
    local self = setmetatable({}, SecureExecutor)
    
    self.adminSystem = adminSystem
    self.secureEnvironments = {}
    self.executionQueue = {}
    self.replicationTargets = {}
    self.rateLimiter = {}
    self.requireCache = {} -- Suggestion #4: Module caching
    
    -- Suggestion #6: Per-player execution stats
    self.playerStats = {}
    
    -- Suggestion #9: Enhanced encryption with key rotation
    self.encryptionKeys = {}
    self.lastKeyRotation = 0
    
    -- Setup cleanup and monitoring tasks
    self:setupCleanupTasks()
    
    return self
end

-- Suggestion #7: Granular permission checking
function SecureExecutor:checkSpecificPermission(player, permissionFlag)
    local playerLevel = self.adminSystem:getPermissionLevel(player)
    local requiredLevel = PERMISSION_FLAGS[permissionFlag]
    
    if not requiredLevel then
        error("Unknown permission flag: " .. tostring(permissionFlag))
    end
    
    return playerLevel >= requiredLevel
end

-- Suggestion #5: Pcall-protected environment functions
local function createSafeFunction(func, context)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            warn("Safe function error in " .. context .. ": " .. tostring(result))
            return nil
        end
        return result
    end
end

-- Suggestion #3: Enhanced sandbox with readonly protection
function SecureExecutor:createSecureEnvironment(player, executionId)
    local startMemory = getMemorySnapshot()
    local instructionCount = 0
    local memoryAllocated = 0
    
    -- Suggestion #10: Async yielding support with RunService integration
    local function safeWait(duration)
        duration = math.max(duration or 0, 0.001)
        local startTime = tick()
        
        while tick() - startTime < duration do
            RunService.Heartbeat:Wait()
            
            -- Check if execution should be cancelled
            if activeExecutions[executionId] and activeExecutions[executionId].cancelled then
                error("Execution cancelled during wait")
            end
        end
    end
    
    -- Suggestion #5: Protected logging functions
    local function safePrint(...)
        local success, result = pcall(function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            -- Memory check for large outputs
            if #message > 10000 then
                message = message:sub(1, 10000) .. "... [TRUNCATED]"
            end
            
            self:logExecution(player, executionId, "OUTPUT", message)
            self:sendExecutionResult(player, executionId, "output", message)
        end, ...)
        
        if not success then
            warn("Print function error: " .. tostring(result))
        end
    end
    
    local function safeWarn(...)
        local success, result = pcall(function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            self:logExecution(player, executionId, "WARNING", message)
            self:sendExecutionResult(player, executionId, "warning", message)
        end, ...)
        
        if not success then
            warn("Warn function error: " .. tostring(result))
        end
    end
    
    -- Suggestion #4: Cached require function
    local function cachedRequire(moduleScript)
        local success, result = pcall(function()
            -- Check cache first
            local cacheKey = tostring(moduleScript)
            if self.requireCache[executionId] and self.requireCache[executionId][cacheKey] then
                return self.requireCache[executionId][cacheKey]
            end
            
            -- Perform require
            local moduleResult = self:secureRequire(player, moduleScript, executionId)
            
            -- Cache result
            if not self.requireCache[executionId] then
                self.requireCache[executionId] = {}
            end
            self.requireCache[executionId][cacheKey] = moduleResult
            
            return moduleResult
        end)
        
        if success then
            return result
        else
            error("Require failed: " .. tostring(result))
        end
    end
    
    -- Suggestion #2: Memory-monitored spawn function
    local function memoryMonitoredSpawn(func)
        return coroutine.wrap(function()
            local memBefore = getMemorySnapshot()
            
            local success, result = pcall(func)
            
            local memAfter = getMemorySnapshot()
            local memDelta = memAfter - memBefore
            
            if memDelta > MAX_MEMORY_USAGE / 10 then -- 10% of limit per spawn
                warn("High memory usage in spawned function: " .. math.floor(memDelta / 1024) .. "KB")
            end
            
            if not success then
                error("Spawned function error: " .. tostring(result))
            end
            
            return result
        end)()
    end
    
    local environment = {
        -- Core Lua functions
        _G = {},
        _VERSION = _VERSION,
        assert = assert,
        error = error,
        ipairs = ipairs,
        next = next,
        pairs = pairs,
        pcall = pcall,
        select = select,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        unpack = unpack,
        xpcall = xpcall,
        
        -- Suggestion #3: Readonly protected libraries
        math = createReadonlyTable(math, "math"),
        string = createReadonlyTable(string, "string"),
        table = createReadonlyTable(table, "table"),
        
        -- Controlled game access
        game = self:createGameProxy(player),
        workspace = self:createWorkspaceProxy(player),
        
        -- Suggestion #10: Enhanced utility functions with RunService integration
        wait = safeWait,
        spawn = memoryMonitoredSpawn,
        delay = function(duration, func)
            memoryMonitoredSpawn(function()
                safeWait(duration)
                func()
            end)
        end,
        
        -- Admin system access
        admin = self.adminSystem,
        executor = self,
        
        -- Execution context
        executionId = executionId,
        executor_player = player,
        executor_timestamp = tick(),
        executor_memory_start = startMemory,
        
        -- Suggestion #4: Cached require function
        require = cachedRequire,
        
        -- Suggestion #5: Protected logging functions
        print = safePrint,
        warn = safeWarn,
        
        -- Memory monitoring utilities
        getMemoryUsage = function()
            return getMemorySnapshot() - startMemory
        end,
        
        getMemoryLimit = function()
            return MAX_MEMORY_USAGE
        end,
        
        -- Execution monitoring
        getExecutionTime = function()
            return tick() - (activeExecutions[executionId] and activeExecutions[executionId].startTime or tick())
        end
    }
    
    -- Store environment with enhanced tracking
    self.secureEnvironments[executionId] = {
        environment = environment,
        startMemory = startMemory,
        player = player,
        createdAt = tick()
    }
    
    return environment
end

-- Suggestion #1: Coroutine-based timeout with deterministic scheduling
function SecureExecutor:executeWithTimeout(player, executionId, func, scriptCode)
    local success, result
    local startTime = tick()
    
    -- Create execution context
    activeExecutions[executionId] = {
        player = player,
        startTime = startTime,
        scriptCode = scriptCode,
        cancelled = false,
        memoryUsage = 0
    }
    
    -- Suggestion #2: Memory monitoring during execution
    local initialMemory = getMemorySnapshot()
    
    -- Create coroutine for execution
    local co = coroutine.create(func)
    
    -- Deterministic timeout loop
    while coroutine.status(co) ~= "dead" do
        -- Check timeout
        if tick() - startTime > MAX_EXECUTION_TIME then
            success = false
            result = "Script execution timed out after " .. MAX_EXECUTION_TIME .. " seconds"
            activeExecutions[executionId].cancelled = true
            self:logExecution(player, executionId, "TIMEOUT", result)
            break
        end
        
        -- Check memory usage
        local currentMemory = getMemorySnapshot()
        local memoryDelta = currentMemory - initialMemory
        activeExecutions[executionId].memoryUsage = memoryDelta
        
        if memoryDelta > MAX_MEMORY_USAGE then
            success = false
            result = "Memory limit exceeded: " .. math.floor(memoryDelta / 1024) .. "KB used"
            activeExecutions[executionId].cancelled = true
            self:logExecution(player, executionId, "MEMORY_LIMIT", result)
            break
        end
        
        -- Resume coroutine
        local ok, err = coroutine.resume(co)
        if not ok then
            success = false
            result = err
            break
        end
        
        -- If coroutine yielded, check if it returned a value
        if coroutine.status(co) == "dead" then
            success = true
            result = err -- This would be the return value
            break
        end
        
        -- Yield to Roblox scheduler
        RunService.Heartbeat:Wait()
    end
    
    -- Cleanup
    if activeExecutions[executionId] then
        activeExecutions[executionId] = nil
    end
    
    -- Handle final result
    if success == nil then
        success = true
    end
    
    -- Suggestion #8: Enhanced error reporting with stack traces
    if not success then
        local errorInfo = {
            error = tostring(result),
            executionTime = tick() - startTime,
            memoryUsage = activeExecutions[executionId] and activeExecutions[executionId].memoryUsage or 0,
            stackTrace = debug.traceback() or "Stack trace unavailable"
        }
        
        self:logExecution(player, executionId, "ERROR", HttpService:JSONEncode(errorInfo))
        return false, result
    else
        self:logExecution(player, executionId, "SUCCESS", tostring(result))
        return true, result
    end
end

-- Suggestion #4: Enhanced require with caching
function SecureExecutor:secureRequire(player, moduleScript, executionId)
    if not self:checkSpecificPermission(player, "canRequireModules") then
        error("Insufficient permissions for module requiring")
    end
    
    -- Validate ModuleScript
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        error("require() can only be used with ModuleScript objects")
    end
    
    local modulePath = self:getModulePath(moduleScript)
    
    -- Security checks
    if self:isRestrictedModule(modulePath) then
        error("Access denied: Cannot require modules from restricted locations")
    end
    
    if self:isSensitiveModule(modulePath) then
        if not self:checkSpecificPermission(player, "canSensitiveModules") then
            error("Insufficient permissions: SuperAdmin level required for sensitive modules")
        end
    end
    
    -- Log attempt
    self:logExecution(player, executionId, "MODULE_REQUIRE", "ATTEMPT: " .. modulePath)
    
    -- Execute module with enhanced error handling
    local success, result = pcall(function()
        local moduleCode = moduleScript.Source
        local environment = self.secureEnvironments[executionId] and self.secureEnvironments[executionId].environment
        
        if not environment then
            error("Invalid execution environment")
        end
        
        -- Create module-specific sandbox
        local moduleSandbox = self:createModuleSandbox(environment, modulePath)
        
        -- Compile and execute
        local compiledModule, compileError = load(moduleCode, "@" .. modulePath, "t", moduleSandbox)
        
        if not compiledModule then
            error("Module compilation failed: " .. tostring(compileError))
        end
        
        return compiledModule()
    end)
    
    if success then
        self:logExecution(player, executionId, "MODULE_REQUIRE", "SUCCESS: " .. modulePath)
        return result
    else
        -- Suggestion #8: Enhanced error reporting
        local errorInfo = {
            module = modulePath,
            error = tostring(result),
            stackTrace = debug.traceback() or "Stack trace unavailable"
        }
        
        self:logExecution(player, executionId, "MODULE_REQUIRE", "ERROR: " .. HttpService:JSONEncode(errorInfo))
        error("Module require failed: " .. tostring(result))
    end
end

-- Suggestion #9: Enhanced encryption with key rotation and nonce
function SecureExecutor:generateEncryptionKey(player)
    local currentTime = tick()
    
    -- Rotate keys every 5 minutes
    if currentTime - self.lastKeyRotation > ENCRYPTION_KEY_ROTATION_INTERVAL then
        self.encryptionKeys = {}
        self.lastKeyRotation = currentTime
    end
    
    local playerKey = self.encryptionKeys[player.UserId]
    if not playerKey then
        playerKey = {
            primary = tostring(player.UserId) .. "_" .. tostring(currentTime) .. "_" .. tostring(math.random(1000000, 9999999)),
            secondary = string.reverse(tostring(player.UserId)) .. "_salt_" .. tostring(math.random(100000, 999999)),
            nonce = 0
        }
        self.encryptionKeys[player.UserId] = playerKey
    end
    
    -- Increment nonce for replay protection
    playerKey.nonce = playerKey.nonce + 1
    
    return playerKey
end

function SecureExecutor:encryptReplicationData(data, player)
    local serialized = HttpService:JSONEncode(data)
    local keys = self:generateEncryptionKey(player)
    
    -- Triple-pass encryption with nonce
    local encrypted = serialized
    local allKeys = {keys.primary, keys.secondary, tostring(keys.nonce)}
    
    for pass = 1, 3 do
        local key = allKeys[pass]
        local passResult = {}
        
        for i = 1, #encrypted do
            local char = encrypted:sub(i, i)
            local keyChar = key:sub(((i - 1) % #key) + 1, ((i - 1) % #key) + 1)
            local encryptedChar = string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
            table.insert(passResult, encryptedChar)
        end
        
        encrypted = table.concat(passResult)
    end
    
    return {
        data = encrypted,
        nonce = keys.nonce,
        checksum = self:generateChecksum(serialized, keys.nonce),
        timestamp = tick(),
        keyVersion = self.lastKeyRotation
    }
end

-- Enhanced checksum with nonce integration
function SecureExecutor:generateChecksum(data, nonce)
    local hash1 = nonce or 0
    local hash2 = nonce or 0
    
    for i = 1, #data do
        local byte = string.byte(data:sub(i, i))
        hash1 = (hash1 + byte * i + nonce) % 1000000007
        hash2 = (hash2 + byte * (i * i) + nonce) % 999999937
    end
    
    return tostring(hash1) .. "_" .. tostring(hash2) .. "_" .. tostring(nonce)
end

-- Suggestion #6: Per-player execution statistics
function SecureExecutor:updatePlayerStats(player, executionResult)
    local userId = player.UserId
    
    if not self.playerStats[userId] then
        self.playerStats[userId] = {
            totalExecutions = 0,
            successfulExecutions = 0,
            failedExecutions = 0,
            totalExecutionTime = 0,
            totalMemoryUsed = 0,
            averageExecutionTime = 0,
            averageMemoryUsage = 0,
            lastExecution = 0,
            replicationCount = 0,
            moduleRequireCount = 0,
            timeoutCount = 0,
            memoryLimitCount = 0
        }
    end
    
    local stats = self.playerStats[userId]
    stats.totalExecutions = stats.totalExecutions + 1
    stats.lastExecution = tick()
    
    if executionResult.success then
        stats.successfulExecutions = stats.successfulExecutions + 1
    else
        stats.failedExecutions = stats.failedExecutions + 1
        
        if executionResult.error and executionResult.error:find("timeout") then
            stats.timeoutCount = stats.timeoutCount + 1
        elseif executionResult.error and executionResult.error:find("Memory limit") then
            stats.memoryLimitCount = stats.memoryLimitCount + 1
        end
    end
    
    stats.totalExecutionTime = stats.totalExecutionTime + (executionResult.executionTime or 0)
    stats.totalMemoryUsed = stats.totalMemoryUsed + (executionResult.memoryUsage or 0)
    
    -- Update averages
    stats.averageExecutionTime = stats.totalExecutionTime / stats.totalExecutions
    stats.averageMemoryUsage = stats.totalMemoryUsed / stats.totalExecutions
end

function SecureExecutor:getPlayerStats(player)
    if not self:checkSpecificPermission(player, "canAdvancedStats") then
        return nil, "Insufficient permissions for advanced statistics"
    end
    
    local userId = player.UserId
    return self.playerStats[userId] or {
        totalExecutions = 0,
        successfulExecutions = 0,
        failedExecutions = 0,
        averageExecutionTime = 0,
        averageMemoryUsage = 0,
        lastExecution = 0
    }
end

-- Enhanced cleanup with per-player cache management
function SecureExecutor:setupCleanupTasks()
    spawn(function()
        while true do
            wait(300) -- 5 minutes
            self:performAdvancedCleanup()
        end
    end)
    
    -- Memory monitoring task
    spawn(function()
        while true do
            wait(60) -- 1 minute
            self:performMemoryCleanup()
        end
    end)
    
    -- Cache cleanup task
    spawn(function()
        while true do
            wait(600) -- 10 minutes
            self:performCacheCleanup()
        end
    end)
end

-- Suggestion #4: Cache cleanup
function SecureExecutor:performCacheCleanup()
    local currentTime = tick()
    
    -- Clean up old execution caches
    for executionId, cacheData in pairs(self.requireCache) do
        if currentTime - (self.secureEnvironments[executionId] and self.secureEnvironments[executionId].createdAt or 0) > 3600 then -- 1 hour
            self.requireCache[executionId] = nil
        end
    end
    
    -- Clean up old encryption keys
    for userId, keyData in pairs(self.encryptionKeys) do
        if currentTime - self.lastKeyRotation > ENCRYPTION_KEY_ROTATION_INTERVAL * 2 then
            self.encryptionKeys[userId] = nil
        end
    end
    
    print("[PERFECTED EXECUTOR] Cache cleanup completed")
end

-- Main execution function with all improvements
function SecureExecutor:executeSecureScript(player, scriptCode, executionId)
    -- Granular permission check
    if not self:checkSpecificPermission(player, "canExecuteScripts") then
        return false, "Insufficient permissions for script execution"
    end
    
    -- Rate limiting
    if not self:checkRateLimit(player) then
        return false, "Rate limit exceeded"
    end
    
    -- Create secure environment
    local environment = self:createSecureEnvironment(player, executionId)
    
    -- Compile script
    local compiledScript, compileError = load(scriptCode, "@UserScript", "t", environment)
    if not compiledScript then
        return false, "Script compilation failed: " .. tostring(compileError)
    end
    
    -- Execute with enhanced timeout
    local startTime = tick()
    local success, result = self:executeWithTimeout(player, executionId, compiledScript, scriptCode)
    local executionTime = tick() - startTime
    
    -- Update player statistics
    self:updatePlayerStats(player, {
        success = success,
        executionTime = executionTime,
        memoryUsage = activeExecutions[executionId] and activeExecutions[executionId].memoryUsage or 0,
        error = not success and result or nil
    })
    
    return success, result
end

-- Enhanced statistics with all improvements
function SecureExecutor:getExecutionStats(player)
    if not self:checkSpecificPermission(player, "canAdvancedStats") then
        return nil, "Insufficient permissions"
    end
    
    local playerStats = self:getPlayerStats(player)
    local globalStats = self:getGlobalStats()
    
    return {
        player = playerStats,
        global = globalStats,
        system = {
            activeExecutions = #activeExecutions,
            cacheSize = self:getCacheSize(),
            memoryOptimization = self:getMemoryOptimization(),
            encryptionStatus = self:getEncryptionStatus()
        }
    }
end

return SecureExecutor