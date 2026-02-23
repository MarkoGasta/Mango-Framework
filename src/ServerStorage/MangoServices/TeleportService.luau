--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local TeleportService = {}
function TeleportService.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")
    local InternalTeleportService = game:GetService("TeleportService")

    --// CONFIG \\--
    local LOG_INFO = true

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local RemoteService = MangoServer.Require("RemoteService")
    local TeleportSettings = MangoServer.Require("TeleportSettings")

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Logs a warning message with the TeleportService prefix.
    ]=]
    local function LogWarning(message: string)
        if not LOG_INFO then
            return
        end

        warn(`[TeleportService] {message}`)
    end

    --[=[
        Handles a self-teleport request from a player.

        ### Parameters:
        ```luau
        player: Player -- The player requesting the teleport.
        placeIdentifier: string -- The place identifier to look up in settings.
        ```

        ### Returns:
        ```luau
        boolean -- Whether the teleport request succeeded.
        string? -- Error details when the request fails.
        ```
    ]=]
    local function HandlePlayerTeleportRequest(player: Player, placeIdentifier: string)
        local placeData = TeleportSettings.PLACE_DATA[placeIdentifier]
        if not placeData then
            return false, `Place with identifier {placeIdentifier} not found`
        end

        if not placeData.ALLOW_SELF_TELEPORT then
            return false, `Place does not allow self teleportation`
        end

        local placeId = placeData.PLACE_ID
        local teleportSuccess, teleportResponse = pcall(function()
            return InternalTeleportService:TeleportAsync(placeId, {player})
        end)

        if not teleportSuccess then
            return false, teleportResponse
        end

        return true
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
        if not TeleportSettings then
            LogWarning("TeleportSettings module not found. Please ensure it exists within ReplicatedStorage.Settings!")
        end
    end

    --// EXPORTS \\--
    TeleportService.__Init = Init

    --// RUNTIME \\--
    RemoteService.OnServerInvoke("TELEPORT_CONTROLLER_REQUEST_TELEPORT", HandlePlayerTeleportRequest)
end

return TeleportService