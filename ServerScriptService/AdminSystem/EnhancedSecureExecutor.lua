-- Enhanced Secure Executor with Improved Timeout and Memory Monitoring
-- Addresses the limitations identified in the security analysis

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnhancedSecureExecutor = {}
EnhancedSecureExecutor.__index = EnhancedSecureExecutor

-- Enhanced security constants
local EXECUTION_TIMEOUT = 30 -- seconds
local MAX_EXECUTION_TIME = 5 -- seconds per script
local MAX_MEMORY_USAGE = 1024 * 1024 -- 1MB
local RATE_LIMIT_WINDOW = 60 -- seconds
local MAX_EXECUTIONS_PER_WINDOW = 10
local MEMORY_CHECK_INTERVAL = 0.1 -- seconds
local MAX_INSTRUCTION_COUNT = 1000000 -- Maximum instructions before yield required

-- Memory monitoring utilities
local function getApproximateMemoryUsage()
    -- Rough estimate using collectgarbage
    collectgarbage("collect")
    local memBefore = collectgarbage("count") * 1024
    
    return memBefore
end

local function estimateObjectMemory(obj)
    -- Basic memory estimation for common types
    local objType = type(obj)
    if objType == "string" then
        return #obj + 40 -- String overhead
    elseif objType == "table" then
        local size = 100 -- Table base overhead
        for k, v in pairs(obj) do
            size = size + estimateObjectMemory(k) + estimateObjectMemory(v)
        end
        return size
    elseif objType == "function" then
        return 200 -- Function overhead estimate
    else
        return 40 -- Basic object overhead
    end
end

function EnhancedSecureExecutor.new(adminSystem)
    local self = setmetatable({}, EnhancedSecureExecutor)
    
    self.adminSystem = adminSystem
    self.secureEnvironments = {}
    self.executionQueue = {}
    self.replicationTargets = {}
    self.rateLimiter = {}
    self.memoryMonitor = {}
    
    -- Enhanced execution tracking
    self.instructionCounts = {}
    self.memoryUsage = {}
    
    -- Setup monitoring tasks
    self:setupEnhancedCleanupTasks()
    
    return self
end

-- Enhanced secure environment with memory and instruction monitoring
function EnhancedSecureExecutor:createEnhancedSecureEnvironment(player, executionId)
    local startMemory = getApproximateMemoryUsage()
    local instructionCount = 0
    
    -- Create instruction counter hook
    local function instructionHook()
        instructionCount = instructionCount + 1
        if instructionCount > MAX_INSTRUCTION_COUNT then
            -- Force yield to prevent infinite loops
            wait(0.001)
            instructionCount = 0
        end
        
        -- Memory check every N instructions
        if instructionCount % 10000 == 0 then
            local currentMemory = getApproximateMemoryUsage()
            local memoryDelta = currentMemory - startMemory
            
            if memoryDelta > MAX_MEMORY_USAGE then
                error("Memory limit exceeded: " .. math.floor(memoryDelta / 1024) .. "KB used")
            end
        end
    end
    
    local environment = {
        -- Safe standard library with monitoring
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
        
        -- Enhanced math library
        math = setmetatable({}, {
            __index = function(_, key)
                instructionHook() -- Monitor math operations
                return math[key]
            end
        }),
        
        -- Enhanced string library with memory monitoring
        string = setmetatable({}, {
            __index = function(_, key)
                return function(...)
                    instructionHook()
                    local args = {...}
                    local result = string[key](unpack(args))
                    
                    -- Monitor string operations that could consume memory
                    if key == "rep" or key == "gsub" then
                        local memUsed = estimateObjectMemory(result)
                        if memUsed > MAX_MEMORY_USAGE / 10 then -- 10% of limit per operation
                            error("String operation would exceed memory limits")
                        end
                    end
                    
                    return result
                end
            end
        }),
        
        -- Enhanced table library with monitoring
        table = setmetatable({}, {
            __index = function(_, key)
                return function(...)
                    instructionHook()
                    return table[key](...)
                end
            end
        }),
        
        -- Controlled game access
        game = self:createGameProxy(player),
        workspace = self:createWorkspaceProxy(player),
        
        -- Enhanced utility functions
        wait = function(t)
            instructionHook()
            t = math.max(t or 0, 0.001) -- Minimum wait time
            return game:GetService("RunService").Heartbeat:Wait()
        end,
        
        spawn = function(func)
            instructionHook()
            return coroutine.wrap(function()
                -- Set up hook for spawned coroutine
                local co = coroutine.running()
                if debug and debug.sethook then
                    debug.sethook(co, instructionHook, "", 1000)
                end
                func()
            end)()
        end,
        
        delay = function(t, func)
            instructionHook()
            spawn(function()
                wait(t)
                func()
            end)
        end,
        
        -- Admin system access
        admin = self.adminSystem,
        executor = self,
        
        -- Execution context with monitoring
        executionId = executionId,
        executor_player = player,
        executor_timestamp = tick(),
        executor_memory_start = startMemory,
        
        -- Enhanced require function
        require = function(moduleScript)
            instructionHook()
            return self:enhancedSecureRequire(player, moduleScript, environment)
        end,
        
        -- Enhanced logging functions
        print = function(...)
            instructionHook()
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
        end,
        
        warn = function(...)
            instructionHook()
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            self:logExecution(player, executionId, "WARNING", message)
            self:sendExecutionResult(player, executionId, "warning", message)
        end,
        
        -- Memory monitoring utilities
        getMemoryUsage = function()
            return getApproximateMemoryUsage() - startMemory
        end,
        
        getInstructionCount = function()
            return instructionCount
        end
    }
    
    -- Store enhanced environment with monitoring data
    self.secureEnvironments[executionId] = {
        environment = environment,
        startMemory = startMemory,
        instructionCount = instructionCount,
        player = player
    }
    
    return environment
end

-- Enhanced secure require with recursive sandboxing
function EnhancedSecureExecutor:enhancedSecureRequire(player, moduleScript, parentEnvironment)
    -- Validate that the object is actually a ModuleScript
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        error("require() can only be used with ModuleScript objects")
    end
    
    local modulePath = self:getModulePath(moduleScript)
    
    -- Enhanced security checks
    if self:isRestrictedModule(modulePath) then
        error("Access denied: Cannot require modules from restricted locations")
    end
    
    if self:isSensitiveModule(modulePath) then
        local permissionLevel = self.adminSystem:getPermissionLevel(player)
        if permissionLevel < 3 then
            error("Insufficient permissions: SuperAdmin level required for sensitive modules")
        end
    end
    
    -- Log the require attempt
    self:logExecution(player, "MODULE_REQUIRE", "ATTEMPT", modulePath)
    
    -- Create sandboxed environment for the module
    local moduleEnvironment = self:createModuleSandbox(parentEnvironment, modulePath)
    
    -- Safely require the module with sandboxing
    local success, result = pcall(function()
        local moduleCode = moduleScript.Source
        local compiledModule, compileError = loadstring(moduleCode, "@" .. modulePath)
        
        if not compiledModule then
            error("Module compilation failed: " .. tostring(compileError))
        end
        
        -- Set sandboxed environment for the module
        setfenv(compiledModule, moduleEnvironment)
        
        -- Execute module in sandboxed environment
        return compiledModule()
    end)
    
    if success then
        self:logExecution(player, "MODULE_REQUIRE", "SUCCESS", modulePath)
        
        -- Validate returned module doesn't contain dangerous references
        if type(result) == "table" then
            self:validateModuleReturn(result, modulePath)
        end
        
        return result
    else
        self:logExecution(player, "MODULE_REQUIRE", "ERROR", modulePath .. " - " .. tostring(result))
        error("Module require failed: " .. tostring(result))
    end
end

-- Create sandboxed environment for required modules
function EnhancedSecureExecutor:createModuleSandbox(parentEnvironment, modulePath)
    local moduleSandbox = {}
    
    -- Copy safe elements from parent environment
    local safeKeys = {
        "_G", "_VERSION", "assert", "error", "ipairs", "next", "pairs", 
        "pcall", "select", "tonumber", "tostring", "type", "unpack", "xpcall",
        "math", "string", "table", "game", "workspace"
    }
    
    for _, key in ipairs(safeKeys) do
        moduleSandbox[key] = parentEnvironment[key]
    end
    
    -- Add module-specific restrictions
    moduleSandbox.require = function(subModule)
        -- Prevent recursive requires that could bypass security
        if self:getModulePath(subModule):find("AdminSystem") then
            error("Modules cannot require admin system components")
        end
        return self:enhancedSecureRequire(parentEnvironment.executor_player, subModule, moduleSandbox)
    end
    
    -- Limited script access
    moduleSandbox.script = nil -- Remove script access for security
    
    return moduleSandbox
end

-- Validate module return values for security
function EnhancedSecureExecutor:validateModuleReturn(moduleReturn, modulePath)
    local function validateValue(value, path, depth)
        if depth > 10 then return end -- Prevent deep recursion
        
        if type(value) == "table" then
            for k, v in pairs(value) do
                -- Check for dangerous references
                if type(v) == "userdata" and tostring(v):find("RBX") then
                    local valueName = tostring(v)
                    if valueName:find("DataStore") or valueName:find("HttpService") then
                        error("Module '" .. modulePath .. "' contains restricted service reference: " .. valueName)
                    end
                end
                
                validateValue(v, path .. "." .. tostring(k), depth + 1)
            end
        elseif type(value) == "function" then
            -- Check function environment for dangerous globals
            local env = getfenv(value)
            if env and env._G and env._G ~= _G then
                warn("Module '" .. modulePath .. "' function has non-standard environment")
            end
        end
    end
    
    validateValue(moduleReturn, modulePath, 0)
end

-- Enhanced execution with better timeout handling
function EnhancedSecureExecutor:executeWithEnhancedTimeout(player, executionId, func, scriptCode)
    local startTime = tick()
    local success, result
    local timeoutOccurred = false
    
    -- Create execution context
    activeExecutions[executionId] = {
        player = player,
        startTime = startTime,
        scriptCode = scriptCode,
        cancelled = false
    }
    
    -- Enhanced timeout mechanism using coroutine yielding
    local executionThread = coroutine.create(function()
        -- Set up instruction hook if available
        if debug and debug.sethook then
            debug.sethook(function()
                if activeExecutions[executionId] and activeExecutions[executionId].cancelled then
                    error("Execution cancelled due to timeout")
                end
                
                if tick() - startTime > MAX_EXECUTION_TIME then
                    activeExecutions[executionId].cancelled = true
                    error("Execution timed out after " .. MAX_EXECUTION_TIME .. " seconds")
                end
            end, "", 1000) -- Check every 1000 instructions
        end
        
        success, result = pcall(func)
    end)
    
    -- Start execution with monitoring
    local resumeSuccess, resumeResult = coroutine.resume(executionThread)
    
    -- Monitor execution with enhanced timeout
    local timeoutCounter = 0
    while coroutine.status(executionThread) ~= "dead" and 
          activeExecutions[executionId] and 
          not activeExecutions[executionId].cancelled and
          (tick() - startTime) < MAX_EXECUTION_TIME do
        
        wait(0.1)
        timeoutCounter = timeoutCounter + 0.1
        
        -- Force cancellation if needed
        if timeoutCounter >= MAX_EXECUTION_TIME then
            activeExecutions[executionId].cancelled = true
            timeoutOccurred = true
            break
        end
    end
    
    -- Cleanup and handle timeout
    if activeExecutions[executionId] then
        activeExecutions[executionId] = nil
    end
    
    if timeoutOccurred or (not success and result and result:find("timeout")) then
        self:logExecution(player, executionId, "TIMEOUT", "Execution exceeded time limit")
        return false, "Script execution timed out after " .. MAX_EXECUTION_TIME .. " seconds"
    end
    
    if success then
        self:logExecution(player, executionId, "SUCCESS", tostring(result))
        return true, result
    else
        self:logExecution(player, executionId, "ERROR", tostring(result))
        return false, result
    end
end

-- Enhanced stronger encryption for client replication
function EnhancedSecureExecutor:enhancedEncryptReplicationData(data, player)
    local serialized = HttpService:JSONEncode(data)
    
    -- Multi-layer encryption
    local key1 = tostring(player.UserId) .. "_" .. tostring(tick())
    local key2 = string.reverse(key1) .. "_salt_" .. tostring(math.random(100000, 999999))
    
    -- First XOR pass
    local encrypted1 = {}
    for i = 1, #serialized do
        local char = serialized:sub(i, i)
        local keyChar = key1:sub(((i - 1) % #key1) + 1, ((i - 1) % #key1) + 1)
        local encryptedChar = string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
        table.insert(encrypted1, encryptedChar)
    end
    
    local firstPass = table.concat(encrypted1)
    
    -- Second XOR pass with different key
    local encrypted2 = {}
    for i = 1, #firstPass do
        local char = firstPass:sub(i, i)
        local keyChar = key2:sub(((i - 1) % #key2) + 1, ((i - 1) % #key2) + 1)
        local encryptedChar = string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
        table.insert(encrypted2, encryptedChar)
    end
    
    return {
        data = table.concat(encrypted2),
        key1 = key1,
        key2 = key2,
        checksum = self:generateEnhancedChecksum(serialized),
        timestamp = tick()
    }
end

-- Enhanced checksum with better collision resistance
function EnhancedSecureExecutor:generateEnhancedChecksum(data)
    local hash1 = 0
    local hash2 = 0
    
    for i = 1, #data do
        local byte = string.byte(data:sub(i, i))
        hash1 = (hash1 + byte * i) % 1000000007 -- Large prime
        hash2 = (hash2 + byte * (i * i)) % 999999937 -- Different large prime
    end
    
    return tostring(hash1) .. "_" .. tostring(hash2)
end

-- Enhanced memory monitoring
function EnhancedSecureExecutor:monitorMemoryUsage(executionId)
    local executionData = self.secureEnvironments[executionId]
    if not executionData then return 0 end
    
    local currentMemory = getApproximateMemoryUsage()
    local memoryDelta = currentMemory - executionData.startMemory
    
    -- Store memory usage for tracking
    self.memoryUsage[executionId] = memoryDelta
    
    return memoryDelta
end

-- Enhanced cleanup with better resource management
function EnhancedSecureExecutor:setupEnhancedCleanupTasks()
    spawn(function()
        while true do
            wait(300) -- 5 minutes
            self:performEnhancedCleanup()
        end
    end)
    
    -- Memory monitoring task
    spawn(function()
        while true do
            wait(30) -- 30 seconds
            self:performMemoryCleanup()
        end
    end)
end

function EnhancedSecureExecutor:performMemoryCleanup()
    local totalMemory = 0
    
    for executionId, memoryUsage in pairs(self.memoryUsage) do
        totalMemory = totalMemory + memoryUsage
        
        -- Clean up high-memory executions
        if memoryUsage > MAX_MEMORY_USAGE / 2 then
            self:cleanupExecution(executionId)
            self:logExecution(nil, executionId, "MEMORY_CLEANUP", "High memory usage cleaned up")
        end
    end
    
    -- Force garbage collection if total memory is high
    if totalMemory > MAX_MEMORY_USAGE * 2 then
        collectgarbage("collect")
        print("[ENHANCED EXECUTOR] Performed memory cleanup - Total usage:", math.floor(totalMemory / 1024) .. "KB")
    end
end

-- Enhanced execution statistics
function EnhancedSecureExecutor:getEnhancedExecutionStats()
    local baseStats = self:getExecutionStats()
    
    -- Add memory statistics
    local totalMemoryUsed = 0
    local highMemoryExecutions = 0
    
    for _, memUsage in pairs(self.memoryUsage) do
        totalMemoryUsed = totalMemoryUsed + memUsage
        if memUsage > MAX_MEMORY_USAGE / 4 then
            highMemoryExecutions = highMemoryExecutions + 1
        end
    end
    
    return {
        -- Base statistics
        totalExecutions = baseStats.totalExecutions,
        successfulExecutions = baseStats.successfulExecutions,
        failedExecutions = baseStats.failedExecutions,
        successRate = baseStats.successRate,
        averageExecutionTime = baseStats.averageExecutionTime,
        activeExecutions = baseStats.activeExecutions,
        historySize = baseStats.historySize,
        
        -- Enhanced statistics
        totalMemoryUsed = totalMemoryUsed,
        averageMemoryPerExecution = totalMemoryUsed / math.max(baseStats.totalExecutions, 1),
        highMemoryExecutions = highMemoryExecutions,
        memoryEfficiency = (1 - (totalMemoryUsed / (MAX_MEMORY_USAGE * baseStats.totalExecutions))) * 100
    }
end

return EnhancedSecureExecutor