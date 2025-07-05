-- Modern Luau Compatibility Fixes for SecureExecutor
-- Addresses loadstring and setfenv deprecation concerns

local ModernLuauFixes = {}

-- Modern load function that replaces loadstring with proper environment handling
function ModernLuauFixes.loadWithEnvironment(source, chunkName, environment)
    -- Use load instead of loadstring for modern Luau compatibility
    local compiledFunction, compileError = load(source, chunkName, "t", environment)
    
    if not compiledFunction then
        return nil, compileError
    end
    
    -- Modern Luau doesn't need setfenv as load accepts environment directly
    return compiledFunction
end

-- Safe environment setter for older Luau versions
function ModernLuauFixes.setEnvironmentSafely(func, environment)
    -- Check if setfenv is available (older Luau versions)
    if setfenv then
        return setfenv(func, environment)
    else
        -- Modern Luau: environment should be set during load
        warn("setfenv not available - environment must be set during load()")
        return func
    end
end

-- Modern secure execution with proper environment handling
function ModernLuauFixes.executeWithModernEnvironment(scriptCode, environment, chunkName)
    -- Use modern load function with environment
    local compiledFunction, compileError = load(scriptCode, chunkName or "SecureScript", "t", environment)
    
    if not compiledFunction then
        return false, "Compilation failed: " .. tostring(compileError)
    end
    
    -- Execute with proper error handling
    local success, result = pcall(compiledFunction)
    
    if success then
        return true, result
    else
        return false, "Runtime error: " .. tostring(result)
    end
end

-- Check for modern Luau features
function ModernLuauFixes.checkLuauFeatures()
    return {
        hasLoad = load ~= nil,
        hasLoadstring = loadstring ~= nil,
        hasSetfenv = setfenv ~= nil,
        hasGetfenv = getfenv ~= nil,
        hasDebugHook = debug and debug.sethook ~= nil,
        luauVersion = _VERSION or "Unknown"
    }
end

-- Recommended pattern for SecureExecutor
function ModernLuauFixes.modernSecureRequire(moduleScript, environment, modulePath)
    local success, result = pcall(function()
        local moduleCode = moduleScript.Source
        
        -- Use modern load with environment
        local compiledModule, compileError = load(
            moduleCode, 
            "@" .. modulePath, 
            "t", -- text mode only for security
            environment
        )
        
        if not compiledModule then
            error("Module compilation failed: " .. tostring(compileError))
        end
        
        -- Execute the module
        return compiledModule()
    end)
    
    if success then
        return result
    else
        error("Module execution failed: " .. tostring(result))
    end
end

-- Example usage patterns
function ModernLuauFixes.getExampleUsage()
    return {
        modernExecution = [[
-- Modern way (recommended):
local success, result = ModernLuauFixes.executeWithModernEnvironment(
    scriptCode, 
    secureEnvironment, 
    "UserScript"
)

-- Old way (still works but deprecated):
local compiled = loadstring(scriptCode)
if compiled then
    setfenv(compiled, secureEnvironment)
    local success, result = pcall(compiled)
end
]],
        
        modernRequire = [[
-- Modern secure require:
local moduleResult = ModernLuauFixes.modernSecureRequire(
    moduleScript, 
    sandboxEnvironment, 
    modulePath
)
]],
        
        environmentSetup = [[
-- Modern environment setup:
local environment = {
    print = safePrint,
    -- ... other safe functions
}

-- Use load with environment directly
local compiled = load(code, chunkName, "t", environment)
]]
    }
end

return ModernLuauFixes