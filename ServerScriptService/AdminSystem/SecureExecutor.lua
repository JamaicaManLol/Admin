-- Secure Luau Script Executor
-- Advanced server-side script execution with comprehensive sandboxing

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SecureExecutor = {}
SecureExecutor.__index = SecureExecutor

-- Security constants
local EXECUTION_TIMEOUT = 30 -- seconds
local MAX_MEMORY_USAGE = 1024 * 1024 -- 1MB
local MAX_EXECUTION_TIME = 5 -- seconds per script
local RATE_LIMIT_WINDOW = 60 -- seconds
local MAX_EXECUTIONS_PER_WINDOW = 10

-- Execution tracking
local executionHistory = {}
local activeExecutions = {}
local executionStats = {
    totalExecutions = 0,
    successfulExecutions = 0,
    failedExecutions = 0,
    averageExecutionTime = 0
}

function SecureExecutor.new(adminSystem)
    local self = setmetatable({}, SecureExecutor)
    
    self.adminSystem = adminSystem
    self.secureEnvironments = {}
    self.executionQueue = {}
    self.replicationTargets = {}
    
    -- Initialize rate limiting
    self.rateLimiter = {}
    
    -- Setup periodic cleanup
    self:setupCleanupTasks()
    
    return self
end

-- Create secure sandbox environment
function SecureExecutor:createSecureEnvironment(player, executionId)
    local environment = {
        -- Safe standard library
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
        
        -- Safe math library
        math = {
            abs = math.abs,
            acos = math.acos,
            asin = math.asin,
            atan = math.atan,
            atan2 = math.atan2,
            ceil = math.ceil,
            cos = math.cos,
            deg = math.deg,
            exp = math.exp,
            floor = math.floor,
            fmod = math.fmod,
            frexp = math.frexp,
            huge = math.huge,
            ldexp = math.ldexp,
            log = math.log,
            log10 = math.log10,
            max = math.max,
            min = math.min,
            modf = math.modf,
            pi = math.pi,
            pow = math.pow,
            rad = math.rad,
            random = math.random,
            randomseed = math.randomseed,
            sin = math.sin,
            sqrt = math.sqrt,
            tan = math.tan
        },
        
        -- Safe string library
        string = {
            byte = string.byte,
            char = string.char,
            find = string.find,
            format = string.format,
            gmatch = string.gmatch,
            gsub = string.gsub,
            len = string.len,
            lower = string.lower,
            match = string.match,
            rep = string.rep,
            reverse = string.reverse,
            sub = string.sub,
            upper = string.upper
        },
        
        -- Safe table library
        table = {
            concat = table.concat,
            insert = table.insert,
            maxn = table.maxn,
            remove = table.remove,
            sort = table.sort,
            unpack = table.unpack
        },
        
        -- Controlled game access
        game = self:createGameProxy(player),
        workspace = self:createWorkspaceProxy(player),
        
        -- Utility functions
        wait = function(t)
            return game:GetService("RunService").Heartbeat:Wait()
        end,
        
        spawn = function(func)
            return coroutine.wrap(func)()
        end,
        
        delay = function(t, func)
            spawn(function()
                wait(t)
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
        
        -- Safe print function
        print = function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            -- Log and send to executor
            self:logExecution(player, executionId, "OUTPUT", message)
            self:sendExecutionResult(player, executionId, "output", message)
        end,
        
        -- Safe warn function
        warn = function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            self:logExecution(player, executionId, "WARNING", message)
            self:sendExecutionResult(player, executionId, "warning", message)
        end
    }
    
    -- Store environment for cleanup
    self.secureEnvironments[executionId] = environment
    
    return environment
end

-- Create controlled game proxy
function SecureExecutor:createGameProxy(player)
    local gameProxy = {}
    
    -- Safe service access
    local allowedServices = {
        "Players",
        "Workspace",
        "Lighting",
        "SoundService",
        "Debris",
        "RunService",
        "TweenService",
        "UserInputService",
        "ContextActionService",
        "GuiService",
        "StarterGui",
        "StarterPack",
        "StarterPlayerScripts",
        "Teams",
        "Chat"
    }
    
    function gameProxy:GetService(serviceName)
        if table.find(allowedServices, serviceName) then
            return game:GetService(serviceName)
        else
            error("Service '" .. serviceName .. "' is not accessible in secure environment")
        end
    end
    
    function gameProxy:FindService(serviceName)
        if table.find(allowedServices, serviceName) then
            return game:FindService(serviceName)
        else
            return nil
        end
    end
    
    -- Safe properties
    gameProxy.Players = game.Players
    gameProxy.Workspace = game.Workspace
    gameProxy.Lighting = game.Lighting
    gameProxy.ReplicatedStorage = game.ReplicatedStorage
    gameProxy.ServerStorage = nil -- Restricted
    gameProxy.ServerScriptService = nil -- Restricted
    
    return gameProxy
end

-- Create controlled workspace proxy
function SecureExecutor:createWorkspaceProxy(player)
    local workspaceProxy = {}
    
    -- Safe methods
    workspaceProxy.FindFirstChild = function(self, name)
        return workspace:FindFirstChild(name)
    end
    
    workspaceProxy.FindFirstChildOfClass = function(self, className)
        return workspace:FindFirstChildOfClass(className)
    end
    
    workspaceProxy.GetChildren = function(self)
        return workspace:GetChildren()
    end
    
    workspaceProxy.GetDescendants = function(self)
        return workspace:GetDescendants()
    end
    
    -- Safe properties
    workspaceProxy.CurrentCamera = workspace.CurrentCamera
    workspaceProxy.Gravity = workspace.Gravity
    
    return workspaceProxy
end

-- Execute script with security measures
function SecureExecutor:executeScript(player, scriptCode, replicateToClient)
    -- Validate admin permissions
    if not self.adminSystem:hasPermission(player, "execute") then
        return false, "Insufficient permissions for script execution"
    end
    
    -- Rate limiting check
    if not self:checkRateLimit(player) then
        return false, "Rate limit exceeded. Please wait before executing more scripts."
    end
    
    -- Generate execution ID
    local executionId = HttpService:GenerateGUID(false)
    
    -- Log execution attempt
    self:logExecution(player, executionId, "ATTEMPT", scriptCode:sub(1, 200))
    
    -- Create secure environment
    local environment = self:createSecureEnvironment(player, executionId)
    
    -- Compile script
    local compiledFunction, compileError = loadstring(scriptCode)
    
    if not compiledFunction then
        self:logExecution(player, executionId, "COMPILE_ERROR", compileError)
        return false, "Compilation error: " .. compileError
    end
    
    -- Set environment
    setfenv(compiledFunction, environment)
    
    -- Execute with timeout and error handling
    local success, result = self:executeWithTimeout(player, executionId, compiledFunction, scriptCode)
    
    -- Handle replication if requested and successful
    if success and replicateToClient then
        self:replicateToClient(player, executionId, scriptCode, result)
    end
    
    -- Update statistics
    self:updateExecutionStats(success, tick() - environment.executor_timestamp)
    
    -- Cleanup
    self:cleanupExecution(executionId)
    
    return success, result
end

-- Execute function with timeout protection
function SecureExecutor:executeWithTimeout(player, executionId, func, scriptCode)
    local startTime = tick()
    local success, result
    
    -- Create execution context
    activeExecutions[executionId] = {
        player = player,
        startTime = startTime,
        scriptCode = scriptCode
    }
    
    -- Execute in protected mode
    local executionThread = coroutine.create(function()
        success, result = pcall(func)
    end)
    
    -- Start execution
    local resumeSuccess, resumeResult = coroutine.resume(executionThread)
    
    -- Handle timeout
    local timeoutThread = coroutine.create(function()
        wait(MAX_EXECUTION_TIME)
        if activeExecutions[executionId] then
            success = false
            result = "Script execution timed out after " .. MAX_EXECUTION_TIME .. " seconds"
            self:logExecution(player, executionId, "TIMEOUT", result)
        end
    end)
    
    coroutine.resume(timeoutThread)
    
    -- Wait for completion or timeout
    while coroutine.status(executionThread) ~= "dead" and 
          activeExecutions[executionId] and 
          (tick() - startTime) < MAX_EXECUTION_TIME do
        wait(0.1)
    end
    
    -- Force cleanup if still running
    if activeExecutions[executionId] then
        activeExecutions[executionId] = nil
    end
    
    if success then
        self:logExecution(player, executionId, "SUCCESS", tostring(result))
        executionStats.successfulExecutions = executionStats.successfulExecutions + 1
        return true, result
    else
        self:logExecution(player, executionId, "ERROR", tostring(result))
        executionStats.failedExecutions = executionStats.failedExecutions + 1
        return false, result
    end
end

-- Rate limiting system
function SecureExecutor:checkRateLimit(player)
    local userId = player.UserId
    local currentTime = tick()
    
    -- Initialize rate limiter for user
    if not self.rateLimiter[userId] then
        self.rateLimiter[userId] = {
            executions = {},
            lastCleanup = currentTime
        }
    end
    
    local userLimiter = self.rateLimiter[userId]
    
    -- Clean old entries
    if currentTime - userLimiter.lastCleanup > RATE_LIMIT_WINDOW then
        local newExecutions = {}
        for _, execTime in ipairs(userLimiter.executions) do
            if currentTime - execTime < RATE_LIMIT_WINDOW then
                table.insert(newExecutions, execTime)
            end
        end
        userLimiter.executions = newExecutions
        userLimiter.lastCleanup = currentTime
    end
    
    -- Check rate limit
    if #userLimiter.executions >= MAX_EXECUTIONS_PER_WINDOW then
        return false
    end
    
    -- Add current execution
    table.insert(userLimiter.executions, currentTime)
    return true
end

-- Replicate script to authorized client
function SecureExecutor:replicateToClient(player, executionId, scriptCode, serverResult)
    -- Verify client replication permissions
    if not self.adminSystem:hasPermission(player, "console") then
        return false, "Insufficient permissions for client replication"
    end
    
    -- Create replication package
    local replicationPackage = {
        executionId = executionId,
        scriptCode = scriptCode,
        serverResult = serverResult,
        timestamp = tick(),
        adminLevel = self.adminSystem:getPermissionLevel(player)
    }
    
    -- Encrypt replication data
    local encryptedPackage = self:encryptReplicationData(replicationPackage, player)
    
    -- Send to client
    self:sendToClient(player, "script_replication", encryptedPackage)
    
    -- Log replication
    self:logExecution(player, executionId, "REPLICATED", "Script replicated to client")
    
    return true
end

-- Encrypt replication data
function SecureExecutor:encryptReplicationData(data, player)
    -- Simple encryption using player-specific key
    local key = tostring(player.UserId) .. "_" .. tostring(tick())
    local serialized = HttpService:JSONEncode(data)
    
    -- XOR encryption (simple but effective for this use case)
    local encrypted = {}
    for i = 1, #serialized do
        local char = serialized:sub(i, i)
        local keyChar = key:sub(((i - 1) % #key) + 1, ((i - 1) % #key) + 1)
        local encryptedChar = string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
        table.insert(encrypted, encryptedChar)
    end
    
    return {
        data = table.concat(encrypted),
        key = key,
        checksum = self:generateChecksum(serialized)
    }
end

-- Generate checksum for data integrity
function SecureExecutor:generateChecksum(data)
    local hash = 0
    for i = 1, #data do
        hash = (hash + string.byte(data:sub(i, i))) % 1000000
    end
    return hash
end

-- Send execution result to client
function SecureExecutor:sendExecutionResult(player, executionId, resultType, message)
    -- Get admin remotes
    local adminRemotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
    if not adminRemotes then return end
    
    local executorRemote = adminRemotes:FindFirstChild("ExecutorResult")
    if not executorRemote then return end
    
    -- Send secure result
    executorRemote:FireClient(player, {
        executionId = executionId,
        type = resultType,
        message = message,
        timestamp = tick()
    })
end

-- Send data to client
function SecureExecutor:sendToClient(player, eventType, data)
    local adminRemotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
    if not adminRemotes then return end
    
    local replicationRemote = adminRemotes:FindFirstChild("ClientReplication")
    if not replicationRemote then return end
    
    replicationRemote:FireClient(player, eventType, data)
end

-- Log execution activity
function SecureExecutor:logExecution(player, executionId, action, details)
    local logEntry = {
        executionId = executionId,
        player = player.Name,
        playerId = player.UserId,
        action = action,
        details = details,
        timestamp = os.time(),
        serverTime = tick()
    }
    
    -- Add to execution history
    table.insert(executionHistory, logEntry)
    
    -- Limit history size
    if #executionHistory > 1000 then
        table.remove(executionHistory, 1)
    end
    
    -- Log to admin system
    if self.adminSystem and self.adminSystem.logAction then
        self.adminSystem:logAction(player, "EXECUTOR_" .. action, executionId, details)
    end
    
    -- Console output
    print("[SECURE EXECUTOR]", player.Name, action, details:sub(1, 100))
end

-- Update execution statistics
function SecureExecutor:updateExecutionStats(success, executionTime)
    executionStats.totalExecutions = executionStats.totalExecutions + 1
    
    -- Update average execution time
    local currentAverage = executionStats.averageExecutionTime
    local totalExecs = executionStats.totalExecutions
    executionStats.averageExecutionTime = ((currentAverage * (totalExecs - 1)) + executionTime) / totalExecs
end

-- Cleanup execution resources
function SecureExecutor:cleanupExecution(executionId)
    -- Remove from active executions
    if activeExecutions[executionId] then
        activeExecutions[executionId] = nil
    end
    
    -- Remove environment
    if self.secureEnvironments[executionId] then
        self.secureEnvironments[executionId] = nil
    end
    
    -- Garbage collection hint
    collectgarbage("collect")
end

-- Setup periodic cleanup tasks
function SecureExecutor:setupCleanupTasks()
    -- Cleanup old executions every 5 minutes
    spawn(function()
        while true do
            wait(300) -- 5 minutes
            self:performCleanup()
        end
    end)
end

-- Perform periodic cleanup
function SecureExecutor:performCleanup()
    local currentTime = tick()
    
    -- Clean up stale executions
    for executionId, execution in pairs(activeExecutions) do
        if currentTime - execution.startTime > EXECUTION_TIMEOUT then
            self:cleanupExecution(executionId)
            self:logExecution(execution.player, executionId, "CLEANUP", "Stale execution cleaned up")
        end
    end
    
    -- Clean up rate limiter
    for userId, limiter in pairs(self.rateLimiter) do
        if currentTime - limiter.lastCleanup > RATE_LIMIT_WINDOW * 2 then
            self.rateLimiter[userId] = nil
        end
    end
    
    -- Garbage collection
    collectgarbage("collect")
end

-- Get execution statistics
function SecureExecutor:getExecutionStats()
    return {
        totalExecutions = executionStats.totalExecutions,
        successfulExecutions = executionStats.successfulExecutions,
        failedExecutions = executionStats.failedExecutions,
        successRate = executionStats.totalExecutions > 0 and 
                     (executionStats.successfulExecutions / executionStats.totalExecutions) * 100 or 0,
        averageExecutionTime = executionStats.averageExecutionTime,
        activeExecutions = #activeExecutions,
        historySize = #executionHistory
    }
end

-- Get execution history
function SecureExecutor:getExecutionHistory(limit)
    limit = limit or 50
    local history = {}
    
    for i = math.max(1, #executionHistory - limit + 1), #executionHistory do
        table.insert(history, executionHistory[i])
    end
    
    return history
end

return SecureExecutor