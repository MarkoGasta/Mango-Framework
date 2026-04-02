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
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// CONFIG \\--

local MODULE_WAIT_TIMEOUT = 10
local MODULE_CONTAINERS = {
	ServerStorage:WaitForChild("Services"),
	ServerStorage:WaitForChild("Resources"),
    ServerStorage:WaitForChild("MangoServices"),
    ServerStorage:WaitForChild("MangoResources"),
    ReplicatedStorage:WaitForChild("Classes"),
	ReplicatedStorage:WaitForChild("Settings"),
	ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Shared"),
	ReplicatedStorage:WaitForChild("MangoResources"):WaitForChild("Shared"),
}

--// MODULES \\--
local Types = require(script.Types)
local RuntimeSettings

--// TYPES \\--

--// CONSTANTS \\--
local MangoServer = {
    Global = {},
    PlayerCache = {},
}

--// VARIABLES \\--
local moduleCache = {}
local cacheFieldHandlers = {}

--// FUNCTIONS \\--

--[=[
	Logs an error message to the console with a MangoServer prefix.

	### Parameters:
	```luau
	message: string -- The error message to log.
	```
]=]
local function LogError(message: string)
    warn(`[MangoClient] {message}\nStack trace:\n{debug.traceback()}`)
end

--[=[
	Invokes a named function on all registered general cache field handlers for a player.

	### Parameters:
	```luau
	player: Player -- The player to pass to each handler.
	cache: table -- The player's cache table to pass to each handler.
	handlerFunctionName: string -- The name of the handler function to call on each handler.
	```
]=]
local function CallCacheFieldHandlers(player: Player, cache: table, handlerFunctionName: string)
    for _, handler: table in cacheFieldHandlers do
        if typeof(handler[handlerFunctionName]) == "function" then
            local callSuccess = xpcall(handler[handlerFunctionName], LogError, player, cache)
            if not callSuccess then
                LogError(`Failed to call cache field handler function {handlerFunctionName}.`)
            end
        else
            LogError(`Cache field handler does not have function {handlerFunctionName}.`)
        end
    end
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
	Requires a module from specified containers with caching and construction logic.

	### Parameters:
	```luau
	moduleName: Types.ModuleNames -- The name of the module to require.
	```

	### Returns:
	```luau
	any -- The required module, or nil if not found.
	```
]=]
local function Require(moduleName: Types.ModuleNames)
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
end

--[=[
	Retrieves a cached value for a specific player.

	### Parameters:
	```luau
	player: Player -- The player whose cache to access.
	key: string -- The key of the cached value.
	```

	### Returns:
	```luau
	any -- The cached value, or nil if not found.
	```
]=]
local function GetCacheField(player: Player, key: string)
	local playerCache = MangoServer.PlayerCache[player]
    if not playerCache then
        LogError(`Player cache does not exist!`)
        return
    end

    return playerCache[key]
end

--[=[
	Sets a cached value for a specific player.

	### Parameters:
	```luau
	player: Player -- The player whose cache to modify.
	key: string -- The key to set.
	value: any -- The value to cache.
	```
]=]
local function SetCacheField(player: Player, key: string, value: any)
    local playerCache = MangoServer.PlayerCache[player]
    if not playerCache then
        LogError(`Player cache does not exist!`)
        return
    end

    playerCache[key] = value
end

-- Handles player being added to the game.
local function PlayerAdded(player: Player)
    local newPlayerCache = {}
    MangoServer.PlayerCache[player] = newPlayerCache
    CallCacheFieldHandlers(player, newPlayerCache, "PlayerCacheCreated")
end

-- Handles player leaving the game.
local function PlayerRemoving(player: Player)
    MangoServer.PlayerCache[player] = nil
end

--// RUNTIME \\--

RuntimeSettings = Require('RuntimeSettings')
MangoServer.Global.__ConstructionMethod = RuntimeSettings.CONSTRUCTION_METHOD
MangoServer.Global.__InitializationMethod = RuntimeSettings.INITIALIZATION_METHOD

local SubmoduleUtils = Require("SubmoduleUtils")
SubmoduleUtils.DefineConstructionMethodName(RuntimeSettings.CONSTRUCTION_METHOD)
SubmoduleUtils.DefineInitializationMethodName(RuntimeSettings.INITIALIZATION_METHOD)
SubmoduleUtils.BuildChildrenSubmodules(script.CacheFieldHandlers, {
    Cache = cacheFieldHandlers,
})

for _, player: Player in Players:GetPlayers() do
    task.defer(PlayerAdded, player)
end

local Connector = Require("Connector")
Connector.Connect(Players.PlayerAdded, PlayerAdded, {
    Priority = Connector.Enum.DefaultPriority - 10,
})
Connector.Connect(Players.PlayerRemoving, PlayerRemoving, {
    Priority = Connector.Enum.DefaultPriority + 10,
})


--// EXPORTS \\--
MangoServer.GetCacheField = GetCacheField
MangoServer.SetCacheField = SetCacheField
MangoServer.CacheModule = CacheModule
MangoServer.Require = Require :: Types.Modules

return MangoServer