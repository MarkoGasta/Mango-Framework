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

--// SERVICES \\--

--// CONFIG \\--
local REDUNDANCY_CHECK_INTERVAL = 180

--// MODULES \\--

local TableUtils = require(script.TableUtils)
local TextUtils = require(script.TextUtils)

--// TYPES \\--

type ConnectionInstance = {
    __Callback: (any...) -> (any...),
    _AdditionalArguments: table,
    _Options: ConnectOptions,
    Id: string,
}
type ConnectOptions = {
    Priority: number?,
    Condition: any?,
    OverrideExisting: boolean?,
    IgnoreSignalArguments: boolean?,
}

type Connect<sA, aA> = (RBXScriptSignal, (sA, aA) -> (any...), aA...) -> ConnectionInstance |
    (RBXScriptSignal, (sA, aA) -> (any...), ConnectOptions?, aA...) -> ConnectionInstance

--// CONSTANTS \\--

local Enums = {
    DefaultPriority = 10,
    GameStartPriority = 11,
}

local ConnectOptionsDefaults: ConnectOptions = {
    Priority = Enums.DefaultPriority,
    Condition = nil,
    OverrideExisting = false,
    IgnoreSignalArguments = false,
}

--// VARIABLES \\--

local Connector = {
    Enum = Enums
}

local connectionInstances = {}
local signalConnections = {}

--// FUNCTIONS \\--

local function GetSignalConnectionWithSignal(signal: RBXScriptSignal)
    for _, signalConnection: table in signalConnections do
        if signalConnection.__Signal == signal then
            return signalConnection
        end
    end

    return nil
end

local function CreateSignalConnection(signal: RBXScriptSignal)
    local existingSignalConnectionId = TableUtils.FindValueInDictionary(signalConnections, signal)
    if existingSignalConnectionId then
        local existingSignalConnection = signalConnections[existingSignalConnectionId]
        existingSignalConnection._Connection:Disconnect()
        signalConnections[existingSignalConnectionId] = nil
    end

    local signalConnectionId: string
    while not signalConnectionId or signalConnections[signalConnectionId] do
        signalConnectionId = TextUtils.GenerateIdentifier()
    end
    
    local newSignalConnection = {
        __Signal = signal,
        _connectionInstances = {},
        Id = signalConnectionId,
    }

    signalConnections[signalConnectionId] = newSignalConnection
    newSignalConnection.__Connection = signal:Connect(function(...)
        local signalArguments = {...}

        -- Calling connection instance callbacks.
        for _, connectionInstanceId: table in newSignalConnection._connectionInstances do
            local connectionInstance = connectionInstances[connectionInstanceId]
            if not connectionInstance then
                continue
            end

            -- Checking if the first argument matches condition criteria.
            if connectionInstance._Options.Condition and signalArguments[1] ~= connectionInstance._Options.Condition then
                continue
            end

            -- Checking the number of signal arguments, if it's 0 then calling without them.
            if #signalArguments <= 0 or connectionInstance._Options.IgnoreSignalArguments then
                task.spawn(function()
                    xpcall(connectionInstance.__Callback, function(errorMessage: string)
                        warn(debug.traceback(errorMessage, 2))
                    end, table.unpack(connectionInstance._AdditionalArguments))
                end)
            else
                -- Concating argument tables.
                local combinedArguments = TableUtils.MergeArrays(signalArguments, connectionInstance._AdditionalArguments)
                task.spawn(function()
                    xpcall(connectionInstance.__Callback, function(errorMessage: string)
                        warn(debug.traceback(errorMessage, 2))
                    end, table.unpack(combinedArguments))
                end)
            end
        end
    end)

    return newSignalConnection
end

function Connector.Disconnect(connectionInstance: ConnectionInstance)
    local signalConnection = signalConnections[connectionInstance._SignalConnectionId]
    if not signalConnection then
        return
    end

    local signalConnectionConnectionInstances = signalConnection._connectionInstances
    local connectionInstanceIndex = table.find(signalConnectionConnectionInstances, connectionInstance.Id)
    table.remove(signalConnectionConnectionInstances, connectionInstanceIndex)
    connectionInstance.connected = false
    connectionInstances[connectionInstance.Id] = nil

    if #signalConnectionConnectionInstances <= 0 then
        signalConnection.__Connection:Disconnect()
        signalConnections[signalConnection.Id] = nil
    end
end

function Connector.Connect<sA, aA>(signal: RBXScriptSignal, callbackFunction: (sA, aA...) -> (any), options: ConnectOptions?, ...: aA...)
    options = options and TableUtils.MergeDictionaries(options, ConnectOptionsDefaults) or ConnectOptionsDefaults

    local connectionInstanceId: string
    while not connectionInstanceId or connectionInstances[connectionInstanceId] do
        connectionInstanceId = TextUtils.GenerateIdentifier()
    end

    local connectionInstance = {
        __Callback = callbackFunction,
        _AdditionalArguments = {...},
        _Options = options,
        Id = connectionInstanceId,
        connected = true,
    }

    connectionInstance.Disconnect = function()
        Connector.Disconnect(connectionInstance)
    end
    
    connectionInstances[connectionInstanceId] = connectionInstance
    
    local signalConnection = GetSignalConnectionWithSignal(signal)
    if not signalConnection or options.OverrideExisting then
        signalConnection = CreateSignalConnection(signal)
    end

    connectionInstance._SignalConnectionId = signalConnection.Id
    table.insert(signalConnection._connectionInstances, connectionInstanceId)
    table.sort(signalConnection._connectionInstances, function(connectionInstanceId1: ConnectionInstance, connectionInstanceId2: ConnectionInstance)
        local connectionInstance1 = connectionInstances[connectionInstanceId1]
        local connectionInstance2 = connectionInstances[connectionInstanceId2]
        local callbackPriority1 = connectionInstance1._Options.Priority
        local callbackPriority2 = connectionInstance2._Options.Priority
        return callbackPriority1 < callbackPriority2
    end)

    return connectionInstance
end

function Connector.Once<sA, aA>(signal: RBXScriptSignal, callbackFunction: (sA, aA...) -> (any), options: ConnectOptions, ...: aA...)
    options = options and TableUtils.MergeDictionaries(options, ConnectOptionsDefaults) or ConnectOptionsDefaults

    local connectionInstance: ConnectionInstance
    connectionInstance = Connector.Connect(signal, function(...)
        Connector.Disconnect(connectionInstance)
        return callbackFunction(...)
    end, options, ...)

    return connectionInstance
end

--// RUNTIME \\--

-- Deffering redundancy check loop.
task.defer(function()
    while true do
        task.wait(REDUNDANCY_CHECK_INTERVAL)

        -- Cleaning up disconnected signal connection instances.
        local disconnectedSignals = {}
        for signalConnectionId: string, signalConnection: table in signalConnections do
            if typeof(signalConnection.__Connection) == "RBXScriptConnection" and signalConnection.__Connection.Connected then
                continue
            elseif typeof(signalConnection.__Connection) ~= "RBXScriptConnection" then
                continue
            end

            for _, connectionInstanceId: table in signalConnection._connectionInstances do
                connectionInstances[connectionInstanceId] = nil
            end

            table.insert(disconnectedSignals, signalConnectionId)
        end

        -- Removing disconnected signals.
        for _, disconnectedSignalId: string in disconnectedSignals do
            signalConnections[disconnectedSignalId] = nil
        end
    end
end)

return Connector