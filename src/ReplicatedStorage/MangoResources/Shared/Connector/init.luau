--!strict
--// Script by: MarkoGasta2 \\--

--[[ 
The MIT License (MIT)
Copyright © 2025 MarkoGasta2

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--// CONFIG \\--

local REDUNDANCY_CHECK_INTERVAL = 180

--// SERVICES \\--

--// MODULES \\--

local TableUtils = require(script.TableUtils)
local TextUtils = require(script.TextUtils)

--// TYPES \\--

type SignalConnection = {}

--// CONSTANTS \\--

local Enums = {
    DefaultPriority = 10,
    GameStartPriority = 11,
}

--// VARIABLES \\--

local Connector = {
    Enum = Enums
}

local connectionInstances = {}
local signalConnections = {}
local lastRedundancyCheckTime = os.clock()

--// FUNCTIONS \\--

-- Disconnects a connection instance that has been passed to it.
function Connector.Disconnect(connectionInstance: SignalConnection)

    -- Removing connection instance from connection instances table.
    for index, existingConnectionInstance: SignalConnection in connectionInstances do
        if existingConnectionInstance == connectionInstance then
            connectionInstances[index] = nil
            break
        end
    end

    -- Removing signal connection if there are no more connection instances.
    local sameSignalConnectionExists = false
    for _, connectionInstanceIndex: SignalConnection in connectionInstances do
        if connectionInstanceIndex._Signal == connectionInstance._Signal then
            sameSignalConnectionExists = true
            break
        end
    end

    if not sameSignalConnectionExists then
        local signalConnection = signalConnections[connectionInstance._SignalConnectionId]
        if signalConnection then
            if signalConnection._Connection and signalConnection._Connection.Connected then
                signalConnection._Connection:Disconnect()
            end
            
            signalConnections[connectionInstance._SignalConnectionId] = nil
        end
    end
end

-- Private connect method, connects a script signal if it already isn't and calls it's callback functions.
local function Connect(signal: RBXScriptSignal, callbackFunction: () -> (), callbackArguments: table): SignalConnection

    -- Defining connection instance properties.
    local connectionInstance = {
        _Signal = signal,
        _Callback = callbackFunction,
        _CallbackArgs = callbackArguments,
        Priority = Enums.DefaultPriority,
        Condition = nil
    }

    -- Caching connection instance.
    local connectionInstanceId
    while not connectionInstanceId or connectionInstances[connectionInstanceId] do
        connectionInstanceId = TextUtils.GenerateIdentifier()
    end
    
    connectionInstances[connectionInstanceId] = connectionInstance

    -- Getting signal connection.
    local signalConnectionExists = false
    for connectionId: string, signalConnection: table in signalConnections do
        if signalConnection._Signal == signal then
            connectionInstance._SignalConnectionId = connectionId
            signalConnectionExists = true
            break
        end
    end
    
    -- Checking if a connection for this signal already exists.
    if not signalConnectionExists then

        -- Generating unique identifier for signal connection.
        local randomId: string
        while not randomId or signalConnections[randomId] do
            randomId = TextUtils.GenerateIdentifier()
        end

        -- Saving signal connection id to connection instance.
        connectionInstance._SignalConnectionId = randomId

        -- Creating a table for identifying signal connections.
        signalConnections[randomId] = {
            _Signal = signal,
            _Connection = signal:Connect(function(...)
                local signalArguments = {...}

                local timeSinceInterval = os.clock() - lastRedundancyCheckTime
                if timeSinceInterval > REDUNDANCY_CHECK_INTERVAL then
                    lastRedundancyCheckTime = os.clock()

                    local cleanedConnectionInstances = {}
                    for index, existingConnectionInstance: SignalConnection in connectionInstances do
                        local signalConnection = signalConnections[existingConnectionInstance._SignalConnectionId]
                        if signalConnection and signalConnection._Connection.Connected then
                            cleanedConnectionInstances[index] = existingConnectionInstance
                        end
                    end
                    
                    connectionInstances = cleanedConnectionInstances
                end

                -- Sorting connection instances.
                local connectionInstancesIndexes = TableUtils.GetIndexes(connectionInstances)
                table.sort(connectionInstancesIndexes, function(connectionInstanceIndex1: SignalConnection, connectionInstanceIndex2: SignalConnection)
                    local connectionInstance1 = connectionInstances[connectionInstanceIndex1]
                    local connectionInstance2 = connectionInstances[connectionInstanceIndex2]

                    -- Getting callback priority.
                    local callbackPriority1 = connectionInstance1.Priority
                    local callbackPriority2 = connectionInstance2.Priority

                    return callbackPriority1 < callbackPriority2
                end)

                for _, connectionInstanceIndex: table in connectionInstancesIndexes do
                    local connectionInstance = connectionInstances[connectionInstanceIndex]
                    if not connectionInstance then
                        continue
                    end

                    -- Checking if connection instance signal matches this signal.
                    if connectionInstance._Signal ~= signal then
                        continue
                    end

                    -- Checking if the first argument matches condition criteria.
                    if connectionInstance.Condition and signalArguments[1] ~= connectionInstance.Condition then
                        continue
                    end

                    -- Checking the number of signal arguments, if it's 0 then calling without them.
                    if #signalArguments <= 0 or connectionInstance.IgnoreActualArguments then
                        task.spawn(xpcall, connectionInstance._Callback, warn, table.unpack(connectionInstance._CallbackArgs))
                    else
                        -- Concating argument tables.
                        local combinedArguments = TableUtils.MergeArrays(signalArguments, connectionInstance._CallbackArgs)
                        task.spawn(xpcall, connectionInstance._Callback, warn, table.unpack(combinedArguments))
                    end
                end
            end)
        }
    end

    return connectionInstance
end

-- Used to connect a `RBXScriptSignal` to a callback function, like a standard :Connect method. Added
-- functionality to pass additional `arguments` to the callback function.
-- Any additional arguments are passed to the callback function.
--- @param signal RBXScriptSignal Any script signal (ex. MouseButton1Clicked, Triggered, Destroyed)
--- @param callbackFunction function Function that is connected to the script signal.
--- @return table SignalConnection Instance of the connection.
Connector.Connect = function<sA, cA>(signal: RBXScriptSignal, callbackFunction: (sA, cA) -> (any), ...: cA...): SignalConnection
    local connectionInstance = Connect(signal, callbackFunction, {...})
    return connectionInstance
end

-- Connects a `RBXScriptSignal` to a callback function and overrides any existing connection for
-- that signal. Works like a standard .Connect method, but removes any existing connections for that signal.
-- Any additional arguments are passed to the callback function.
--- @param signal RBXScriptSignal Any script signal (ex. MouseButton1Clicked, Triggered, Destroyed)
--- @param callbackFunction function Function that is connected to the script signal.
--- @return table SignalConnection Instance of the connection.
Connector.ConnectOverride = function<sA, cA>(signal: RBXScriptSignal, callbackFunction: (sA, cA) -> (any), ...: cA...): SignalConnection
    
    -- Iterating over connection instances and disconnecting them if they are the same signal.
    for _, connectionInstance: SignalConnection in connectionInstances do
        if connectionInstance._Signal == signal then
            Connector.Disconnect(connectionInstance)
        end
    end
    
    -- Connecting the signal again.
    local connectionInstance = Connect(signal, callbackFunction, {...})
    return connectionInstance
end

-- Connects a `RBXScriptSignal` to a callback function and sets the priority of the connection.
-- Connections with lower priority are called first.
-- Use the default priority `Connector.Enums.DefaultPriority` for reference.
-- Any additional arguments are passed to the callback function.
--- @param signal RBXScriptSignal Any script signal (ex. MouseButton1Clicked, Triggered, Destroyed)
--- @param priority number Priority of the connection. Lower numbers are called first.
--- @param callbackFunction function Function that is connected to the script signal.
--- @return table SignalConnection Instance of the connection.
Connector.ConnectWithPriority = function<sA, cA>(signal: RBXScriptSignal, priority: number, callbackFunction: (sA, cA) -> (any), ...: cA...): SignalConnection
    local connectionInstance = Connect(signal, callbackFunction, {...})
    connectionInstance.Priority = priority
    return connectionInstance
end

-- Connects a `RBXScriptSignal` to a callback function and sets the condition for the connection firing.
-- The connection will only fire if the first argument matches the condition criteria.
-- Any additional arguments are passed to the callback function.
--- @param signal RBXScriptSignal Any script signal (ex. MouseButton1Clicked, Triggered, Destroyed)
--- @param conditionCriteria any Condition criteria for the connection to fire.
--- @param callbackFunction function Function that is connected to the script signal.
--- @return table SignalConnection Instance of the connection.
Connector.ConnectArgumentCondition = function<sA, cA>(signal: RBXScriptSignal, conditionCriteria: any, callbackFunction: (sA, cA) -> (any), ...: cA...): SignalConnection
    local connectionInstance = Connect(signal, callbackFunction, {...})
    connectionInstance.Condition = conditionCriteria
    return connectionInstance
end

-- Connects a `RBXScriptSignal` to a callback function and ignores any arguments passed by the signal.
-- Only the additional arguments passed to this function will be passed to the callback function.
-- Any additional arguments are passed to the callback function.
--- @param signal RBXScriptSignal Any script signal (ex. MouseButton1Clicked, Triggered, Destroyed)
--- @param callbackFunction function Function that is connected to the script signal.
--- @return table SignalConnection Instance of the connection.
Connector.ConnectIgnoreArguments = function<sA, cA>(signal: RBXScriptSignal, callbackFunction: (sA, cA) -> (any), ...: cA...): SignalConnection
    local connectionInstance = Connect(signal, callbackFunction, {...})
    connectionInstance.IgnoreActualArguments = true
    return connectionInstance
end


return Connector