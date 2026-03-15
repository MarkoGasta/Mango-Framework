--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local InterfaceControllerDynamicFrameFlagHandler = {}
function InterfaceControllerDynamicFrameFlagHandler.__Construct(mainGui: ScreenGui)

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Closes the provided interface frame.

        ### Parameters:
        ```luau
        frame: GuiObject -- The frame instance to close.
        ```
    ]=]
    local function CloseFrame(frame: GuiObject)
        
    end

    --[=[
        Opens the provided interface frame.

        ### Parameters:
        ```luau
        frame: GuiObject -- The frame instance to open.
        ```
    ]=]
    local function OpenFrame(frame: GuiObject)
        
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    InterfaceControllerDynamicFrameFlagHandler.__Init = Init
    InterfaceControllerDynamicFrameFlagHandler.CloseFrame = CloseFrame
    InterfaceControllerDynamicFrameFlagHandler.OpenFrame = OpenFrame

    --// RUNTIME \\--
end

return InterfaceControllerDynamicFrameFlagHandler