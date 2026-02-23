--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local GameService = {}
function GameService.__Construct()

    --// SERVICES \\--
    local ServerStorage = game:GetService("ServerStorage")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    
    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --- Starts the game loop.
        local function Start()

        end

        --// RUNTIME \\--

        --// EXPORTS \\--
        GameService.Start = Start
    end

    --// RUNTIME \\--

    --// EXPORTS \\--
    GameService.__Init = Init
end

return GameService