-- Secure Executor Examples
-- Demonstrates the enhanced server-side executor with require() support and admin restrictions

-- Example 1: Basic Server-Only Execution
--[[
Execute this in console with Ctrl+Enter (server-only):
]]

print("=== BASIC SERVER EXECUTION ===")
print("Current server time:", os.time())
print("Number of players:", #game.Players:GetPlayers())

for i, player in ipairs(game.Players:GetPlayers()) do
    print(i, player.Name, "UserID:", player.UserId)
end

--[[
Example 2: Using require() with ModuleScripts
Create a ModuleScript in ReplicatedStorage named "TestModule" with this content:

local TestModule = {}

function TestModule.getMessage()
    return "Hello from ModuleScript!"
end

function TestModule.getCurrentPlayers()
    local playerList = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        table.insert(playerList, player.Name)
    end
    return playerList
end

return TestModule

Then execute this in console:
]]

print("=== MODULE SCRIPT EXAMPLE ===")
local testModule = require(game.ReplicatedStorage.TestModule)
print("Module message:", testModule.getMessage())
print("Players from module:", table.concat(testModule.getCurrentPlayers(), ", "))

--[[
Example 3: Client Replication (Admin Level 2+ Only)
Execute this with Ctrl+Shift+Enter (server + client replication):
]]

print("=== CLIENT REPLICATION EXAMPLE ===")
print("This script runs on both server AND client!")
print("Execution context:", executor_player and executor_player.Name or "Unknown")
print("Execution ID:", executionId)

-- Create a GUI that appears on both server (ServerStorage) and client (PlayerGui)
local gui = Instance.new("ScreenGui")
gui.Name = "ReplicationTest_" .. tostring(tick())

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0.5, -150, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
frame.BorderSizePixel = 0
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 1, -20)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 16
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "Replicated Script Test\nExecuted on: " .. (game:GetService("RunService"):IsServer() and "SERVER" or "CLIENT")
label.TextWrapped = true
label.Parent = frame

-- Different behavior for server vs client
if game:GetService("RunService"):IsServer() then
    -- On server: place in workspace for all to see
    gui.Parent = workspace
    print("GUI placed in workspace (server)")
else
    -- On client: place in PlayerGui
    gui.Parent = playerGui
    print("GUI placed in PlayerGui (client)")
end

-- Auto-remove after 5 seconds
game:GetService("Debris"):AddItem(gui, 5)

--[[
Example 4: Advanced require() with Error Handling
]]

print("=== ADVANCED REQUIRE EXAMPLE ===")

-- Safe module loading with error handling
local function safeRequire(modulePath)
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        print("Successfully loaded module:", modulePath)
        return result
    else
        warn("Failed to load module:", modulePath, "Error:", result)
        return nil
    end
end

-- Try to load various modules
local httpService = safeRequire(game:GetService("HttpService")) -- Should work
print("HttpService loaded:", httpService ~= nil)

-- Try to load a restricted module (this will fail for security)
local restrictedModule = safeRequire(game.ServerScriptService) -- Should fail
print("Restricted module loaded:", restrictedModule ~= nil)

--[[
Example 5: Permission Level Demonstration
This example shows different behavior based on admin level
]]

print("=== PERMISSION LEVEL EXAMPLE ===")
print("Your admin level:", admin:getPermissionLevel(executor_player))

-- Check specific permissions
local permissions = {"tp", "kick", "ban", "execute", "console"}
for _, permission in ipairs(permissions) do
    local hasPermission = admin:hasPermission(executor_player, permission)
    print("Permission '" .. permission .. "':", hasPermission and "GRANTED" or "DENIED")
end

-- Try to access different admin functions based on level
local playerLevel = admin:getPermissionLevel(executor_player)

if playerLevel >= 4 then
    print("OWNER LEVEL: Full system access")
    -- Owner-level operations
    local stats = admin:getExecutionStats()
    print("Total executions:", stats.totalExecutions)
    print("Success rate:", math.floor(stats.successRate) .. "%")
    
elseif playerLevel >= 3 then
    print("SUPERADMIN LEVEL: Advanced operations available")
    -- SuperAdmin operations
    print("Available commands:", #admin:getAvailableCommands(executor_player))
    
elseif playerLevel >= 2 then
    print("ADMIN LEVEL: Standard admin operations")
    -- Standard admin operations
    local players = admin:findPlayers("")
    print("Can manage", #players, "players")
    
elseif playerLevel >= 1 then
    print("MODERATOR LEVEL: Basic moderation only")
    -- Basic moderation only
    print("Limited admin access")
    
else
    print("NO ADMIN LEVEL: Read-only access")
end

--[[
Example 6: Statistics and Monitoring
]]

print("=== SYSTEM STATISTICS ===")

-- Get executor statistics (Owner/SuperAdmin only)
if admin:getPermissionLevel(executor_player) >= 3 then
    local stats = admin:getExecutionStats()
    print("=== Execution Statistics ===")
    print("Total executions:", stats.totalExecutions)
    print("Successful executions:", stats.successfulExecutions)
    print("Failed executions:", stats.failedExecutions)
    print("Success rate:", math.floor(stats.successRate) .. "%")
    print("Average execution time:", math.floor(stats.averageExecutionTime * 1000) .. "ms")
    print("Active executions:", stats.activeExecutions)
    
    -- Get recent execution history
    local history = admin:getExecutionHistory(5)
    print("\n=== Recent Execution History ===")
    for i, entry in ipairs(history) do
        print(string.format("%d. [%s] %s - %s", 
            i, 
            os.date("%H:%M:%S", entry.timestamp), 
            entry.action, 
            entry.details:sub(1, 50)
        ))
    end
else
    print("Statistics require SuperAdmin level or higher")
end

--[[
Example 7: Security Testing (This will fail appropriately)
]]

print("=== SECURITY TESTING ===")

-- These operations should fail with appropriate security messages:

-- Try to access restricted service
print("Testing restricted service access...")
local success1, result1 = pcall(function()
    return game:GetService("DataStoreService")
end)
print("DataStoreService access:", success1 and "ALLOWED (Security Risk!)" or "BLOCKED (Good)")

-- Try to require restricted module
print("Testing restricted module require...")
local success2, result2 = pcall(function()
    return require(game.ServerScriptService.AdminSystem.Config)
end)
print("Admin config access:", success2 and "ALLOWED (Security Risk!)" or "BLOCKED (Good)")

-- Try to access _G directly
print("Testing global environment access...")
local success3, result3 = pcall(function()
    return _G.AdminSystem
end)
print("Direct admin system access:", success3 and "ALLOWED (Expected)" or "BLOCKED")

print("=== Security test complete ===")

--[[
USAGE INSTRUCTIONS:

1. SERVER-ONLY EXECUTION (All Admins):
   - Copy any example above
   - Paste in console
   - Press Ctrl+Enter
   - View results in console output

2. CLIENT REPLICATION (Admin Level 2+ Only):
   - Copy Example 3 (Client Replication)
   - Paste in console  
   - Press Ctrl+Shift+Enter
   - See GUI appear on both server and client

3. MODULE SCRIPT TESTING:
   - Create the TestModule as described in Example 2
   - Execute the require() example
   - Observe secure module loading

4. PERMISSION TESTING:
   - Use Example 5 to test your permission level
   - Try different operations based on your level
   - Observe security restrictions in action

SECURITY FEATURES DEMONSTRATED:

✅ Secure require() function with path validation
✅ Permission-based feature access
✅ Restricted service access (DataStoreService blocked)
✅ Protected admin system modules
✅ Rate limiting (try executing rapidly)
✅ Execution timeouts (create infinite loop to test)
✅ Client replication restrictions (Admin Level 2+ only)
✅ Comprehensive logging of all actions

Remember: This system is designed for legitimate development and administration.
Always use responsibly and only in authorized environments.
]]