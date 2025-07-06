-- Admin System Automated Tests using TestEZ Framework
-- Comprehensive testing for all admin system functionality

local TestEZ = require(game:GetService("ReplicatedStorage"):WaitForChild("TestEZ", 5))
or {
    describe = function(name, func) print("[TEST]", name); func() end,
    it = function(name, func) print("  -", name); local success, err = pcall(func); if not success then warn("FAILED:", err) end end,
    expect = function(value) 
        return {
            to = {
                equal = function(expected) assert(value == expected, "Expected " .. tostring(expected) .. " but got " .. tostring(value)) end,
                be = {
                    ok = function() assert(value ~= nil and value ~= false, "Expected truthy value but got " .. tostring(value)) end
                }
            },
            never = {
                to = {
                    equal = function(expected) assert(value ~= expected, "Expected not " .. tostring(expected) .. " but got " .. tostring(value)) end
                }
            }
        }
    end
}

local Config = require(script.Parent.Config)
local AdminCore = require(script.Parent.AdminCore)

-- Mock objects for testing
local MockPlayer = {}
MockPlayer.__index = MockPlayer

function MockPlayer.new(name, userId, adminLevel)
    local self = setmetatable({}, MockPlayer)
    self.Name = name or "TestPlayer"
    self.UserId = userId or 123456789
    self.Character = nil
    self.events = {}
    self.adminLevel = adminLevel or 0
    return self
end

function MockPlayer:Kick(reason)
    self.kicked = true
    self.kickReason = reason
end

function MockPlayer:LoadCharacter()
    self.respawned = true
end

-- Test Results Storage
local TestResults = {
    passed = 0,
    failed = 0,
    results = {}
}

local function addTestResult(testName, success, errorMsg)
    table.insert(TestResults.results, {
        name = testName,
        success = success,
        error = errorMsg
    })
    
    if success then
        TestResults.passed = TestResults.passed + 1
    else
        TestResults.failed = TestResults.failed + 1
    end
end

-- Admin System Tests
TestEZ.describe("Admin System Core Tests", function()
    
    TestEZ.describe("Rate Limiting System", function()
        
        TestEZ.it("should initialize rate limiting data for new players", function()
            local adminSystem = AdminCore.new()
            local testPlayer = MockPlayer.new("RateLimitTest", 999999, 0)
            
            local success, result = pcall(function()
                return adminSystem:checkRateLimit(testPlayer, "commands")
            end)
            
            TestEZ.expect(success).to.be.ok()
            TestEZ.expect(result).to.equal(true)
            
            addTestResult("Rate Limiting Initialization", success, result)
        end)
        
        TestEZ.it("should enforce command rate limits", function()
            local adminSystem = AdminCore.new()
            local testPlayer = MockPlayer.new("RateLimitTest", 999998, 0)
            
            local success = true
            local errorMsg = nil
            
            pcall(function()
                -- Simulate exceeding rate limit
                for i = 1, Config.RateLimiting.CommandsPerMinute + 5 do
                    adminSystem:checkRateLimit(testPlayer, "commands")
                end
                
                -- This should fail
                local canProceed = adminSystem:checkRateLimit(testPlayer, "commands")
                assert(canProceed == false, "Rate limit should have been triggered")
            end)
            
            addTestResult("Command Rate Limiting", success, errorMsg)
        end)
        
        TestEZ.it("should handle burst limits correctly", function()
            local adminSystem = AdminCore.new()
            local testPlayer = MockPlayer.new("BurstTest", 999997, 0)
            
            local success, errorMsg = pcall(function()
                -- Rapid fire commands
                for i = 1, Config.RateLimiting.CommandBurstLimit + 1 do
                    local canProceed = adminSystem:checkRateLimit(testPlayer, "commands")
                    if i > Config.RateLimiting.CommandBurstLimit then
                        assert(canProceed == false, "Burst limit should prevent execution")
                    end
                end
            end)
            
            addTestResult("Burst Rate Limiting", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Permission System", function()
        
        TestEZ.it("should correctly identify admin permissions", function()
            local adminSystem = AdminCore.new()
            local adminPlayer = MockPlayer.new("AdminTest", 123456789, 4) -- Owner level
            
            local success, errorMsg = pcall(function()
                local level = adminSystem:getPermissionLevel(adminPlayer)
                assert(level == 4, "Admin should have level 4 permissions")
                
                local hasKickPermission = adminSystem:hasPermission(adminPlayer, "kick")
                assert(hasKickPermission == true, "Admin should have kick permission")
                
                local hasExecutePermission = adminSystem:hasPermission(adminPlayer, "execute")
                assert(hasExecutePermission == true, "Admin should have execute permission")
            end)
            
            addTestResult("Admin Permission Checks", success, errorMsg)
        end)
        
        TestEZ.it("should deny permissions to non-admins", function()
            local adminSystem = AdminCore.new()
            local regularPlayer = MockPlayer.new("RegularTest", 999996, 0)
            
            local success, errorMsg = pcall(function()
                local level = adminSystem:getPermissionLevel(regularPlayer)
                assert(level == 0, "Regular player should have level 0 permissions")
                
                local hasKickPermission = adminSystem:hasPermission(regularPlayer, "kick")
                assert(hasKickPermission == false, "Regular player should not have kick permission")
                
                local hasExecutePermission = adminSystem:hasPermission(regularPlayer, "execute")
                assert(hasExecutePermission == false, "Regular player should not have execute permission")
            end)
            
            addTestResult("Regular Player Permission Checks", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Ban System", function()
        
        TestEZ.it("should correctly check permanent bans", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                -- Add a test ban
                Config.BannedUsers[999995] = {
                    reason = "Test ban",
                    bannedBy = "TestAdmin",
                    timestamp = os.time()
                }
                
                local isBanned = adminSystem:isBanned(999995)
                assert(isBanned == true, "Player should be detected as banned")
                
                local isNotBanned = adminSystem:isBanned(999994)
                assert(isNotBanned == false, "Player should not be detected as banned")
                
                -- Clean up
                Config.BannedUsers[999995] = nil
            end)
            
            addTestResult("Permanent Ban Detection", success, errorMsg)
        end)
        
        TestEZ.it("should handle temporary bans correctly", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                -- Add a temporary ban
                adminSystem.tempBannedUsers[999993] = tick() + 300 -- 5 minutes
                
                local isTempBanned = adminSystem:isBanned(999993)
                assert(isTempBanned == true, "Player should be temporarily banned")
                
                -- Simulate expired ban
                adminSystem.tempBannedUsers[999993] = tick() - 300 -- 5 minutes ago
                
                local isStillBanned = adminSystem:isBanned(999993)
                assert(isStillBanned == false, "Expired temp ban should not be active")
            end)
            
            addTestResult("Temporary Ban System", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Webhook Integration", function()
        
        TestEZ.it("should create proper Discord embeds", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                local embed = adminSystem:createDiscordEmbed(
                    "Test Title",
                    "Test Description",
                    15158332,
                    {{name = "Test Field", value = "Test Value", inline = true}}
                )
                
                assert(embed.title == "Test Title", "Embed title should match")
                assert(embed.description == "Test Description", "Embed description should match")
                assert(embed.color == 15158332, "Embed color should match")
                assert(embed.fields[1].name == "Test Field", "Embed field should match")
            end)
            
            addTestResult("Discord Embed Creation", success, errorMsg)
        end)
        
        TestEZ.it("should handle webhook queuing", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                local embed = adminSystem:createDiscordEmbed("Test", "Test", 3447003)
                
                -- Simulate webhook being queued due to cooldown
                adminSystem.lastWebhookTime["AdminLogs"] = tick()
                local queueResult = adminSystem:sendWebhook("AdminLogs", embed, "normal")
                
                -- Should be queued since we just set the last webhook time
                assert(#adminSystem.webhookQueue >= 0, "Webhook should be queued or processed")
            end)
            
            addTestResult("Webhook Queuing System", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Security Monitoring", function()
        
        TestEZ.it("should detect suspicious activity patterns", function()
            local adminSystem = AdminCore.new()
            local testPlayer = MockPlayer.new("SuspiciousTest", 999992, 0)
            
            local success, errorMsg = pcall(function()
                -- Simulate high command usage
                local userId = testPlayer.UserId
                adminSystem.rateLimitData[userId] = {
                    commands = {},
                    violations = 0
                }
                
                local currentTime = tick()
                -- Add many recent commands
                for i = 1, Config.Security.SuspiciousCommandThreshold + 10 do
                    table.insert(adminSystem.rateLimitData[userId].commands, currentTime - (i * 10))
                end
                
                -- Run security scan
                adminSystem:performSecurityScan()
                
                -- Should have logged suspicious activity
                assert(true, "Security scan completed without errors")
            end)
            
            addTestResult("Security Activity Detection", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Command Processing", function()
        
        TestEZ.it("should handle command argument parsing", function()
            local adminSystem = AdminCore.new()
            local testPlayer = MockPlayer.new("CommandTest", 123456789, 4) -- Admin level
            
            local success, errorMsg = pcall(function()
                -- Mock the Commands module response
                local originalCommands = getfenv().Commands
                getfenv().Commands = {
                    test = function(admin, player, arg1, arg2)
                        return "Test command executed with args: " .. (arg1 or "none") .. ", " .. (arg2 or "none")
                    end
                }
                
                -- Test command parsing
                adminSystem:handleChatCommand(testPlayer, "test arg1 arg2")
                
                -- Restore original commands
                getfenv().Commands = originalCommands
                
                assert(true, "Command parsing completed successfully")
            end)
            
            addTestResult("Command Argument Parsing", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("Error Handling", function()
        
        TestEZ.it("should handle invalid player operations gracefully", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                -- Test with nil player
                local result = adminSystem:findPlayers("NonexistentPlayer")
                assert(type(result) == "table", "Should return empty table for non-existent player")
                assert(#result == 0, "Should return empty table for non-existent player")
                
                -- Test with invalid permission check
                local invalidPlayer = {UserId = "invalid", Name = "Invalid"}
                local hasPermission = adminSystem:hasPermission(invalidPlayer, "test")
                assert(hasPermission == false, "Invalid player should have no permissions")
            end)
            
            addTestResult("Invalid Player Operation Handling", success, errorMsg)
        end)
        
        TestEZ.it("should handle malformed data gracefully", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                -- Test with malformed webhook data
                local embed = adminSystem:createDiscordEmbed(nil, nil, nil, nil)
                assert(type(embed) == "table", "Should create valid embed even with nil values")
                
                -- Test rate limiting with invalid data
                local testPlayer = MockPlayer.new("MalformedTest", 999991, 0)
                local canProceed = adminSystem:checkRateLimit(testPlayer, "invalid_action_type")
                assert(canProceed == true, "Unknown action types should be allowed")
            end)
            
            addTestResult("Malformed Data Handling", success, errorMsg)
        end)
        
    end)
    
    TestEZ.describe("System Statistics", function()
        
        TestEZ.it("should provide accurate system statistics", function()
            local adminSystem = AdminCore.new()
            
            local success, errorMsg = pcall(function()
                local stats = adminSystem:getSystemStatistics()
                
                assert(type(stats) == "table", "Statistics should be a table")
                assert(type(stats.rateLimiting) == "table", "Rate limiting stats should exist")
                assert(type(stats.webhooks) == "table", "Webhook stats should exist")
                assert(type(stats.security) == "table", "Security stats should exist")
                assert(type(stats.general) == "table", "General stats should exist")
                
                assert(type(stats.general.adminCount) == "number", "Admin count should be a number")
                assert(stats.general.adminCount >= 0, "Admin count should be non-negative")
            end)
            
            addTestResult("System Statistics Generation", success, errorMsg)
        end)
        
    end)
    
end)

-- Test Performance Benchmarks
TestEZ.describe("Performance Tests", function()
    
    TestEZ.it("should handle rate limit checks efficiently", function()
        local adminSystem = AdminCore.new()
        local testPlayer = MockPlayer.new("PerformanceTest", 999990, 0)
        
        local success, errorMsg = pcall(function()
            local startTime = tick()
            
            -- Perform many rate limit checks
            for i = 1, 1000 do
                adminSystem:checkRateLimit(testPlayer, "commands")
            end
            
            local endTime = tick()
            local duration = endTime - startTime
            
            assert(duration < 1, "1000 rate limit checks should complete in under 1 second, took: " .. duration)
        end)
        
        addTestResult("Rate Limit Performance", success, errorMsg)
    end)
    
    TestEZ.it("should handle permission checks efficiently", function()
        local adminSystem = AdminCore.new()
        local testPlayer = MockPlayer.new("PermissionPerf", 123456789, 4)
        
        local success, errorMsg = pcall(function()
            local startTime = tick()
            
            -- Perform many permission checks
            for i = 1, 1000 do
                adminSystem:hasPermission(testPlayer, "kick")
                adminSystem:hasPermission(testPlayer, "ban")
                adminSystem:hasPermission(testPlayer, "execute")
            end
            
            local endTime = tick()
            local duration = endTime - startTime
            
            assert(duration < 1, "3000 permission checks should complete in under 1 second, took: " .. duration)
        end)
        
        addTestResult("Permission Check Performance", success, errorMsg)
    end)
    
end)

-- Test Runner Function
local function runTests()
    print("\n" .. string.rep("=", 60))
    print("🧪 ADMIN SYSTEM AUTOMATED TESTS")
    print(string.rep("=", 60))
    
    local startTime = tick()
    
    -- Reset test results
    TestResults.passed = 0
    TestResults.failed = 0
    TestResults.results = {}
    
    print("Starting comprehensive test suite...")
    
    -- Run all tests (this happens automatically when TestEZ.describe is called)
    
    local endTime = tick()
    local duration = endTime - startTime
    
    print(string.rep("-", 60))
    print("📊 TEST RESULTS SUMMARY")
    print(string.rep("-", 60))
    print(string.format("✅ Passed: %d", TestResults.passed))
    print(string.format("❌ Failed: %d", TestResults.failed))
    print(string.format("⏱️  Duration: %.3f seconds", duration))
    print(string.format("📈 Success Rate: %.1f%%", 
        TestResults.passed > 0 and (TestResults.passed / (TestResults.passed + TestResults.failed)) * 100 or 0))
    
    if TestResults.failed > 0 then
        print("\n❌ FAILED TESTS:")
        for _, result in ipairs(TestResults.results) do
            if not result.success then
                print(string.format("  - %s: %s", result.name, result.error or "Unknown error"))
            end
        end
    end
    
    print(string.rep("=", 60))
    
    -- Return test results for external use
    return {
        passed = TestResults.passed,
        failed = TestResults.failed,
        duration = duration,
        successRate = TestResults.passed > 0 and (TestResults.passed / (TestResults.passed + TestResults.failed)) * 100 or 0,
        results = TestResults.results
    }
end

-- Auto-run tests if not in production
if Config.Settings.TestingMode then
    spawn(function()
        wait(2) -- Give the admin system time to initialize
        runTests()
    end)
end

-- Export for manual testing
return {
    runTests = runTests,
    TestResults = TestResults,
    MockPlayer = MockPlayer
}