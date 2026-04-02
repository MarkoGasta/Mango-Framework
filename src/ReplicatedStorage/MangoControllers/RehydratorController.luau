--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local RehydratorController = {}
function RehydratorController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// CONFIG \\--
    local CLASS_CONTAINERS = {
        ReplicatedStorage.Classes,
    }

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local RehydratorUtils = MangoClient.Require("RehydratorUtils")
    local Logger = MangoClient.Require("Logger")

     --// TYPES \\--

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Rehydrates an instance with its assigned class methods.

        ### Parameters:
        ```luau
        instance: table -- The instance to rehydrate with the assigned class replica.
        ```
    ]=]
    local function Rehydrate(instance: table): ()
        local classData = instance.RHDClassData
        if not classData then
            Logger.warn("Attempted to rehydrate an instance without RHDClassData")
            return
        end

        local className = classData.ClassName
        if not className then
            Logger.warn("Attempted to rehydrate an instance with invalid RHDClassData: missing ClassName")
            return
        end

        local classModule = MangoClient.Require(className)
        instance.RHDClassData.__ClassValue = classModule
        RehydratorUtils.HydrateInstance(instance)
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    RehydratorController.__Init = Init
    RehydratorController.Rehydrate = Rehydrate

    --// RUNTIME \\--
    RehydratorUtils.InterceptConstructors(CLASS_CONTAINERS)
end

return RehydratorController