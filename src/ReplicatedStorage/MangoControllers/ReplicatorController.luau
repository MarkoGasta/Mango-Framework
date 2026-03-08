--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local ReplicatorController = {}
function ReplicatorController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--
    local LOG_ERRORS = false

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local RemoteController = MangoClient.Require("RemoteController")
    local FastSignal = MangoClient.Require("FastSignal")
    local Logger = MangoClient.Require("Logger")
    local ReplicatorSettings = MangoClient.Require("ReplicatorSettings")

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--
    local replicaCache = {}
    local classData = {}

    --// FUNCTIONS \\--

    local function GetClassReplicaCreatedSignal(classIdentifier: string): typeof(FastSignal)
        if not classData[classIdentifier] then
            Logger.warn(`Requested created signal for undefined replica class {classIdentifier}.`)
            return nil
        end

        return classData[classIdentifier].__CreatedSignal
    end

    local function GetClassReplicaUpdatedSignal(classIdentifier: string): typeof(FastSignal)
        if not classData[classIdentifier] then
            Logger.warn(`Requested updated signal for undefined replica class {classIdentifier}.`)
            return nil
        end

        return classData[classIdentifier].__UpdatedSignal
    end

    local function GetClassReplicaDestroyedSignal(classIdentifier: string): typeof(FastSignal)
        if not classData[classIdentifier] then
            Logger.warn(`Requested destroyed signal for undefined replica class {classIdentifier}.`)
            return nil
        end

        return classData[classIdentifier].__DestroyedSignal
    end

    local function GetAllClassReplicaInstances(classIdentifier: string): table?
        if not classData[classIdentifier] then
            Logger.warn(`Requested replicas for undefined replica class {classIdentifier}.`)
            return
        end

        local replicaClassCache = replicaCache[classIdentifier]
        if not replicaClassCache then
            return {}
        end

        local replicaInstances = {}
        for _, replicaData in replicaClassCache do
            table.insert(replicaInstances, replicaData.RootInstance)
        end

        return replicaInstances
    end

    local function HandleClassReplicaAssigned(classIdentifier: string, replicaData: table)
        local replicaClassCache = replicaCache[classIdentifier]
        if not replicaClassCache then
            replicaClassCache = {}
            replicaCache[classIdentifier] = replicaClassCache
        end

        if replicaClassCache[replicaData.Id] then
            if LOG_ERRORS then
                Logger.error(`Received duplicate replica assignment for replica {replicaData.Id} of class {classIdentifier}.`)
            end

            return
        end

        replicaClassCache[replicaData.Id] = replicaData
        classData[classIdentifier].__CreatedSignal:Fire(replicaData.RootInstance)
    end

    local function HandleClassReplicaUpdated(classIdentifier: string, replicaId: string, replicaChanges: table)
        local replicaClassCache = replicaCache[classIdentifier]
        if not replicaClassCache then
            Logger.warn(`Received update for replica {replicaId} of undefined class {classIdentifier}.`)
            return
        end

        local replicaData = replicaClassCache[replicaId]
        if not replicaData then
            Logger.warn(`Received update for non-existent replica {replicaId}.`)
            return
        end

        for key, value in replicaChanges do
            replicaData[key] = value
        end

        classData[classIdentifier].__UpdatedSignal:Fire(replicaData.RootInstance)
    end
    
    local function HandleClassReplicaDestroyed(classIdentifier: string, replicaId: string)
        local replicaClassCache = replicaCache[classIdentifier]
        if not replicaClassCache then
            Logger.warn(`Received destroy for non-existent replica {replicaId} of class {classIdentifier}.`)
            return
        end

        local replicaData = replicaClassCache[replicaId]
        if not replicaData then
            Logger.warn(`Received destroy for non-existent replica {replicaId} of class {classIdentifier}.`)
            return
        end

        classData[classIdentifier].__DestroyedSignal:Fire(replicaData.RootInstance)
        replicaClassCache[replicaId] = nil
    end

    local function HandleClassUndefined(classIdentifier: string)
        local classData = classData[classIdentifier]
        if not classData then
            return
        end

        -- Connections are disconnected automatically when the event is destroyed, so we don't need to manually disconnect them here.
        classData.__CreatedSignal:Destroy()
        classData.__UpdatedSignal:Destroy()
        classData.__DestroyedSignal:Destroy()
    end

    local function HandleClassDefined(classIdentifier: string)
        if classData[classIdentifier] then
            return
        end

        classData[classIdentifier] = {
            __CreatedConnection = RemoteController.OnClientEvent(string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, classIdentifier), HandleClassReplicaAssigned),
            __UpdatedConnection = RemoteController.OnClientEvent(string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, classIdentifier), HandleClassReplicaUpdated),
            __DestroyedConnection = RemoteController.OnClientEvent(string.format(ReplicatorSettings.CLASS_REPLICA_DESTROYED_REMOTE_NAME_FORMAT, classIdentifier), HandleClassReplicaDestroyed),
            __CreatedSignal = FastSignal.new(),
            __UpdatedSignal = FastSignal.new(),
            __DestroyedSignal = FastSignal.new(),
        }
    end

    local function SyncDataWithServer()
        local serverData = RemoteController.InvokeServer("REPLICATOR_CONTROLLER_REQUEST_REPLICA_DATA")
        if not serverData then
            Logger.warn("No replica data received from server.")
            return
        end

        for _, classIdentifier: string in serverData.Classes do
            HandleClassDefined(classIdentifier)
        end

        for _, replicaInstance: table in serverData.Replicas do
            HandleClassReplicaAssigned(replicaInstance.Class, replicaInstance)
        end
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    ReplicatorController.__Init = Init
    ReplicatorController.GetAllClassReplicaInstances = GetAllClassReplicaInstances
    ReplicatorController.GetClassReplicaCreatedSignal = GetClassReplicaCreatedSignal
    ReplicatorController.GetClassReplicaUpdatedSignal = GetClassReplicaUpdatedSignal
    ReplicatorController.GetClassReplicaDestroyedSignal = GetClassReplicaDestroyedSignal
    
    --// RUNTIME \\--
    SyncDataWithServer()
    RemoteController.OnClientEvent("REPLICATOR_SERVICE_REPLICA_CLASS_UNDEFINED", HandleClassUndefined)
    RemoteController.OnClientEvent("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED", HandleClassDefined)
end

return ReplicatorController