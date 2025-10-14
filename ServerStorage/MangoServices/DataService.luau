--!strict
--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local USE_STUDIO_DATA = true

--// SERVICES \\--

local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// MODULES \\--

local MangoServer = require(ServerStorage.MangoServer)
local RemoteService = MangoServer.Require("RemoteService")
local ProfileService = MangoServer.Require("ProfileService")
local PublicValues = MangoServer.Require("PublicValues")
local Connector = MangoServer.Require('Connector')
local WaitFor = MangoServer.Require("WaitFor")
local Logger = MangoServer.Require("Logger")
local Signal = MangoServer.Require("FastSignal")
local DataSettings = MangoServer.Require("DataSettings")

--// TYPES \\--

--// CONSTANTS \\--

local DataTemplate = DataSettings["TEMPLATE"]
local DataVersion = DataSettings["VERSION"]
local ProfileStore = ProfileService.GetProfileStore(`PlayerDataV{DataVersion}`, DataTemplate)

--// VARIABLES \\--

local DataService = {
    PlayerDataSaved = Signal.new(),
}
local orderedDatastoreCache = {}
local playersDataLoaded = {}
local playerProfiles = {}

--// FUNCTIONS \\--

-- Returns the player profile, waiting for profile if non existant.
local function GetPlayerProfile(player: Player)

    -- Getting player profile and checking if it exists.
    local playerProfile = playerProfiles[player.UserId]
    if playerProfile then
        return playerProfile
    else

        -- Waiting for the profile to load with a timeout.
        local success, playerProfile = WaitFor.Custom(function()
            return playerProfiles[player.UserId]
        end):timeout(20):await()

        -- Checking if successfully got player profile, if so returning it.
        if success then
            return playerProfile
        else

            -- Warning of error and returning nil.
            Logger.warn(`Player {player.Name}'s profile couldn't be fetched`)
            return
        end
    end
end

-- Handles player leaving the game.
local function PlayerRemoving(player: Player)

    -- Instantly removing players data loaded variable.
    playersDataLoaded[player.Name] = nil

    -- Getting players profile and checking if it exists.
    local playerProfile = GetPlayerProfile(player)
    if not playerProfile then
        return
    end

    -- Releasing profile and clearing memory.
    playerProfile:Release()
    playerProfiles[player.UserId] = nil
end

-- Handles player being added.
local function PlayerAdded(player: Player): nil
    local profileStoreAdjusted = if RunService:IsStudio() and USE_STUDIO_DATA then ProfileStore.Mock else ProfileStore

    -- Attempting to load player profile.
    Logger.info(`Attempting to load {player.Name}'s profile...`)
    local playerProfile: typeof(ProfileService.GetProfileStore) 

    -- Loading players data for multiple attempts.
    for _ = 1, DataSettings["LOADING_ATTEMPTS"] do

        -- Attempting to load players profile and checking if profile successfully loaded..
        playerProfile = profileStoreAdjusted:LoadProfileAsync(`{player.UserId} ({player.Name})`)
        if playerProfile and playerProfile.Data then
            break
        end

        -- Waiting for a set amount of time before attempting to load profile again.
        task.wait(5)
    end

    -- Checking if profile was successfully loaded.
    if playerProfile then

        -- Common profile actions.
        playerProfile:AddUserId(player.UserId)
        playerProfile:Reconcile()

        -- Caching profile as loaded and players profile to a dictionary.
        playersDataLoaded[player.Name] = true
        playerProfiles[player.UserId] = playerProfile

        -- Logging profile loaded.
        Logger.info(`Successfully loaded {player.Name}'s profile!`)
    else
        return player:Kick(`Your profile couldn't be loaded, please rejoin. If the problem continue please report it on our community server or to an admin.`)
    end
end

-- Returns the players data, includes success checking.
local function GetPlayerData(player: Player): table

    -- Getting players profile and checking if it exists.
    local playerProfile = GetPlayerProfile(player)
    if not playerProfile then
        return false, `Couldn't fetch your data profile, please try again.`
    end

    return true, playerProfile.Data
end

-- Sets the players profile data.
local function SetPlayerData(player: Player, newData: table): nil

    -- Getting players profile and checking if it exists.
    local playerProfile = GetPlayerProfile(player)
    if not playerProfile then
        return false, `Couldn't fetch your data profile, please try again.`
    end

    -- Updating data for players client.
    RemoteService.FireClient(player, "DATA_SERVICE_UPDATE_DATA", newData)
    DataService.PlayerDataSaved:Fire(player, newData)

    -- Caching new data to players data profile.
    playerProfile.Data = newData
end

-- Gets the ordered datastore sorted pages.
local function GetOrderedData(orderedDatastoreName: string, ascenting: boolean, pageSize: number)
    
    -- Getting ordered datastore and chacking if it exists.
    local orderedDatastore: OrderedDataStore = orderedDatastoreCache[orderedDatastoreName]
    if not orderedDatastore then
        return Logger.warn(`Ordered datastore {orderedDatastoreName} doesn't exist`)
    end

    return orderedDatastore:GetSortedAsync(ascenting, pageSize, 0, 2147000000)
end

-- Gets a value of a key from an ordered datastore.
local function GetOrderedDataKeyValue(orderedDatastoreName: string, key: string)
    
    -- Getting ordered datastore and chacking if it exists.
    local orderedDatastore: OrderedDataStore = orderedDatastoreCache[orderedDatastoreName]
    if not orderedDatastore then
        return Logger.warn(`Ordered datastore {orderedDatastoreName} doesn't exist`)
    end

    return orderedDatastore:GetAsync(key)
end

-- Sets the value of a key in ordered data.
local function SetOrderedDataKeyValue(orderedDatastoreName: string, key: string, value: number)

    -- Getting ordered datastore and chacking if it exists.
    local orderedDatastore: OrderedDataStore = orderedDatastoreCache[orderedDatastoreName]
    if not orderedDatastore then
        return Logger.warn(`Ordered datastore {orderedDatastoreName} doesn't exist`)
    end

    -- Setting the value.
    orderedDatastore:SetAsync(key, value)
end

-- Exporting methods.
DataService.PlayerRemoving = PlayerRemoving
DataService.GetPlayerData = GetPlayerData
DataService.SetPlayerData = SetPlayerData
DataService.GetOrderedData = GetOrderedData
DataService.GetOrderedDataKeyValue = GetOrderedDataKeyValue
DataService.SetOrderedDataKeyValue = SetOrderedDataKeyValue

-- Initiation method.
function DataService.Init()

    -- Setting metamethod. When a new players data is loaded, update the public value too.
    setmetatable(playersDataLoaded, {
        __newindex = function(t, i, v)
            rawset(t, i, v)
            PublicValues.SetValue("PlayersDataLoaded", t)
        end
    })
    
    -- Iterating over joined players.
    for _, player: Player in Players:GetPlayers() do
        PlayerAdded(player)
    end

    -- Iterating over ordered datastores and creating them if any exist.
    for _, datastoreName: string in DataSettings["ORDERED_DATASTORES"] do
        orderedDatastoreCache[datastoreName] = DataStoreService:GetOrderedDataStore(datastoreName, DataSettings["VERSION"])
    end

    -- Connections.
    Connector.Connect(Players.PlayerAdded, PlayerAdded)
    RemoteService.OnServerInvoke("DATA_CONTROLLER_GET_DATA", GetPlayerData)
end

return DataService