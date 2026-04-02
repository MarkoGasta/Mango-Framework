--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local RehydratorService = {}
function RehydratorService.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")

    --// CONFIG \\--
    local CLASS_CONTAINERS = {
        ReplicatedStorage.Classes,
    }

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local ReplicatorService = MangoServer.Require("ReplicatorService")
    local RehydratorUtils = MangoServer.Require("RehydratorUtils")

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--
    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    RehydratorService.__Init = Init

    --// RUNTIME \\--
    RehydratorUtils.InterceptConstructors(CLASS_CONTAINERS)
end

return RehydratorService