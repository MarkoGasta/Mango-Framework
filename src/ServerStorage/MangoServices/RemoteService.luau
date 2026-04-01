--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local RemoteService = {}
function RemoteService.__Construct()

    --// SERVICES \--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")

    --// CONFIG \--

    --// MODULES \--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local TextUtils = MangoServer.Require("TextUtils")
    local Connector = MangoServer.Require("Connector")
    local Logger = MangoServer.Require("Logger")

    --// TYPES \--

    --// CONSTANTS \--

    local RemoteStorage: Folder
    
    --// VARIABLES \--

    --// FUNCTIONS \--

    --[=[
        Generates and stores a per-player remote validation key.

        ### Parameters:
        ```luau
        player: Player -- The player requesting a remote key.
        ```

        ### Returns:
        ```luau
        boolean -- Whether key generation succeeded.
        number? -- Generated key value when successful.
        ```
    ]=]
    local function GenerateKey(player: Player): string

        -- Kicking the player if they request a key twice.
        if MangoServer.GetCacheField(player, "RemoteKey") then
            player:Kick("Remote key re-request detected.")
            return false
        end

        local playerKey = tonumber(TextUtils.GenerateRandomString(9, {
            CapitalLetters = false,
            SmallLetters = false,
            Numbers = true,
        }))

        local playerRandom = Random.new(playerKey)
        MangoServer.SetCacheField(player, "RemoteKey", playerKey)
        MangoServer.SetCacheField(player, "RemoteRandom", playerRandom)
        return true, playerKey
    end

    --[=[
        Resolves a remote instance by name from remote storage.

        ### Parameters:
        ```luau
        name: string -- Remote instance name.
        ```

        ### Returns:
        ```luau
        RemoteEvent | RemoteFunction | nil -- Matching remote instance when found.
        ```
    ]=]
    local function GetRequestedRemote(name: string): RemoteEvent | RemoteFunction | nil
        local remoteInstance = RemoteStorage:FindFirstChild(name)
        return remoteInstance
    end

    --[=[
        Destroys a named remote event if it exists.

        ### Parameters:
        ```luau
        eventName: string -- RemoteEvent name to destroy.
        ```
    ]=]
    local function DestroyRemoteEvent(eventName: string)
        local remoteEvent = GetRequestedRemote(eventName)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:Destroy()
        end
    end

    --[=[
        Destroys a named remote function if it exists.

        ### Parameters:
        ```luau
        functionName: string -- RemoteFunction name to destroy.
        ```
    ]=]
    local function DestroyRemoteFunction(functionName: string)
        local remoteFunction = GetRequestedRemote(functionName)
        if remoteFunction and remoteFunction:IsA("RemoteFunction") then
            remoteFunction:Destroy()
        end
    end

    --[=[
        Creates and stores a new remote event.

        ### Parameters:
        ```luau
        name: string -- Name to assign to the remote event.
        ```

        ### Returns:
        ```luau
        RemoteEvent -- Newly created remote event.
        ```
    ]=]
    local function CreateRemoteEvent(name: string): RemoteEvent
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = RemoteStorage
        return remoteEvent
    end

    --[=[
        Creates and stores a new remote function.

        ### Parameters:
        ```luau
        name: string -- Name to assign to the remote function.
        ```

        ### Returns:
        ```luau
        RemoteFunction -- Newly created remote function.
        ```
    ]=]
    local function CreateRemoteFunction(name: string): RemoteFunction
        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = name
        remoteFunction.Parent = RemoteStorage
        return remoteFunction
    end

    --[=[
        Fires a remote event to one client.

        ### Parameters:
        ```luau
        player: Player -- Target player.
        eventName: string -- RemoteEvent name.
        ...: any... -- Event payload values.
        ```

        ### Returns:
        ```luau
        boolean -- Whether the event was fired.
        ```
    ]=]
    local function FireClient(player: Player, eventName: string, ...: any...): boolean
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            remoteEvent = CreateRemoteEvent(eventName)
            Logger.warn(`Please, create the remote event '{eventName}' explicitly for syncing with client`)
        end

        if not remoteEvent:IsA("RemoteEvent") then
            return false
        end

        remoteEvent:FireClient(player, ...)
        return true
    end

    --[=[
        Fires a remote event to a list of clients.

        ### Parameters:
        ```luau
        players: {Player} -- Target players.
        eventName: string -- RemoteEvent name.
        ...: any... -- Event payload values.
        ```

        ### Returns:
        ```luau
        boolean -- Whether the event was fired.
        ```
    ]=]
    local function FireClients(players: {Player}, eventName: string, ...: any...): boolean
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            remoteEvent = CreateRemoteEvent(eventName)
            Logger.warn(`Please, create the remote event '{eventName}' explicitly for syncing with client`)
        end

        if not remoteEvent:IsA("RemoteEvent") then
            return false
        end

        for _, player in players do
            if not player:IsA("Player") then
                Logger.warn(`Invalid player instance provided for firing remote event '{eventName}'`)
                continue
            end

            remoteEvent:FireClient(player, ...)
        end

        return true
    end

    --[=[
        Fires a remote event to all connected clients.

        ### Parameters:
        ```luau
        eventName: string -- RemoteEvent name.
        ...: any... -- Event payload values.
        ```

        ### Returns:
        ```luau
        boolean -- Whether the event was fired.
        ```
    ]=]
    local function FireAllClients(eventName: string, ...: any...): boolean
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            remoteEvent = CreateRemoteEvent(eventName)
            Logger.warn(`Please, create the remote event '{eventName}' explicitly for syncing with client`)
        end

        if not remoteEvent:IsA("RemoteEvent") then
            return false
        end

        remoteEvent:FireAllClients(...)
        return true
    end

    --[=[
        Connects a callback to a server remote event with key validation.

        ### Parameters:
        ```luau
        eventName: string -- RemoteEvent name.
        callback: (Player, any...) -> () -- Handler called after validation.
        ```

        ### Returns:
        ```luau
        table? -- Connector connection table when successful.
        ```
    ]=]
    local function OnServerEvent(eventName: string, callback: (Player, any...) -> ()): table?
        local remoteEvent = GetRequestedRemote(eventName)
        if not remoteEvent then
            remoteEvent = CreateRemoteEvent(eventName)
        end
        
        if not remoteEvent:IsA("RemoteEvent") then
            Logger.warn(`Remote '{eventName}' is not a RemoteEvent`)
            return 
        end

        return Connector.Connect(remoteEvent.OnServerEvent, function(player: Player, ...: any...)
            local playerRemoteRandom: Random = MangoServer.GetCacheField(player, "RemoteRandom")
            local playerFirstRemoteFired: boolean = MangoServer.GetCacheField(player, "FirstRemoteFired")
            if not playerRemoteRandom and playerFirstRemoteFired then
                player:Kick("Remote event accessed without a valid key detected.")
                return
            end

            -- Security check for the key value.
            local receivedArguments = {...}
            if playerFirstRemoteFired then
                local expectedKeyValue = playerRemoteRandom:NextInteger(100000000, 999999999)
                local receivedKeyValue = receivedArguments[1]
                if receivedKeyValue ~= expectedKeyValue then
                    player:Kick("Remote event accessed with an invalid key detected.")
                    return
                end

                table.remove(receivedArguments, 1)
            else
                MangoServer.SetCacheField(player, "FirstRemoteFired", true)
            end

            callback(player, table.unpack(receivedArguments))
        end)
    end

    --[=[
        Registers a server invoke handler with key validation.

        ### Parameters:
        ```luau
        functionName: string -- RemoteFunction name.
        callback: (Player, any...) -> (any...) -- Invoke handler called after validation.
        ```

        ### Returns:
        ```luau
        RemoteFunction? -- Registered remote function when successful.
        ```
    ]=]
    local function OnServerInvoke(functionName: string, callback: (Player, any...) -> (any...)): RemoteFunction?
        local remoteFunction = GetRequestedRemote(functionName)
        if not remoteFunction then
            remoteFunction = CreateRemoteFunction(functionName)
        end

        if not remoteFunction:IsA("RemoteFunction") then
            Logger.warn(`Remote '{functionName}' is not a RemoteFunction`)
            return
        end

        remoteFunction.OnServerInvoke = function(player: Player, ...: any...)
            local playerRemoteRandom: Random = MangoServer.GetCacheField(player, "RemoteRandom")
            local playerFirstRemoteFired: boolean = MangoServer.GetCacheField(player, "FirstRemoteFired")
            if not playerRemoteRandom and playerFirstRemoteFired then
                player:Kick("Remote function accessed without a valid key detected.")
                return
            end

            -- Security check for the key value.
            local receivedArguments = {...}
            if playerFirstRemoteFired then
                local expectedKeyValue = playerRemoteRandom:NextInteger(100000000, 999999999)
                local receivedKeyValue = receivedArguments[1]
                if receivedKeyValue ~= expectedKeyValue then
                    player:Kick("Remote function accessed with an invalid key detected.")
                    return
                end

                table.remove(receivedArguments, 1)
            else
                MangoServer.SetCacheField(player, "FirstRemoteFired", true)
            end

            return callback(player, table.unpack(receivedArguments))
        end

        return remoteFunction
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --// RUNTIME \--

        --// EXPORTS \--
    end

    --// RUNTIME \--
    RemoteStorage = Instance.new("Folder")
    RemoteStorage.Name = "_RemoteStorage"
    RemoteStorage.Parent = ReplicatedStorage

    OnServerInvoke("REMOTE_CONTROLLER_REQUEST_KEY", GenerateKey)

    --// EXPORTS \--
    RemoteService.__Init = Init
    RemoteService.CreateRemoteEvent = CreateRemoteEvent
    RemoteService.CreateRemoteFunction = CreateRemoteFunction
    RemoteService.DestroyRemoteEvent = DestroyRemoteEvent
    RemoteService.DestroyRemoteFunction = DestroyRemoteFunction
    RemoteService.FireClient = FireClient
    RemoteService.FireClients = FireClients
    RemoteService.FireAllClients = FireAllClients
    RemoteService.OnServerEvent = OnServerEvent
    RemoteService.OnServerInvoke = OnServerInvoke
    RemoteService.GetRequestedRemote = GetRequestedRemote
end

return RemoteService