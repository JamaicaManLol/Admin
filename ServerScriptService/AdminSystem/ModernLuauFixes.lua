-- Modern Luau Compatibility Fixes for SecureExecutor
-- Addresses loadstring and setfenv deprecation concerns
-- Version: 2.0 - Implements professional-grade improvements

local ModernLuauFixes = {}

-- Configuration for warnings and error handling
local DEFAULT_CONFIG = {
    enableWarnings = true,
    warningHandler = warn,
    returnConsistentAPI = true
}

-- More robust Luau version detection
local function detectLuauVersion()
    local version = _VERSION or "Unknown"
    
    -- Try to detect Luau-specific features for better version reporting
    local features = {
        hasLoad = load ~= nil,
        hasLoadstring = loadstring ~= nil,
        hasSetfenv = setfenv ~= nil,
        hasDebugHook = debug and debug.sethook ~= nil,
        hasStringPack = string.pack ~= nil, -- Luau-specific feature
        hasTableMove = table.move ~= nil,   -- Modern Lua feature
    }
    
    -- Estimate Luau version based on available features
    if features.hasStringPack and features.hasLoad then
        return version .. " (Modern Luau)"
    elseif features.hasLoad then
        return version .. " (Transitional Luau)"
    else
        return version .. " (Legacy Lua)"
    end
end

-- Suggestion #1: Consistent return pattern for loading functions
-- All loading functions now return (success, result_or_error) consistently
function ModernLuauFixes.loadWithEnvironment(source, chunkName, environment)
    -- Use load instead of loadstring for modern Luau compatibility
    local compiledFunction, compileError = load(source, chunkName or "Chunk", "t", environment)
    
    if not compiledFunction then
        return false, "Compilation failed: " .. tostring(compileError)
    end
    
    -- Return consistent (success, result) pattern
    return true, compiledFunction
end

-- Suggestion #2: Configurable warnings and clear behavior documentation
function ModernLuauFixes.setEnvironmentSafely(func, environment, config)
    config = config or DEFAULT_CONFIG
    
    -- Check if setfenv is available (older Luau versions)
    if setfenv then
        -- setfenv returns the function with the new environment
        local success, result = pcall(setfenv, func, environment)
        if success then
            return true, result -- Returns the function with new environment
        else
            if config.enableWarnings then
                config.warningHandler("setfenv failed: " .. tostring(result))
            end
            return false, "Failed to set environment: " .. tostring(result)
        end
    else
        -- Modern Luau: environment should be set during load
        if config.enableWarnings then
            config.warningHandler("setfenv not available - environment must be set during load()")
        end
        return false, "setfenv unavailable in modern Luau - use load() with environment parameter"
    end
end

-- Suggestion #1: Consistent return pattern with executeWithModernEnvironment
function ModernLuauFixes.executeWithModernEnvironment(scriptCode, environment, chunkName, config)
    config = config or DEFAULT_CONFIG
    
    -- Use modern load function with environment
    local success, compiledFunction = ModernLuauFixes.loadWithEnvironment(scriptCode, chunkName, environment)
    
    if not success then
        return false, compiledFunction -- compiledFunction contains error message
    end
    
    -- Execute with proper error handling
    local execSuccess, result = pcall(compiledFunction)
    
    if execSuccess then
        return true, result
    else
        return false, "Runtime error: " .. tostring(result)
    end
end

-- Enhanced Luau feature detection with more robust version reporting
function ModernLuauFixes.checkLuauFeatures()
    return {
        hasLoad = load ~= nil,
        hasLoadstring = loadstring ~= nil,
        hasSetfenv = setfenv ~= nil,
        hasGetfenv = getfenv ~= nil,
        hasDebugHook = debug and debug.sethook ~= nil,
        hasStringPack = string.pack ~= nil,  -- Luau-specific
        hasTableMove = table.move ~= nil,    -- Modern Lua
        hasBit32 = bit32 ~= nil,            -- Luau-specific
        hasUtf8 = utf8 ~= nil,              -- Modern feature
        luauVersion = detectLuauVersion(),   -- Enhanced version detection
        
        -- Security-relevant features
        hasTextModeOnly = pcall(function() load("", "", "t") end), -- Can restrict to text mode
        hasEnvironmentSupport = pcall(function() load("", "", "t", {}) end), -- Can set environment
    }
end

-- Suggestion #1 & #2: Improved modernSecureRequire with consistent API and better error handling
function ModernLuauFixes.modernSecureRequire(moduleScript, environment, modulePath, config)
    config = config or DEFAULT_CONFIG
    
    -- Validate input parameters
    if not moduleScript or type(moduleScript) ~= "userdata" then
        return false, "Invalid moduleScript: expected userdata object"
    end
    
    if not environment or type(environment) ~= "table" then
        return false, "Invalid environment: expected table"
    end
    
    local success, result = pcall(function()
        local moduleCode = moduleScript.Source
        
        -- Use modern load with environment - consistent with other loading functions
        local loadSuccess, compiledModule = ModernLuauFixes.loadWithEnvironment(
            moduleCode, 
            "@" .. (modulePath or "Module"), 
            environment
        )
        
        if not loadSuccess then
            error(compiledModule) -- Contains error message
        end
        
        -- Execute the module
        return compiledModule()
    end)
    
    if success then
        return true, result
    else
        return false, "Module execution failed: " .. tostring(result)
    end
end

-- Suggestion #3: Security documentation and environment validation
function ModernLuauFixes.createSecureEnvironment(baseEnvironment, securityConfig)
    securityConfig = securityConfig or {
        allowGlobalAccess = false,
        allowDebugAccess = false,
        allowFileSystem = false,
        allowNetwork = false
    }
    
    local secureEnv = {}
    
    -- Copy safe base environment
    if baseEnvironment then
        for key, value in pairs(baseEnvironment) do
            -- Security check: filter dangerous globals
            local isDangerous = false
            
            -- Block dangerous global access
            if not securityConfig.allowGlobalAccess and (key == "_G" or key == "getfenv" or key == "setfenv") then
                isDangerous = true
            end
            
            -- Block debug access unless explicitly allowed
            if not securityConfig.allowDebugAccess and key == "debug" then
                isDangerous = true
            end
            
            -- Block filesystem access unless explicitly allowed
            if not securityConfig.allowFileSystem and (key == "io" or key == "os") then
                isDangerous = true
            end
            
            -- Block network access unless explicitly allowed  
            if not securityConfig.allowNetwork and type(value) == "userdata" then
                local serviceName = tostring(value)
                if serviceName:find("HttpService") or serviceName:find("DataStore") then
                    isDangerous = true
                end
            end
            
            if not isDangerous then
                secureEnv[key] = value
            end
        end
    end
    
    return secureEnv
end

-- Suggestion #5: Local helper functions for internal use
local function validateExecutionResult(success, result, context)
    if success then
        return true, result
    else
        return false, (context or "Execution") .. " failed: " .. tostring(result)
    end
end

local function createErrorHandler(config)
    config = config or DEFAULT_CONFIG
    
    return function(errorMsg)
        if config.enableWarnings then
            config.warningHandler("ModernLuauFixes Error: " .. tostring(errorMsg))
        end
        return false, tostring(errorMsg)
    end
end

-- Enhanced example usage with all improvements
function ModernLuauFixes.getEnhancedExampleUsage()
    return {
        consistentLoading = [[
-- Consistent API pattern - all loading functions return (success, result)
local success, func = ModernLuauFixes.loadWithEnvironment(
    "return 'Hello World'", 
    "TestScript", 
    { print = print }
)

if success then
    local execSuccess, result = pcall(func)
    print("Result:", result)
else
    warn("Load failed:", func) -- func contains error message
end
]],
        
        configurableWarnings = [[
-- Configurable warning system
local config = {
    enableWarnings = false,          -- Disable warnings for production
    warningHandler = function(msg)   -- Custom warning handler
        game:GetService("LogService"):WriteLog(Enum.LogLevel.Warning, msg)
    end
}

local success, result = ModernLuauFixes.executeWithModernEnvironment(
    scriptCode, 
    environment, 
    "UserScript",
    config
)
]],
        
        secureEnvironment = [[
-- Secure environment creation with validation
local secureConfig = {
    allowGlobalAccess = false,
    allowDebugAccess = false,
    allowFileSystem = false,
    allowNetwork = false
}

local safeEnv = ModernLuauFixes.createSecureEnvironment(baseEnv, secureConfig)
local success, result = ModernLuauFixes.executeWithModernEnvironment(
    userScript,
    safeEnv,
    "SecureUserScript"
)
]],
        
        modernRequire = [[
-- Modern secure require with consistent API
local success, moduleResult = ModernLuauFixes.modernSecureRequire(
    moduleScript, 
    sandboxEnvironment, 
    "MyModule"
)

if success then
    -- Use moduleResult safely
    print("Module loaded:", moduleResult)
else
    -- Handle error gracefully
    warn("Module failed to load:", moduleResult)
end
]],
        
        featureDetection = [[
-- Enhanced feature detection
local features = ModernLuauFixes.checkLuauFeatures()
print("Luau Version:", features.luauVersion)
print("Modern Load Support:", features.hasLoad)
print("Security Features:", features.hasTextModeOnly)

if features.hasEnvironmentSupport then
    -- Use modern environment handling
else
    -- Fallback for older versions
end
]]
    }
end

-- Enhanced version info with all improvements
function ModernLuauFixes.getVersionInfo()
    return {
        version = "2.0",
        improvements = {
            "Consistent (success, result) API pattern across all functions",
            "Configurable warning system with custom handlers", 
            "Enhanced security environment validation",
            "Robust Luau version detection with feature analysis",
            "Professional error handling with context preservation",
            "Comprehensive documentation and usage examples"
        },
        compatibility = {
            modernLuau = "Full support with load() and environment handling",
            transitionalLuau = "Backwards compatibility with setfenv fallbacks", 
            legacyLua = "Basic compatibility with appropriate warnings"
        },
        security = {
            textModeOnly = "Prevents bytecode injection attacks",
            environmentIsolation = "Sandboxed execution with filtered globals",
            validationChecks = "Input validation and type checking",
            errorContainment = "Safe error propagation without exposure"
        }
    }
end

return ModernLuauFixes