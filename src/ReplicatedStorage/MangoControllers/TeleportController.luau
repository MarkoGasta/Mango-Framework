--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local TeleportController = {}
function TeleportController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--
    local LOG_INFO = true

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local RemoteController = MangoClient.Require("RemoteController")
    local TeleportSettings = MangoClient.Require("TeleportSettings")

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Logs a warning message with the TeleportController prefix.
    ]=]
    local function LogWarning(message: string)
        if not LOG_INFO then
            return
        end

        warn(`[TeleportController] {message}`)
    end

    local function Teleport(placeIdentifier: string, teleportData: table?)
        local teleportSuccess: boolean, teleportResponse: string? = RemoteController.InvokeServer("TELEPORT_CONTROLLER_REQUEST_TELEPORT", placeIdentifier, teleportData)
        if not teleportSuccess then
            LogWarning(`Teleportation failed, details:\n{teleportResponse}`)
        end

        return teleportSuccess, teleportResponse
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
        if not TeleportSettings then
            LogWarning("TeleportSettings module not found. Please ensure it exists within ReplicatedStorage.Settings!")
        end
    end

    --// EXPORTS \\--
    TeleportController.__Init = Init
    TeleportController.Teleport = Teleport

    --// RUNTIME \\--
end

return TeleportController