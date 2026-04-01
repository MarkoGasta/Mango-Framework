--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local IdleService = {}
function IdleService.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")

    --// CONFIG \\--
    local IDLE_ACTIVATION_TIME = 120
    local IDLE_CHECK_INTERVAL = 30

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local RemoteService = MangoServer.Require("RemoteService")
    local FastSignal = MangoServer.Require("FastSignal")
    local Connector = MangoServer.Require("Connector")

    --// TYPES \\--

    --// CONSTANTS \\-.
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Retrieves the idle status of a player from cache.

        ### Parameters:
        ```luau
        player: Player -- The player to check idle status for.
        ```

        ### Returns:
        ```luau
        boolean -- True if the player is idle, false otherwise.
        ```
    ]=]
    local function GetIsPlayerIdle(player: Player)
        return MangoServer.GetCacheField(player, "isIdle")
    end

    --[=[
        Marks a player as active and emits the unidled signal.

        ### Parameters:
        ```luau
        player: Player -- The player to clear from idle state.
        ```
    ]=]
    local function UnidlePlayer(player: Player)
        MangoServer.SetCacheField(player, "isIdle", false)
        IdleService.PlayerUnidled:Fire(player)
    end

    --[=[
        Marks a player as idle and emits the idled signal.

        ### Parameters:
        ```luau
        player: Player -- The player to mark as idle.
        ```
    ]=]
    local function IdlePlayer(player: Player)
        MangoServer.SetCacheField(player, "isIdle", true)
        IdleService.PlayerIdled:Fire(player)
    end

    --[=[
        Starts the background loop that tracks movement and toggles idle state.
    ]=]
    local function StartIdleCheckThread()
        task.defer(function()
            while task.wait(IDLE_CHECK_INTERVAL) do
                for _, player in Players:GetPlayers() do
                    local character = player.Character
                    if not character and not character.PrimaryPart then
                        continue
                    end

                    local isPlayerIdle = GetIsPlayerIdle(player)
                    local lastPosition = MangoServer.GetCacheField(player, "idleCheckPosition")
                    local lastMovedTime = MangoServer.GetCacheField(player, "idleCheckLastMovedTime")
                    if isPlayerIdle then
                        if lastPosition and character:GetPivot() ~= lastPosition then
                            UnidlePlayer(player)
                        end
                    else
                        if lastPosition and character:GetPivot() ~= lastPosition then
                            MangoServer.SetCacheField(player, "idleCheckLastMovedTime", Workspace:GetServerTimeNow())

                        elseif lastMovedTime and Workspace:GetServerTimeNow() - lastMovedTime >= IDLE_ACTIVATION_TIME then
                            IdlePlayer(player)
                        end
                    end

                    MangoServer.SetCacheField(player, "idleCheckPosition", character:GetPivot())
                end
            end
        end)
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    IdleService.__Init = Init
    IdleService.GetIsPlayerIdle = GetIsPlayerIdle
    IdleService.PlayerIdled = FastSignal.new()
    IdleService.PlayerUnidled = FastSignal.new()

    --// RUNTIME \\--
    StartIdleCheckThread()
end

return IdleService  