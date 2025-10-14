--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ServerStorage = game:GetService("ServerStorage")

--// MODULES \\--

local MangoServer = require(ServerStorage.MangoServer)
local RuntimeSettings = MangoServer.Require('RuntimeSettings')
local PublicValues = MangoServer.Require("PublicValues")
local TableUtils = MangoServer.Require('TableUtils')
local Logger = MangoServer.Require("Logger")

--// TYPES \\--

--// CONSTANTS \\--

local ServiceContainers = {
    ServerStorage.Services,
    ServerStorage.MangoServices
}

--// VARIABLES \\--

local services = {}

--// FUNCTIONS \\--

-- Creating server loaded shared value.
PublicValues.SetValue("ServerLoaded", false)
PublicValues.SetValue("LoadingComplete", false)
PublicValues.SetValue("PlayersDataLoaded", {})
Logger.info(`Started loading server...`)

-- Getting services from all destinations.
for _, serviceFolder: Folder in ServiceContainers do
    local folderServices = serviceFolder:GetChildren()
    TableUtils.MergeArrays(services, folderServices)
end

-- Sorting services.
table.sort(services, function(service1: ModuleScript, service2: ModuleScript)
    local service1Priority = RuntimeSettings["SERVICE_PRIORITIES"][service1.Name] or RuntimeSettings["DEFAULT_PRIORITY"]
    local service2Priority = RuntimeSettings["SERVICE_PRIORITIES"][service2.Name] or RuntimeSettings["DEFAULT_PRIORITY"]

    return service1Priority < service2Priority
end)

-- Loading services.
for i: number, class: ModuleScript in services do
    local startDT = DateTime.now()
    Logger.info(`Starting {class.Name}...`)
    PublicValues.SetValue("LoadingProgressPercentage", i / #services)
    PublicValues.SetValue("LoadingProgress", `Initiating {class.Name}`)
    local requiredClass = require(class)

    -- Calling init if it exists.
    if requiredClass.Init then
        requiredClass.Init()
    end
    
    -- Logging time to require and initiate.
    local tookTimeMS = DateTime.now().UnixTimestampMillis - startDT.UnixTimestampMillis
    Logger.info(`Started {class.Name}, took {tookTimeMS}ms!`)
end

-- Setting server loaded shared value.
PublicValues.SetValue("ServerLoaded", true)
Logger.info(`Server loading complete!`)

-- Starting game service.
local GameService = MangoServer.Require('GameService')
GameService.Start()

-- Setting all loading as complete.
PublicValues.SetValue("LoadingComplete", true)