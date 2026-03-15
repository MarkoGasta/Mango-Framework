--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local InterfaceControllerInterface = {}
function InterfaceControllerInterface.__Construct(mainGui: ScreenGui)

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

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    InterfaceControllerInterface.__Init = Init

    --// RUNTIME \\--
end

return InterfaceControllerInterface