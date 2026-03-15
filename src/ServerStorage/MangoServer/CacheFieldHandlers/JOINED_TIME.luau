--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local MangoServerGeneralCacheFieldHandler = {}
function MangoServerGeneralCacheFieldHandler.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")

    --// CONFIG \\--

    --// MODULES \\--

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Called when a player's general cache has been successfully created.

        ### Parameters:
        ```luau
        player: Player -- The player whose cache was created.
        cache: table -- The cache data associated with the player.
        ```
    ]=]
    local function PlayerCacheCreated(player: Player, cache: table)
        cache[script.Name] = Workspace:GetServerTimeNow()
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    MangoServerGeneralCacheFieldHandler.__Init = Init
    MangoServerGeneralCacheFieldHandler.PlayerCacheCreated = PlayerCacheCreated

    --// RUNTIME \\--
end

return MangoServerGeneralCacheFieldHandler