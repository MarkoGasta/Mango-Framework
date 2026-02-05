--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local LeaderstatService = {}
function LeaderstatService.__Construct()

    --// SERVICES \--
    local ServerStorage = game:GetService("ServerStorage")
    local Players = game:GetService("Players")

    --// CONFIG \--

    --// MODULES \--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local Logger = MangoServer.Require("Logger")
    local Connector = MangoServer.Require("Connector")
    local LeaderstatSettings = MangoServer.Require("LeaderstatSettings")

    --// TYPES \--

    --// CONSTANTS \--
    
    --// VARIABLES \--

    --// FUNCTIONS \--

    --[=[
        Retrieves the leaderstat IntValue for a player.

        ### Parameters:
        ```luau
        player: Player -- The player to get the leaderstat for.
        leaderstatIdentifier: string -- The identifier of the leaderstat.
        ```

        ### Returns:
        ```luau
        IntValue? -- The leaderstat value or nil if not found.
        ```
    ]=]
    local function GetLeaderstatValue(player: Player, leaderstatIdentifier: string): IntValue?
        local leaderstatValues = MangoServer.GetCacheField(player, "LeaderstatValues")
        if not leaderstatValues then

            -- Attempt to wait for leaderstat values to load
            local waitStartTime = os.clock()
            while os.clock() - waitStartTime < LeaderstatSettings.LOAD_WAIT_TIME do
                leaderstatValues = MangoServer.GetCacheField(player, "LeaderstatValues")
                if leaderstatValues then
                    break
                end

                task.wait(0.1)
            end
            
            if not leaderstatValues then
                Logger.warn(`Leaderstat values not found for player {player.Name}`)
                return
            end
        end

        local leaderstatValue = leaderstatValues[leaderstatIdentifier]
        return leaderstatValue
    end

    --[=[
        Creates a new leaderstat IntValue for a player.

        ### Parameters:
        ```luau
        player: Player -- The player to create the leaderstat for.
        leaderstatIdentifier: string -- The identifier of the leaderstat.
        ```

        ### Returns:
        ```luau
        IntValue -- The created leaderstat value.
        ```
    ]=]
    local function CreateLeaderstatValue(player: Player, leaderstatIdentifier: string): IntValue
        local leaderstatStorage = MangoServer.GetCacheField(player, "LeaderstatStorage")
        if not leaderstatStorage then
            Logger.warn(`Leaderstat storage not found for player {player.Name}`)
            return
        end

        local leaderstatValues = MangoServer.GetCacheField(player, "LeaderstatValues")
        if not leaderstatValues then
            leaderstatValues = {}
            MangoServer.SetCacheField(player, "LeaderstatValues", leaderstatValues)
        end

        local leaderstatData = LeaderstatSettings.LEADERSTAT_DATA[leaderstatIdentifier]
        if not leaderstatData then
            Logger.warn(`Leaderstat data not found for identifier {leaderstatIdentifier}`)
            return
        end

        local leaderstatValue = Instance.new("IntValue")
        leaderstatValue.Name = leaderstatData.RICH_NAME
        leaderstatValue.Parent = leaderstatStorage
        leaderstatValues[leaderstatIdentifier] = leaderstatValue
        return leaderstatValue
    end

    --[=[
        Sets the leaderstat value for a player.

        ### Parameters:
        ```luau
        player: Player -- The player to set the leaderstat for.
        leaderstatIdentifier: string -- The identifier of the leaderstat.
        value: number -- The value to set.
        ```
    ]=]
    local function SetLeaderstat(player: Player, leaderstatIdentifier: string, value: number)
        local leaderstatValue = GetLeaderstatValue(player, leaderstatIdentifier)
        if not leaderstatValue then
            Logger.warn(`Cannot set leaderstat value for identifier {leaderstatIdentifier} for player {player.Name} because it does not exist`)
            return
        end

        leaderstatValue.Value = value
    end
    
    --[=[
        Initializes leaderstats for a newly added player.

        ### Parameters:
        ```luau
        player: Player -- The player who was added.
        ```
    ]=]
    local function PlayerAdded(player: Player)
        local leaderstatStorage = Instance.new("Folder")
        leaderstatStorage.Name = "leaderstats"
        leaderstatStorage.Parent = player
        MangoServer.SetCacheField(player, "LeaderstatStorage", leaderstatStorage)

        for leaderstatIdentifier in LeaderstatSettings.LEADERSTAT_DATA do
            CreateLeaderstatValue(player, leaderstatIdentifier)
        end
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --// RUNTIME \--
        for _, player: Player in Players:GetPlayers() do
            task.defer(PlayerAdded, player)
        end

        Connector.Connect(Players.PlayerAdded, PlayerAdded, {
            Priority = Connector.Enum.DefaultPriority + 1,
        })

        --// EXPORTS \--
    end

    --// RUNTIME \--

    --// EXPORTS \--
    LeaderstatService.__Init = Init
    LeaderstatService.GetLeaderstatValue = GetLeaderstatValue
    LeaderstatService.SetLeaderstat = SetLeaderstat
end

return LeaderstatService