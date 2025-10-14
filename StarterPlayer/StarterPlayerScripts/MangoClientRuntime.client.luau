--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// MODULES \\--

local MangoClient = require(ReplicatedStorage.MangoClient)
local PublicValues = MangoClient.Require("PublicValues")
local TableUtils = MangoClient.Require('TableUtils')
local Logger = MangoClient.Require("Logger")
local RuntimeSettings = MangoClient.Require('RuntimeSettings')

--// TYPES \\--

--// CONSTANTS \\--

local Player = Players.LocalPlayer
local ControllerContainers = {
    ReplicatedStorage.Controllers,
    ReplicatedStorage.MangoControllers,
}

--// VARIABLES \\--

local controllers = {}

--// FUNCTIONS \\--

-- Starting client loading.
Logger.info(`Client loading started...`)
MangoClient.Global.LoadingProgress = "Client loading started..."

-- Getting services from all destinations.
MangoClient.Global.LoadingProgress = "Gathering controllers..."
for _, serviceFolder: Folder in ControllerContainers do
    local folderServices = serviceFolder:GetChildren()
    TableUtils.MergeArrays(controllers, folderServices)
end

-- Sorting controllers.
MangoClient.Global.LoadingProgress = "Sorting controllers..."
table.sort(controllers, function(controller1: ModuleScript, controller2: ModuleScript)
    local controller1Priority = RuntimeSettings["CONTROLLER_PRIORITIES"][controller1.Name] or RuntimeSettings["DEFAULT_PRIORITY"]
    local controller2Priority = RuntimeSettings["CONTROLLER_PRIORITIES"][controller2.Name] or RuntimeSettings["DEFAULT_PRIORITY"]

    return controller1Priority < controller2Priority
end)

-- Waiting for game to load.
if not game:IsLoaded() then
    Logger.info(`Waiting for the game.Loaded...`)
    MangoClient.Global.LoadingProgress = "Waiting for the game.Loaded..."
    game.Loaded:Wait()
end

-- Waiting for server to load all services.
if PublicValues.GetValue("ServerLoaded") == false then
    Logger.info(`Waiting for the server to load...`)
    PublicValues.GetValueChangedSignal("ServerLoaded"):Wait()
end

-- Waiting for player data to load.
MangoClient.Global.LoadingProgress = "Waiting for player data to load..."
local playersDataLoaded = PublicValues.GetValue("PlayersDataLoaded")
if not playersDataLoaded[Player.Name] then

    -- Checking if the players data in loaded.
    local playersDataLoadedConnection: RBXScriptConnection
    local isPlayersDataLoaded: boolean = PublicValues.GetValue("PlayersDataLoaded")[Player.Name]
    if not isPlayersDataLoaded then
        playersDataLoadedConnection = PublicValues.GetValueChangedSignal("PlayersDataLoaded"):Connect(function()
            isPlayersDataLoaded = PublicValues.GetValue("PlayersDataLoaded")[Player.Name]
        end)
    end

    Logger.info(`Waiting for player data to load...`)

    -- Waiting for players data to load.
    while true do
        if isPlayersDataLoaded then
            playersDataLoadedConnection:Disconnect()
            Logger.info(`Player data successfully loaded!`)
            break
        end

        task.wait(0.5)
    end
end

-- Loading controllers.
for i: number, class: ModuleScript in controllers do
    local startDT = DateTime.now()
    Logger.info(`Starting {class.Name}...`)
    local requiredClass = require(class)

    -- Calling init if it exists.
    if requiredClass.Init then
        requiredClass.Init()
    end

    -- Updating loading progress.
    MangoClient.Global.LoadingProgress = `Initiating {class.Name}`
    MangoClient.Global.LoadingProgressPercentage = i / #controllers
    
    -- Logging time to require and initiate.
    local tookTimeMS = DateTime.now().UnixTimestampMillis - startDT.UnixTimestampMillis
    Logger.info(`Started {class.Name}, took {tookTimeMS}ms!`)
end

-- Client has loaded.
MangoClient.Global.ClientLoaded = true
Logger.info(`Client loading complete!`)

-- Starting game and notifying server player has loaded.
local GameController = MangoClient.Require("GameController")
GameController.Start()