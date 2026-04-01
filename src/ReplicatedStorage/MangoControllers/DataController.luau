--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local DataController = {}
function DataController.__Construct()

    --// SERVICES \--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \--

    --// MODULES \--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local RemoteController = MangoClient.Require("RemoteController")
    local FastSignal = MangoClient.Require("FastSignal")
    local Logger = MangoClient.Require("Logger")

    --// TYPES \--

    --// CONSTANTS \--
    
    --// VARIABLES \--
    local playerData = {}

    --// FUNCTIONS \--

    --[=[
    	Retrieves the current local player data.

    	### Returns:
    	```luau
    	table -- The player's data table.
    	```
    ]=]
    local function GetPlayerData()
        return playerData
    end

    --[=[
    	Synchronizes the local player data with the provided data table.

    	### Parameters:
    	```luau
    	data: table -- The data table to sync with local player data.
    	```
    ]=]
    local function SyncData(data: table)
        playerData = data
        DataController.DataUpdated:Fire(data)
    end
    

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --// EXPORTS \--
        
        --// RUNTIME \--
    end

    --// EXPORTS \--
    DataController.__Init = Init
    DataController.GetPlayerData = GetPlayerData
    DataController.DataUpdated = FastSignal.new()
    DataController.StoreDataUpdated = FastSignal.new()

    --// RUNTIME \--
    local response: table = RemoteController.InvokeServer("DATA_CONTROLLER_GET_DATA")
    if response then
        SyncData(response)
    else
        Logger.warn("Failed to retrieve player data from server")
    end

    RemoteController.OnClientEvent("DATA_SERVICE_SYNC_DATA", SyncData)
end

return DataController