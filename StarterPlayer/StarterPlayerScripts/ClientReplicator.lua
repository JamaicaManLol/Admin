-- Client-Side Script Replicator
-- Secure client-side script replication system for authorized administrators

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Client Replicator Class
local ClientReplicator = {}
ClientReplicator.__index = ClientReplicator

-- Security constants
local VERIFICATION_TIMEOUT = 10 -- seconds
local MAX_REPLICATION_SIZE = 1024 * 512 -- 512KB
local HEARTBEAT_INTERVAL = 30 -- seconds
local MAX_CONCURRENT_EXECUTIONS = 5

-- Authentication state
local authenticationState = {
    isAuthenticated = false,
    adminLevel = 0,
    authToken = nil,
    lastHeartbeat = 0,
    verificationAttempts = 0
}

-- Replication state
local replicationState = {
    activeReplications = {},
    executionHistory = {},
    pendingExecutions = {},
    replicationStats = {
        totalReceived = 0,
        successfulExecutions = 0,
        failedExecutions = 0,
        bytesReceived = 0
    }
}

function ClientReplicator.new()
    local self = setmetatable({}, ClientReplicator)
    
    self.remoteEvents = {}
    self.clientEnvironments = {}
    self.replicationQueue = {}
    self.authCallbacks = {}
    self.adminCheckComplete = false
    
    -- Wait for initial admin check before full initialization
    self:performInitialAdminCheck()
    
    return self
end

-- Perform initial admin privilege check
function ClientReplicator:performInitialAdminCheck()
    -- Don't initialize replicator for non-admins
    spawn(function()
        wait(2) -- Wait for admin system to load
        
        -- Initialize connection only after admin check
        self:initializeConnection()
        
        -- Setup other systems only if authenticated
        if authenticationState.isAuthenticated then
            self:setupHeartbeat()
            self:setupCleanupTasks()
        end
        
        self.adminCheckComplete = true
    end)
end

-- Initialize connection to server
function ClientReplicator:initializeConnection()
    -- Wait for admin remotes
    local adminRemotes = ReplicatedStorage:WaitForChild("AdminRemotes", 30)
    if not adminRemotes then
        warn("[CLIENT REPLICATOR] Failed to connect to server - AdminRemotes not found")
        return
    end
    
    -- Get remote events
    self.remoteEvents.replication = adminRemotes:WaitForChild("ClientReplication", 10)
    self.remoteEvents.authentication = adminRemotes:WaitForChild("AdminLog", 10)
    self.remoteEvents.executorResult = adminRemotes:WaitForChild("ExecutorResult", 10)
    
    -- Create missing remotes if needed
    if not self.remoteEvents.replication then
        warn("[CLIENT REPLICATOR] ClientReplication remote not found")
        return
    end
    
    -- Connect event handlers
    self:connectEventHandlers()
    
    -- Request authentication
    self:requestAuthentication()
    
    print("[CLIENT REPLICATOR] Connection initialized successfully")
end

-- Connect remote event handlers
function ClientReplicator:connectEventHandlers()
    -- Handle replication events
    if self.remoteEvents.replication then
        self.remoteEvents.replication.OnClientEvent:Connect(function(eventType, data)
            self:handleReplicationEvent(eventType, data)
        end)
    end
    
    -- Handle authentication events
    if self.remoteEvents.authentication then
        self.remoteEvents.authentication.OnClientEvent:Connect(function(eventType, data)
            self:handleAuthenticationEvent(eventType, data)
        end)
    end
    
    -- Handle executor results
    if self.remoteEvents.executorResult then
        self.remoteEvents.executorResult.OnClientEvent:Connect(function(resultData)
            self:handleExecutorResult(resultData)
        end)
    end
end

-- Request authentication from server
function ClientReplicator:requestAuthentication()
    authenticationState.verificationAttempts = authenticationState.verificationAttempts + 1
    
    if authenticationState.verificationAttempts > 3 then
        warn("[CLIENT REPLICATOR] Too many authentication attempts")
        return
    end
    
    -- Generate client verification token
    local clientToken = HttpService:GenerateGUID(false)
    
    -- Request authentication
    if self.remoteEvents.authentication then
        self.remoteEvents.authentication:FireServer("request_auth", {
            clientToken = clientToken,
            timestamp = tick(),
            userId = player.UserId
        })
    end
    
    print("[CLIENT REPLICATOR] Authentication requested")
end

-- Handle authentication events
function ClientReplicator:handleAuthenticationEvent(eventType, data)
    if eventType == "admin_status" then
        self:processAuthenticationResponse(data)
    elseif eventType == "auth_challenge" then
        self:handleAuthChallenge(data)
    elseif eventType == "auth_revoked" then
        self:handleAuthRevoked(data)
    end
end

-- Process authentication response
function ClientReplicator:processAuthenticationResponse(data)
    if data.isAdmin and data.level > 0 then
        -- Additional security check - only activate for Admin level 2+ or higher
        if data.level >= 2 then
            authenticationState.isAuthenticated = true
            authenticationState.adminLevel = data.level
            authenticationState.authToken = self:generateAuthToken(data)
            authenticationState.lastHeartbeat = tick()
            
            print("[CLIENT REPLICATOR] Authentication successful - Level:", data.level)
            
            -- Initialize systems now that we're authenticated
            if not self.heartbeatActive then
                self:setupHeartbeat()
            end
            if not self.cleanupActive then
                self:setupCleanupTasks()
            end
            
            -- Notify authentication success
            self:notifyAuthenticationSuccess(data)
        else
            print("[CLIENT REPLICATOR] Authentication failed - Insufficient admin level (requires Admin level 2+)")
            self:disableReplicator("Insufficient admin level")
        end
    else
        authenticationState.isAuthenticated = false
        authenticationState.adminLevel = 0
        authenticationState.authToken = nil
        
        print("[CLIENT REPLICATOR] Authentication failed - No admin privileges")
        self:disableReplicator("No admin privileges")
    end
end

-- Disable replicator for non-admin users
function ClientReplicator:disableReplicator(reason)
    authenticationState.isAuthenticated = false
    authenticationState.adminLevel = 0
    authenticationState.authToken = nil
    
    -- Clear all data
    self.clientEnvironments = {}
    self.replicationQueue = {}
    replicationState.activeReplications = {}
    replicationState.executionHistory = {}
    replicationState.pendingExecutions = {}
    
    -- Disconnect events
    for _, connection in pairs(self.remoteEvents) do
        if connection and connection.disconnect then
            pcall(function() connection:disconnect() end)
        end
    end
    
    print("[CLIENT REPLICATOR] Replicator disabled:", reason)
end

-- Generate authentication token
function ClientReplicator:generateAuthToken(authData)
    local tokenData = {
        userId = player.UserId,
        adminLevel = authData.level,
        timestamp = tick(),
        sessionId = HttpService:GenerateGUID(false)
    }
    
    return HttpService:JSONEncode(tokenData)
end

-- Handle replication events
function ClientReplicator:handleReplicationEvent(eventType, data)
    if not authenticationState.isAuthenticated then
        warn("[CLIENT REPLICATOR] Replication rejected - Not authenticated")
        return
    end
    
    if eventType == "script_replication" then
        self:handleScriptReplication(data)
    elseif eventType == "replication_heartbeat" then
        self:handleReplicationHeartbeat(data)
    elseif eventType == "replication_status" then
        self:handleReplicationStatus(data)
    end
end

-- Handle script replication
function ClientReplicator:handleScriptReplication(encryptedData)
    -- Security check - ensure user is authenticated admin
    if not authenticationState.isAuthenticated or authenticationState.adminLevel < 2 then
        warn("[CLIENT REPLICATOR] Replication rejected - Not authenticated as admin")
        return
    end
    
    -- Validate replication size
    local dataSize = string.len(HttpService:JSONEncode(encryptedData))
    if dataSize > MAX_REPLICATION_SIZE then
        warn("[CLIENT REPLICATOR] Replication rejected - Data too large:", dataSize)
        return
    end
    
    -- Decrypt replication data
    local decryptedData = self:decryptReplicationData(encryptedData)
    if not decryptedData then
        warn("[CLIENT REPLICATOR] Replication failed - Decryption error")
        return
    end
    
    -- Validate replication data
    if not self:validateReplicationData(decryptedData) then
        warn("[CLIENT REPLICATOR] Replication rejected - Invalid data")
        return
    end
    
    -- Process replication
    self:processScriptReplication(decryptedData)
    
    -- Update statistics
    replicationState.replicationStats.totalReceived = replicationState.replicationStats.totalReceived + 1
    replicationState.replicationStats.bytesReceived = replicationState.replicationStats.bytesReceived + dataSize
    
    print("[CLIENT REPLICATOR] Script replication received:", decryptedData.executionId)
end

-- Decrypt replication data
function ClientReplicator:decryptReplicationData(encryptedData)
    if not encryptedData.data or not encryptedData.key or not encryptedData.checksum then
        return nil
    end
    
    -- Decrypt using XOR
    local decrypted = {}
    local key = encryptedData.key
    
    for i = 1, #encryptedData.data do
        local char = encryptedData.data:sub(i, i)
        local keyChar = key:sub(((i - 1) % #key) + 1, ((i - 1) % #key) + 1)
        local decryptedChar = string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
        table.insert(decrypted, decryptedChar)
    end
    
    local decryptedString = table.concat(decrypted)
    
    -- Verify checksum
    local calculatedChecksum = self:calculateChecksum(decryptedString)
    if calculatedChecksum ~= encryptedData.checksum then
        warn("[CLIENT REPLICATOR] Checksum mismatch - Data corrupted")
        return nil
    end
    
    -- Parse JSON
    local success, data = pcall(function()
        return HttpService:JSONDecode(decryptedString)
    end)
    
    if not success then
        warn("[CLIENT REPLICATOR] JSON parsing failed:", data)
        return nil
    end
    
    return data
end

-- Calculate checksum
function ClientReplicator:calculateChecksum(data)
    local hash = 0
    for i = 1, #data do
        hash = (hash + string.byte(data:sub(i, i))) % 1000000
    end
    return hash
end

-- Validate replication data
function ClientReplicator:validateReplicationData(data)
    -- Check required fields
    if not data.executionId or not data.scriptCode or not data.adminLevel then
        return false
    end
    
    -- Check admin level authorization
    if data.adminLevel < authenticationState.adminLevel then
        return false
    end
    
    -- Check timestamp (within 5 minutes)
    if tick() - data.timestamp > 300 then
        return false
    end
    
    -- Check script size
    if string.len(data.scriptCode) > MAX_REPLICATION_SIZE / 2 then
        return false
    end
    
    return true
end

-- Process script replication
function ClientReplicator:processScriptReplication(replicationData)
    -- Check concurrent execution limit
    if #replicationState.pendingExecutions >= MAX_CONCURRENT_EXECUTIONS then
        warn("[CLIENT REPLICATOR] Execution queue full - Rejecting replication")
        return
    end
    
    -- Add to execution queue
    table.insert(replicationState.pendingExecutions, {
        executionId = replicationData.executionId,
        scriptCode = replicationData.scriptCode,
        serverResult = replicationData.serverResult,
        timestamp = tick(),
        adminLevel = replicationData.adminLevel
    })
    
    -- Process execution
    self:executeReplicatedScript(replicationData)
end

-- Execute replicated script on client
function ClientReplicator:executeReplicatedScript(replicationData)
    local executionId = replicationData.executionId
    local scriptCode = replicationData.scriptCode
    
    -- Create client execution environment
    local clientEnvironment = self:createClientEnvironment(executionId)
    
    -- Compile script
    local compiledFunction, compileError = loadstring(scriptCode)
    
    if not compiledFunction then
        self:logReplicationError(executionId, "COMPILE_ERROR", compileError)
        replicationState.replicationStats.failedExecutions = replicationState.replicationStats.failedExecutions + 1
        return
    end
    
    -- Set environment
    setfenv(compiledFunction, clientEnvironment)
    
    -- Execute with protection
    local success, result = pcall(compiledFunction)
    
    if success then
        self:logReplicationSuccess(executionId, result)
        replicationState.replicationStats.successfulExecutions = replicationState.replicationStats.successfulExecutions + 1
    else
        self:logReplicationError(executionId, "RUNTIME_ERROR", result)
        replicationState.replicationStats.failedExecutions = replicationState.replicationStats.failedExecutions + 1
    end
    
    -- Remove from pending executions
    for i, pending in ipairs(replicationState.pendingExecutions) do
        if pending.executionId == executionId then
            table.remove(replicationState.pendingExecutions, i)
            break
        end
    end
    
    -- Cleanup environment
    self:cleanupClientEnvironment(executionId)
end

-- Create client execution environment
function ClientReplicator:createClientEnvironment(executionId)
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
        
        -- Safe libraries
        math = math,
        string = string,
        table = table,
        
        -- Client-specific game access
        game = game,
        workspace = workspace,
        player = player,
        playerGui = playerGui,
        
        -- Utility functions
        wait = function(t)
            return RunService.Heartbeat:Wait()
        end,
        
        spawn = function(func)
            return coroutine.wrap(func)()
        end,
        
        -- Client replicator access
        replicator = self,
        executionId = executionId,
        
        -- Safe print function
        print = function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            print("[CLIENT EXEC]", message)
            self:logClientOutput(executionId, message)
        end,
        
        -- Safe warn function
        warn = function(...)
            local args = {...}
            local output = {}
            for i, v in ipairs(args) do
                table.insert(output, tostring(v))
            end
            local message = table.concat(output, " ")
            
            warn("[CLIENT EXEC]", message)
            self:logClientWarning(executionId, message)
        end
    }
    
    -- Store environment
    self.clientEnvironments[executionId] = environment
    
    return environment
end

-- Log client output
function ClientReplicator:logClientOutput(executionId, message)
    table.insert(replicationState.executionHistory, {
        executionId = executionId,
        type = "OUTPUT",
        message = message,
        timestamp = tick()
    })
end

-- Log client warning
function ClientReplicator:logClientWarning(executionId, message)
    table.insert(replicationState.executionHistory, {
        executionId = executionId,
        type = "WARNING",
        message = message,
        timestamp = tick()
    })
end

-- Log replication success
function ClientReplicator:logReplicationSuccess(executionId, result)
    table.insert(replicationState.executionHistory, {
        executionId = executionId,
        type = "SUCCESS",
        message = tostring(result),
        timestamp = tick()
    })
    
    print("[CLIENT REPLICATOR] Execution successful:", executionId)
end

-- Log replication error
function ClientReplicator:logReplicationError(executionId, errorType, errorMessage)
    table.insert(replicationState.executionHistory, {
        executionId = executionId,
        type = errorType,
        message = errorMessage,
        timestamp = tick()
    })
    
    warn("[CLIENT REPLICATOR] Execution failed:", executionId, errorType, errorMessage)
end

-- Handle executor results
function ClientReplicator:handleExecutorResult(resultData)
    if not authenticationState.isAuthenticated then
        return
    end
    
    -- Display result in console if available
    if _G.AdminClient and _G.AdminClient.addConsoleOutput then
        local message = string.format("[%s] %s", resultData.type:upper(), resultData.message)
        _G.AdminClient:addConsoleOutput(message)
    end
    
    -- Log result
    table.insert(replicationState.executionHistory, {
        executionId = resultData.executionId,
        type = "SERVER_" .. resultData.type:upper(),
        message = resultData.message,
        timestamp = resultData.timestamp
    })
end

-- Setup heartbeat system
function ClientReplicator:setupHeartbeat()
    if self.heartbeatActive then
        return -- Already active
    end
    
    self.heartbeatActive = true
    spawn(function()
        while self.heartbeatActive and authenticationState.isAuthenticated do
            wait(HEARTBEAT_INTERVAL)
            
            if authenticationState.isAuthenticated then
                self:sendHeartbeat()
            else
                break -- Exit if authentication lost
            end
        end
        self.heartbeatActive = false
    end)
end

-- Send heartbeat to server
function ClientReplicator:sendHeartbeat()
    if self.remoteEvents.authentication then
        self.remoteEvents.authentication:FireServer("heartbeat", {
            authToken = authenticationState.authToken,
            timestamp = tick(),
            stats = replicationState.replicationStats
        })
    end
    
    authenticationState.lastHeartbeat = tick()
end

-- Setup cleanup tasks
function ClientReplicator:setupCleanupTasks()
    if self.cleanupActive then
        return -- Already active
    end
    
    self.cleanupActive = true
    spawn(function()
        while self.cleanupActive and authenticationState.isAuthenticated do
            wait(300) -- 5 minutes
            
            if authenticationState.isAuthenticated then
                self:performCleanup()
            else
                break -- Exit if authentication lost
            end
        end
        self.cleanupActive = false
    end)
end

-- Perform cleanup
function ClientReplicator:performCleanup()
    local currentTime = tick()
    
    -- Clean old execution history
    local newHistory = {}
    for _, entry in ipairs(replicationState.executionHistory) do
        if currentTime - entry.timestamp < 3600 then -- Keep 1 hour
            table.insert(newHistory, entry)
        end
    end
    replicationState.executionHistory = newHistory
    
    -- Clean old client environments
    for executionId, environment in pairs(self.clientEnvironments) do
        if currentTime - environment.executor_timestamp > 600 then -- 10 minutes
            self:cleanupClientEnvironment(executionId)
        end
    end
    
    -- Garbage collection
    collectgarbage("collect")
end

-- Cleanup client environment
function ClientReplicator:cleanupClientEnvironment(executionId)
    if self.clientEnvironments[executionId] then
        self.clientEnvironments[executionId] = nil
    end
end

-- Notify authentication success
function ClientReplicator:notifyAuthenticationSuccess(authData)
    -- Call registered callbacks
    for _, callback in pairs(self.authCallbacks) do
        pcall(callback, authData)
    end
    
    -- Create notification
    self:createNotification("Authentication Successful", "Client replicator activated - Level " .. authData.level)
end

-- Create notification
function ClientReplicator:createNotification(title, message)
    local notification = Instance.new("ScreenGui")
    notification.Name = "ReplicatorNotification"
    notification.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    frame.BorderSizePixel = 0
    frame.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0.5, 0)
    messageLabel.Position = UDim2.new(0, 10, 0.5, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 14
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.Text = message
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = frame
    
    -- Auto-remove after 5 seconds
    game:GetService("Debris"):AddItem(notification, 5)
end

-- Register authentication callback
function ClientReplicator:registerAuthCallback(callback)
    table.insert(self.authCallbacks, callback)
end

-- Get replication statistics
function ClientReplicator:getReplicationStats()
    -- Security check - only return stats for authenticated admins
    if not authenticationState.isAuthenticated or authenticationState.adminLevel < 2 then
        return {
            isAuthenticated = false,
            adminLevel = 0,
            message = "Access denied - Admin privileges required"
        }
    end
    
    return {
        isAuthenticated = authenticationState.isAuthenticated,
        adminLevel = authenticationState.adminLevel,
        totalReceived = replicationState.replicationStats.totalReceived,
        successfulExecutions = replicationState.replicationStats.successfulExecutions,
        failedExecutions = replicationState.replicationStats.failedExecutions,
        successRate = replicationState.replicationStats.totalReceived > 0 and
                     (replicationState.replicationStats.successfulExecutions / replicationState.replicationStats.totalReceived) * 100 or 0,
        bytesReceived = replicationState.replicationStats.bytesReceived,
        pendingExecutions = #replicationState.pendingExecutions,
        historySize = #replicationState.executionHistory
    }
end

-- Get execution history
function ClientReplicator:getExecutionHistory(limit)
    -- Security check - only return history for authenticated admins
    if not authenticationState.isAuthenticated or authenticationState.adminLevel < 2 then
        return {
            {
                executionId = "access_denied",
                type = "ERROR",
                message = "Access denied - Admin privileges required",
                timestamp = tick()
            }
        }
    end
    
    limit = limit or 50
    local history = {}
    
    local startIndex = math.max(1, #replicationState.executionHistory - limit + 1)
    for i = startIndex, #replicationState.executionHistory do
        table.insert(history, replicationState.executionHistory[i])
    end
    
    return history
end

-- Initialize client replicator (only for potential admins)
local clientReplicator = ClientReplicator.new()

-- Set up conditional global access
spawn(function()
    -- Wait for authentication check to complete
    while not clientReplicator.adminCheckComplete do
        wait(0.5)
    end
    
    -- Only provide global access if authenticated as admin
    if authenticationState.isAuthenticated and authenticationState.adminLevel >= 2 then
        _G.ClientReplicator = clientReplicator
        print("[CLIENT REPLICATOR] Client replicator initialized successfully for admin level", authenticationState.adminLevel)
    else
        -- Clear any potential global access for non-admins
        _G.ClientReplicator = nil
        print("[CLIENT REPLICATOR] Client replicator disabled - No admin privileges")
        
        -- Disable the replicator completely for non-admins
        clientReplicator:disableReplicator("Non-admin user")
    end
end)