--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local DataServiceSelfUpdatingFieldHandler = {}
function DataServiceSelfUpdatingFieldHandler.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Called when a player's profile is about to be unloaded.

        ### Parameters:
        ```luau
        player: Player -- The player whose profile is being unloaded.
        profile: table -- The profile data associated with the player.
        ```
    ]=]
    local function HandlePlayerProfileUnloading(player: Player, profile: table)
        profile.Data[script.Name] = Workspace:GetServerTimeNow()
    end

    --[=[
        Called when a player's profile has been successfully loaded.

        ### Parameters:
        ```luau
        player: Player -- The player whose profile was loaded.
        profile: table -- The profile data associated with the player.
        ```
    ]=]
    local function HandlePlayerProfileLoaded(player: Player, profile: table)
        
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    DataServiceSelfUpdatingFieldHandler.__Init = Init
    DataServiceSelfUpdatingFieldHandler.HandlePlayerProfileLoaded = HandlePlayerProfileLoaded
    DataServiceSelfUpdatingFieldHandler.HandlePlayerProfileUnloading = HandlePlayerProfileUnloading

    --// RUNTIME \\--
end

return DataServiceSelfUpdatingFieldHandler