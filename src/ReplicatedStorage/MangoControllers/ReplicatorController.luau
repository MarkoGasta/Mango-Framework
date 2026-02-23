--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local ReplicatorController = {}
function ReplicatorController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--

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

    local function HandleClassReplicaAssigned(classIdentifier: string, replicaData: table)
        replicaCache[replicaData.Id] = replicaData
        classData[classIdentifier].__CreatedSignal:Fire(replicaData)
    end

    local function HandleClassReplicaUpdated(classIdentifier: string, replicaId: string, replicaChanges: table)
        local replicaData = replicaCache[replicaId]
        if not replicaData then
            Logger.warn(`Received update for non-existent replica {replicaId}.`)
            return
        end

        for key, value in replicaChanges do
            replicaData[key] = value
        end

        classData[classIdentifier].__UpdatedSignal:Fire(replicaData)
    end

    local function HandleClassDefined(classIdentifier: string)
        classData[classIdentifier] = {
            __CreatedConnection = RemoteController.OnClientEvent(string.format(ReplicatorSettings.CLASS_REPLICA_ASSIGNED_REMOTE_NAME_FORMAT, classIdentifier), HandleClassReplicaAssigned),
            __UpdatedConnection = RemoteController.OnClientEvent(string.format(ReplicatorSettings.CLASS_REPLICA_UPDATE_REMOTE_NAME_FORMAT, classIdentifier), HandleClassReplicaUpdated),
            __CreatedSignal = FastSignal.new(),
            __UpdatedSignal = FastSignal.new(),
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
    ReplicatorController.GetClassReplicaCreatedSignal = GetClassReplicaCreatedSignal
    ReplicatorController.GetClassReplicaUpdatedSignal = GetClassReplicaUpdatedSignal
    
    --// RUNTIME \\--
    SyncDataWithServer()
    RemoteController.OnClientEvent("REPLICATOR_SERVICE_REPLICA_CLASS_DEFINED", HandleClassDefined)
end

return ReplicatorController