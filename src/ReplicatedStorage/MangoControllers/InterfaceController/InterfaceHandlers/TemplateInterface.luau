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
        mainGui.TemplateFrame.Visible = true
    end

    --// EXPORTS \\--
    InterfaceControllerInterface.__Init = Init
    -- InterfaceControllerInterface.__DynamicFrames = {
    --     DynamicFrameTemplate = {
    --         __OpenFrame = function()
    
    --         end,
    --         __CloseFrame = function()
    
    --         end,

    --          OR!!!

    --         _Frame = mainGui:WaitForChild("TemplateFrame"),
    --         _MethodFlag = "TEMPLATE",

    --          OpTIONALLY!!!

    --         _Groups = {"TemplateGroup"}
    --     }
    -- }

    --// RUNTIME \\--
end

return InterfaceControllerInterface