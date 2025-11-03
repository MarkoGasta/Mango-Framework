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
	ReplicatedStorage:WaitForChild("Settings"),
	ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Shared"),
	ReplicatedStorage:WaitForChild("MangoResources"):WaitForChild("Shared"),
}

--// MODULES \\--

local Types = require(script.Types)

--// TYPES \\--

--// CONSTANTS \\--

local MangoServer = {
    Global = {} :: {string: any}
}

--// VARIABLES \\--

local moduleCache = {}

--// FUNCTIONS \\--

--- Wrapper for logging error messages.
--- @param message string The message to log.
local function LogError(message: string)
    warn(`[MangoClient] {message}`)
end

--- Caches a module required externally.
--- @param moduleName string The name of the module.
--- @param module table The module to cache.
local function CacheModule(moduleName: string, module: table)
    moduleCache[moduleName] = module
end

--- Uses a class name to require or return a cached class.
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
            local callingFunction = debug.info(2, "n")
            local constructionMethod = MangoServer.Global.__ConstructionMethod
            local isCallingFunctionConstructor = callingFunction == constructionMethod
            local isRequiredModuleTable = typeof(requiredModule) == "table"
            if isRequiredModuleTable then
                local hasRequiredModuleConstructionMethod = requiredModule[constructionMethod] ~= nil
                local wasRequiredModuleConstructed = requiredModule["__IsConstructed"] == true
                if isCallingFunctionConstructor and hasRequiredModuleConstructionMethod and not wasRequiredModuleConstructed then
                    requiredModule[constructionMethod]()
                    requiredModule[MangoServer.Global.__ConstructedFlag] = true
                end
            end

            return requiredModule
        end

        currentTime = os.clock()
        task.wait(1)
    end
    
    LogError(`Module "{moduleName}" not found in specified containers, waited {MODULE_WAIT_TIMEOUT} seconds!`)
end

-- Returns the players cache.
local function GetPlayerCache(player: Player)
    
    -- Getting modules and data.
    local WaitFor = Require("WaitFor")
    local success: boolean, playerCache: table = WaitFor.Custom(function()
        return MangoServer.Global.PlayerCache[player]
    end):timeout(5):await()

    -- Checking if successfully got player cache.
    if not success then
        warn(`Failed to get player cache for {player}`)
        return
    end

    return playerCache
end

-- Gets the value of a specific key in a players cache.
local function GetPlayerCacheKeyValue(player: Player, key: string)

    -- Getting cache key value.
	local playerCache = GetPlayerCache(player)
    return playerCache[key]
end

-- Sets the value of a specific key in a players cache.
local function SetPlayerCacheKeyValue(player: Player, key: string, value: any)

    -- Writing value to key in cache.
    local playerCache = GetPlayerCache(player)
    playerCache[key] = value
end

-- Handles player being added to the game.
local function PlayerAdded(player: Player)

    -- Creating player cache.
    MangoServer.Global.PlayerCache[player] = {}
end

-- Handles player leaving the game.
local function PlayerRemoving(player: Player)
    
    -- Destroying player cache.
    MangoServer.Global.PlayerCache[player] = nil
end

--// RUNTIME \\--
for _, player: Player in Players:GetPlayers() do
    PlayerAdded(player)
end

local Connector = Require("Connector")
-- Connector.ConnectWithPriority(Players.PlayerAdded, Connector.Enum.DefaultPriority - 10, PlayerAdded)
-- Connector.ConnectWithPriority(Players.PlayerRemoving, Connector.Enum.DefaultPriority + 10, PlayerRemoving)

--// EXPORTS \\--
MangoServer.GetPlayerCacheKeyValue = GetPlayerCacheKeyValue
MangoServer.SetPlayerCacheKeyValue = SetPlayerCacheKeyValue
MangoServer.CacheModule = CacheModule
MangoServer.Require = Require :: Types.Modules

return MangoServer