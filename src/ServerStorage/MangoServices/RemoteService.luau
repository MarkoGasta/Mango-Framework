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

    local function CreateRemoteEvent(name: string): RemoteEvent
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = RemoteStorage
        return remoteEvent
    end

    local function CreateRemoteFunction(name: string): RemoteFunction
        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = name
        remoteFunction.Parent = RemoteStorage
        return remoteFunction
    end

    local function GetRequestedRemote(name: string): RemoteEvent | RemoteFunction | nil
        local remoteInstance = RemoteStorage:FindFirstChild(name)
        return remoteInstance
    end

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
    RemoteService.FireClient = FireClient
    RemoteService.FireClients = FireClients
    RemoteService.FireAllClients = FireAllClients
    RemoteService.OnServerEvent = OnServerEvent
    RemoteService.OnServerInvoke = OnServerInvoke
    RemoteService.GetRequestedRemote = GetRequestedRemote
end

return RemoteService