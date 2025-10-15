--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local LOG_ERRORS = false

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES \\--

local MangoClient = require(ReplicatedStorage.MangoClient)
local Logger = MangoClient.Require("Logger")
local WaitFor = MangoClient.Require("WaitFor")

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local RemoteService = {}
local remoteEventCallbacks = {}
local remoteEvent: RemoteEvent
local remoteFunction: RemoteFunction

--// FUNCTIONS \\--

-- Fires remote call to server.
local function FireServer(remoteName: string, ...)

    -- Waiting for remote event to exist.
    if not remoteEvent then
        WaitFor.Custom(function()
            return remoteEvent
        end):await()
    end

    remoteEvent:FireServer(remoteName, ...)
end

-- Fires remote function call to server.
local function InvokeServer(remoteName: string, ...)

    -- Waiting for remote function to exist.
    if not remoteFunction then
        WaitFor.Custom(function()
            return remoteFunction
        end):await()
    end

    return remoteFunction:InvokeServer(remoteName, ...)
end

-- Connecting callback to remote event.
local function OnClientEvent(remoteName: string, callback: (player: Player, ...any) -> table)
    
    -- Checking if event has callback table.
    if not remoteEventCallbacks[remoteName] then
        remoteEventCallbacks[remoteName] = {}
    end

    table.insert(remoteEventCallbacks[remoteName], callback)
end

-- Handles recieving remote event call.
local function RemoteEventCall(remoteName: string, ...)

    -- Checking if event has any callbacks.
    if not remoteEventCallbacks[remoteName] then
        if LOG_ERRORS then
            return Logger.warn(`Remote event {remoteName} doesn't have any client callbacks, check that you have written the remote name correctly!`, {
                printCallstack = true
            })
        else 
            return
        end
    end
    
    -- Calling all event callback functions.
    for _, callback in remoteEventCallbacks[remoteName] do
        callback(...)
    end
end

-- Exporting methods.
RemoteService.FireServer = FireServer
RemoteService.InvokeServer = InvokeServer
RemoteService.OnClientEvent = OnClientEvent

-- Initiation method.
function RemoteService.Init()
    remoteEvent = ReplicatedStorage:WaitForChild("FunneledRemoteEvent")
    remoteFunction = ReplicatedStorage:WaitForChild("FunneledRemoteFunction")

    -- Connections.
    remoteEvent.OnClientEvent:Connect(RemoteEventCall)
end

return RemoteService