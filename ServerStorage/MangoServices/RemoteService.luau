--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local LOG_ERRORS = true

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// MODULES \\--

local MangoServer = require(ServerStorage.MangoServer)
local Logger = MangoServer.Require("Logger")

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local RemoteService = {}
local remoteEventCallbacks = {}
local remoteFunctionCallbacks = {}
local remoteEvent: RemoteEvent
local remoteFunction: RemoteFunction

--// FUNCTIONS \\--

-- Fires client remote event.
local function FireClient(player: Player, remoteName: string, ...)
    remoteEvent:FireClient(player, remoteName, ...)
end

-- Fires all client remote events.
local function FireAllClients(remoteName: string, ...)

    -- Iterating over all players.
    for _, player: Player in Players:GetPlayers() do
        remoteEvent:FireClient(player, remoteName, ...)
    end
end

-- Connecting callback to remote event.
local function OnServerEvent(remoteName: string, callback: (player: Player, ...any) -> table)
    
    -- Checking if event has callback table.
    if not remoteEventCallbacks[remoteName] then
        remoteEventCallbacks[remoteName] = {}
    end

    table.insert(remoteEventCallbacks[remoteName], callback)
end

-- Connecting callback to remote function.
local function OnServerInvoke(remoteName: string, callback: (player: Player, ...any) -> table | any)

    -- If callback is a function, then set it as callback.
    -- If callback is a value, then return the callback value.
    if typeof(callback) == "function" then
        remoteFunctionCallbacks[remoteName] = callback
    else
        remoteFunctionCallbacks[remoteName] = function()
            return callback
        end
    end
end

-- Handles recieving remote event call.
local function RemoteEventCall(player: Player, remoteName: string, ...)

    -- Checking if event has any callbacks.
    if not remoteEventCallbacks[remoteName] then
        if LOG_ERRORS then
            return Logger.warn(`Remote event {remoteName} doesn't have any server callbacks, check that you have written the remote name correctly!`, {
                printCallstack = true
            })
        else 
            return
        end
    end
    
    -- Calling all event callback functions.
    for _, callback in remoteEventCallbacks[remoteName] do
        callback(player, ...)
    end
end

-- Handles recieving remote function call.
local function RemoteFunctionCall(player: Player, remoteName: string, ...)

    -- Checking if event has any callbacks.
    if not remoteFunctionCallbacks[remoteName] then
        if LOG_ERRORS then
            return Logger.warn(`Remote function {remoteName} doesn't have any server callbacks, check that you have written the remote name correctly!`, {
                printCallstack = true
            })
        else 
            return
        end
    end

    -- Calling remote function callback.
    return remoteFunctionCallbacks[remoteName](player, ...)
end

-- Exporting methods.
RemoteService.FireClient = FireClient
RemoteService.FireAllClients = FireAllClients
RemoteService.OnServerEvent = OnServerEvent
RemoteService.OnServerInvoke = OnServerInvoke

-- Initiation method.
function RemoteService.Init()
    
    -- Creating required remotes.
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Parent = ReplicatedStorage
    remoteEvent.Name = "FunneledRemoteEvent"

    remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Parent = ReplicatedStorage
    remoteFunction.Name = "FunneledRemoteFunction"

    -- Connections.
    remoteEvent.OnServerEvent:Connect(RemoteEventCall)
    remoteFunction.OnServerInvoke = RemoteFunctionCall
end

return RemoteService