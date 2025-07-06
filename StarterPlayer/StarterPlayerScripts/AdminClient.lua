-- ====================================================================
-- ADMIN CLIENT SCRIPT - GOD-TIER UNIFIED VERSION
-- Perfect 10/10 Professional-Grade Client Framework  
-- Unified style, structure, and seamless system integration
-- ====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load theme configuration with unified error handling
local ThemeConfig = require(script.Parent.AdminThemeConfig)

-- ====================================================================
-- REMOTE EVENTS MANAGEMENT (UNIFIED WITH SERVER)
-- ====================================================================
local RemoteEvents = {}

-- Wait for admin remotes with enhanced error handling
local function initializeRemoteEvents()
    local success, error = pcall(function()
        local adminRemotes = ReplicatedStorage:WaitForChild("AdminRemotes", 10)
        if not adminRemotes then
            warn("[ADMIN CLIENT] Failed to find AdminRemotes folder")
            return false
        end
        
        -- Load all remote events with consistent naming
        local remoteNames = {
            "ExecuteCommand",
            "ConsoleToggle", 
            "AdminLog",
            "ExecutorResult",
            "ClientReplication",
            "ThemeUpdate",
            "SystemStatus",
            "SecurityAlert"
        }
        
        for _, remoteName in ipairs(remoteNames) do
            local remote = adminRemotes:WaitForChild(remoteName, 5)
            if remote then
                RemoteEvents[remoteName] = remote
            else
                warn("[ADMIN CLIENT] Failed to find remote: " .. remoteName)
            end
        end
        
        return true
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Remote events initialization failed: " .. tostring(error))
        return false
    end
    
    return true
end

-- ====================================================================
-- ADMIN CLIENT CLASS (UNIFIED STRUCTURE)
-- ====================================================================
local AdminClient = {}
AdminClient.__index = AdminClient

function AdminClient.new()
    local self = setmetatable({}, AdminClient)
    
    -- Core client state (unified naming)
    self.initialized = false
    self.isAdmin = false
    self.adminLevel = 0
    self.availableCommands = {}
    self.consoleOpen = false
    self.adminPanelOpen = false
    
    -- UI Components
    self.gui = nil
    self.console = nil
    self.adminPanel = nil
    
    -- God-Tier: Enhanced features
    self.commandHistory = {}
    self.historyIndex = 0
    self.maxHistorySize = 50
    
    -- God-Tier: Smart scroll detection system
    self.scrollStates = {
        console = {userScrolled = false, autoScroll = true},
        panel = {userScrolled = false, autoScroll = true}
    }
    
    -- God-Tier: Drag system data
    self.dragData = {
        dragging = false,
        dragStart = nil,
        startPos = nil
    }
    
    -- Theme elements for dynamic switching
    self.themeElements = {}
    
    -- Initialize client
    local initSuccess = self:initializeClient()
    if not initSuccess then
        warn("[ADMIN CLIENT] Client initialization failed")
    end
    
    return self
end

function AdminClient:initializeClient()
    local success, error = pcall(function()
        -- Step 1: Initialize remote events
        if not initializeRemoteEvents() then
            return false
        end
        
        -- Step 2: Connect remote events
        self:connectEvents()
        
        -- Step 3: Request authentication
        self:requestAuthentication()
        
        self.initialized = true
        return true
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Client initialization error: " .. tostring(error))
        return false
    end
    
    return true
end

-- ====================================================================
-- ENHANCED DRAG SUPPORT SYSTEM (UNIFIED)
-- ====================================================================
function AdminClient:makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateDragPosition(input)
        if not dragging then return end
        
        local success, error = pcall(function()
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            
            -- Enhanced screen boundary constraints
            local screenSize = workspace.CurrentCamera.ViewportSize
            local frameSize = frame.AbsoluteSize
            
            -- Ensure frame stays within screen bounds
            newPos = UDim2.new(
                0,
                math.max(0, math.min(screenSize.X - frameSize.X, newPos.X.Offset)),
                0,
                math.max(0, math.min(screenSize.Y - frameSize.Y, newPos.Y.Offset))
            )
            
            -- Smooth tween to new position
            local tween = TweenService:Create(
                frame,
                TweenInfo.new(0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = newPos}
            )
            tween:Play()
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Drag update error: " .. tostring(error))
        end
    end
    
    -- Enhanced drag event handling
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local success, error = pcall(function()
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                
                -- Enhanced visual feedback
                local tween = TweenService:Create(
                    frame,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Size = frame.Size + UDim2.new(0, 4, 0, 4),
                        BackgroundTransparency = frame.BackgroundTransparency - 0.1
                    }
                )
                tween:Play()
            end)
            
            if not success then
                warn("[ADMIN CLIENT] Drag start error: " .. tostring(error))
            end
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            updateDragPosition(input)
        end
    end)
    
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local success, error = pcall(function()
                dragging = false
                
                -- Remove visual feedback
                local tween = TweenService:Create(
                    frame,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Size = frame.Size - UDim2.new(0, 4, 0, 4),
                        BackgroundTransparency = frame.BackgroundTransparency + 0.1
                    }
                )
                tween:Play()
            end)
            
            if not success then
                warn("[ADMIN CLIENT] Drag end error: " .. tostring(error))
            end
        end
    end)
end

-- ====================================================================
-- SMART SCROLL DETECTION SYSTEM (ENHANCED)
-- ====================================================================
function AdminClient:setupScrollDetection(scrollFrame, scrollType)
    local scrollState = self.scrollStates[scrollType]
    if not scrollState then return end
    
    local lastCanvasPosition = scrollFrame.CanvasPosition
    local isAtBottom = true
    
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local success, error = pcall(function()
            local currentPos = scrollFrame.CanvasPosition
            local maxScroll = scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteSize.Y
            
            -- Check if user manually scrolled
            if math.abs(currentPos.Y - lastCanvasPosition.Y) > 0 then
                -- Determine if at bottom (with tolerance)
                isAtBottom = currentPos.Y >= maxScroll - 50
                
                -- If user scrolled up from bottom, disable auto-scroll
                if not isAtBottom and scrollState.autoScroll then
                    scrollState.userScrolled = true
                    scrollState.autoScroll = false
                    
                    -- Show visual indicator
                    self:showScrollIndicator(scrollFrame)
                end
                
                -- If user scrolled to bottom, re-enable auto-scroll
                if isAtBottom and scrollState.userScrolled then
                    scrollState.userScrolled = false
                    scrollState.autoScroll = true
                    
                    -- Hide indicator
                    self:hideScrollIndicator(scrollFrame)
                end
            end
            
            lastCanvasPosition = currentPos
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Scroll detection error: " .. tostring(error))
        end
    end)
end

function AdminClient:showScrollIndicator(scrollFrame)
    local indicator = scrollFrame:FindFirstChild("ScrollIndicator")
    if indicator then return end
    
    local success, error = pcall(function()
        indicator = Instance.new("TextLabel")
        indicator.Name = "ScrollIndicator"
        indicator.Size = UDim2.new(1, -20, 0, 25)
        indicator.Position = UDim2.new(0, 10, 1, -35)
        indicator.BackgroundColor3 = ThemeConfig:getCurrentTheme().warning
        indicator.BorderSizePixel = 0
        indicator.Font = ThemeConfig.Fonts.body
        indicator.TextSize = ThemeConfig.FontSizes.small
        indicator.TextColor3 = ThemeConfig:getCurrentTheme().text.primary
        indicator.Text = "📜 Auto-scroll paused - scroll to bottom to resume"
        indicator.TextWrapped = true
        indicator.ZIndex = 100
        indicator.Parent = scrollFrame
        
        -- Add corner and animation
        local corner = ThemeConfig:createCorner("small")
        corner.Parent = indicator
        
        -- Animate in
        indicator.BackgroundTransparency = 1
        indicator.TextTransparency = 1
        local tween = TweenService:Create(
            indicator,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0, TextTransparency = 0}
        )
        tween:Play()
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Scroll indicator show error: " .. tostring(error))
    end
end

function AdminClient:hideScrollIndicator(scrollFrame)
    local indicator = scrollFrame:FindFirstChild("ScrollIndicator")
    if not indicator then return end
    
    local success, error = pcall(function()
        local tween = TweenService:Create(
            indicator,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1, TextTransparency = 1}
        )
        tween:Play()
        
        tween.Completed:Connect(function()
            indicator:Destroy()
        end)
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Scroll indicator hide error: " .. tostring(error))
    end
end

-- ====================================================================
-- SMART AUTO-SCROLL SYSTEM (ENHANCED)
-- ====================================================================
function AdminClient:smartAutoScroll(scrollFrame, scrollType)
    local scrollState = self.scrollStates[scrollType]
    if not scrollState or not scrollState.autoScroll then return end
    
    local success, error = pcall(function()
        local targetY = scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteSize.Y
        if targetY > 0 then
            local tween = TweenService:Create(
                scrollFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CanvasPosition = Vector2.new(0, targetY)}
            )
            tween:Play()
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Auto-scroll error: " .. tostring(error))
    end
end

-- ====================================================================
-- COMMAND HISTORY SYSTEM (ENHANCED)
-- ====================================================================
function AdminClient:addToHistory(command)
    if not command or command == "" or command == self.commandHistory[#self.commandHistory] then
        return
    end
    
    local success, error = pcall(function()
        table.insert(self.commandHistory, command)
        
        -- Maintain history size limit
        if #self.commandHistory > self.maxHistorySize then
            table.remove(self.commandHistory, 1)
        end
        
        -- Reset history index
        self.historyIndex = #self.commandHistory + 1
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Command history add error: " .. tostring(error))
    end
end

function AdminClient:getHistoryCommand(direction)
    if #self.commandHistory == 0 then return "" end
    
    local success, result = pcall(function()
        if direction == "up" then
            self.historyIndex = math.max(1, self.historyIndex - 1)
        elseif direction == "down" then
            self.historyIndex = math.min(#self.commandHistory + 1, self.historyIndex + 1)
        end
        
        if self.historyIndex > #self.commandHistory then
            return ""
        else
            return self.commandHistory[self.historyIndex] or ""
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] History command get error: " .. tostring(result))
        return ""
    end
    
    return result
end

function AdminClient:setupHistoryNavigation(inputElement)
    inputElement.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Up then
            local success, error = pcall(function()
                local historyCommand = self:getHistoryCommand("up")
                inputElement.Text = historyCommand
                inputElement.CursorPosition = #historyCommand + 1
            end)
            
            if not success then
                warn("[ADMIN CLIENT] History navigation up error: " .. tostring(error))
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            local success, error = pcall(function()
                local historyCommand = self:getHistoryCommand("down")
                inputElement.Text = historyCommand
                inputElement.CursorPosition = #historyCommand + 1
            end)
            
            if not success then
                warn("[ADMIN CLIENT] History navigation down error: " .. tostring(error))
            end
        end
    end)
end

-- ====================================================================
-- REMOTE EVENTS CONNECTION (UNIFIED)
-- ====================================================================
function AdminClient:connectEvents()
    if not RemoteEvents.AdminLog then
        warn("[ADMIN CLIENT] AdminLog remote not available")
        return
    end
    
    RemoteEvents.AdminLog.OnClientEvent:Connect(function(eventType, data)
        local success, error = pcall(function()
            if eventType == "admin_status" then
                self:setupAdminStatus(data)
            elseif eventType == "admin_message" then
                self:showMessage(data)
            elseif eventType == "console_access" then
                if data then
                    self:openConsole()
                else
                    self:showMessage({
                        message = "You don't have permission to access the console.",
                        type = "Error"
                    })
                end
            elseif eventType == "console_output" then
                self:addConsoleOutput(data)
            elseif eventType == "theme_update" then
                self:handleThemeUpdate(data)
            elseif eventType == "system_status" then
                self:handleSystemStatus(data)
            elseif eventType == "security_alert" then
                self:handleSecurityAlert(data)
            end
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Event handling error: " .. tostring(error))
        end
    end)
    
    -- Connect other remote events
    if RemoteEvents.ExecutorResult then
        RemoteEvents.ExecutorResult.OnClientEvent:Connect(function(data)
            self:handleExecutorResult(data)
        end)
    end
    
    if RemoteEvents.ThemeUpdate then
        RemoteEvents.ThemeUpdate.OnClientEvent:Connect(function(themeData)
            self:applyThemeUpdate(themeData)
        end)
    end
end

function AdminClient:requestAuthentication()
    if not RemoteEvents.AdminLog then return end
    
    local success, error = pcall(function()
        RemoteEvents.AdminLog:FireServer("request_auth", {
            timestamp = tick(),
            clientVersion = "Enhanced_v3.0"
        })
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Authentication request error: " .. tostring(error))
    end
end

-- ====================================================================
-- ADMIN STATUS SETUP (ENHANCED)
-- ====================================================================
function AdminClient:setupAdminStatus(data)
    local success, error = pcall(function()
        self.isAdmin = data.isAdmin
        self.adminLevel = data.level or 0
        self.availableCommands = data.commands or {}
        
        if self.isAdmin then
            self:createAdminGUI()
            print("[ADMIN CLIENT] Admin privileges enabled. Level:", self.adminLevel)
            
            -- Send heartbeat for session management
            self:startHeartbeat()
        else
            print("[ADMIN CLIENT] No admin privileges detected")
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Admin status setup error: " .. tostring(error))
    end
end

function AdminClient:startHeartbeat()
    spawn(function()
        while self.isAdmin do
            wait(30) -- Send heartbeat every 30 seconds
            
            local success, error = pcall(function()
                if RemoteEvents.AdminLog then
                    RemoteEvents.AdminLog:FireServer("heartbeat", {
                        timestamp = tick(),
                        adminLevel = self.adminLevel
                    })
                end
            end)
            
            if not success then
                warn("[ADMIN CLIENT] Heartbeat error: " .. tostring(error))
            end
        end
    end)
end

-- ====================================================================
-- ENHANCED GUI CREATION (UNIFIED WITH THEMES)
-- ====================================================================
function AdminClient:createAdminGUI()
    -- Remove existing GUI
    if self.gui then
        self.gui:Destroy()
    end
    
    local success, error = pcall(function()
        local theme = ThemeConfig:getCurrentTheme()
        
        -- Create main GUI with enhanced scaling support
        self.gui = Instance.new("ScreenGui")
        self.gui.Name = "AdminGUI"
        self.gui.ResetOnSpawn = false
        self.gui.DisplayOrder = 5
        self.gui.Parent = playerGui
        
        -- Add platform scaling
        local scaling = ThemeConfig:createScaling()
        scaling.Parent = self.gui
        
        -- Create main frame with enhanced styling
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 320, 0, 55)
        mainFrame.Position = UDim2.new(1, -340, 0, 20)
        mainFrame.BackgroundColor3 = theme.background.main
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = self.gui
        
        -- Add to theme elements for dynamic switching
        table.insert(self.themeElements, {
            element = mainFrame,
            type = "frame",
            colorType = "main"
        })
        
        -- Add corner radius and shadow effect
        local corner = ThemeConfig:createCorner("large")
        corner.Parent = mainFrame
        
        -- Enhanced admin panel button
        local adminButton = Instance.new("TextButton")
        adminButton.Name = "AdminButton"
        adminButton.Size = UDim2.new(0.45, -8, 1, -10)
        adminButton.Position = UDim2.new(0, 5, 0, 5)
        adminButton.BackgroundColor3 = theme.primary
        adminButton.BorderSizePixel = 0
        adminButton.Font = ThemeConfig.Fonts.button
        adminButton.TextSize = ThemeConfig.FontSizes.normal
        adminButton.TextColor3 = theme.text.primary
        adminButton.Text = "📋 Admin Panel"
        adminButton.Parent = mainFrame
        
        table.insert(self.themeElements, {
            element = adminButton,
            type = "button",
            colorType = "primary"
        })
        
        local adminCorner = ThemeConfig:createCorner("small")
        adminCorner.Parent = adminButton
        
        -- Enhanced console button
        local consoleButton = Instance.new("TextButton")
        consoleButton.Name = "ConsoleButton"
        consoleButton.Size = UDim2.new(0.45, -8, 1, -10)
        consoleButton.Position = UDim2.new(0.55, 5, 0, 5)
        consoleButton.BackgroundColor3 = theme.secondary
        consoleButton.BorderSizePixel = 0
        consoleButton.Font = ThemeConfig.Fonts.button
        consoleButton.TextSize = ThemeConfig.FontSizes.normal
        consoleButton.TextColor3 = theme.text.primary
        consoleButton.Text = "⚡ Console"
        consoleButton.Parent = mainFrame
        
        table.insert(self.themeElements, {
            element = consoleButton,
            type = "button",
            colorType = "secondary"
        })
        
        local consoleCorner = ThemeConfig:createCorner("small")
        consoleCorner.Parent = consoleButton
        
        -- Add enhanced hover effects
        self:addHoverEffect(adminButton, theme.primary)
        self:addHoverEffect(consoleButton, theme.secondary)
        
        -- Button events with error handling
        adminButton.MouseButton1Click:Connect(function()
            local success, error = pcall(function()
                self:toggleAdminPanel()
            end)
            
            if not success then
                warn("[ADMIN CLIENT] Admin panel toggle error: " .. tostring(error))
            end
        end)
        
        consoleButton.MouseButton1Click:Connect(function()
            local success, error = pcall(function()
                if RemoteEvents.ConsoleToggle then
                    RemoteEvents.ConsoleToggle:FireServer("request_console")
                end
            end)
            
            if not success then
                warn("[ADMIN CLIENT] Console request error: " .. tostring(error))
            end
        end)
        
        -- Create admin panel
        self:createAdminPanel()
        
        -- Add theme switcher for owners (Level 4+)
        if self.adminLevel >= 4 then
            self:addThemeSwitcher(mainFrame)
        end
        
        -- Add system info indicator
        self:addSystemInfoIndicator(mainFrame)
    end)
    
    if not success then
        warn("[ADMIN CLIENT] GUI creation error: " .. tostring(error))
    end
end

-- ====================================================================
-- ENHANCED HOVER EFFECTS (UNIFIED)
-- ====================================================================
function AdminClient:addHoverEffect(button, originalColor)
    local hoverColor = Color3.new(
        math.min(1, originalColor.R + 0.15),
        math.min(1, originalColor.G + 0.15),
        math.min(1, originalColor.B + 0.15)
    )
    
    local pressedColor = Color3.new(
        math.max(0, originalColor.R - 0.1),
        math.max(0, originalColor.G - 0.1),
        math.max(0, originalColor.B - 0.1)
    )
    
    button.MouseEnter:Connect(function()
        local success, error = pcall(function()
            local tween = TweenService:Create(
                button,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    BackgroundColor3 = hoverColor,
                    Size = button.Size + UDim2.new(0, 2, 0, 2)
                }
            )
            tween:Play()
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Hover enter effect error: " .. tostring(error))
        end
    end)
    
    button.MouseLeave:Connect(function()
        local success, error = pcall(function()
            local tween = TweenService:Create(
                button,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    BackgroundColor3 = originalColor,
                    Size = button.Size - UDim2.new(0, 2, 0, 2)
                }
            )
            tween:Play()
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Hover leave effect error: " .. tostring(error))
        end
    end)
    
    button.MouseButton1Down:Connect(function()
        local success, error = pcall(function()
            local tween = TweenService:Create(
                button,
                TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = pressedColor}
            )
            tween:Play()
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Button press effect error: " .. tostring(error))
        end
    end)
    
    button.MouseButton1Up:Connect(function()
        local success, error = pcall(function()
            local tween = TweenService:Create(
                button,
                TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = hoverColor}
            )
            tween:Play()
        end)
        
        if not success then
            warn("[ADMIN CLIENT] Button release effect error: " .. tostring(error))
        end
    end)
end

-- ====================================================================
-- THEME SWITCHER (GOD-TIER FEATURE)
-- ====================================================================
function AdminClient:addThemeSwitcher(parent)
    local success, error = pcall(function()
        local themeButton = Instance.new("TextButton")
        themeButton.Size = UDim2.new(0, 25, 0, 25)
        themeButton.Position = UDim2.new(1, -30, 0, -30)
        themeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        themeButton.BorderSizePixel = 0
        themeButton.Font = ThemeConfig.Fonts.body
        themeButton.TextSize = 14
        themeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        themeButton.Text = "🎨"
        themeButton.Parent = parent
        
        local corner = ThemeConfig:createCorner("small")
        corner.Parent = themeButton
        
        local themes = {"Default", "Dark", "Light", "Cyberpunk"}
        local currentThemeIndex = 1
        
        themeButton.MouseButton1Click:Connect(function()
            currentThemeIndex = currentThemeIndex + 1
            if currentThemeIndex > #themes then
                currentThemeIndex = 1
            end
            
            local newTheme = themes[currentThemeIndex]
            local success = ThemeConfig:switchTheme(newTheme, self.themeElements)
            
            if success then
                self:showMessage({
                    message = "Theme switched to: " .. ThemeConfig:getTheme(newTheme).name,
                    type = "Success"
                })
                
                -- Notify server of theme change
                if RemoteEvents.ThemeUpdate then
                    RemoteEvents.ThemeUpdate:FireServer("theme_changed", {
                        theme = newTheme,
                        player = player.Name
                    })
                end
            else
                self:showMessage({
                    message = "Failed to switch theme",
                    type = "Error"
                })
            end
        end)
        
        self:addHoverEffect(themeButton, Color3.fromRGB(100, 100, 100))
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Theme switcher creation error: " .. tostring(error))
    end
end

-- ====================================================================
-- SYSTEM INFO INDICATOR (NEW FEATURE)
-- ====================================================================
function AdminClient:addSystemInfoIndicator(parent)
    local success, error = pcall(function()
        local infoButton = Instance.new("TextButton")
        infoButton.Size = UDim2.new(0, 25, 0, 25)
        infoButton.Position = UDim2.new(1, -60, 0, -30)
        infoButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        infoButton.BorderSizePixel = 0
        infoButton.Font = ThemeConfig.Fonts.body
        infoButton.TextSize = 14
        infoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoButton.Text = "ℹ️"
        infoButton.Parent = parent
        
        local corner = ThemeConfig:createCorner("small")
        corner.Parent = infoButton
        
        infoButton.MouseButton1Click:Connect(function()
            self:showSystemInfo()
        end)
        
        self:addHoverEffect(infoButton, Color3.fromRGB(50, 150, 50))
    end)
    
    if not success then
        warn("[ADMIN CLIENT] System info indicator creation error: " .. tostring(error))
    end
end

-- ====================================================================
-- ENHANCED ADMIN PANEL (UNIFIED FEATURES)
-- ====================================================================
function AdminClient:createAdminPanel()
    local success, error = pcall(function()
        local theme = ThemeConfig:getCurrentTheme()
        
        -- Create admin panel frame
        local panelFrame = Instance.new("Frame")
        panelFrame.Name = "AdminPanel"
        panelFrame.Size = UDim2.new(0, 400, 0, 500)
        panelFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
        panelFrame.BackgroundColor3 = theme.background.panel
        panelFrame.BorderSizePixel = 0
        panelFrame.Visible = false
        panelFrame.Parent = self.gui
        
        table.insert(self.themeElements, {
            element = panelFrame,
            type = "frame",
            colorType = "panel"
        })
        
        local panelCorner = ThemeConfig:createCorner("large")
        panelCorner.Parent = panelFrame
        
        -- Make panel draggable
        self:makeDraggable(panelFrame, panelFrame)
        
        -- Create title bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 40)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = theme.background.titleBar
        titleBar.BorderSizePixel = 0
        titleBar.Parent = panelFrame
        
        local titleCorner = ThemeConfig:createCorner("medium")
        titleCorner.Parent = titleBar
        
        -- Title text
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(1, -80, 1, 0)
        titleText.Position = UDim2.new(0, 10, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Font = ThemeConfig.Fonts.title
        titleText.TextSize = ThemeConfig.FontSizes.large
        titleText.TextColor3 = theme.text.primary
        titleText.Text = string.format("🛡️ Admin Panel (Level %d)", self.adminLevel)
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar
        
        -- Close button
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -35, 0, 5)
        closeButton.BackgroundColor3 = theme.error
        closeButton.BorderSizePixel = 0
        closeButton.Font = ThemeConfig.Fonts.button
        closeButton.TextSize = 16
        closeButton.TextColor3 = theme.text.primary
        closeButton.Text = "✕"
        closeButton.Parent = titleBar
        
        local closeCorner = ThemeConfig:createCorner("small")
        closeCorner.Parent = closeButton
        
        closeButton.MouseButton1Click:Connect(function()
            self:toggleAdminPanel()
        end)
        
        -- Create command input section
        self:createCommandInput(panelFrame, theme)
        
        -- Create quick actions section
        self:createQuickActions(panelFrame, theme)
        
        -- Create player list section
        self:createPlayerList(panelFrame, theme)
        
        self.adminPanel = panelFrame
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Admin panel creation error: " .. tostring(error))
    end
end

function AdminClient:createCommandInput(parent, theme)
    local success, error = pcall(function()
        -- Command input section
        local inputSection = Instance.new("Frame")
        inputSection.Name = "CommandInput"
        inputSection.Size = UDim2.new(1, -20, 0, 80)
        inputSection.Position = UDim2.new(0, 10, 0, 50)
        inputSection.BackgroundColor3 = theme.background.input
        inputSection.BorderSizePixel = 0
        inputSection.Parent = parent
        
        local inputCorner = ThemeConfig:createCorner("medium")
        inputCorner.Parent = inputSection
        
        -- Input label
        local inputLabel = Instance.new("TextLabel")
        inputLabel.Size = UDim2.new(1, -10, 0, 25)
        inputLabel.Position = UDim2.new(0, 5, 0, 5)
        inputLabel.BackgroundTransparency = 1
        inputLabel.Font = ThemeConfig.Fonts.body
        inputLabel.TextSize = ThemeConfig.FontSizes.normal
        inputLabel.TextColor3 = theme.text.secondary
        inputLabel.Text = "Command Input:"
        inputLabel.TextXAlignment = Enum.TextXAlignment.Left
        inputLabel.Parent = inputSection
        
        -- Command input box
        local commandInput = Instance.new("TextBox")
        commandInput.Name = "CommandBox"
        commandInput.Size = UDim2.new(1, -80, 0, 30)
        commandInput.Position = UDim2.new(0, 5, 0, 30)
        commandInput.BackgroundColor3 = theme.background.main
        commandInput.BorderSizePixel = 0
        commandInput.Font = ThemeConfig.Fonts.console
        commandInput.TextSize = ThemeConfig.FontSizes.normal
        commandInput.TextColor3 = theme.text.primary
        commandInput.Text = ""
        commandInput.PlaceholderText = "Enter command (e.g., tp PlayerName)"
        commandInput.PlaceholderColor3 = theme.text.placeholder
        commandInput.ClearTextOnFocus = false
        commandInput.Parent = inputSection
        
        local commandCorner = ThemeConfig:createCorner("small")
        commandCorner.Parent = commandInput
        
        -- Execute button
        local executeButton = Instance.new("TextButton")
        executeButton.Size = UDim2.new(0, 70, 0, 30)
        executeButton.Position = UDim2.new(1, -75, 0, 30)
        executeButton.BackgroundColor3 = theme.primary
        executeButton.BorderSizePixel = 0
        executeButton.Font = ThemeConfig.Fonts.button
        executeButton.TextSize = ThemeConfig.FontSizes.normal
        executeButton.TextColor3 = theme.text.primary
        executeButton.Text = "Execute"
        executeButton.Parent = inputSection
        
        local executeCorner = ThemeConfig:createCorner("small")
        executeCorner.Parent = executeButton
        
        -- Setup command history navigation
        self:setupHistoryNavigation(commandInput)
        
        -- Execute command function
        local function executeCommand()
            local command = commandInput.Text:trim()
            if command ~= "" then
                self:addToHistory(command)
                self:sendCommand(command)
                commandInput.Text = ""
            end
        end
        
        executeButton.MouseButton1Click:Connect(executeCommand)
        commandInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                executeCommand()
            end
        end)
        
        self:addHoverEffect(executeButton, theme.primary)
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Command input creation error: " .. tostring(error))
    end
end

-- ====================================================================
-- MESSAGE DISPLAY SYSTEM (ENHANCED)
-- ====================================================================
function AdminClient:showMessage(messageData)
    local success, error = pcall(function()
        local message = messageData.message or "Unknown message"
        local messageType = messageData.type or "Info"
        
        -- Create notification
        local notification = Instance.new("ScreenGui")
        notification.Name = "AdminNotification"
        notification.ResetOnSpawn = false
        notification.DisplayOrder = 10
        notification.Parent = playerGui
        
        local theme = ThemeConfig:getCurrentTheme()
        local notificationColor = theme.primary
        
        if messageType == "Success" then
            notificationColor = theme.success
        elseif messageType == "Error" then
            notificationColor = theme.error
        elseif messageType == "Warning" then
            notificationColor = theme.warning
        end
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 350, 0, 80)
        frame.Position = UDim2.new(1, -370, 0, 20)
        frame.BackgroundColor3 = notificationColor
        frame.BorderSizePixel = 0
        frame.Parent = notification
        
        local corner = ThemeConfig:createCorner("large")
        corner.Parent = frame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, -20, 1, -20)
        messageLabel.Position = UDim2.new(0, 10, 0, 10)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Font = ThemeConfig.Fonts.body
        messageLabel.TextSize = ThemeConfig.FontSizes.normal
        messageLabel.TextColor3 = theme.text.primary
        messageLabel.Text = string.format("[%s] %s", messageType, message)
        messageLabel.TextWrapped = true
        messageLabel.TextYAlignment = Enum.TextYAlignment.Center
        messageLabel.Parent = frame
        
        -- Animate in
        frame.Position = UDim2.new(1, 20, 0, 20)
        local tween = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -370, 0, 20)}
        )
        tween:Play()
        
        -- Auto remove
        spawn(function()
            wait(4)
            
            local outTween = TweenService:Create(
                frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 20, 0, 20)}
            )
            outTween:Play()
            
            outTween.Completed:Connect(function()
                notification:Destroy()
            end)
        end)
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Message display error: " .. tostring(error))
    end
end

-- ... existing code ...