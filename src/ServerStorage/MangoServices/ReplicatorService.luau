--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local ReplicatorService = {}
function ReplicatorService.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")
    local Players = game:GetService("Players")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local RemoteService = MangoServer.Require("RemoteService")
    local TableUtils = MangoServer.Require("TableUtils")
    local TextUtils = MangoServer.Require("TextUtils")
    local Logger = MangoServer.Require("Logger")
    local ReplicatorSettings = MangoServer.Require("ReplicatorSettings")

    --// TYPES \\--
    type AssignReplicaOptions = {
        ClassIdentifier: string?,
        ReplicationScope: string | Player | { Player } | nil,
        IgnorePrivateFields: boolean?,
        FilterMode: "WHITELIST" | "BLACKLIST",
        FilterList: { string }?,
        ManualSync: boolean?,
    }

    --// CONSTANTS \\--
    local AssignReplicaOptionsDefault: AssignReplicaOptions = {
        ClassIdentifier = "__GLOBALREPLICA",
        ReplicationScope = "ALL",
        IgnorePrivateFields = true,
        FilterMode = "BLACKLIST",
        FilterList = {},
        ManualSync = false,
    }
    
    --// VARIABLES \\--
    local replicaCache = setmetatable({}, {__mode = "v"})
    local replicaClasses = {}

    --// FUNCTIONS \\--
    --[=[
        Retrieves the replica associated with a root instance.

        ### Parameters:
        ```luau
        instance: table -- The root instance to look up.
        ```

        ### Returns:
        ```luau
        table? -- The replica if found, nil otherwise.
        ```
    ]=]
    local function GetReplicaByRootInstance(instance: table): table?
        return instance[ReplicatorSettings.ROOT_INSTANCE_REPLICA_KEY]
    end

    --[=[
        Determines which players should receive replica updates based on replication scope.

        ### Parameters:
        ```luau
        replica: table -- The replica to get replication targets for.
        ```

        ### Returns:
        ```luau
        {Player}? -- Array of target players for replication.
        ```
    ]=]
    local function GetReplicationTargets(replica: table): { Player }?
        if replica.Options.ReplicationScope == "ALL" then
            return Players:GetPlayers()
        elseif typeof(replica.Options.ReplicationScope) == "Instance" and replica.Options.ReplicationScope:IsA("Player") then
            return {replica.Options.ReplicationScope}
        elseif typeof(replica.Options.ReplicationScope) == "table" then
            return replica.Options.ReplicationScope
        else
            Logger.warn(`Invalid replication scope. No replication targets found!`)
            return {}
        end
    end

    --[=[
        Synchronizes staged replica changes to clients.

        ### Parameters:
        ```luau
        replica: table -- The replica with staged changes to sync.
        ```
    ]=]
    local function SyncReplicaChanges(replica: table): nil
        if TableUtils.GetTableLength(replica.stagedChanges) == 0 then
            return
        end

        local classRemoteName = string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, replica.Class)
        local replicationTargets = GetReplicationTargets(replica)
        RemoteService.FireClients(replicationTargets, classRemoteName, replica.Class, replica.Id, replica.stagedChanges)

        table.clear(replica.stagedChanges)
    end

    --[=[
        Processes a replica field update by staging it for replication.

        ### Parameters:
        ```luau
        replica: table -- The replica being updated.
        key: string -- The field name being changed.
        value: any -- The new value for the field.
        ```
    ]=]
    local function ProcessReplicaUpdate(replica: table, key: string, value: any)
        if replica.Options.IgnorePrivateFields and string.sub(key, 1, 1) == "_" then
            return
        end

        if replica.Options.FilterMode == "WHITELIST" then
            if not table.find(replica.Options.FilterList, key) then
                return
            end
        end

        if replica.Options.FilterMode == "BLACKLIST" then
            if table.find(replica.Options.FilterList, key) then
                return
            end
        end

        replica.stagedChanges[key] = value
        if not replica.Options.ManualSync then
            SyncReplicaChanges(replica)
        end
    end

    --[=[
        Assigns metamethods to a replica instance for automatic change tracking.

        ### Parameters:
        ```luau
        replica: table -- The replica to attach metamethods to.
        ```
    ]=]
    local function AssignReplicaMetamethods(replica: table)
        setmetatable(replica._ReplicaInstance, {
            __index = function(_, key)
                return replica.RootInstance[key]
            end,

            __newindex = function(_, key, value)
                rawset(replica.RootInstance, key, value)
                ProcessReplicaUpdate(replica, key, value)
            end,
        })
    end

    --[=[
        Undefines a replica class and cleans up associated resources.

        ### Parameters:
        ```luau
        classIdentifier: string -- The identifier of the class to undefine.
        ```
    ]=]
    local function UndefineReplicaClass(classIdentifier: string)
        local classIndex = table.find(replicaClasses, classIdentifier)
        if not classIndex then
            Logger.warn(`Replica class {classIdentifier} is not defined.`)
            return
        end

        RemoteService.FireAllClients("REPLICATOR_SERVICE_REPLICA_CLASS_UNDEFINED", classIdentifier)
        RemoteService.DestroyRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, classIdentifier))
        RemoteService.DestroyRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, classIdentifier))
        RemoteService.DestroyRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_DESTROYED_REMOTE_NAME_FORMAT, classIdentifier))
        table.remove(replicaClasses, classIndex)
    end

    --[=[
        Defines a new replica class and creates associated remote events.

        ### Parameters:
        ```luau
        classIdentifier: string -- The identifier for the new class.
        ```
    ]=]
    local function DefineReplicaClass(classIdentifier: string)
        if table.find(replicaClasses, classIdentifier) then
            Logger.warn(`Replica class {classIdentifier} is already defined.`)
            return
        end

        RemoteService.FireAllClients("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED", classIdentifier)
        RemoteService.CreateRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, classIdentifier))
        RemoteService.CreateRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, classIdentifier))
        RemoteService.CreateRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_DESTROYED_REMOTE_NAME_FORMAT, classIdentifier))
        table.insert(replicaClasses, classIdentifier)
    end

    --[=[
        Assigns a replica to a specified class.

        ### Parameters:
        ```luau
        replica: table -- The replica to assign.
        classIdentifier: string -- The class to assign the replica to.
        ```
    ]=]
    local function AssignReplicaToClass(replica: table, classIdentifier: string)
        replica.Class = classIdentifier

        if not table.find(replicaClasses, classIdentifier) then
            DefineReplicaClass(classIdentifier)
        end
    end

    --[=[
        Destroys a replica and notifies clients.

        ### Parameters:
        ```luau
        replica: table -- The replica to destroy.
        ```
    ]=]
    local function DestroyReplica(replica: table)
        local replicationTargets = GetReplicationTargets(replica)
        local classReplicaDestroyedRemoteName = string.format(ReplicatorSettings.CLASS_REPLICA_DESTROYED_REMOTE_NAME_FORMAT, replica.Class)
        RemoteService.FireClients(replicationTargets, classReplicaDestroyedRemoteName, replica.Class, replica.Id)

        replica.RootInstance[ReplicatorSettings.ROOT_INSTANCE_REPLICA_KEY] = nil
        replicaCache[replica.Id] = nil
    end

    --[=[
        Unassigns a replica from its root instance.

        ### Parameters:
        ```luau
        replicaInstance: table -- The replica instance to unassign.
        ```
    ]=]
    local function UnassignReplica(replicaInstance: table)
        local replica = GetReplicaByRootInstance(replicaInstance)
        if not replica then
            Logger.warn(`Failed to unassign replica. No replica found for the given instance.`)
            return
        end

        DestroyReplica(replica)
    end

    --[=[
        Creates a new replica with a unique identifier.

        ### Parameters:
        ```luau
        instance: table -- The root instance for the replica.
        options: AssignReplicaOptions? -- Configuration options for the replica.
        ```

        ### Returns:
        ```luau
        table -- The public replica instance.
        table -- The internal replica data.
        ```
    ]=]
    local function CreateReplica(instance: table, options: AssignReplicaOptions?): (table, table)
        local replicaId: string?
        while not replicaId or replicaCache[replicaId] do
            replicaId = TextUtils.GenerateIdentifier()
        end

        local newReplica = {
            _ReplicaInstance = {},
            RootInstance = instance,
            Options = options,
            Id = replicaId,
            Class = nil,
            stagedChanges = {},
        }

        -- Adding strong reference to replica to the root instance to prevent garbage collection.
        -- When the root instance is garbage collected, the replica will be garbage collected as well.
        instance[ReplicatorSettings.ROOT_INSTANCE_REPLICA_KEY] = newReplica
        
        replicaCache[replicaId] = newReplica
        AssignReplicaToClass(newReplica, options.ClassIdentifier)
        AssignReplicaMetamethods(newReplica)

        return newReplica._ReplicaInstance, newReplica
    end

    --[=[
        Assigns a replica to an instance with optional configuration.

        ### Parameters:
        ```luau
        instance: table -- The instance to assign a replica to.
        options = {
            ClassIdentifier: string = "__GLOBALREPLICA" -- The class identifier for this replica.
            ReplicationScope: string | Player | {Player} = "ALL" -- Defines which players receive updates.
            IgnorePrivateFields: boolean = true -- Whether to skip fields starting with underscore.
            FilterMode: "WHITELIST" | "BLACKLIST" = "BLACKLIST" -- Filtering strategy for field replication.
            FilterList: {string} = {} -- List of fields to filter based on mode.
            ManualSync: boolean = false -- Whether to require manual sync calls.
        }
        ```

        ### Returns:
        ```luau
        table -- The public replica instance.
        table -- The internal replica data.
        ```
    ]=]
    local function AssignReplica(instance: table, options: AssignReplicaOptions?): (table, table)
        options = if options
            then TableUtils.MergeDictionaries(options, AssignReplicaOptionsDefault)
            else AssignReplicaOptionsDefault

        local existingReplica = GetReplicaByRootInstance(instance)
        if existingReplica then
            Logger.warn(`Instance already has a replica assigned. Returning existing replica.`)
            return existingReplica._ReplicaInstance, existingReplica
        end

        local newReplicaInstance, newReplica = CreateReplica(instance, options)
        local replicationTargets = GetReplicationTargets(newReplica)
        local replicableReplicaInstance = TableUtils.CopyTable(newReplica, {
            RemoveCyclic = true,
        })

        local classReplicateAssignedRemoteName = string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, options.ClassIdentifier)
        RemoteService.FireClients(replicationTargets, classReplicateAssignedRemoteName, options.ClassIdentifier, replicableReplicaInstance)

        return newReplicaInstance, newReplica
    end

    --[=[
        Handles a player request for replica data.

        ### Parameters:
        ```luau
        player: Player -- The player requesting replica data.
        ```

        ### Returns:
        ```luau
        table -- A dictionary containing replica classes and replicas visible to the player.
        ```
    ]=]
    local function HandleReplicaDataRequest(player: Player)
        local replicas = {}
        for _, replica: table in replicaCache do
            local replicationTargets = GetReplicationTargets(replica)
            if not replicationTargets then
                continue
            end

            if table.find(replicationTargets, player) then
                local safeReplica = TableUtils.CopyTable(replica, {
                    RemoveCyclic = true,
                })

                replicas[replica.Id] = safeReplica
            end
        end

        return {
            Classes = replicaClasses,
            Replicas = replicas,
        }
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    ReplicatorService.__Init = Init
    ReplicatorService.DefineReplicaClass = DefineReplicaClass
    ReplicatorService.SyncReplicaChanges = SyncReplicaChanges
    ReplicatorService.UnassignReplica = UnassignReplica
    ReplicatorService.AssignReplica = AssignReplica

    --// RUNTIME \\--
    RemoteService.CreateRemoteEvent("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED")
    RemoteService.CreateRemoteEvent("REPLICATOR_SERVICE_REPLICA_CLASS_UNDEFINED")
    RemoteService.OnServerInvoke("REPLICATOR_CONTROLLER_REQUEST_REPLICA_DATA", HandleReplicaDataRequest)
end

return ReplicatorService