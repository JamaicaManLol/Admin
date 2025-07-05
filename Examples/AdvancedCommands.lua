-- Advanced Admin Commands Example
-- This file shows how to create custom admin commands
-- Add these to your Commands.lua file or create as a separate module

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AdvancedCommands = {}

-- Freeze/Unfreeze player
function AdvancedCommands.freeze(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /freeze [player]"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        target.Character.HumanoidRootPart.Anchored = true
        admin:logAction(adminPlayer, "FREEZE", target.Name, "Player frozen")
        return "Froze " .. target.Name
    else
        return "Character not found"
    end
end

function AdvancedCommands.unfreeze(admin, adminPlayer, targetName)
    if not targetName then
        return "Usage: /unfreeze [player]"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        target.Character.HumanoidRootPart.Anchored = false
        admin:logAction(adminPlayer, "UNFREEZE", target.Name, "Player unfrozen")
        return "Unfroze " .. target.Name
    else
        return "Character not found"
    end
end

-- Invisible/Visible player
function AdvancedCommands.invisible(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character then
        for _, part in pairs(target.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 1
            elseif part:IsA("Accessory") then
                part.Handle.Transparency = 1
            end
        end
        
        admin:logAction(adminPlayer, "INVISIBLE", target.Name, "Made player invisible")
        return "Made " .. target.Name .. " invisible"
    else
        return "Character not found"
    end
end

function AdvancedCommands.visible(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character then
        for _, part in pairs(target.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            elseif part:IsA("Accessory") then
                part.Handle.Transparency = 0
            end
        end
        
        admin:logAction(adminPlayer, "VISIBLE", target.Name, "Made player visible")
        return "Made " .. target.Name .. " visible"
    else
        return "Character not found"
    end
end

-- Change player size
function AdvancedCommands.size(admin, adminPlayer, targetName, sizeValue)
    if not targetName or not sizeValue then
        return "Usage: /size [player] [scale]"
    end
    
    local scale = tonumber(sizeValue)
    if not scale or scale <= 0 then
        return "Invalid size value (must be positive number)"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("Humanoid") then
        local humanoid = target.Character.Humanoid
        
        -- Scale the character
        for _, part in pairs(target.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Size = part.Size * scale
            end
        end
        
        -- Adjust walk speed proportionally
        humanoid.WalkSpeed = humanoid.WalkSpeed * scale
        humanoid.JumpPower = humanoid.JumpPower * scale
        
        admin:logAction(adminPlayer, "SIZE", target.Name, "Scaled to " .. scale)
        return "Scaled " .. target.Name .. " to " .. scale .. "x size"
    else
        return "Character not found"
    end
end

-- Lighting controls
function AdvancedCommands.time(admin, adminPlayer, timeValue)
    if not timeValue then
        return "Usage: /time [0-24]"
    end
    
    local time = tonumber(timeValue)
    if not time or time < 0 or time > 24 then
        return "Invalid time value (0-24)"
    end
    
    Lighting.TimeOfDay = string.format("%02d:00:00", time)
    admin:logAction(adminPlayer, "TIME", "lighting", "Set time to " .. time)
    return "Set time to " .. time .. ":00"
end

function AdvancedCommands.brightness(admin, adminPlayer, brightnessValue)
    if not brightnessValue then
        return "Usage: /brightness [0-10]"
    end
    
    local brightness = tonumber(brightnessValue)
    if not brightness or brightness < 0 or brightness > 10 then
        return "Invalid brightness value (0-10)"
    end
    
    Lighting.Brightness = brightness
    admin:logAction(adminPlayer, "BRIGHTNESS", "lighting", "Set brightness to " .. brightness)
    return "Set brightness to " .. brightness
end

-- Weather effects
function AdvancedCommands.fog(admin, adminPlayer, densityValue)
    if not densityValue then
        return "Usage: /fog [0-1]"
    end
    
    local density = tonumber(densityValue)
    if not density or density < 0 or density > 1 then
        return "Invalid fog density (0-1)"
    end
    
    Lighting.FogEnd = 1000 - (density * 900)
    Lighting.FogStart = 0
    admin:logAction(adminPlayer, "FOG", "lighting", "Set fog density to " .. density)
    return "Set fog density to " .. density
end

-- Teleport to coordinates
function AdvancedCommands.tppos(admin, adminPlayer, x, y, z)
    if not x or not y or not z then
        return "Usage: /tppos [x] [y] [z]"
    end
    
    local posX, posY, posZ = tonumber(x), tonumber(y), tonumber(z)
    if not posX or not posY or not posZ then
        return "Invalid coordinates"
    end
    
    if adminPlayer.Character and adminPlayer.Character:FindFirstChild("HumanoidRootPart") then
        adminPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(posX, posY, posZ)
        admin:logAction(adminPlayer, "TPPOS", "coordinates", string.format("(%d,%d,%d)", posX, posY, posZ))
        return string.format("Teleported to (%d, %d, %d)", posX, posY, posZ)
    else
        return "Character not found"
    end
end

-- Give tools/gear
function AdvancedCommands.gear(admin, adminPlayer, targetName, gearId)
    if not targetName or not gearId then
        return "Usage: /gear [player] [gearId]"
    end
    
    local id = tonumber(gearId)
    if not id then
        return "Invalid gear ID"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character then
        local success, gear = pcall(function()
            return game:GetService("InsertService"):LoadAsset(id)
        end)
        
        if success and gear then
            local tool = gear:GetChildren()[1]
            if tool and tool:IsA("Tool") then
                tool.Parent = target.Backpack
                admin:logAction(adminPlayer, "GEAR", target.Name, "Given gear ID " .. id)
                return "Gave gear " .. id .. " to " .. target.Name
            else
                return "Invalid gear ID or not a tool"
            end
        else
            return "Failed to load gear"
        end
    else
        return "Character not found"
    end
end

-- Fly mode
function AdvancedCommands.fly(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = target.Character.HumanoidRootPart
        
        -- Create BodyVelocity for flying
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart
        
        -- Create BodyAngularVelocity for stability
        local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        bodyAngularVelocity.Parent = rootPart
        
        admin:logAction(adminPlayer, "FLY", target.Name, "Enabled fly mode")
        return "Enabled fly mode for " .. target.Name
    else
        return "Character not found"
    end
end

function AdvancedCommands.unfly(admin, adminPlayer, targetName)
    targetName = targetName or adminPlayer.Name
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = target.Character.HumanoidRootPart
        
        -- Remove flying objects
        for _, obj in pairs(rootPart:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") then
                obj:Destroy()
            end
        end
        
        admin:logAction(adminPlayer, "UNFLY", target.Name, "Disabled fly mode")
        return "Disabled fly mode for " .. target.Name
    else
        return "Character not found"
    end
end

-- Team management
function AdvancedCommands.team(admin, adminPlayer, targetName, teamName)
    if not targetName or not teamName then
        return "Usage: /team [player] [teamName]"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    local team = game.Teams:FindFirstChild(teamName)
    
    if not team then
        return "Team not found: " .. teamName
    end
    
    target.Team = team
    admin:logAction(adminPlayer, "TEAM", target.Name, "Moved to team " .. teamName)
    return "Moved " .. target.Name .. " to team " .. teamName
end

-- Server message to specific player
function AdvancedCommands.pm(admin, adminPlayer, targetName, ...)
    if not targetName then
        return "Usage: /pm [player] [message]"
    end
    
    local message = table.concat({...}, " ")
    if not message or message == "" then
        return "Message cannot be empty"
    end
    
    local targets = admin:findPlayers(targetName)
    
    if #targets == 0 then
        return "Player not found: " .. targetName
    elseif #targets > 1 then
        return "Multiple players found, be more specific"
    end
    
    local target = targets[1]
    
    -- Send private message
    local gui = Instance.new("ScreenGui")
    gui.Name = "PrivateMessage"
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0.3, 0)
    frame.Position = UDim2.new(0.2, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 150)
    title.BorderSizePixel = 0
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Private Message from " .. adminPlayer.Name
    title.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0.7, -20)
    messageLabel.Position = UDim2.new(0, 10, 0.3, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 16
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.Parent = frame
    
    gui.Parent = target.PlayerGui
    
    -- Auto-remove after 10 seconds
    game:GetService("Debris"):AddItem(gui, 10)
    
    admin:logAction(adminPlayer, "PM", target.Name, message:sub(1, 50))
    return "Sent private message to " .. target.Name
end

-- How to integrate these commands:
--[[
To add these commands to your admin system:

1. Open ServerScriptService/AdminSystem/Commands.lua
2. Add the functions you want to the Commands table
3. Update Config.lua to set permission levels:

Example:
Config.CommandPermissions = {
    -- ... existing commands ...
    ["freeze"] = 1,
    ["unfreeze"] = 1,
    ["invisible"] = 2,
    ["visible"] = 2,
    ["size"] = 2,
    ["time"] = 2,
    ["brightness"] = 2,
    ["fog"] = 2,
    ["tppos"] = 1,
    ["gear"] = 3,
    ["fly"] = 2,
    ["unfly"] = 2,
    ["team"] = 1,
    ["pm"] = 1
}
--]]

return AdvancedCommands