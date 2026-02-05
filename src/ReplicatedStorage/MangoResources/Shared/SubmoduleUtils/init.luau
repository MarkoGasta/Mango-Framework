--[[
-----------------------------------------------------------------------------
Last Updated - 5 Jan 2025
Copyright 2025 MarkoGasta @ Studio Blackout

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the“Software”),
to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
-----------------------------------------------------------------------------
]]--

--// SERVICES \\--

--// CONFIG \\--
local TEMPLATE_TOKEN = "TEMPLATE"

--// MODULES \\--
local TableUtils = require(script.TableUtils)

--// TYPES \\--
type BuildFilterType = "Whitelist" | "Blacklist"
type BuildSubmoduleOptions = {
    FilterType: BuildFilterType?,
    Filter: {string}?,
    ConstructionArguments: {any}?,
    InitializationArguments: {any}?,
    ConstructionMethod: string,
    InitializationMethod: string,
    ExcludeTemplates: boolean?,
}

--// CONSTANTS \\--
local BuildSubmoduleOptionDefaults: BuildSubmoduleOptions = {
    FilterType = nil,
    Filter = nil,
    ConstructionArguments = {},
    InitializationArguments = {},
    ConstructionMethod = nil,
    InitializationMethod = nil,
    ExcludeTemplates = true,
}

--// VARIABLES \\--
local submoduleUtils = {}

--// FUNCTIONS \\--
local LogError: (message: string) -> nil
local DefineConstructionMethodName: (methodName: string) -> nil
local DefineInitializationMethodName: (methodName: string) -> nil
local ConstructSubmodule: (submoduleReturn: any, options: BuildSubmoduleOptions) -> boolean
local InitializeSubmodule: (submoduleReturn: any, options: BuildSubmoduleOptions) -> boolean
local BuildSubmodules: (submodules: {ModuleScript}, options: BuildSubmoduleOptions?) -> (boolean, {table}?)
local BuildChildrenSubmodules: (parent: Instance, options: BuildSubmoduleOptions?) -> (boolean, {table}?)

--[=[
    Logs an error message to the console with a SubmoduleUtils prefix.

    ### Parameters:
    ```luau
    message: string -- The error message to log.
    ```
]=]
LogError = function(message: string)
    warn(`[SubmoduleUtils] {message}`)
end

--[=[
    Sets the default construction method name for submodules.

    ### Parameters:
    ```luau
    methodName: string -- The name of the method to use for constructing submodules.
    ```
]=]
DefineConstructionMethodName = function(methodName)
    BuildSubmoduleOptionDefaults.ConstructionMethod = methodName
end

--[=[
    Sets the default initialization method name for submodules.

    ### Parameters:
    ```luau
    methodName: string -- The name of the method to use for initializing submodules.
    ```
]=]
DefineInitializationMethodName = function(methodName)
    BuildSubmoduleOptionDefaults.InitializationMethod = methodName
end

--[=[
    Constructs a submodule by calling its construction method with specified options.

    ### Parameters:
    ```luau
    submoduleReturn: any -- The return value of requiring the submodule.
    options: BuildSubmoduleOptions -- The options containing the construction method name and arguments.
    ```

    ### Returns:
    ```luau
    boolean -- Returns true if construction was successful, false otherwise.
    ```
]=]
ConstructSubmodule = function(submoduleReturn, options)
    if not submoduleReturn then
        LogError("Attempted to construct a nil submodule")
        return false
    end

    if not submoduleReturn[options.ConstructionMethod] then
        LogError(`Submodule is missing the construction method`)
        return false
    end

    local constructionSuccess = xpcall(submoduleReturn[options.ConstructionMethod], LogError, unpack(options.ConstructionArguments))
    if not constructionSuccess then
        return false
    end

    return true
end

--[=[
    Initializes a submodule by calling its initialization method with specified options.

    ### Parameters:
    ```luau
    submoduleReturn: any -- The return value of requiring the submodule.
    options: BuildSubmoduleOptions -- The options containing the initialization method name and arguments.
    ```

    ### Returns:
    ```luau
    boolean -- Returns true if initialization was successful, false otherwise.
    ```
]=]
InitializeSubmodule = function(submoduleReturn, options)
    if not submoduleReturn then
        LogError("Attempted to initialize a nil submodule")
        return false
    end

    if not submoduleReturn[options.InitializationMethod] then
        LogError(`Submodule is missing the initialization method`)
        return false
    end

    local initializationSuccess = xpcall(submoduleReturn[options.InitializationMethod], LogError, unpack(options.InitializationArguments))
    if not initializationSuccess then
        return false
    end

    return true
end

--[=[
    Builds submodules for a given parent instance based on specified options.

    ### Parameters:
    ```luau
    parent: Instance -- The parent instance to build submodules under.
    options: BuildSubmoduleOptions? -- Optional configuration for submodule construction and initialization.
    ```

    ### Returns:
    ```luau
    boolean -- Returns true if submodules were successfully built, false otherwise.
    {table}? -- A table containing the built submodules, or nil if building failed.
    ```
]=]
BuildSubmodules = function(submodules, options)
    if not options.ConstructionMethod then
        LogError("Construction method name is not defined. Define it using DefineConstructionMethodName. Cannot build submodules.")
        return false
    end

    if not options.InitializationMethod then
        LogError("Initialization method name is not defined. Define it using DefineInitializationMethodName. Cannot build submodules.")
        return false
    end

    for submoduleIndex = #submodules, 1, -1 do
        local submodule = submodules[submoduleIndex]
        if typeof(submodule) ~= "Instance" or not submodule:IsA("ModuleScript") then
            table.remove(submodules, submoduleIndex)
        end
    end

    -- Apply filtering based on options.
    if options.FilterType and options.Filter then
        if typeof(options.FilterType) ~= "string" then
            LogError("FilterType must be a string")
            return false
        end

        if typeof(options.Filter) ~= "table" then
            LogError("Filter must be a table of strings")
            return false
        end

        if options.FilterType == "Whitelist" then
            for submoduleIndex = #submodules, 1, -1 do
                local submodule = submodules[submoduleIndex]
                if not table.find(options.Filter, submodule.Name) then
                    table.remove(submodules, submoduleIndex)
                end
            end
        elseif options.FilterType == "Blacklist" then
            for submoduleIndex = #submodules, 1, -1 do
                local submodule = submodules[submoduleIndex]
                if table.find(options.Filter, submodule.Name) then
                    table.remove(submodules, submoduleIndex)
                end
            end
        else
            LogError("FilterType is not a valid filter type.")
            return false
        end
    end

    -- Exclude templates if the option is enabled.
    if options.ExcludeTemplates then
        for submoduleIndex = #submodules, 1, -1 do
            local submodule = submodules[submoduleIndex]
            if string.find(submodule.Name, TEMPLATE_TOKEN) then
                table.remove(submodules, submoduleIndex)
            end
        end
    end

    local builtSubmodules = {}
    for _, submodule: ModuleScript in submodules do
        local submoduleName = submodule.Name
        local submoduleRequired = require(submodule)

        local constructionSuccess = ConstructSubmodule(submoduleRequired, options)
        if not constructionSuccess then
            LogError(`Failed to construct submodule {submoduleName}, continuing without it`)
            continue
        end

        local initializationSuccess = InitializeSubmodule(submoduleRequired, options)
        if not initializationSuccess then
            LogError(`Failed to initialize submodule {submoduleName}, continuing without it`)
            continue
        end

        builtSubmodules[submoduleName] = submoduleRequired
    end

    return true, builtSubmodules
end

BuildChildrenSubmodules = function(parent, options)
    options = if options
        then TableUtils.MergeDictionaries(options, BuildSubmoduleOptionDefaults)
        else BuildSubmoduleOptionDefaults

    local submodules = parent:GetChildren()
    return BuildSubmodules(submodules, options)
end

--// EXPORTS \\--
submoduleUtils.DefineConstructionMethodName = DefineConstructionMethodName
submoduleUtils.DefineInitializationMethodName = DefineInitializationMethodName
submoduleUtils.BuildChildrenSubmodules = BuildChildrenSubmodules

--// RUNTIME \\--
return submoduleUtils