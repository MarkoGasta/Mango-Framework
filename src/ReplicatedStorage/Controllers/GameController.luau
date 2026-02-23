--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local GameController = {}
function GameController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))

    --// TYPES \\--

    --// CONSTANTS \\--

    --// VARIABLES \\--

    --// FUNCTIONS \\--

    -- Initializes the controller.
    local function Init()

        --// FUNCTION \\--

        --- Starts the game loop.
        local function Start()
            MangoClient.LockModule("RemoteController")
        end

        --// RUNTIME \\--

        --// EXPORTS \\--
        GameController.Start = Start
    end

    --// RUNTIME \\--

    --// EXPORTS \\--
    GameController.__Init = Init
end

return GameController