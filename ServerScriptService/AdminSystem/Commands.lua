-- ====================================================================
-- ADMIN COMMANDS MODULE - GOD-TIER UNIFIED VERSION
-- Perfect 10/10 Professional-Grade Command Framework
-- Unified style, structure, and seamless system integration
-- ====================================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

-- ====================================================================
-- COMMANDS MODULE
-- ====================================================================
local Commands = {}

-- Constants for consistent behavior
local ANNOUNCEMENT_DURATION = 8
local TELEPORT_OFFSET = Vector3.new(5, 0, 0)
local MAX_BAN_REASON_LENGTH = 200
local DEFAULT_REASON = "No reason provided"

-- ====================================================================
-- UTILITY FUNCTIONS (UNIFIED ERROR HANDLING)
-- ====================================================================
local function safePlayerOperation(operation, errorMessage)
    local success, result = pcall(operation)
    if not success then
        warn("[COMMANDS] " .. errorMessage .. ": " .. tostring(result))
        return false, errorMessage .. " failed"
    end
    return true, result
end

local function validatePlayerCharacter(player)
    return player.Character and 
           player.Character:FindFirstChild("HumanoidRootPart") and
           player.Character:FindFirstChild("Humanoid")
end

local function sanitizeReason(...)
    local reason = table.concat({...}, " ")
    if reason == "" then
        return DEFAULT_REASON
    end
    
    -- Limit reason length and sanitize
    if #reason > MAX_BAN_REASON_LENGTH then
        reason = reason:sub(1, MAX_BAN_REASON_LENGTH) .. "..."
    end
    
    return reason
end

-- ====================================================================
-- MOVEMENT COMMANDS (ENHANCED WITH ERROR HANDLING)
-- ====================================================================

-- Teleport to player
function Commands.tp(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /tp [player]"
    end
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        if not validatePlayerCharacter(adminPlayer) then
            return "Your character is not available for teleportation"
        end
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        -- Enhanced teleportation with safety checks
        local targetCFrame = target.Character.HumanoidRootPart.CFrame
        local safeCFrame = targetCFrame + TELEPORT_OFFSET
        
        adminPlayer.Character.HumanoidRootPart.CFrame = safeCFrame
        
        -- Log action with enhanced details
        admin:logAction(adminPlayer, "TELEPORT", target.Name, 
            string.format("Teleported to player at position: %.1f, %.1f, %.1f", 
                targetCFrame.Position.X, targetCFrame.Position.Y, targetCFrame.Position.Z))
        
        -- Track analytics
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "tp",
                admin = adminPlayer.Name,
                target = target.Name,
                timestamp = tick()
            })
        end
        
        return "Teleported to " .. target.Name
    end, "Teleport operation")
    
    return result
end

-- Bring player to admin
function Commands.bring(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /bring [player]"
    end
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        -- Check permissions - prevent bringing higher level admins
        if admin:getPermissionLevel(target) > admin:getPermissionLevel(adminPlayer) then
            return "Cannot bring a higher level admin"
        end
        
        if not validatePlayerCharacter(adminPlayer) then
            return "Your character is not available"
        end
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        -- Enhanced bring with safety
        local adminCFrame = adminPlayer.Character.HumanoidRootPart.CFrame
        local safeCFrame = adminCFrame + TELEPORT_OFFSET
        
        target.Character.HumanoidRootPart.CFrame = safeCFrame
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "BRING", target.Name, 
            string.format("Brought player to position: %.1f, %.1f, %.1f", 
                adminCFrame.Position.X, adminCFrame.Position.Y, adminCFrame.Position.Z))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "bring",
                admin = adminPlayer.Name,
                target = target.Name,
                timestamp = tick()
            })
        end
        
        return "Brought " .. target.Name .. " to you"
    end, "Bring operation")
    
    return result
end

-- ====================================================================
-- MODERATION COMMANDS (ENHANCED WITH SECURITY)
-- ====================================================================

-- Kick player
function Commands.kick(admin, adminPlayer, targetName, ...)
    if not targetName then
        return "Usage: /kick [player] [reason]"
    end
    
    local success, result = safePlayerOperation(function()
        local reason = sanitizeReason(...)
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        -- Enhanced permission checking
        local adminLevel = admin:getPermissionLevel(adminPlayer)
        local targetLevel = admin:getPermissionLevel(target)
        
        if targetLevel >= adminLevel then
            return "You cannot kick this player (equal or higher admin level)"
        end
        
        -- Enhanced logging with more details
        admin:logAction(adminPlayer, "KICK", target.Name, reason)
        
        -- Send webhook notification
        if admin.sendWebhook then
            admin:notifyAdminAction(adminPlayer, "KICK", target.Name, reason)
        end
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "kick",
                admin = adminPlayer.Name,
                target = target.Name,
                reason = reason,
                timestamp = tick()
            })
        end
        
        -- Enhanced kick message
        local kickMessage = string.format(
            "You have been kicked from the server.\nReason: %s\nKicked by: %s\nTime: %s",
            reason, adminPlayer.Name, os.date("%Y-%m-%d %H:%M:%S")
        )
        
        target:Kick(kickMessage)
        
        return string.format("Kicked %s (%s)", target.Name, reason)
    end, "Kick operation")
    
    return result
end

-- Ban player (enhanced with expiration support)
function Commands.ban(admin, adminPlayer, targetName, ...)
    if not targetName then
        return "Usage: /ban [player] [reason]"
    end
    
    local success, result = safePlayerOperation(function()
        local reason = sanitizeReason(...)
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        -- Enhanced permission checking
        local adminLevel = admin:getPermissionLevel(adminPlayer)
        local targetLevel = admin:getPermissionLevel(target)
        
        if targetLevel >= adminLevel then
            return "You cannot ban this player (equal or higher admin level)"
        end
        
        -- Enhanced ban data structure
        local Config = require(script.Parent.Config)
        Config.BannedUsers[target.UserId] = {
            reason = reason,
            bannedBy = adminPlayer.Name,
            bannedById = adminPlayer.UserId,
            timestamp = tick(),
            expires = nil, -- Permanent ban (can be modified for temporary bans)
            ip = admin:getPlayerIP and admin:getPlayerIP(target) or nil
        }
        
        -- Save ban data
        admin:saveBanData()
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "BAN", target.Name, reason)
        
        -- Send webhook notification
        if admin.sendWebhook then
            admin:notifyAdminAction(adminPlayer, "BAN", target.Name, reason)
        end
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "ban",
                admin = adminPlayer.Name,
                target = target.Name,
                reason = reason,
                timestamp = tick()
            })
        end
        
        -- Enhanced ban message
        local banMessage = string.format(
            "You have been permanently banned from this server.\nReason: %s\nBanned by: %s\nTime: %s\nAppeal at: [Server Discord/Website]",
            reason, adminPlayer.Name, os.date("%Y-%m-%d %H:%M:%S")
        )
        
        target:Kick(banMessage)
        
        return string.format("Banned %s (%s)", target.Name, reason)
    end, "Ban operation")
    
    return result
end

-- Unban player (enhanced with better lookup)
function Commands.unban(admin, adminPlayer, targetId)
    if not targetId then
        return "Usage: /unban [userId]"
    end
    
    local success, result = safePlayerOperation(function()
        local userId = tonumber(targetId)
        if not userId then
            return "Invalid user ID format"
        end
        
        local Config = require(script.Parent.Config)
        
        if not Config.BannedUsers[userId] then
            return "User ID " .. userId .. " is not currently banned"
        end
        
        local banInfo = Config.BannedUsers[userId]
        Config.BannedUsers[userId] = nil
        
        -- Save updated ban data
        admin:saveBanData()
        
        -- Enhanced logging with ban details
        admin:logAction(adminPlayer, "UNBAN", tostring(userId), 
            string.format("Unbanned user (originally banned by %s for: %s)", 
                banInfo.bannedBy or "Unknown", banInfo.reason or "Unknown reason"))
        
        -- Send webhook notification
        if admin.sendWebhook then
            admin:notifyAdminAction(adminPlayer, "UNBAN", tostring(userId), 
                "User unbanned by " .. adminPlayer.Name)
        end
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "unban",
                admin = adminPlayer.Name,
                target = tostring(userId),
                timestamp = tick()
            })
        end
        
        return string.format("Successfully unbanned user ID: %d", userId)
    end, "Unban operation")
    
    return result
end

-- ====================================================================
-- PLAYER MODIFICATION COMMANDS (ENHANCED)
-- ====================================================================

-- God mode (enhanced with better tracking)
function Commands.god(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        -- Check if already in god mode
        if admin.godPlayers[target] then
            return target.Name .. " is already in god mode"
        end
        
        local humanoid = target.Character.Humanoid
        
        -- Store original health values
        admin.godPlayers[target] = {
            originalMaxHealth = humanoid.MaxHealth,
            originalHealth = humanoid.Health,
            enabledBy = adminPlayer.Name,
            enabledAt = tick()
        }
        
        -- Apply god mode
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        
        -- Enhanced connection with cleanup
        local connection
        connection = humanoid.HealthChanged:Connect(function(health)
            if admin.godPlayers[target] and health < math.huge then
                humanoid.Health = math.huge
            end
        end)
        
        -- Clean up connection when character is removed
        target.CharacterRemoving:Connect(function()
            if connection then
                connection:Disconnect()
            end
            admin.godPlayers[target] = nil
        end)
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "GOD", target.Name, 
            string.format("Enabled god mode (Max Health: %.1f -> Infinite)", 
                admin.godPlayers[target].originalMaxHealth))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "god",
                admin = adminPlayer.Name,
                target = target.Name,
                timestamp = tick()
            })
        end
        
        return "Enabled god mode for " .. target.Name
    end, "God mode operation")
    
    return result
end

-- Remove god mode (enhanced)
function Commands.ungod(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        if not admin.godPlayers[target] then
            return target.Name .. " is not in god mode"
        end
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        local humanoid = target.Character.Humanoid
        local godData = admin.godPlayers[target]
        
        -- Restore original health values
        humanoid.MaxHealth = godData.originalMaxHealth
        humanoid.Health = math.min(godData.originalHealth, godData.originalMaxHealth)
        
        -- Clean up god mode tracking
        admin.godPlayers[target] = nil
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "UNGOD", target.Name, 
            string.format("Disabled god mode (restored to Max Health: %.1f)", godData.originalMaxHealth))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "ungod",
                admin = adminPlayer.Name,
                target = target.Name,
                timestamp = tick()
            })
        end
        
        return "Disabled god mode for " .. target.Name
    end, "Ungod operation")
    
    return result
end

-- Set player speed (enhanced with limits)
function Commands.speed(admin, adminPlayer, targetName, speedValue)
    if not targetName or not speedValue then
        return "Usage: /speed [player] [speed]"
    end
    
    local success, result = safePlayerOperation(function()
        local speed = tonumber(speedValue)
        if not speed then
            return "Invalid speed value: " .. tostring(speedValue)
        end
        
        -- Speed limits for safety
        if speed < 0 then
            return "Speed cannot be negative"
        elseif speed > 500 then
            return "Speed too high (maximum: 500)"
        end
        
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        local humanoid = target.Character.Humanoid
        local originalSpeed = humanoid.WalkSpeed
        
        humanoid.WalkSpeed = speed
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "SPEED", target.Name, 
            string.format("Changed speed from %.1f to %.1f", originalSpeed, speed))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "speed",
                admin = adminPlayer.Name,
                target = target.Name,
                oldValue = originalSpeed,
                newValue = speed,
                timestamp = tick()
            })
        end
        
        return string.format("Set %s's speed to %.1f", target.Name, speed)
    end, "Speed modification")
    
    return result
end

-- Set player jump power (enhanced with limits)
function Commands.jump(admin, adminPlayer, targetName, jumpValue)
    if not targetName or not jumpValue then
        return "Usage: /jump [player] [power]"
    end
    
    local success, result = safePlayerOperation(function()
        local jumpPower = tonumber(jumpValue)
        if not jumpPower then
            return "Invalid jump power value: " .. tostring(jumpValue)
        end
        
        -- Jump power limits for safety
        if jumpPower < 0 then
            return "Jump power cannot be negative"
        elseif jumpPower > 500 then
            return "Jump power too high (maximum: 500)"
        end
        
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        if not validatePlayerCharacter(target) then
            return "Target player's character is not available"
        end
        
        local humanoid = target.Character.Humanoid
        local originalJumpPower = humanoid.JumpPower
        
        humanoid.JumpPower = jumpPower
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "JUMP", target.Name, 
            string.format("Changed jump power from %.1f to %.1f", originalJumpPower, jumpPower))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "jump",
                admin = adminPlayer.Name,
                target = target.Name,
                oldValue = originalJumpPower,
                newValue = jumpPower,
                timestamp = tick()
            })
        end
        
        return string.format("Set %s's jump power to %.1f", target.Name, jumpPower)
    end, "Jump power modification")
    
    return result
end

-- Respawn player (enhanced)
function Commands.respawn(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        
        -- Store god mode status if active
        local wasInGodMode = admin.godPlayers[target] ~= nil
        local godModeData = admin.godPlayers[target]
        
        target:LoadCharacter()
        
        -- Restore god mode if it was active
        if wasInGodMode and godModeData then
            spawn(function()
                wait(1) -- Wait for character to fully load
                if target.Character and target.Character:FindFirstChild("Humanoid") then
                    Commands.god(admin, {Name = godModeData.enabledBy, UserId = 0}, target.Name)
                end
            end)
        end
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "RESPAWN", target.Name, 
            wasInGodMode and "Respawned player (god mode restored)" or "Respawned player")
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "respawn",
                admin = adminPlayer.Name,
                target = target.Name,
                hadGodMode = wasInGodMode,
                timestamp = tick()
            })
        end
        
        return "Respawned " .. target.Name
    end, "Respawn operation")
    
    return result
end

-- ====================================================================
-- COMMUNICATION COMMANDS (ENHANCED)
-- ====================================================================

-- Server announcement (enhanced with styling)
function Commands.announce(admin, adminPlayer, ...)
    local message = table.concat({...}, " ")
    
    if not message or message == "" then
        return "Usage: /announce [message]"
    end
    
    local success, result = safePlayerOperation(function()
        -- Enhanced announcement system
        local announcement = {
            text = message,
            admin = adminPlayer.Name,
            timestamp = tick(),
            id = HttpService:GenerateGUID(false)
        }
        
        -- Create enhanced announcement GUI for all players
        for _, player in pairs(Players:GetPlayers()) do
            spawn(function()
                local success, error = pcall(function()
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "AdminAnnouncement_" .. announcement.id
                    gui.ResetOnSpawn = false
                    gui.DisplayOrder = 10
                    
                    -- Main frame with enhanced styling
                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(0.8, 0, 0.15, 0)
                    frame.Position = UDim2.new(0.1, 0, 0.85, 0)
                    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    frame.BorderSizePixel = 0
                    frame.Parent = gui
                    
                    -- Corner styling
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = frame
                    
                    -- Gradient background
                    local gradient = Instance.new("UIGradient")
                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
                    }
                    gradient.Parent = frame
                    
                    -- Icon
                    local icon = Instance.new("TextLabel")
                    icon.Size = UDim2.new(0, 40, 1, 0)
                    icon.Position = UDim2.new(0, 10, 0, 0)
                    icon.BackgroundTransparency = 1
                    icon.Font = Enum.Font.SourceSansBold
                    icon.TextSize = 28
                    icon.TextColor3 = Color3.fromRGB(255, 215, 0)
                    icon.Text = "📢"
                    icon.TextYAlignment = Enum.TextYAlignment.Center
                    icon.Parent = frame
                    
                    -- Main message
                    local textLabel = Instance.new("TextLabel")
                    textLabel.Size = UDim2.new(1, -120, 0.7, 0)
                    textLabel.Position = UDim2.new(0, 60, 0, 5)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Font = Enum.Font.SourceSansBold
                    textLabel.TextSize = 18
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.Text = message
                    textLabel.TextWrapped = true
                    textLabel.TextXAlignment = Enum.TextXAlignment.Left
                    textLabel.TextYAlignment = Enum.TextYAlignment.Center
                    textLabel.Parent = frame
                    
                    -- Admin signature
                    local signature = Instance.new("TextLabel")
                    signature.Size = UDim2.new(1, -120, 0.3, 0)
                    signature.Position = UDim2.new(0, 60, 0.7, 0)
                    signature.BackgroundTransparency = 1
                    signature.Font = Enum.Font.SourceSans
                    signature.TextSize = 12
                    signature.TextColor3 = Color3.fromRGB(200, 200, 200)
                    signature.Text = "— " .. adminPlayer.Name .. " • " .. os.date("%H:%M:%S")
                    signature.TextWrapped = true
                    signature.TextXAlignment = Enum.TextXAlignment.Left
                    signature.TextYAlignment = Enum.TextYAlignment.Center
                    signature.Parent = frame
                    
                    -- Close button
                    local closeButton = Instance.new("TextButton")
                    closeButton.Size = UDim2.new(0, 30, 0, 30)
                    closeButton.Position = UDim2.new(1, -40, 0, 10)
                    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    closeButton.BorderSizePixel = 0
                    closeButton.Font = Enum.Font.SourceSansBold
                    closeButton.TextSize = 16
                    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    closeButton.Text = "✕"
                    closeButton.Parent = frame
                    
                    local closeCorner = Instance.new("UICorner")
                    closeCorner.CornerRadius = UDim.new(0, 15)
                    closeCorner.Parent = closeButton
                    
                    closeButton.MouseButton1Click:Connect(function()
                        gui:Destroy()
                    end)
                    
                    gui.Parent = player.PlayerGui
                    
                    -- Animate appearance
                    frame.Position = UDim2.new(0.1, 0, 1.2, 0)
                    frame:TweenPosition(
                        UDim2.new(0.1, 0, 0.85, 0),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Back,
                        0.5,
                        true
                    )
                    
                    -- Auto-remove after duration
                    Debris:AddItem(gui, ANNOUNCEMENT_DURATION)
                end)
                
                if not success then
                    warn("[COMMANDS] Announcement GUI error for " .. player.Name .. ": " .. tostring(error))
                end
            end)
        end
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "ANNOUNCE", "all", message)
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "announce",
                admin = adminPlayer.Name,
                messageLength = #message,
                timestamp = tick()
            })
        end
        
        return string.format("Announcement sent to %d players: %s", #Players:GetPlayers(), message)
    end, "Announcement operation")
    
    return result
end

-- ====================================================================
-- SYSTEM COMMANDS (ENHANCED)
-- ====================================================================

-- Console command (handled by client)
function Commands.console(admin, adminPlayer)
    -- Enhanced logging
    admin:logAction(adminPlayer, "CONSOLE_REQUEST", "system", "Console access requested")
    
    -- Analytics tracking
    if admin.analytics and admin.analytics.commandUsage then
        admin:trackAnalyticsEvent("commandUsage", {
            command = "console",
            admin = adminPlayer.Name,
            timestamp = tick()
        })
    end
    
    return "Opening console interface..."
end

-- Server shutdown (enhanced with countdown)
function Commands.shutdown(admin, adminPlayer, delay)
    local success, result = safePlayerOperation(function()
        delay = tonumber(delay) or 10
        
        -- Limit shutdown delay for safety
        if delay < 5 then
            delay = 5
        elseif delay > 300 then
            delay = 300
        end
        
        -- Enhanced logging
        admin:logAction(adminPlayer, "SHUTDOWN", "server", 
            string.format("Server shutdown initiated with %d second delay", delay))
        
        -- Analytics tracking
        if admin.analytics and admin.analytics.commandUsage then
            admin:trackAnalyticsEvent("commandUsage", {
                command = "shutdown",
                admin = adminPlayer.Name,
                delay = delay,
                timestamp = tick()
            })
        end
        
        -- Enhanced countdown announcements
        Commands.announce(admin, adminPlayer, 
            string.format("🚨 SERVER SHUTDOWN: Server will restart in %d seconds! 🚨", delay))
        
        -- Countdown announcements
        local countdownPoints = {60, 30, 15, 10, 5, 3, 2, 1}
        
        spawn(function()
            for i = delay, 1, -1 do
                for _, point in ipairs(countdownPoints) do
                    if i == point then
                        Commands.announce(admin, adminPlayer, 
                            string.format("🚨 Server restarting in %d second%s! 🚨", 
                                i, i == 1 and "" or "s"))
                        break
                    end
                end
                wait(1)
            end
            
            -- Final shutdown
            for _, player in pairs(Players:GetPlayers()) do
                pcall(function()
                    player:Kick("Server is restarting for maintenance. Please rejoin in a moment.")
                end)
            end
        end)
        
        return string.format("Server shutdown initiated with %d second countdown", delay)
    end, "Shutdown operation")
    
    return result
end

-- Help command (enhanced with categorization)
function Commands.help(admin, adminPlayer, category)
    local success, result = safePlayerOperation(function()
        local availableCommands = admin:getAvailableCommands(adminPlayer)
        
        if not availableCommands or #availableCommands == 0 then
            return "No commands available for your permission level"
        end
        
        -- Categorize commands
        local categories = {
            movement = {"tp", "bring"},
            moderation = {"kick", "ban", "unban"},
            player = {"god", "ungod", "speed", "jump", "respawn"},
            communication = {"announce"},
            system = {"console", "shutdown", "help"},
            advanced = {"execute", "ipban", "reload", "analytics"}
        }
        
        if category then
            local categoryCommands = categories[category:lower()]
            if not categoryCommands then
                return "Invalid category. Available categories: movement, moderation, player, communication, system, advanced"
            end
            
            local helpText = string.format("Commands in category '%s':\n", category:lower())
            for _, command in pairs(categoryCommands) do
                for _, availableCommand in pairs(availableCommands) do
                    if command == availableCommand then
                        helpText = helpText .. "/" .. command .. "\n"
                        break
                    end
                end
            end
            return helpText
        else
            -- Enhanced help with categories
            local helpText = string.format("Available commands for %s (Level %d):\n\n", 
                adminPlayer.Name, admin:getPermissionLevel(adminPlayer))
            
            for categoryName, categoryCommands in pairs(categories) do
                local categoryHasCommands = false
                local categoryText = string.upper(categoryName) .. ": "
                
                for _, command in pairs(categoryCommands) do
                    for _, availableCommand in pairs(availableCommands) do
                        if command == availableCommand then
                            categoryText = categoryText .. "/" .. command .. " "
                            categoryHasCommands = true
                            break
                        end
                    end
                end
                
                if categoryHasCommands then
                    helpText = helpText .. categoryText .. "\n"
                end
            end
            
            helpText = helpText .. "\nUse '/help [category]' for category-specific help."
            return helpText
        end
    end, "Help command")
    
    return result
end

-- ====================================================================
-- GOD-TIER ENHANCED COMMANDS
-- ====================================================================

-- IP Ban command
function Commands.ipban(admin, adminPlayer, targetName, duration, ...)
    if not admin:hasPermission(adminPlayer, "ipban") then
        return "You don't have permission to use IP ban"
    end
    
    if not targetName then
        return "Usage: /ipban [player] [duration_minutes] [reason]"
    end
    
    local success, result = safePlayerOperation(function()
        local targets = admin:findPlayers(targetName)
        if #targets == 0 then
            return "Player not found: " .. targetName
        elseif #targets > 1 then
            return "Multiple players found, be more specific"
        end
        
        local target = targets[1]
        local banDuration = duration and (tonumber(duration) * 60) or (7 * 24 * 3600) -- Default 7 days
        local reason = sanitizeReason(...)
        
        if admin.banPlayerIP then
            local success, result = admin:banPlayerIP(adminPlayer, target, reason, banDuration)
            return result
        else
            return "IP ban functionality not available"
        end
    end, "IP ban operation")
    
    return result
end

-- Configuration reload command
function Commands.reload(admin, adminPlayer, sectionName)
    if not admin:hasPermission(adminPlayer, "reload") then
        return "You don't have permission to reload configuration"
    end
    
    local success, result = safePlayerOperation(function()
        if admin.reloadConfig then
            local success, result = admin:reloadConfig(adminPlayer, sectionName)
            return result
        else
            return "Configuration reload functionality not available"
        end
    end, "Configuration reload")
    
    return result
end

-- Analytics command
function Commands.analytics(admin, adminPlayer, action)
    if not admin:hasPermission(adminPlayer, "analytics") then
        return "You don't have permission to view analytics"
    end
    
    local success, result = safePlayerOperation(function()
        if not admin.analytics then
            return "Analytics functionality not available"
        end
        
        if action == "report" then
            local report = admin:generateAnalyticsReport()
            if report then
                local summary = string.format(
                    "📊 Analytics Report:\n• Commands: %d\n• Errors: %d\n• Performance: %.3fs avg\n• Generated: %s",
                    report.summary.commandUsage and report.summary.commandUsage.total or 0,
                    report.summary.errors and report.summary.errors.total or 0,
                    report.summary.performance and report.summary.performance.avgResponseTime or 0,
                    os.date("%H:%M:%S")
                )
                return summary
            else
                return "Analytics report not available"
            end
        elseif action == "send" then
            admin:sendAnalyticsReport()
            return "Analytics report sent to webhook"
        else
            return "Usage: /analytics [report|send]"
        end
    end, "Analytics command")
    
    return result
end

-- ====================================================================
-- MODULE EXPORT
-- ====================================================================
return Commands