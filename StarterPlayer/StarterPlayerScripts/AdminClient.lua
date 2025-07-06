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
                        timestamp = os.clock(),
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
        inputSection.Size = UDim2.new(1, -20, 0, 100)
        inputSection.Position = UDim2.new(0, 10, 0, 50)
        inputSection.BackgroundColor3 = theme.background.input
        inputSection.BorderSizePixel = 0
        inputSection.Parent = parent
        
        local inputCorner = ThemeConfig:createCorner("medium")
        inputCorner.Parent = inputSection
        
        -- Input label
        local inputLabel = Instance.new("TextLabel")
        inputLabel.Size = UDim2.new(1, -10, 0, 20)
        inputLabel.Position = UDim2.new(0, 5, 0, 5)
        inputLabel.BackgroundTransparency = 1
        inputLabel.Font = ThemeConfig.Fonts.body
        inputLabel.TextSize = ThemeConfig.FontSizes.normal
        inputLabel.TextColor3 = theme.text.secondary
        inputLabel.Text = "🎯 Quick Command Input:"
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
        commandInput.PlaceholderText = "Enter command (e.g., tp PlayerName, ban UserId reason)"
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
        
        -- Quick action buttons
        local quickActionsFrame = Instance.new("Frame")
        quickActionsFrame.Size = UDim2.new(1, -10, 0, 30)
        quickActionsFrame.Position = UDim2.new(0, 5, 0, 65)
        quickActionsFrame.BackgroundTransparency = 1
        quickActionsFrame.Parent = inputSection
        
        local quickLayout = Instance.new("UIListLayout")
        quickLayout.FillDirection = Enum.FillDirection.Horizontal
        quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        quickLayout.Padding = UDim.new(0, 5)
        quickLayout.Parent = quickActionsFrame
        
        local quickButtons = {
            {text = "Console", color = theme.secondary, command = "console"},
            {text = "Analytics", color = theme.warning, command = "analytics report"},
            {text = "Help", color = theme.success, command = "help"}
        }
        
        for _, buttonData in ipairs(quickButtons) do
            local quickBtn = Instance.new("TextButton")
            quickBtn.Size = UDim2.new(0, 70, 1, 0)
            quickBtn.BackgroundColor3 = buttonData.color
            quickBtn.BorderSizePixel = 0
            quickBtn.Font = ThemeConfig.Fonts.button
            quickBtn.TextSize = ThemeConfig.FontSizes.small
            quickBtn.TextColor3 = theme.text.primary
            quickBtn.Text = buttonData.text
            quickBtn.Parent = quickActionsFrame
            
            local btnCorner = ThemeConfig:createCorner("small")
            btnCorner.Parent = quickBtn
            
            quickBtn.MouseButton1Click:Connect(function()
                if buttonData.command == "console" then
                    if RemoteEvents.ConsoleToggle then
                        RemoteEvents.ConsoleToggle:FireServer("request_console")
                    end
                else
                    self:sendCommand(buttonData.command)
                end
            end)
            
            self:addHoverEffect(quickBtn, buttonData.color)
        end
        
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
-- SECURE EXECUTOR UI (GOD-TIER FEATURE)
-- ====================================================================
function AdminClient:createSecureExecutor()
    local success, error = pcall(function()
        local theme = ThemeConfig:getCurrentTheme()
        
        -- Create secure executor frame
        local executorFrame = Instance.new("Frame")
        executorFrame.Name = "SecureExecutor"
        executorFrame.Size = UDim2.new(0, 600, 0, 450)
        executorFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
        executorFrame.BackgroundColor3 = theme.background.panel
        executorFrame.BorderSizePixel = 0
        executorFrame.Visible = false
        executorFrame.Parent = self.gui
        
        table.insert(self.themeElements, {
            element = executorFrame,
            type = "frame",
            colorType = "panel"
        })
        
        local executorCorner = ThemeConfig:createCorner("large")
        executorCorner.Parent = executorFrame
        
        -- Make executor draggable
        self:makeDraggable(executorFrame, executorFrame)
        
        -- Create title bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 40)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = theme.background.titleBar
        titleBar.BorderSizePixel = 0
        titleBar.Parent = executorFrame
        
        local titleCorner = ThemeConfig:createCorner("medium")
        titleCorner.Parent = titleBar
        
        -- Security indicator
        local securityIndicator = Instance.new("Frame")
        securityIndicator.Size = UDim2.new(0, 20, 0, 20)
        securityIndicator.Position = UDim2.new(0, 10, 0, 10)
        securityIndicator.BackgroundColor3 = theme.success
        securityIndicator.BorderSizePixel = 0
        securityIndicator.Parent = titleBar
        
        local securityCorner = ThemeConfig:createCorner("round")
        securityCorner.Parent = securityIndicator
        
        -- Title text
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(1, -120, 1, 0)
        titleText.Position = UDim2.new(0, 40, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Font = ThemeConfig.Fonts.title
        titleText.TextSize = ThemeConfig.FontSizes.large
        titleText.TextColor3 = theme.text.primary
        titleText.Text = "🛡️ Secure Script Executor (FE Network)"
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
            self:toggleSecureExecutor()
        end)
        
        -- Script type selector
        local selectorFrame = Instance.new("Frame")
        selectorFrame.Size = UDim2.new(1, -20, 0, 40)
        selectorFrame.Position = UDim2.new(0, 10, 0, 50)
        selectorFrame.BackgroundTransparency = 1
        selectorFrame.Parent = executorFrame
        
        local selectorLayout = Instance.new("UIListLayout")
        selectorLayout.FillDirection = Enum.FillDirection.Horizontal
        selectorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        selectorLayout.Padding = UDim.new(0, 10)
        selectorLayout.Parent = selectorFrame
        
        -- Type buttons
        local typeButtons = {
            {name = "LuaScript", text = "📜 Lua Script", description = "Standard Lua with FE replication"},
            {name = "RequireScript", text = "📦 Require Script", description = "ModuleScript execution"},
            {name = "NetworkScript", text = "🌐 Network Script", description = "Multi-client replication"}
        }
        
        local selectedType = "LuaScript"
        local typeButtonElements = {}
        
        for _, buttonData in ipairs(typeButtons) do
            local typeButton = Instance.new("TextButton")
            typeButton.Size = UDim2.new(0, 140, 0, 35)
            typeButton.BackgroundColor3 = buttonData.name == selectedType and theme.primary or theme.background.secondary
            typeButton.BorderSizePixel = 0
            typeButton.Font = ThemeConfig.Fonts.button
            typeButton.TextSize = ThemeConfig.FontSizes.small
            typeButton.TextColor3 = theme.text.primary
            typeButton.Text = buttonData.text
            typeButton.Parent = selectorFrame
            
            local btnCorner = ThemeConfig:createCorner("small")
            btnCorner.Parent = typeButton
            
            typeButtonElements[buttonData.name] = typeButton
            
            typeButton.MouseButton1Click:Connect(function()
                -- Update selection
                for typeName, btn in pairs(typeButtonElements) do
                    btn.BackgroundColor3 = typeName == buttonData.name and theme.primary or theme.background.secondary
                end
                selectedType = buttonData.name
                
                -- Update description
                local descLabel = executorFrame:FindFirstChild("TypeDescription")
                if descLabel then
                    descLabel.Text = "📋 Type: " .. buttonData.description
                end
            end)
            
            self:addHoverEffect(typeButton, typeButton.BackgroundColor3)
        end
        
        -- Type description
        local typeDescription = Instance.new("TextLabel")
        typeDescription.Name = "TypeDescription"
        typeDescription.Size = UDim2.new(1, -20, 0, 25)
        typeDescription.Position = UDim2.new(0, 10, 0, 100)
        typeDescription.BackgroundTransparency = 1
        typeDescription.Font = ThemeConfig.Fonts.body
        typeDescription.TextSize = ThemeConfig.FontSizes.small
        typeDescription.TextColor3 = theme.text.secondary
        typeDescription.Text = "📋 Type: Standard Lua with FE replication"
        typeDescription.TextXAlignment = Enum.TextXAlignment.Left
        typeDescription.Parent = executorFrame
        
        -- Script input area
        local inputFrame = Instance.new("Frame")
        inputFrame.Size = UDim2.new(1, -20, 1, -220)
        inputFrame.Position = UDim2.new(0, 10, 0, 130)
        inputFrame.BackgroundColor3 = theme.background.input
        inputFrame.BorderSizePixel = 0
        inputFrame.Parent = executorFrame
        
        local inputCorner = ThemeConfig:createCorner("medium")
        inputCorner.Parent = inputFrame
        
        -- Script input textbox
        local scriptInput = Instance.new("TextBox")
        scriptInput.Name = "ScriptInput"
        scriptInput.Size = UDim2.new(1, -20, 1, -20)
        scriptInput.Position = UDim2.new(0, 10, 0, 10)
        scriptInput.BackgroundTransparency = 1
        scriptInput.Font = ThemeConfig.Fonts.console
        scriptInput.TextSize = ThemeConfig.FontSizes.normal
        scriptInput.TextColor3 = theme.text.primary
        scriptInput.Text = ""
        scriptInput.PlaceholderText = [[-- Enter your script here...
-- Example: Standard Lua Script
game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 50

-- Example: Require Script
local module = require(script.Parent.MyModule)
module:Initialize()

-- Example: Network Script (FE Compliant)
-- This will replicate to all clients safely]]
        scriptInput.PlaceholderColor3 = theme.text.placeholder
        scriptInput.MultiLine = true
        scriptInput.ClearTextOnFocus = false
        scriptInput.TextXAlignment = Enum.TextXAlignment.Left
        scriptInput.TextYAlignment = Enum.TextYAlignment.Top
        scriptInput.Parent = inputFrame
        
        -- Execution controls
        local controlsFrame = Instance.new("Frame")
        controlsFrame.Size = UDim2.new(1, -20, 0, 60)
        controlsFrame.Position = UDim2.new(0, 10, 1, -70)
        controlsFrame.BackgroundTransparency = 1
        controlsFrame.Parent = executorFrame
        
        local controlsLayout = Instance.new("UIListLayout")
        controlsLayout.FillDirection = Enum.FillDirection.Horizontal
        controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        controlsLayout.Padding = UDim.new(0, 10)
        controlsLayout.Parent = controlsFrame
        
        -- Execute button
        local executeButton = Instance.new("TextButton")
        executeButton.Size = UDim2.new(0, 120, 0, 40)
        executeButton.BackgroundColor3 = theme.success
        executeButton.BorderSizePixel = 0
        executeButton.Font = ThemeConfig.Fonts.button
        executeButton.TextSize = ThemeConfig.FontSizes.normal
        executeButton.TextColor3 = theme.text.primary
        executeButton.Text = "🚀 Execute"
        executeButton.Parent = controlsFrame
        
        local executeCorner = ThemeConfig:createCorner("small")
        executeCorner.Parent = executeButton
        
        -- Clear button
        local clearButton = Instance.new("TextButton")
        clearButton.Size = UDim2.new(0, 100, 0, 40)
        clearButton.BackgroundColor3 = theme.warning
        clearButton.BorderSizePixel = 0
        clearButton.Font = ThemeConfig.Fonts.button
        clearButton.TextSize = ThemeConfig.FontSizes.normal
        clearButton.TextColor3 = theme.text.primary
        clearButton.Text = "🗑️ Clear"
        clearButton.Parent = controlsFrame
        
        local clearCorner = ThemeConfig:createCorner("small")
        clearCorner.Parent = clearButton
        
        -- Validate button
        local validateButton = Instance.new("TextButton")
        validateButton.Size = UDim2.new(0, 100, 0, 40)
        validateButton.BackgroundColor3 = theme.secondary
        validateButton.BorderSizePixel = 0
        validateButton.Font = ThemeConfig.Fonts.button
        validateButton.TextSize = ThemeConfig.FontSizes.normal
        validateButton.TextColor3 = theme.text.primary
        validateButton.Text = "✅ Validate"
        validateButton.Parent = controlsFrame
        
        local validateCorner = ThemeConfig:createCorner("small")
        validateCorner.Parent = validateButton
        
        -- Button event handlers
        executeButton.MouseButton1Click:Connect(function()
            local script = scriptInput.Text:trim()
            if script ~= "" then
                self:executeSecureScript(script, selectedType)
            else
                self:showMessage({
                    message = "Please enter a script to execute",
                    type = "Warning"
                })
            end
        end)
        
        clearButton.MouseButton1Click:Connect(function()
            scriptInput.Text = ""
        end)
        
        validateButton.MouseButton1Click:Connect(function()
            local script = scriptInput.Text:trim()
            if script ~= "" then
                self:validateScript(script, selectedType)
            else
                self:showMessage({
                    message = "Please enter a script to validate",
                    type = "Warning"
                })
            end
        end)
        
        -- Add hover effects
        self:addHoverEffect(executeButton, theme.success)
        self:addHoverEffect(clearButton, theme.warning)
        self:addHoverEffect(validateButton, theme.secondary)
        self:addHoverEffect(closeButton, theme.error)
        
        self.secureExecutor = executorFrame
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Secure executor creation error: " .. tostring(error))
    end
end

function AdminClient:executeSecureScript(script, scriptType)
    local success, error = pcall(function()
        if not RemoteEvents.SecureExecutor then
            self:showMessage({
                message = "Secure executor not available",
                type = "Error"
            })
            return
        end
        
        -- Validate script before execution
        local validationResult = self:validateScriptSyntax(script)
        if not validationResult.valid then
            self:showMessage({
                message = "Script validation failed: " .. validationResult.error,
                type = "Error"
            })
            return
        end
        
        -- Send script for secure execution
        RemoteEvents.SecureExecutor:FireServer("execute_script", {
            script = script,
            scriptType = scriptType,
            feCompliant = true,
            networkAware = scriptType == "NetworkScript"
        })
        
        self:showMessage({
            message = string.format("Executing %s script...", scriptType),
            type = "Success"
        })
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Script execution error: " .. tostring(error))
        self:showMessage({
            message = "Failed to execute script: " .. tostring(error),
            type = "Error"
        })
    end
end

function AdminClient:validateScript(script, scriptType)
    local success, error = pcall(function()
        local validationResult = self:validateScriptSyntax(script)
        
        if validationResult.valid then
            self:showMessage({
                message = string.format("%s script validation passed", scriptType),
                type = "Success"
            })
        else
            self:showMessage({
                message = "Validation failed: " .. validationResult.error,
                type = "Error"
            })
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Script validation error: " .. tostring(error))
    end
end

function AdminClient:validateScriptSyntax(script)
    local success, result = pcall(function()
        -- Basic syntax validation
        local func, syntaxError = loadstring(script)
        if not func then
            return {valid = false, error = syntaxError}
        end
        
        -- Check for dangerous functions (basic security)
        local dangerousFunctions = {
            "getfenv", "setfenv", "debug.getfenv", "debug.setfenv",
            "debug.getupvalue", "debug.setupvalue"
        }
        
        for _, dangerous in ipairs(dangerousFunctions) do
            if script:find(dangerous) then
                return {valid = false, error = "Contains potentially dangerous function: " .. dangerous}
            end
        end
        
        return {valid = true, error = nil}
    end)
    
    if success then
        return result
    else
        return {valid = false, error = "Validation failed: " .. tostring(result)}
    end
end

function AdminClient:toggleSecureExecutor()
    local success, error = pcall(function()
        if not self.secureExecutor then
            self:createSecureExecutor()
        end
        
        if self.secureExecutor then
            self.secureExecutor.Visible = not self.secureExecutor.Visible
            
            if self.secureExecutor.Visible then
                -- Focus on script input when opened
                local scriptInput = self.secureExecutor:FindFirstChild("ScriptInput", true)
                if scriptInput then
                    wait(0.1)
                    scriptInput:CaptureFocus()
                end
            end
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Secure executor toggle error: " .. tostring(error))
    end
end

-- ====================================================================
-- ENHANCED PLAYER LIST (PROFESSIONAL UI)
-- ====================================================================
function AdminClient:createPlayerList(parent, theme)
    local success, error = pcall(function()
        -- Player list frame
        local playerListFrame = Instance.new("Frame")
        playerListFrame.Name = "PlayerList"
        playerListFrame.Size = UDim2.new(1, -20, 1, -160)
        playerListFrame.Position = UDim2.new(0, 10, 0, 160)
        playerListFrame.BackgroundColor3 = theme.background.secondary
        playerListFrame.BorderSizePixel = 0
        playerListFrame.Parent = parent
        
        local listCorner = ThemeConfig:createCorner("medium")
        listCorner.Parent = playerListFrame
        
        -- Player list header
        local headerFrame = Instance.new("Frame")
        headerFrame.Size = UDim2.new(1, -10, 0, 40)
        headerFrame.Position = UDim2.new(0, 5, 0, 5)
        headerFrame.BackgroundTransparency = 1
        headerFrame.Parent = playerListFrame
        
        local listHeader = Instance.new("TextLabel")
        listHeader.Size = UDim2.new(0.6, 0, 1, 0)
        listHeader.Position = UDim2.new(0, 0, 0, 0)
        listHeader.BackgroundTransparency = 1
        listHeader.Font = ThemeConfig.Fonts.header
        listHeader.TextSize = ThemeConfig.FontSizes.large
        listHeader.TextColor3 = theme.text.primary
        listHeader.Text = "👥 Players in Server"
        listHeader.TextXAlignment = Enum.TextXAlignment.Left
        listHeader.Parent = headerFrame
        
        -- Player count display
        local playerCount = Instance.new("TextLabel")
        playerCount.Name = "PlayerCount"
        playerCount.Size = UDim2.new(0.4, 0, 1, 0)
        playerCount.Position = UDim2.new(0.6, 0, 0, 0)
        playerCount.BackgroundTransparency = 1
        playerCount.Font = ThemeConfig.Fonts.body
        playerCount.TextSize = ThemeConfig.FontSizes.normal
        playerCount.TextColor3 = theme.text.secondary
        playerCount.Text = "Loading..."
        playerCount.TextXAlignment = Enum.TextXAlignment.Right
        playerCount.Parent = headerFrame
        
        -- Refresh button
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Size = UDim2.new(0, 30, 0, 30)
        refreshBtn.Position = UDim2.new(1, -35, 0, 5)
        refreshBtn.BackgroundColor3 = theme.primary
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Font = ThemeConfig.Fonts.button
        refreshBtn.TextSize = ThemeConfig.FontSizes.normal
        refreshBtn.TextColor3 = theme.text.primary
        refreshBtn.Text = "🔄"
        refreshBtn.Parent = playerListFrame
        
        local refreshCorner = ThemeConfig:createCorner("small")
        refreshCorner.Parent = refreshBtn
        
        refreshBtn.MouseButton1Click:Connect(function()
            self:updatePlayerList(theme)
        end)
        
        self:addHoverEffect(refreshBtn, theme.primary)
        
        -- Player list container
        local listContainer = Instance.new("ScrollingFrame")
        listContainer.Size = UDim2.new(1, -10, 1, -50)
        listContainer.Position = UDim2.new(0, 5, 0, 45)
        listContainer.BackgroundTransparency = 1
        listContainer.BorderSizePixel = 0
        listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listContainer.ScrollBarThickness = 6
        listContainer.Parent = playerListFrame
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.Name
        listLayout.Padding = UDim.new(0, 3)
        listLayout.Parent = listContainer
        
        self.PlayerListContainer = listContainer
        self.PlayerCountLabel = playerCount
        self:updatePlayerList(theme)
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Player list creation error: " .. tostring(error))
    end
end

function AdminClient:updatePlayerList(theme)
    local success, error = pcall(function()
        if not self.PlayerListContainer then return end
        
        -- Clear existing entries
        for _, child in ipairs(self.PlayerListContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        local players = game.Players:GetPlayers()
        local playerCount = #players
        
        -- Update player count
        if self.PlayerCountLabel then
            self.PlayerCountLabel.Text = string.format("(%d/%d players)", playerCount, game.Players.MaxPlayers)
        end
        
        -- Create player entries
        for _, targetPlayer in ipairs(players) do
            self:createPlayerEntry(targetPlayer, theme)
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Player list update error: " .. tostring(error))
    end
end

function AdminClient:createPlayerEntry(targetPlayer, theme)
    local success, error = pcall(function()
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = targetPlayer.Name
        playerFrame.Size = UDim2.new(1, -10, 0, 50)
        playerFrame.BackgroundColor3 = theme.background.input
        playerFrame.BorderSizePixel = 0
        playerFrame.Parent = self.PlayerListContainer
        
        local entryCorner = ThemeConfig:createCorner("small")
        entryCorner.Parent = playerFrame
        
        -- Player info
        local playerInfo = Instance.new("TextLabel")
        playerInfo.Size = UDim2.new(0.6, 0, 1, 0)
        playerInfo.Position = UDim2.new(0, 10, 0, 0)
        playerInfo.BackgroundTransparency = 1
        playerInfo.Font = ThemeConfig.Fonts.body
        playerInfo.TextSize = ThemeConfig.FontSizes.normal
        playerInfo.TextColor3 = theme.text.primary
        playerInfo.Text = string.format("%s\nID: %d", targetPlayer.Name, targetPlayer.UserId)
        playerInfo.TextXAlignment = Enum.TextXAlignment.Left
        playerInfo.TextYAlignment = Enum.TextYAlignment.Center
        playerInfo.Parent = playerFrame
        
        -- Action buttons
        local actionFrame = Instance.new("Frame")
        actionFrame.Size = UDim2.new(0.4, -10, 1, -10)
        actionFrame.Position = UDim2.new(0.6, 0, 0, 5)
        actionFrame.BackgroundTransparency = 1
        actionFrame.Parent = playerFrame
        
        local actionLayout = Instance.new("UIListLayout")
        actionLayout.FillDirection = Enum.FillDirection.Horizontal
        actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        actionLayout.Padding = UDim.new(0, 3)
        actionLayout.Parent = actionFrame
        
        -- Action buttons data
        local actions = {
            {text = "TP", color = theme.primary, command = "tp " .. targetPlayer.Name},
            {text = "Kick", color = theme.warning, command = "kick " .. targetPlayer.Name},
            {text = "Ban", color = theme.error, command = "ban " .. targetPlayer.UserId}
        }
        
        if self.adminLevel >= 3 then -- Only show ban for high-level admins
            for _, action in ipairs(actions) do
                local actionBtn = Instance.new("TextButton")
                actionBtn.Size = UDim2.new(0, 35, 0, 30)
                actionBtn.BackgroundColor3 = action.color
                actionBtn.BorderSizePixel = 0
                actionBtn.Font = ThemeConfig.Fonts.button
                actionBtn.TextSize = ThemeConfig.FontSizes.small
                actionBtn.TextColor3 = theme.text.primary
                actionBtn.Text = action.text
                actionBtn.Parent = actionFrame
                
                local btnCorner = ThemeConfig:createCorner("small")
                btnCorner.Parent = actionBtn
                
                actionBtn.MouseButton1Click:Connect(function()
                    self:sendCommand(action.command)
                end)
                
                self:addHoverEffect(actionBtn, action.color)
            end
        else
            -- Limited actions for lower-level admins
            local limitedActions = {actions[1], actions[2]} -- Only TP and Kick
            for _, action in ipairs(limitedActions) do
                local actionBtn = Instance.new("TextButton")
                actionBtn.Size = UDim2.new(0, 35, 0, 30)
                actionBtn.BackgroundColor3 = action.color
                actionBtn.BorderSizePixel = 0
                actionBtn.Font = ThemeConfig.Fonts.button
                actionBtn.TextSize = ThemeConfig.FontSizes.small
                actionBtn.TextColor3 = theme.text.primary
                actionBtn.Text = action.text
                actionBtn.Parent = actionFrame
                
                local btnCorner = ThemeConfig:createCorner("small")
                btnCorner.Parent = actionBtn
                
                actionBtn.MouseButton1Click:Connect(function()
                    self:sendCommand(action.command)
                end)
                
                self:addHoverEffect(actionBtn, action.color)
            end
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Player entry creation error: " .. tostring(error))
    end
end

-- ====================================================================
-- QUICK ACTIONS SECTION
-- ====================================================================
function AdminClient:createQuickActions(parent, theme)
    local success, error = pcall(function()
        -- Quick actions frame
        local actionsFrame = Instance.new("Frame")
        actionsFrame.Name = "QuickActions"
        actionsFrame.Size = UDim2.new(1, -20, 0, 80)
        actionsFrame.Position = UDim2.new(0, 10, 0, 160)
        actionsFrame.BackgroundColor3 = theme.background.input
        actionsFrame.BorderSizePixel = 0
        actionsFrame.Parent = parent
        
        local actionsCorner = ThemeConfig:createCorner("medium")
        actionsCorner.Parent = actionsFrame
        
        -- Actions label
        local actionsLabel = Instance.new("TextLabel")
        actionsLabel.Size = UDim2.new(1, -10, 0, 25)
        actionsLabel.Position = UDim2.new(0, 5, 0, 5)
        actionsLabel.BackgroundTransparency = 1
        actionsLabel.Font = ThemeConfig.Fonts.body
        actionsLabel.TextSize = ThemeConfig.FontSizes.normal
        actionsLabel.TextColor3 = theme.text.secondary
        actionsLabel.Text = "⚡ Quick Actions:"
        actionsLabel.TextXAlignment = Enum.TextXAlignment.Left
        actionsLabel.Parent = actionsFrame
        
        -- Actions container
        local actionsContainer = Instance.new("Frame")
        actionsContainer.Size = UDim2.new(1, -10, 0, 45)
        actionsContainer.Position = UDim2.new(0, 5, 0, 30)
        actionsContainer.BackgroundTransparency = 1
        actionsContainer.Parent = actionsFrame
        
        local actionsLayout = Instance.new("UIListLayout")
        actionsLayout.FillDirection = Enum.FillDirection.Horizontal
        actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        actionsLayout.Padding = UDim.new(0, 8)
        actionsLayout.Parent = actionsContainer
        
        -- Quick action buttons
        local quickActions = {
            {text = "🖥️ Executor", color = theme.primary, action = "executor"},
            {text = "📊 Analytics", color = theme.warning, action = "analytics"},
            {text = "🔒 Security", color = theme.error, action = "security"},
            {text = "🎮 Game", color = theme.success, action = "game"},
            {text = "⚙️ Settings", color = theme.secondary, action = "settings"}
        }
        
        for _, actionData in ipairs(quickActions) do
            local actionBtn = Instance.new("TextButton")
            actionBtn.Size = UDim2.new(0, 90, 0, 40)
            actionBtn.BackgroundColor3 = actionData.color
            actionBtn.BorderSizePixel = 0
            actionBtn.Font = ThemeConfig.Fonts.button
            actionBtn.TextSize = ThemeConfig.FontSizes.small
            actionBtn.TextColor3 = theme.text.primary
            actionBtn.Text = actionData.text
            actionBtn.Parent = actionsContainer
            
            local btnCorner = ThemeConfig:createCorner("small")
            btnCorner.Parent = actionBtn
            
            actionBtn.MouseButton1Click:Connect(function()
                self:handleQuickAction(actionData.action)
            end)
            
            self:addHoverEffect(actionBtn, actionData.color)
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Quick actions creation error: " .. tostring(error))
    end
end

function AdminClient:handleQuickAction(action)
    local success, error = pcall(function()
        if action == "executor" then
            self:toggleSecureExecutor()
        elseif action == "analytics" then
            self:sendCommand("analytics report")
        elseif action == "security" then
            self:sendCommand("security status")
        elseif action == "game" then
            self:sendCommand("server info")
        elseif action == "settings" then
            self:showMessage({
                message = "Settings panel coming soon!",
                type = "Info"
            })
        end
    end)
    
    if not success then
        warn("[ADMIN CLIENT] Quick action error: " .. tostring(error))
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