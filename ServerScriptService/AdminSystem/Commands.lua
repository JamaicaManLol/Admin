-- Admin Commands Module
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local Commands = {}

-- Teleport to player
function Commands.tp(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /tp [player]"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if adminPlayer.Character and adminPlayer.Character:FindFirstChild("HumanoidRootPart") and
       target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        
        adminPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
        admin:logAction(adminPlayer, "TELEPORT", target.Name, "Teleported to player")
        return "Teleported to " .. target.Name
    else
        return "Character not found for teleportation"
    end
end

-- Bring player to admin
function Commands.bring(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /bring [player]"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if adminPlayer.Character and adminPlayer.Character:FindFirstChild("HumanoidRootPart") and
       target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        
        target.Character.HumanoidRootPart.CFrame = adminPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
        admin:logAction(adminPlayer, "BRING", target.Name, "Brought player to admin")
        return "Brought " .. target.Name .. " to you"
    else
        return "Character not found for teleportation"
    end
end

-- Kick player
function Commands.kick(admin, adminPlayer, targetName, ...)
    if not targetName then
        return "Usage: /kick [player] [reason]"
    end
    
    local reason = table.concat({...}, " ") or "No reason provided"
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    -- Prevent kicking higher level admins
    if admin:getPermissionLevel(target) >= admin:getPermissionLevel(adminPlayer) then
        return "You cannot kick this player (equal or higher admin level)"
    end
    
    admin:logAction(adminPlayer, "KICK", target.Name, reason)
    target:Kick("You have been kicked. Reason: " .. reason)
    
    return "Kicked " .. target.Name .. " (" .. reason .. ")"
end

-- Ban player
function Commands.ban(admin, adminPlayer, targetName, ...)
    if not targetName then
        return "Usage: /ban [player] [reason]"
    end
    
    local reason = table.concat({...}, " ") or "No reason provided"
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    -- Prevent banning higher level admins
    if admin:getPermissionLevel(target) >= admin:getPermissionLevel(adminPlayer) then
        return "You cannot ban this player (equal or higher admin level)"
    end
    
    -- Add to ban list
    local Config = require(script.Parent.Config)
    Config.BannedUsers[target.UserId] = {
        reason = reason,
        bannedBy = adminPlayer.Name,
        timestamp = os.time()
    }
    
    admin:saveBanData()
    admin:logAction(adminPlayer, "BAN", target.Name, reason)
    target:Kick("You have been banned. Reason: " .. reason)
    
    return "Banned " .. target.Name .. " (" .. reason .. ")"
end

-- Unban player
function Commands.unban(admin, adminPlayer, targetId)
    if not targetId then
        return "Usage: /unban [userId]"
    end
    
    local userId = tonumber(targetId)
    if not userId then
        return "Invalid user ID"
    end
    
    local Config = require(script.Parent.Config)
    
    if not Config.BannedUsers[userId] then
        return "User is not banned"
    end
    
    local banInfo = Config.BannedUsers[userId]
    Config.BannedUsers[userId] = nil
    
    admin:saveBanData()
    admin:logAction(adminPlayer, "UNBAN", tostring(userId), "Unbanned user")
    
    return "Unbanned user " .. userId
end

-- God mode
function Commands.god(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("Humanoid") then
        -- Store original max health
        admin.godPlayers[target] = target.Character.Humanoid.MaxHealth
        
        -- Set god mode
        target.Character.Humanoid.MaxHealth = math.huge
        target.Character.Humanoid.Health = math.huge
        
        -- Connect health change prevention
        local connection
        connection = target.Character.Humanoid.HealthChanged:Connect(function(health)
            if admin.godPlayers[target] and health < math.huge then
                target.Character.Humanoid.Health = math.huge
            end
        end)
        
        -- Clean up connection when character is removed
        target.CharacterRemoving:Connect(function()
            if connection then
                connection:Disconnect()
            end
        end)
        
        admin:logAction(adminPlayer, "GOD", target.Name, "Enabled god mode")
        return "Enabled god mode for " .. target.Name
    else
        return "Character not found"
    end
end

-- Remove god mode
function Commands.ungod(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if admin.godPlayers[target] and target.Character and target.Character:FindFirstChild("Humanoid") then
        -- Restore original max health
        target.Character.Humanoid.MaxHealth = admin.godPlayers[target]
        target.Character.Humanoid.Health = admin.godPlayers[target]
        admin.godPlayers[target] = nil
        
        admin:logAction(adminPlayer, "UNGOD", target.Name, "Disabled god mode")
        return "Disabled god mode for " .. target.Name
    else
        return "Player is not in god mode"
    end
end

-- Set player speed
function Commands.speed(admin, adminPlayer, targetName, speedValue)
    if not targetName or not speedValue then
        return "Usage: /speed [player] [speed]"
    end
    
    local speed = tonumber(speedValue)
    if not speed then
        return "Invalid speed value"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("Humanoid") then
        target.Character.Humanoid.WalkSpeed = speed
        admin:logAction(adminPlayer, "SPEED", target.Name, "Set speed to " .. speed)
        return "Set " .. target.Name .. "'s speed to " .. speed
    else
        return "Character not found"
    end
end

-- Set player jump power
function Commands.jump(admin, adminPlayer, targetName, jumpValue)
    if not targetName or not jumpValue then
        return "Usage: /jump [player] [power]"
    end
    
    local jumpPower = tonumber(jumpValue)
    if not jumpPower then
        return "Invalid jump power value"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("Humanoid") then
        target.Character.Humanoid.JumpPower = jumpPower
        admin:logAction(adminPlayer, "JUMP", target.Name, "Set jump power to " .. jumpPower)
        return "Set " .. target.Name .. "'s jump power to " .. jumpPower
    else
        return "Character not found"
    end
end

-- Respawn player
function Commands.respawn(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    target:LoadCharacter()
    
    admin:logAction(adminPlayer, "RESPAWN", target.Name, "Respawned player")
    return "Respawned " .. target.Name
end

-- Server announcement
function Commands.announce(admin, adminPlayer, ...)
    local message = table.concat({...}, " ")
    
    if not message or message == "" then
        return "Usage: /announce [message]"
    end
    
    -- Create announcement GUI for all players
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            local gui = Instance.new("ScreenGui")
            gui.Name = "AdminAnnouncement"
            gui.ResetOnSpawn = false
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0.8, 0, 0.2, 0)
            frame.Position = UDim2.new(0.1, 0, 0.4, 0)
            frame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 24
            textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Text = "📢 ANNOUNCEMENT: " .. message
            textLabel.TextWrapped = true
            textLabel.Parent = frame
            
            gui.Parent = player.PlayerGui
            
            -- Remove after duration
            Debris:AddItem(gui, 8)
        end)
    end
    
    admin:logAction(adminPlayer, "ANNOUNCE", "all", message)
    return "Announcement sent: " .. message
end

-- Open console (handled by client)
function Commands.console(admin, adminPlayer)
    -- This command is handled by the client-side script
    return "Opening console..."
end

-- Server shutdown (owner only)
function Commands.shutdown(admin, adminPlayer, delay)
    delay = tonumber(delay) or 10
    
    admin:logAction(adminPlayer, "SHUTDOWN", "server", "Shutdown in " .. delay .. " seconds")
    
    -- Announce shutdown
    Commands.announce(admin, adminPlayer, "Server shutting down in " .. delay .. " seconds!")
    
    -- Schedule shutdown
    wait(delay)
    
    for _, player in pairs(Players:GetPlayers()) do
        player:Kick("Server is shutting down for maintenance.")
    end
    
    return "Server shutdown initiated"
end

-- Help command
function Commands.help(admin, adminPlayer)
    local availableCommands = admin:getAvailableCommands(adminPlayer)
    local helpText = "Available commands:\n"
    
    for _, command in pairs(availableCommands) do
        helpText = helpText .. "/" .. command .. "\n"
    end
    
    return helpText
end

return Commands