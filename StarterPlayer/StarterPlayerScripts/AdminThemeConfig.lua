-- Admin Client Theme Configuration
-- God-Tier Enhancement: External theme config for easy customization

local AdminThemeConfig = {}

-- Default Theme Palette
AdminThemeConfig.Themes = {
    Default = {
        name = "Default Professional",
        
        -- Main UI Colors
        primary = Color3.fromRGB(0, 120, 215),      -- Blue
        secondary = Color3.fromRGB(220, 50, 50),    -- Red
        success = Color3.fromRGB(0, 150, 0),        -- Green
        warning = Color3.fromRGB(255, 165, 0),      -- Orange
        error = Color3.fromRGB(220, 50, 50),        -- Red
        
        -- Background Colors
        background = {
            main = Color3.fromRGB(30, 30, 30),      -- Main frame background
            panel = Color3.fromRGB(25, 25, 25),     -- Panel background
            console = Color3.fromRGB(20, 20, 20),   -- Console background
            input = Color3.fromRGB(40, 40, 40),     -- Input field background
            output = Color3.fromRGB(35, 35, 35),    -- Output area background
            titleBar = Color3.fromRGB(0, 120, 215)  -- Title bar background
        },
        
        -- Text Colors
        text = {
            primary = Color3.fromRGB(255, 255, 255),    -- Main text
            secondary = Color3.fromRGB(200, 200, 200),  -- Secondary text
            placeholder = Color3.fromRGB(150, 150, 150), -- Placeholder text
            success = Color3.fromRGB(100, 255, 100),    -- Success messages
            error = Color3.fromRGB(255, 100, 100),      -- Error messages
            warning = Color3.fromRGB(255, 200, 100)     -- Warning messages
        },
        
        -- Corner Radius Settings
        cornerRadius = {
            large = UDim.new(0, 8),     -- Large elements
            medium = UDim.new(0, 6),    -- Medium elements
            small = UDim.new(0, 4)      -- Small elements
        },
        
        -- Transparency Settings
        transparency = {
            none = 0,           -- Fully opaque
            light = 0.1,        -- Slightly transparent
            medium = 0.3,       -- Medium transparency
            heavy = 0.7,        -- Heavy transparency
            invisible = 1       -- Fully transparent
        }
    },
    
    Dark = {
        name = "Dark Mode",
        
        primary = Color3.fromRGB(100, 100, 255),
        secondary = Color3.fromRGB(255, 100, 100),
        success = Color3.fromRGB(100, 255, 100),
        warning = Color3.fromRGB(255, 200, 100),
        error = Color3.fromRGB(255, 100, 100),
        
        background = {
            main = Color3.fromRGB(15, 15, 15),
            panel = Color3.fromRGB(10, 10, 10),
            console = Color3.fromRGB(5, 5, 5),
            input = Color3.fromRGB(25, 25, 25),
            output = Color3.fromRGB(20, 20, 20),
            titleBar = Color3.fromRGB(100, 100, 255)
        },
        
        text = {
            primary = Color3.fromRGB(240, 240, 240),
            secondary = Color3.fromRGB(180, 180, 180),
            placeholder = Color3.fromRGB(120, 120, 120),
            success = Color3.fromRGB(120, 255, 120),
            error = Color3.fromRGB(255, 120, 120),
            warning = Color3.fromRGB(255, 220, 120)
        },
        
        cornerRadius = {
            large = UDim.new(0, 12),
            medium = UDim.new(0, 8),
            small = UDim.new(0, 6)
        },
        
        transparency = {
            none = 0,
            light = 0.1,
            medium = 0.3,
            heavy = 0.7,
            invisible = 1
        }
    },
    
    Light = {
        name = "Light Mode",
        
        primary = Color3.fromRGB(0, 100, 200),
        secondary = Color3.fromRGB(200, 100, 0),
        success = Color3.fromRGB(0, 180, 0),
        warning = Color3.fromRGB(255, 140, 0),
        error = Color3.fromRGB(200, 50, 50),
        
        background = {
            main = Color3.fromRGB(240, 240, 240),
            panel = Color3.fromRGB(250, 250, 250),
            console = Color3.fromRGB(255, 255, 255),
            input = Color3.fromRGB(230, 230, 230),
            output = Color3.fromRGB(245, 245, 245),
            titleBar = Color3.fromRGB(0, 100, 200)
        },
        
        text = {
            primary = Color3.fromRGB(50, 50, 50),
            secondary = Color3.fromRGB(100, 100, 100),
            placeholder = Color3.fromRGB(150, 150, 150),
            success = Color3.fromRGB(0, 120, 0),
            error = Color3.fromRGB(180, 50, 50),
            warning = Color3.fromRGB(200, 100, 0)
        },
        
        cornerRadius = {
            large = UDim.new(0, 8),
            medium = UDim.new(0, 6),
            small = UDim.new(0, 4)
        },
        
        transparency = {
            none = 0,
            light = 0.1,
            medium = 0.3,
            heavy = 0.7,
            invisible = 1
        }
    },
    
    Cyberpunk = {
        name = "Cyberpunk Neon",
        
        primary = Color3.fromRGB(0, 255, 255),      -- Cyan
        secondary = Color3.fromRGB(255, 0, 255),    -- Magenta
        success = Color3.fromRGB(0, 255, 0),        -- Neon green
        warning = Color3.fromRGB(255, 255, 0),      -- Neon yellow
        error = Color3.fromRGB(255, 0, 100),        -- Hot pink
        
        background = {
            main = Color3.fromRGB(10, 10, 20),
            panel = Color3.fromRGB(5, 5, 15),
            console = Color3.fromRGB(0, 0, 10),
            input = Color3.fromRGB(20, 0, 20),
            output = Color3.fromRGB(10, 0, 15),
            titleBar = Color3.fromRGB(0, 255, 255)
        },
        
        text = {
            primary = Color3.fromRGB(0, 255, 255),
            secondary = Color3.fromRGB(255, 0, 255),
            placeholder = Color3.fromRGB(100, 100, 200),
            success = Color3.fromRGB(0, 255, 100),
            error = Color3.fromRGB(255, 100, 150),
            warning = Color3.fromRGB(255, 255, 100)
        },
        
        cornerRadius = {
            large = UDim.new(0, 2),     -- Sharp edges for cyberpunk feel
            medium = UDim.new(0, 1),
            small = UDim.new(0, 0)
        },
        
        transparency = {
            none = 0,
            light = 0.2,
            medium = 0.4,
            heavy = 0.8,
            invisible = 1
        }
    }
}

-- Current Theme Settings
AdminThemeConfig.CurrentTheme = "Default"

-- Font Settings
AdminThemeConfig.Fonts = {
    title = Enum.Font.SourceSansBold,
    body = Enum.Font.SourceSans,
    console = Enum.Font.Code,           -- Monospace for console
    button = Enum.Font.SourceSansBold
}

-- Font Sizes
AdminThemeConfig.FontSizes = {
    tiny = 10,
    small = 12,
    normal = 14,
    medium = 16,
    large = 18,
    huge = 24
}

-- Animation Settings
AdminThemeConfig.Animations = {
    fast = 0.1,
    normal = 0.3,
    slow = 0.5,
    easing = Enum.EasingStyle.Quad,
    direction = Enum.EasingDirection.Out
}

-- Scaling Settings for Mobile/Console Support
AdminThemeConfig.Scaling = {
    -- Base scale for different platforms
    mobile = 1.2,       -- 20% larger for mobile
    tablet = 1.1,       -- 10% larger for tablet
    console = 1.3,      -- 30% larger for console
    desktop = 1.0,      -- Standard scale
    
    -- Minimum sizes
    minButtonSize = UDim2.new(0, 80, 0, 30),
    minFrameSize = UDim2.new(0, 300, 0, 200),
    
    -- Maximum sizes
    maxFrameSize = UDim2.new(0, 1200, 0, 800)
}

-- UI Layout Settings
AdminThemeConfig.Layout = {
    padding = {
        small = UDim.new(0, 5),
        medium = UDim.new(0, 10),
        large = UDim.new(0, 20)
    },
    
    scrollbar = {
        thickness = 8,
        color = Color3.fromRGB(100, 100, 100)
    }
}

-- Methods
function AdminThemeConfig:getTheme(themeName)
    return self.Themes[themeName or self.CurrentTheme] or self.Themes.Default
end

function AdminThemeConfig:setTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = themeName
        return true
    end
    return false
end

function AdminThemeConfig:getCurrentTheme()
    return self:getTheme()
end

function AdminThemeConfig:getAvailableThemes()
    local themes = {}
    for name, theme in pairs(self.Themes) do
        table.insert(themes, {name = name, displayName = theme.name})
    end
    return themes
end

-- Platform Detection
function AdminThemeConfig:detectPlatform()
    local UserInputService = game:GetService("UserInputService")
    
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        if workspace.CurrentCamera.ViewportSize.X < 768 then
            return "mobile"
        else
            return "tablet"
        end
    elseif UserInputService.GamepadEnabled then
        return "console"
    else
        return "desktop"
    end
end

-- Get appropriate scale for current platform
function AdminThemeConfig:getPlatformScale()
    local platform = self:detectPlatform()
    return self.Scaling[platform] or self.Scaling.desktop
end

-- Apply theme to a GUI element
function AdminThemeConfig:applyTheme(element, elementType, colorType)
    local theme = self:getCurrentTheme()
    
    if elementType == "frame" then
        element.BackgroundColor3 = theme.background[colorType] or theme.background.main
    elseif elementType == "text" then
        element.TextColor3 = theme.text[colorType] or theme.text.primary
    elseif elementType == "button" then
        element.BackgroundColor3 = theme[colorType] or theme.primary
        element.TextColor3 = theme.text.primary
    end
    
    -- Apply corner radius if it's a GuiObject
    if element:IsA("GuiObject") then
        local corner = element:FindFirstChild("UICorner")
        if corner then
            corner.CornerRadius = theme.cornerRadius.medium
        end
    end
end

-- Create a themed corner
function AdminThemeConfig:createCorner(size)
    local theme = self:getCurrentTheme()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.cornerRadius[size] or theme.cornerRadius.medium
    return corner
end

-- Create themed padding
function AdminThemeConfig:createPadding(size)
    local padding = Instance.new("UIPadding")
    local paddingSize = self.Layout.padding[size] or self.Layout.padding.medium
    padding.PaddingTop = paddingSize
    padding.PaddingBottom = paddingSize
    padding.PaddingLeft = paddingSize
    padding.PaddingRight = paddingSize
    return padding
end

-- Create platform-appropriate scaling
function AdminThemeConfig:createScaling()
    local scale = Instance.new("UIScale")
    scale.Scale = self:getPlatformScale()
    return scale
end

-- Create aspect ratio constraint for mobile support
function AdminThemeConfig:createAspectRatio(ratio)
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = ratio or 16/9
    aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
    aspectRatio.DominantAxis = Enum.DominantAxis.Width
    return aspectRatio
end

-- God-Tier: Dynamic theme switching with smooth transitions
function AdminThemeConfig:switchTheme(themeName, guiElements)
    local oldTheme = self:getCurrentTheme()
    
    if not self:setTheme(themeName) then
        return false
    end
    
    local newTheme = self:getCurrentTheme()
    local TweenService = game:GetService("TweenService")
    
    -- Animate theme transition
    if guiElements then
        for _, element in pairs(guiElements) do
            if element.element and element.type and element.colorType then
                local targetColor
                
                if element.type == "frame" then
                    targetColor = newTheme.background[element.colorType] or newTheme.background.main
                elseif element.type == "text" then
                    targetColor = newTheme.text[element.colorType] or newTheme.text.primary
                elseif element.type == "button" then
                    targetColor = newTheme[element.colorType] or newTheme.primary
                end
                
                if targetColor then
                    local tween = TweenService:Create(
                        element.element,
                        TweenInfo.new(
                            self.Animations.normal,
                            self.Animations.easing,
                            self.Animations.direction
                        ),
                        {
                            BackgroundColor3 = targetColor,
                            TextColor3 = element.type == "text" and targetColor or element.element.TextColor3
                        }
                    )
                    tween:Play()
                end
            end
        end
    end
    
    return true
end

return AdminThemeConfig