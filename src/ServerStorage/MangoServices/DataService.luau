--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local DataService = {}
function DataService.__Construct()

    --// SERVICES \--
    local DataStoreService = game:GetService("DataStoreService")
    local ServerStorage = game:GetService("ServerStorage")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    --// CONFIG \--
    local USE_STUDIO_DATA = true
    local USE_TEST_DATA = true
    local PROFILE_WAIT_TIME = 20
    local PROFILE_FETCH_ATTEMPTS = 10
    local DATA_SYNC_INTERVAL = 60

    --// MODULES \--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local ProfileService = MangoServer.Require("ProfileService")
    local SubmoduleUtils = MangoServer.Require("SubmoduleUtils")
    local RemoteService = MangoServer.Require("RemoteService")
    local FastSignal = MangoServer.Require("FastSignal")
    local TableUtils = MangoServer.Require("TableUtils")
    local Connector = MangoServer.Require("Connector")
    local Logger = MangoServer.Require("Logger")
    local DataSettings = MangoServer.Require("DataSettings")

    --// TYPES \--
    type GetOrderedDataOptions = {
        Ascending: boolean?,
        PageSize: number?,
        MinValue: number?,
        MaxValue: number?,
    }

    --// CONSTANTS \--
    local IsStudio = RunService:IsStudio()
    local DataTemplate = (IsStudio and USE_TEST_DATA) and DataSettings.TEST_DATA_TEMPLATE or DataSettings.DATA_TEMPLATE
    local ProfileStore = ProfileService.GetProfileStore(`PlayerData_v{DataSettings.DATA_VERSION}`, DataTemplate)
    local SubmoduleStorage = ServerStorage.MangoSubmodules.DataService

    local GetOrderedDataOptionsDefaults: GetOrderedDataOptions = {
        Ascending = false,
        PageSize = 30,
        MinValue = nil,
        MaxValue = nil,
    }

    --// VARIABLES \--
    local playerProfiles = {}
    local loadedStores = {}
    local loadedOrderedStores = {}
    local selfUpdatingFieldHandlers = {}

    --// FUNCTIONS \--

    --[=[
        Loads a data store by name and stores it in the loadedStores table.

        ### Parameters:
        ```luau
        storeName: string -- The name of the data store to load.
        ```
    ]=]
    local function LoadDataStore(storeName: string)
        local loadSuccess: boolean, loadResponse: DataStore | string = xpcall(function()
            return DataStoreService:GetDataStore(storeName, DataSettings.DATA_VERSION)
        end, Logger.error)

        if loadSuccess then
            loadedStores[storeName] = loadResponse
            Logger.info(`Successfully loaded data store {storeName}`)
        else
            Logger.warn(`Failed to load data store {storeName}`)
        end
    end

    --[=[
        Loads an ordered data store by name and stores it in the loadedOrderedStores table.

        ### Parameters:
        ```luau
        storeName: string -- The name of the ordered data store to load.
        ```
    ]=]
    local function LoadOrderedDataStore(storeName: string)
        local loadSuccess: boolean, loadResponse: DataStore | string = xpcall(function()
            return DataStoreService:GetOrderedDataStore(storeName, DataSettings.DATA_VERSION)
        end, Logger.error)

        if loadSuccess then
            loadedOrderedStores[storeName] = loadResponse
            Logger.info(`Successfully loaded ordered data store {storeName}`)
        else
            Logger.warn(`Failed to load ordered data store {storeName}`)
        end
    end

    local function CallAllSelfUpdatingFieldHandlers(player: Player, profile: table, handlerFunctionName: string)
        for _, handler: table in selfUpdatingFieldHandlers do
            if typeof(handler[handlerFunctionName]) == "function" then
                local callSuccess, callResponse = xpcall(handler[handlerFunctionName], Logger.error, player, profile)
                if not callSuccess then
                    Logger.warn(`Failed to call handler function {handlerFunctionName}.`)
                end
            end
        end
    end

    --[=[
    	Retrieves or waits for a player's profile to be loaded.

    	### Parameters:
    	```luau
    	player: Player -- The player whose profile to retrieve.
    	```

    	### Returns:
    	```luau
    	table? -- The player's profile, or nil if not found within timeout.
    	```
    ]=]
    local function GetPlayerProfile(player: Player): table?
        local playerProfile = playerProfiles[player.UserId]
        if playerProfile then
            return playerProfile
        else

            -- Waiting for the profile to load with a timeout.
            local waitStartTime = os.clock()
            while os.clock() - waitStartTime < PROFILE_WAIT_TIME and not playerProfile do
                playerProfile = playerProfiles[player.UserId]
                task.wait(0.1)
            end
                
            if playerProfile then
                return playerProfile
            else
                Logger.warn(`Player {player.Name}'s profile couldn't be fetched`)
                return
            end
        end
    end

    --[=[
    	Handles loading a player's profile when they join the game.

    	### Parameters:
    	```luau
    	player: Player -- The player who joined.
    	```
    ]=]
    local function PlayerAdded(player: Player)
        local profileStore = (IsStudio and USE_STUDIO_DATA) and ProfileStore.Mock or ProfileStore

        -- Attempting to load player profile.
        Logger.info(`Attempting to load {player.Name}'s profile...`)
        local playerProfile: typeof(ProfileService.GetProfileStore) 

        -- Loading players data for multiple attempts.
        for _ = 1, PROFILE_FETCH_ATTEMPTS do
            playerProfile = profileStore:LoadProfileAsync(`{player.UserId}`)
            if playerProfile and playerProfile.Data then
                break
            end

            task.wait(2)
        end

        if playerProfile then
            playerProfile:AddUserId(player.UserId)
            playerProfile:Reconcile()
            playerProfiles[player.UserId] = playerProfile
            CallAllSelfUpdatingFieldHandlers(player, playerProfile, "HandlePlayerProfileLoaded")

            Logger.info(`Successfully loaded {player.Name}'s profile!`)
        else
            return player:Kick(`Your profile couldn't be loaded, please rejoin. If the problem continue please report it on our community server or to an admin.`)
        end
    end

    --[=[
        Handles cleanup when a player leaves the game, releasing their profile.

        ### Parameters:
        ```luau
        player: Player -- The player who is leaving.
        ```
    ]=]
    local function PlayerRemoving(player: Player)
        local playerProfile = playerProfiles[player.UserId]
        if playerProfile then
            CallAllSelfUpdatingFieldHandlers(player, playerProfile, "HandlePlayerProfileUnloading")
            playerProfile:Release()
            playerProfiles[player.UserId] = nil
        end
    end

    --[=[
    	Retrieves a player's data with success/error indication.

    	### Parameters:
    	```luau
    	player: Player -- The player whose data to retrieve.
    	```

    	### Returns:
    	```luau
    	(boolean, string | table) -- Success flag and data table or error message.
    	```
    ]=]
    local function GetPlayerData(player: Player): table?
        local playerProfile = GetPlayerProfile(player)
        if not playerProfile then
            Logger.warn(`Couldn't fetch data for player {player.Name}, profile not found!`)
            return
        end

        return playerProfile.Data
    end

    --[=[
    	Synchronizes a player's data to their client.

    	### Parameters:
    	```luau
    	player: Player -- The player whose data to sync.
    	```
    ]=]
    local function SyncPlayerData(player: Player)
        local playerProfile = GetPlayerProfile(player)
        if not playerProfile then
            Logger.warn(`Couldn't sync data for player {player.Name}, profile not found!`)
            return
        end

        DataService.PlayerDataUpdated:Fire(player, playerProfile.Data)
        RemoteService.FireClient(player, "DATA_SERVICE_SYNC_DATA", playerProfile.Data)
    end

    --[=[
        Retrieves data from a specific key in a data store.

        ### Parameters:
        ```luau
        storeName: string -- The name of the data store.
        key: string -- The key to retrieve data from.
        ```

        ### Returns:
        ```luau
        any? -- The retrieved data or nil if failed.
        ```
    ]=]
    local function GetStoreKeyData(storeName: string, key: string): any?
        local dataStore = loadedStores[storeName]
        if not dataStore then
            Logger.warn(`Data store {storeName} not found`)
            return
        end

        local success, result = xpcall(function()
            return dataStore:GetAsync(key)
        end, Logger.error)

        if success then
            return result
        else
            Logger.warn(`Failed to retrieve data from store {storeName}`)
            return
        end
    end

    --[=[
        Sets data for a specific key in a data store.

        ### Parameters:
        ```luau
        storeName: string -- The name of the data store.
        key: string -- The key to set data for.
        data: any -- The data to set.
        ```

        ### Returns:
        ```luau
        boolean -- Success status.
        ```
    ]=]
    local function SetStoreKeyData(storeName: string, key: string, data: any)
        local dataStore = loadedStores[storeName]
        if not dataStore then
            Logger.warn(`Data store {storeName} not found`)
            return false
        end

        local success = xpcall(function()
            dataStore:SetAsync(key, data)
        end, Logger.error)

        if success then
            return true
        else
            Logger.warn(`Failed to set data for store {storeName}`)
            return false
        end
    end

    --[=[
        Retrieves ordered data from a specific ordered data store.

        ### Parameters:
        ```luau
        storeName: string -- The name of the ordered data store.
        options: {
            Ascending: boolean?, -- Whether to sort in ascending order.
            PageSize: number?, -- The number of entries to retrieve.
            MinValue: number?, -- Minimum value filter.
            MaxValue: number?, -- Maximum value filter.
        }
        ```

        ### Returns:
        ```luau
        table? -- The retrieved ordered data or nil if failed.
        ```
    ]=]
    local function GetOrderedStoreData(storeName: string, options: GetOrderedDataOptions?)
        options = options and TableUtils.MergeDictionaries(options, GetOrderedDataOptionsDefaults) or GetOrderedDataOptionsDefaults

        local orderedDataStore = loadedOrderedStores[storeName]
        if not orderedDataStore then
            Logger.warn(`Ordered data store {storeName} not found`)
            return
        end

        local getOrderedDataSuccess, getOrderedDataResponse = xpcall(function()
            return orderedDataStore:GetSortedAsync(options.Ascending, options.PageSize, options.MinValue, options.MaxValue)
        end, Logger.error)

        if getOrderedDataSuccess then
            return getOrderedDataResponse
        else
            Logger.warn(`Failed to retrieve ordered data from store {storeName}`)
            return
        end
    end

    --[=[
        Retrieves data from a specific key in an ordered data store.

        ### Parameters:
        ```luau
        storeName: string -- The name of the ordered data store.
        key: string -- The key to retrieve data from.
        ```

        ### Returns:
        ```luau
        any? -- The retrieved data or nil if failed.
        ```
    ]=]
    local function GetOrderedStoreKeyData(storeName: string, key: string)
        local orderedDataStore = loadedOrderedStores[storeName]
        if not orderedDataStore then
            Logger.warn(`Ordered data store {storeName} not found`)
            return
        end

        local success, result = xpcall(function()
            return orderedDataStore:GetAsync(key)
        end, Logger.error)

        if success then
            return result
        else
            Logger.warn(`Failed to retrieve data from ordered store {storeName}`)
            return
        end
    end

    --[=[
        Sets data for a specific key in an ordered data store.

        ### Parameters:
        ```luau
        storeName: string -- The name of the ordered data store.
        key: string -- The key to set data for.
        data: any -- The data to set.
        ```

        ### Returns:
        ```luau
        boolean -- Success status.
        ```
    ]=]
    local function SetOrderedStoreKeyData(storeName: string, key: string, data: any)
        local orderedDataStore = loadedOrderedStores[storeName]
        if not orderedDataStore then
            Logger.warn(`Ordered data store {storeName} not found`)
            return false
        end

        local setOrderedDataSuccess = xpcall(function()
            orderedDataStore:SetAsync(key, data)
        end, Logger.error)

        if setOrderedDataSuccess then
            return true
        else
            Logger.warn(`Failed to set data for ordered store {storeName}`)
            return false
        end
    end

    --[=[
        Handles a player's request for their ordered data.

        ### Parameters:
        ```luau
        player: Player -- The player requesting the data.
        ```

        ### Returns:
        ```luau
        boolean -- Success status.
        table -- The player's ordered data.
        ```
    ]=]
    local function HandlePlayerOrderedDataRequest(player: Player)
        local orderedData = {}
        for storeName: string in loadedOrderedStores do
            local storeData = GetOrderedStoreKeyData(storeName, player.UserId)
            orderedData[storeName] = storeData
        end

        return true, orderedData
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --// RUNTIME \--
        for _, player: Player in Players:GetPlayers() do
            task.defer(PlayerAdded, player)
        end

        Connector.Connect(Players.PlayerAdded, PlayerAdded)
        Connector.Connect(Players.PlayerRemoving, PlayerRemoving)

        -- Periodically syncs player data.
        task.defer(function()
            while true do
                for _, player: Player in Players:GetPlayers() do
                    SyncPlayerData(player)
                end

                task.wait(DATA_SYNC_INTERVAL)
            end
        end)

        --// EXPORTS \--
    end
    
    --// EXPORTS \--
    DataService.__Init = Init
    DataService.GetPlayerData = GetPlayerData
    DataService.SyncPlayerData = SyncPlayerData
    DataService.GetStoreKeyData = GetStoreKeyData
    DataService.SetStoreKeyData = SetStoreKeyData
    DataService.GetOrderedStoreData = GetOrderedStoreData
    DataService.GetOrderedStoreKeyData = GetOrderedStoreKeyData
    DataService.SetOrderedStoreKeyData = SetOrderedStoreKeyData
    DataService.PlayerDataUpdated = FastSignal.new()

    --// RUNTIME \--

    -- Loading required data stores.
    for _, storeName: string in DataSettings.REQUIRED_STORES do
        task.spawn(function()
            LoadDataStore(storeName)
        end)
    end

    -- Loading required ordered data stores.
    for _, orderedStoreName: string in DataSettings.REQUIRED_ORDERED_STORES do
        LoadOrderedDataStore(orderedStoreName)
    end

    SubmoduleUtils.BuildChildrenSubmodules(SubmoduleStorage.SelfUpdatingFieldHandlers, {
        Cache = selfUpdatingFieldHandlers,
    })

    RemoteService.CreateRemoteEvent("DATA_SERVICE_SYNC_DATA")
    RemoteService.OnServerInvoke("DATA_CONTROLLER_GET_DATA", GetPlayerData)
    RemoteService.OnServerInvoke("DATA_CONTROLLER_GET_ORDERED_DATA", HandlePlayerOrderedDataRequest)
end

return DataService