--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local RemoteController = {}
function RemoteController.__Construct()

    --// SERVICES \--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \--

    --// MODULES \--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local Connector = MangoClient.Require("Connector")
    local Logger = MangoClient.Require("Logger")

    --// TYPES \--

    --// CONSTANTS \--

    local RemoteStorage: Folder
    local RemoteRandom: Random
    
    --// VARIABLES \--

    --// FUNCTIONS \--

    --[=[
        Gets a remote instance by name.

        ### Parameters:
        ```luau
        name: string -- The name of the remote.
        ```

        ### Returns:
        ```luau
        RemoteEvent | RemoteFunction | nil -- The remote instance or nil if not found.
        ```
    ]=]
    local function GetRequestedRemote(name: string): RemoteEvent | RemoteFunction | nil
        local remoteInstance = RemoteStorage:FindFirstChild(name)
        return remoteInstance
    end

    --[=[
        Fires a server event.

        ### Parameters:
        ```luau
        eventName: string -- The name of the event.
        ...: any... -- Additional arguments to pass.
        ```
    ]=]
    local function FireServer(eventName: string, ...: any...)
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            Logger.warn(`Remote event '{eventName}' does not exist`)
            return
        end

        if not remoteEvent:IsA("RemoteEvent") then
            Logger.warn(`Remote '{eventName}' is not a RemoteEvent`)
            return
        end

        if RemoteRandom then
            local nextKeyValue = RemoteRandom:NextInteger(100000000, 999999999)
            remoteEvent:FireServer(nextKeyValue, ...)
        else
            remoteEvent:FireServer(...)
        end

        return
    end

    --[=[
        Invokes a server function.

        ### Parameters:
        ```luau
        functionName: string -- The name of the function.
        ...: any? -- Additional arguments to pass.
        ```

        ### Returns:
        ```luau
        ...any? -- The return values from the server function.
        ```
    ]=]
    local function InvokeServer(functionName: string, ...: any?): ...any?
        local remoteFunction = GetRequestedRemote(functionName)
        if not remoteFunction then
            Logger.warn(`Remote function '{functionName}' does not exist.`)
            return
        end

        if not remoteFunction:IsA("RemoteFunction") then
            Logger.warn(`Remote '{functionName}' is not a RemoteFunction`)
            return
        end

        if RemoteRandom then
            local nextKeyValue = RemoteRandom:NextInteger(100000000, 999999999)
            return remoteFunction:InvokeServer(nextKeyValue, ...)
        else
            return remoteFunction:InvokeServer(...)
        end
    end

    --[=[
        Connects to a client event.

        ### Parameters:
        ```luau
        eventName: string -- The name of the event.
        callback: (any...) -> () -- The callback function.
        ```

        ### Returns:
        ```luau
        table? -- The connection object or nil if failed.
        ```
    ]=]
    local function OnClientEvent(eventName: string, callback: (any...) -> ()): table?
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            Logger.warn(`Remote event '{eventName}' does not exist`)
            return false
        end

        if not remoteEvent:IsA("RemoteEvent") then
            Logger.warn(`Remote '{eventName}' is not a RemoteEvent`)
            return
        end

        return Connector.Connect(remoteEvent.OnClientEvent, callback)
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --// RUNTIME \--

        --// EXPORTS \--
    end

    --// RUNTIME \--
    RemoteStorage = ReplicatedStorage:WaitForChild("_RemoteStorage")

    -- Posting request to generate a remote key for accessing remotes.
    local success: boolean, key: string = InvokeServer("REMOTE_CONTROLLER_REQUEST_KEY")
    if not success then
        Logger.error("Failed to obtain remote controller key from server!")
        return
    end

    RemoteRandom = Random.new(key)

    --// EXPORTS \--
    RemoteController.__Init = Init
    RemoteController.FireServer = FireServer
    RemoteController.InvokeServer = InvokeServer
    RemoteController.OnClientEvent = OnClientEvent
end

return RemoteController