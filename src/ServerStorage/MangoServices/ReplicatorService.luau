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
    local function GetReplicateByRootInstance(instance: Instance): table?
        for _, replica: table in replicaCache do
            if replica.RootInstance == instance then
                return replica
            end
        end

        return nil
    end

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

    local function SyncReplicaChanges(replica: table): nil
        if TableUtils.GetTableLength(replica.stagedChanges) == 0 then
            return
        end

        local classRemoteName = string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, replica.Class)
        local replicationTargets = GetReplicationTargets(replica)
        RemoteService.FireClients(replicationTargets, classRemoteName, replica.Class, replica.Id, replica.stagedChanges)

        table.clear(replica.stagedChanges)
    end

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

    local function AssignReplicaToClass(replica: table, classIdentifier: string)
        replica.Class = classIdentifier

        if not table.find(replicaClasses, classIdentifier) then
            table.insert(replicaClasses, classIdentifier)
            RemoteService.CreateRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, classIdentifier))
            RemoteService.CreateRemoteEvent(string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, classIdentifier))
            RemoteService.FireAllClients("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED", classIdentifier)
        end
    end

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

    local function AssignReplica(instance: table, options: AssignReplicaOptions?): (table, table)
        options = if options
            then TableUtils.MergeDictionaries(options, AssignReplicaOptionsDefault)
            else AssignReplicaOptionsDefault

        local existingReplica = GetReplicateByRootInstance(instance)
        if existingReplica then
            Logger.warn(`Instance already has a replica assigned. Returning existing replica.`)
            return existingReplica._ReplicaInstance, existingReplica
        end

        local newReplicaInstance, newReplica = CreateReplica(instance, options)
        local replicationTargets = GetReplicationTargets(newReplica)
        local replicableReplicaInstance = TableUtils.CopyTable(newReplica, {
            RemoveCyclic = true,
        })

        RemoteService.FireClients(replicationTargets, string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, options.ClassIdentifier), replicableReplicaInstance)

        return newReplicaInstance, newReplica
    end

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
    ReplicatorService.SyncReplicaChanges = SyncReplicaChanges
    ReplicatorService.AssignReplica = AssignReplica

    --// RUNTIME \\--
    RemoteService.CreateRemoteEvent("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED")
    RemoteService.OnServerInvoke("REPLICATOR_CONTROLLER_REQUEST_REPLICA_DATA", HandleReplicaDataRequest)
end

return ReplicatorService