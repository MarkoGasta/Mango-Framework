--[[
-----------------------------------------------------------------------------
Last Updated - 15. Oct 2025.
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

--// CONFIG \\--
local MODULE_WAIT_TIMEOUT = 10
local MODULE_CONTAINERS = {
    ReplicatedFirst,
    ReplicatedStorage:WaitForChild("Controllers"),
    ReplicatedStorage:WaitForChild("Settings"),
    ReplicatedStorage:WaitForChild("Resources"),
    ReplicatedStorage:WaitForChild("MangoControllers"),
    ReplicatedStorage:WaitForChild("MangoResources"):WaitForChild("Client"),
    ReplicatedStorage:WaitForChild("MangoResources"):WaitForChild("Shared"),
}

--// MODULES \\--
local Types = require(script.Types)
local RuntimeSettings: table?

--// TYPES \\--

--// CONSTANTS \\--
local MangoClient = {
    Global = {}
}

--// VARIABLES \\--
local moduleCache = {}
local lockedModules = {}

--// FUNCTIONS \\--

--[=[
	Logs an error message to the console with a MangoClient prefix.

	### Parameters:
	```luau
	message: string -- The error message to log.
	```
]=]
local function LogError(message: string)
    warn(`[MangoClient] {message}`)
end

--[=[
	Caches a module in the internal module cache.

	### Parameters:
	```luau
	moduleName: string -- The name of the module to cache.
	module: table -- The module table to cache.
	```
]=]
local function CacheModule(moduleName: string, module: table)
    moduleCache[moduleName] = module
end

--[=[
	Locks a module to prevent it from being required.

	### Parameters:
	```luau
	moduleName: string -- The name of the module to lock.
	```
]=]
local function LockModule(moduleName: string)
    lockedModules[moduleName] = true
end

--[=[
	Requires a module from specified containers with caching and construction logic.

	### Parameters:
	```luau
	moduleName: Types.ModuleNames -- The name of the module to require.
	```

	### Returns:
	```luau
	any -- The required module, or nil if not found or locked.
	```
]=]
local function Require(moduleName: Types.ModuleNames)
    if lockedModules[moduleName] then
        LogError(`Module '{moduleName}' is locked and cannot be required`)
        return nil
    end

    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end

    -- Caching a class, if not found.
    local startTime = os.clock()
    local currentTime = startTime
    while currentTime - startTime < MODULE_WAIT_TIMEOUT do
        for _, moduleContainer: Folder in MODULE_CONTAINERS do
            local module: ModuleScript? = moduleContainer:FindFirstChild(moduleName, true)
            if not module then
                continue
            end

            -- Only cache top level modules.
            if module:FindFirstAncestorOfClass("ModuleScript") then
                continue
            end

            local requiredModule = require(module)
            moduleCache[moduleName] = requiredModule

            -- If the module being required is being called by a construction method, pre-construct the module if it has one.
            if RuntimeSettings then
                local callingFunction = debug.info(2, "n")
                local constructionMethod = RuntimeSettings.CONSTRUCTION_METHOD
                local isCallingFunctionConstructor = callingFunction == constructionMethod
                local isRequiredModuleTable = typeof(requiredModule) == "table"
                if isRequiredModuleTable then
                    local hasRequiredModuleConstructionMethod = requiredModule[constructionMethod] ~= nil
                    local wasRequiredModuleConstructed = requiredModule[RuntimeSettings.CONSTRUCTED_FLAG] == true
                    if isCallingFunctionConstructor and hasRequiredModuleConstructionMethod and not wasRequiredModuleConstructed then
                        requiredModule[constructionMethod]()
                        requiredModule[RuntimeSettings.CONSTRUCTED_FLAG] = true
                    end
                end
            end

            return requiredModule
        end

        currentTime = os.clock()
        task.wait(1)
    end

    LogError(`Module "{moduleName}" not found in specified containers, waited {MODULE_WAIT_TIMEOUT} seconds!`)
    return nil
end

--// EXPORTS \\--
MangoClient.CacheModule = CacheModule
MangoClient.LockModule = LockModule
MangoClient.Require = Require:: Types.Modules

--// RUNTIME \\--
RuntimeSettings = Require("RuntimeSettings")
MangoClient.Global.ConstructionMethod = RuntimeSettings.CONSTRUCTION_METHOD
MangoClient.Global.InitializationMethod = RuntimeSettings.INITIALIZATION_METHOD

local SubmoduleUtils = Require("SubmoduleUtils")
SubmoduleUtils.DefineConstructionMethodName(RuntimeSettings.CONSTRUCTION_METHOD)
SubmoduleUtils.DefineInitializationMethodName(RuntimeSettings.INITIALIZATION_METHOD)

return MangoClient