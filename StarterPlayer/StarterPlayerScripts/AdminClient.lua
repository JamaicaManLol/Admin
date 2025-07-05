-- Admin Client Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for admin remotes
local adminRemotes = ReplicatedStorage:WaitForChild("AdminRemotes")
local executeRemote = adminRemotes:WaitForChild("ExecuteCommand")
local consoleRemote = adminRemotes:WaitForChild("ConsoleToggle")
local logRemote = adminRemotes:WaitForChild("AdminLog")

-- Admin Client Class
local AdminClient = {}
AdminClient.__index = AdminClient

function AdminClient.new()
    local self = setmetatable({}, AdminClient)
    
    self.isAdmin = false
    self.adminLevel = 0
    self.availableCommands = {}
    self.consoleOpen = false
    self.gui = nil
    self.console = nil
    
    -- Connect remote events
    self:connectEvents()
    
    return self
end

-- Connect remote events
function AdminClient:connectEvents()
    logRemote.OnClientEvent:Connect(function(eventType, data)
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
        end
    end)
end

-- Setup admin status
function AdminClient:setupAdminStatus(data)
    self.isAdmin = data.isAdmin
    self.adminLevel = data.level
    self.availableCommands = data.commands
    
    if self.isAdmin then
        self:createAdminGUI()
        print("[ADMIN CLIENT] Admin privileges enabled. Level:", self.adminLevel)
    end
end

-- Create admin GUI
function AdminClient:createAdminGUI()
    -- Remove existing GUI
    if self.gui then
        self.gui:Destroy()
    end
    
    -- Create main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "AdminGUI"
    self.gui.ResetOnSpawn = false
    self.gui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 50)
    mainFrame.Position = UDim2.new(1, -320, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = self.gui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Create admin panel button
    local adminButton = Instance.new("TextButton")
    adminButton.Name = "AdminButton"
    adminButton.Size = UDim2.new(0.45, -5, 1, -10)
    adminButton.Position = UDim2.new(0, 5, 0, 5)
    adminButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    adminButton.BorderSizePixel = 0
    adminButton.Font = Enum.Font.SourceSansBold
    adminButton.TextSize = 14
    adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    adminButton.Text = "Admin Panel"
    adminButton.Parent = mainFrame
    
    local adminCorner = Instance.new("UICorner")
    adminCorner.CornerRadius = UDim.new(0, 4)
    adminCorner.Parent = adminButton
    
    -- Create console button
    local consoleButton = Instance.new("TextButton")
    consoleButton.Name = "ConsoleButton"
    consoleButton.Size = UDim2.new(0.45, -5, 1, -10)
    consoleButton.Position = UDim2.new(0.55, 0, 0, 5)
    consoleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    consoleButton.BorderSizePixel = 0
    consoleButton.Font = Enum.Font.SourceSansBold
    consoleButton.TextSize = 14
    consoleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    consoleButton.Text = "Console"
    consoleButton.Parent = mainFrame
    
    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 4)
    consoleCorner.Parent = consoleButton
    
    -- Button events
    adminButton.MouseButton1Click:Connect(function()
        self:toggleAdminPanel()
    end)
    
    consoleButton.MouseButton1Click:Connect(function()
        consoleRemote:FireServer("request_console")
    end)
    
    -- Create admin panel
    self:createAdminPanel()
end

-- Create admin panel
function AdminClient:createAdminPanel()
    local panelFrame = Instance.new("Frame")
    panelFrame.Name = "AdminPanel"
    panelFrame.Size = UDim2.new(0, 400, 0, 500)
    panelFrame.Position = UDim2.new(1, -420, 0, 80)
    panelFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    panelFrame.BorderSizePixel = 0
    panelFrame.Visible = false
    panelFrame.Parent = self.gui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = panelFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    title.BorderSizePixel = 0
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Admin Panel - Level " .. self.adminLevel
    title.Parent = panelFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Command input
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -20, 0, 40)
    inputFrame.Position = UDim2.new(0, 10, 0, 50)
    inputFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = panelFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputFrame
    
    local commandInput = Instance.new("TextBox")
    commandInput.Size = UDim2.new(0.8, -10, 1, -10)
    commandInput.Position = UDim2.new(0, 5, 0, 5)
    commandInput.BackgroundTransparency = 1
    commandInput.Font = Enum.Font.SourceSans
    commandInput.TextSize = 16
    commandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    commandInput.PlaceholderText = "Enter command..."
    commandInput.Text = ""
    commandInput.TextXAlignment = Enum.TextXAlignment.Left
    commandInput.Parent = inputFrame
    
    local executeButton = Instance.new("TextButton")
    executeButton.Size = UDim2.new(0.2, -5, 1, -10)
    executeButton.Position = UDim2.new(0.8, 5, 0, 5)
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    executeButton.BorderSizePixel = 0
    executeButton.Font = Enum.Font.SourceSansBold
    executeButton.TextSize = 14
    executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeButton.Text = "Execute"
    executeButton.Parent = inputFrame
    
    local executeCorner = Instance.new("UICorner")
    executeCorner.CornerRadius = UDim.new(0, 4)
    executeCorner.Parent = executeButton
    
    -- Output area
    local outputFrame = Instance.new("ScrollingFrame")
    outputFrame.Size = UDim2.new(1, -20, 1, -110)
    outputFrame.Position = UDim2.new(0, 10, 0, 100)
    outputFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    outputFrame.BorderSizePixel = 0
    outputFrame.ScrollBarThickness = 6
    outputFrame.Parent = panelFrame
    
    local outputCorner = Instance.new("UICorner")
    outputCorner.CornerRadius = UDim.new(0, 4)
    outputCorner.Parent = outputFrame
    
    local outputList = Instance.new("UIListLayout")
    outputList.SortOrder = Enum.SortOrder.LayoutOrder
    outputList.Padding = UDim.new(0, 2)
    outputList.Parent = outputFrame
    
    -- Execute command function
    local function executeCommand()
        local command = commandInput.Text
        if command and command ~= "" then
            executeRemote:FireServer("chat_command", command)
            commandInput.Text = ""
        end
    end
    
    executeButton.MouseButton1Click:Connect(executeCommand)
    commandInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            executeCommand()
        end
    end)
    
    -- Store references
    self.adminPanel = panelFrame
    self.outputFrame = outputFrame
end

-- Create console
function AdminClient:createConsole()
    if self.console then
        self.console:Destroy()
    end
    
    local consoleFrame = Instance.new("Frame")
    consoleFrame.Name = "AdminConsole"
    consoleFrame.Size = UDim2.new(0, 800, 0, 600)
    consoleFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    consoleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    consoleFrame.BorderSizePixel = 0
    consoleFrame.Parent = self.gui
    
    local consoleCorner = Instance.new("UICorner")
    consoleCorner.CornerRadius = UDim.new(0, 8)
    consoleCorner.Parent = consoleFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = consoleFrame
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 8)
    titleBarCorner.Parent = titleBar
    
    local consoleTitle = Instance.new("TextLabel")
    consoleTitle.Size = UDim2.new(0.8, 0, 1, 0)
    consoleTitle.BackgroundTransparency = 1
    consoleTitle.Font = Enum.Font.SourceSansBold
    consoleTitle.TextSize = 16
    consoleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    consoleTitle.Text = "Admin Console - Server Executor"
    consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
    consoleTitle.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 1, 0)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 16
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Parent = titleBar
    
    -- Output area
    local outputArea = Instance.new("ScrollingFrame")
    outputArea.Size = UDim2.new(1, -20, 1, -100)
    outputArea.Position = UDim2.new(0, 10, 0, 40)
    outputArea.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    outputArea.BorderSizePixel = 0
    outputArea.ScrollBarThickness = 8
    outputArea.Parent = consoleFrame
    
    local outputCorner = Instance.new("UICorner")
    outputCorner.CornerRadius = UDim.new(0, 4)
    outputCorner.Parent = outputArea
    
    local outputList = Instance.new("UIListLayout")
    outputList.SortOrder = Enum.SortOrder.LayoutOrder
    outputList.Padding = UDim.new(0, 2)
    outputList.Parent = outputArea
    
    -- Input area
    local inputArea = Instance.new("TextBox")
    inputArea.Size = UDim2.new(1, -20, 0, 50)
    inputArea.Position = UDim2.new(0, 10, 1, -60)
    inputArea.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    inputArea.BorderSizePixel = 0
    inputArea.Font = Enum.Font.SourceSans
    inputArea.TextSize = 14
    inputArea.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputArea.PlaceholderText = "Enter Lua code to execute on server..."
    inputArea.Text = ""
    inputArea.TextXAlignment = Enum.TextXAlignment.Left
    inputArea.TextYAlignment = Enum.TextYAlignment.Top
    inputArea.MultiLine = true
    inputArea.ClearTextOnFocus = false
    inputArea.Parent = consoleFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputArea
    
    -- Events
    closeButton.MouseButton1Click:Connect(function()
        self:closeConsole()
    end)
    
    inputArea.FocusLost:Connect(function(enterPressed)
        if enterPressed and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local code = inputArea.Text
            if code and code ~= "" then
                executeRemote:FireServer("console_execute", code)
                inputArea.Text = ""
            end
        end
    end)
    
    -- Store references
    self.console = consoleFrame
    self.consoleOutput = outputArea
    
    -- Add initial message
    self:addConsoleOutput("Console ready. Press Ctrl+Enter to execute code.")
    self:addConsoleOutput("Available globals: game, workspace, Players, admin, config, getPlayers(name)")
end

-- Toggle admin panel
function AdminClient:toggleAdminPanel()
    if self.adminPanel then
        self.adminPanel.Visible = not self.adminPanel.Visible
    end
end

-- Open console
function AdminClient:openConsole()
    if not self.console then
        self:createConsole()
    end
    self.console.Visible = true
    self.consoleOpen = true
end

-- Close console
function AdminClient:closeConsole()
    if self.console then
        self.console.Visible = false
        self.consoleOpen = false
    end
end

-- Add console output
function AdminClient:addConsoleOutput(text)
    if not self.consoleOutput then return end
    
    local outputLabel = Instance.new("TextLabel")
    outputLabel.Size = UDim2.new(1, -10, 0, 20)
    outputLabel.BackgroundTransparency = 1
    outputLabel.Font = Enum.Font.SourceSans
    outputLabel.TextSize = 14
    outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    outputLabel.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    outputLabel.TextXAlignment = Enum.TextXAlignment.Left
    outputLabel.TextWrapped = true
    outputLabel.Parent = self.consoleOutput
    
    -- Auto-scroll to bottom
    self.consoleOutput.CanvasPosition = Vector2.new(0, self.consoleOutput.CanvasSize.Y.Offset)
end

-- Show message
function AdminClient:showMessage(data)
    local messageFrame = Instance.new("Frame")
    messageFrame.Size = UDim2.new(0, 400, 0, 80)
    messageFrame.Position = UDim2.new(0.5, -200, 0, 100)
    messageFrame.BackgroundColor3 = data.type == "Error" and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(0, 150, 0)
    messageFrame.BorderSizePixel = 0
    messageFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = messageFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -20)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.SourceSansBold
    messageLabel.TextSize = 16
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.Text = data.message
    messageLabel.TextWrapped = true
    messageLabel.Parent = messageFrame
    
    -- Auto-remove after 3 seconds
    game:GetService("Debris"):AddItem(messageFrame, 3)
    
    -- Add to output if admin panel is open
    if self.outputFrame then
        local outputLabel = Instance.new("TextLabel")
        outputLabel.Size = UDim2.new(1, -10, 0, 20)
        outputLabel.BackgroundTransparency = 1
        outputLabel.Font = Enum.Font.SourceSans
        outputLabel.TextSize = 14
        outputLabel.TextColor3 = data.type == "Error" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
        outputLabel.Text = "[" .. os.date("%H:%M:%S") .. "] " .. data.message
        outputLabel.TextXAlignment = Enum.TextXAlignment.Left
        outputLabel.TextWrapped = true
        outputLabel.Parent = self.outputFrame
        
        -- Auto-scroll
        self.outputFrame.CanvasPosition = Vector2.new(0, self.outputFrame.CanvasSize.Y.Offset)
    end
end

-- Initialize the admin client
local adminClient = AdminClient.new()

print("[ADMIN CLIENT] Admin client script loaded successfully!")