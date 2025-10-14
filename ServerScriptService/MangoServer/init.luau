--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// MODULES \\--

local Types = require(script.Types)

--// TYPES \\--

--// CONSTANTS \\--

local ClassFolders = {
	ServerStorage.Services,
	ServerStorage.Resources,
    ServerStorage.MangoServices,
    ServerStorage.MangoServerResources,
	ReplicatedStorage.Settings,
	ReplicatedStorage.Packages,
	ReplicatedStorage.Resources.Shared,
	ReplicatedStorage.MangoReplicatedResources.Shared,
}

--// VARIABLES \\--

local MangoServer = {
    Global = {
        PlayerCache = {},
    }
}
local requiredClasses = {}

--// FUNCTIONS \\--

-- Returns a required class.
local function Require(className: Types.classNames, _loopIter: number?)
    
    -- Checking if class was previously required.
    if requiredClasses[className] then
        return requiredClasses[className]
    end

    -- Finding class by name.
    for _, classFolder: Folder in ClassFolders do
        for _, class: ModuleScript in classFolder:GetDescendants() do
            
            -- Checking class name.
            if class.Name ~= className then
                continue
            end

            -- Checking if class is descendant of another class.
            if class:FindFirstAncestorWhichIsA("ModuleScript") then
                continue
            end

            local requiredClass = require(class)
            
            -- Caching and returning class.
            requiredClasses[class.Name] = requiredClass
            return requiredClass
        end
    end

    -- Delaying looking through modules again in case game hasn't loaded it fully yet.
    if not _loopIter or (_loopIter and _loopIter < 20) then
        task.wait(0.1)
        return Require(className, _loopIter and _loopIter + 1 or 1)
    elseif _loopIter and _loopIter >= 20 then
        warn(`Couldn't find module {className}, check if it exists or is miss spelled`)
    end
end

-- Retuns the players cache.
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

-- Exporting methods.
MangoServer.GetPlayerCacheKeyValue = GetPlayerCacheKeyValue
MangoServer.SetPlayerCacheKeyValue = SetPlayerCacheKeyValue
MangoServer.Require = Require:: Types.classValues

-- Runtime.
-- Getting modules.
local Connector = Require("Connector")

-- Iterating over existing players.
for _, player: Player in Players:GetPlayers() do
    PlayerAdded(player)
end

-- Connecting signals.
Connector.ConnectWithPriority(Players.PlayerAdded, Connector.Enum.DefaultPriority - 10, PlayerAdded)
Connector.ConnectWithPriority(Players.PlayerRemoving, Connector.Enum.DefaultPriority + 10, PlayerRemoving)

return MangoServer