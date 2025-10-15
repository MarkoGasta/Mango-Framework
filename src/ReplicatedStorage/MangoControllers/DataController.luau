--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES \\--

local MangoClient = require(ReplicatedStorage.MangoClient)
local RemoteController = MangoClient.Require("RemoteController")
local Logger = MangoClient.Require('Logger')

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local DataController = {}
local data = {}

--// FUNCTIONS \\--

-- Updates the client data on server call.
local function UpdateData(newData: table)
    data = newData
end

-- Returns players data.
local function GetPlayerData()
    return data
end

-- Exporting methods.
DataController.GetPlayerData = GetPlayerData

-- Initiation method.
function DataController.Init()
    
    -- Posting data request to server.
    local success: boolean, response: table | string = RemoteController.InvokeServer("DATA_CONTROLLER_GET_DATA")
    if not success then
        return Logger.warn(response)
    end

    -- Updating data.
    UpdateData(response)

    -- Connections.
    RemoteController.OnClientEvent("DATA_SERVICE_UPDATE_DATA", UpdateData)
end

return DataController