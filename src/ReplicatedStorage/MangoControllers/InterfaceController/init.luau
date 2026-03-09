--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local InterfaceController = {}
function InterfaceController.__Construct()

    --// SERVICES \--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local StarterGui = game:GetService("StarterGui")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")

    --// CONFIG \--
    local DEBUG_LOGGING = false
    local PROGRES_LOGGING = true
    local MODULE_WAIT_TIMEOUT = 10
    local DEFAULT_PRIORITY = 10
    local INTERFACE_PRIORITIES = {
        DialogueBoxInterface = 7,
        InfoCardInterface = 7,
        PointerInterface = 7,
        HudInterface = 8,
        CompletionInterface = 8,
        MinigameInterface = 9,
        CurrencyInterface = 9,
    }

    --// MODULES \--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local SubmoduleUtils = MangoClient.Require("SubmoduleUtils")
    local DeviceUtils = MangoClient.Require("DeviceUtils")
    local TableUtils = MangoClient.Require("TableUtils")
    local FastSignal = MangoClient.Require("FastSignal")
    local Connector = MangoClient.Require("Connector")
    local Logger = MangoClient.Require("Logger")
    local RuntimeSettings = MangoClient.Require("RuntimeSettings")

    --// TYPES \--
    local Types = require(script.Types)
    
    --// CONSTANTS \--
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local GuiStorage = ReplicatedStorage:WaitForChild("Interface")
    local SubmoduleStorage = ReplicatedStorage.MangoSubmodules.InterfaceController
    local InterfaceContainers = {
        SubmoduleStorage.InterfaceHandlers,
        SubmoduleStorage.InterfaceHelpers,
        SubmoduleStorage.MangoInterfaceHelpers,
    }
    
    --// VARIABLES \--
    local interfaceModules = {}
    local moduleCache = {}
    local dynamicFrames = {}
    local dynamicFrameFlagHandlerCache = {}
    local openDynamicFrames = {}
    local groupDynamicFrames = {}
    local objectDynamicScalers = {}

    --// FUNCTIONS \--

    --[=[
        Logs a progress message to the console and updates the global progress string.

        ### Parameters:
        ```luau
        message: string -- The progress message to log.
        ```
    ]=]
    local function LogProgress(message: string)
        MangoClient.Global.LoadProgressString = message
        if not PROGRES_LOGGING then
            return
        end

        Logger.info(message)
    end

    --[=[
        Logs a debug message to the console if debug logging is enabled.

        ### Parameters:
        ```luau
        message: string -- The debug message to log.
        ```
    ]=]
    local function LogDebug(message: string)
        MangoClient.Global.LoadProgressString = message
        if not DEBUG_LOGGING then
            return
        end

        Logger.info(message)
    end

    --[=[
        Closes a dynamic frame.
    ]=]
    local function CloseDynamicFrame(closingFrameName: string)
        local dynamicFrameData = dynamicFrames[closingFrameName]
        if not dynamicFrameData then
            Logger.warn(`Dynamic frame {closingFrameName} not found`)
            return
        end
        
        local openFrameIndex = table.find(openDynamicFrames, closingFrameName)
        if not openFrameIndex then
            return
        end

        if dynamicFrameData._MethodFlag then
            local flagHandler = dynamicFrameFlagHandlerCache[dynamicFrameData._MethodFlag]
            if not flagHandler then
                Logger.warn(`No dynamic frame flag handler found for method flag {dynamicFrameData._MethodFlag}, cannot close frame {closingFrameName}`)
                return
            end

            if not flagHandler.CloseFrame then
                Logger.warn(`Dynamic frame flag handler for method flag {dynamicFrameData._MethodFlag} does not have a CloseFrame method, cannot close frame {closingFrameName}`)
                return
            end

            flagHandler.CloseFrame(dynamicFrameData._Frame)
        else
            if dynamicFrameData.__CloseFrame then
                dynamicFrameData.__CloseFrame()
            else
                Logger.warn(`Dynamic frame {closingFrameName} does not have a close method, cannot close it`)
                return
            end
        end
        
        table.remove(openDynamicFrames, openFrameIndex)
    end

    --[=[
        Closes all open dynamic frames.
    ]=]
    local function CloseAllDynamicFrames()
        for _, openFrameName in openDynamicFrames do
            CloseDynamicFrame(openFrameName)
        end

        table.clear(openDynamicFrames)
    end

    --[=[
        Closes all dynamic frames in a group.

        ### Parameters:
        ```luau
        groupName: string -- The name of the group to close.
        ```
    ]=]
    local function CloseGroupDynamicFrames(groupName: string)
        local groupFrames = groupDynamicFrames[groupName]
        if not groupFrames then
            Logger.warn(`No dynamic frame group with name {groupName} found`)
            return
        end

        for _, frameName: string in groupFrames do
            if table.find(openDynamicFrames, frameName) then
                CloseDynamicFrame(frameName)
            end
        end
    end

    --[=[
        Opens a specific dynamic frame and closes others.

        ### Parameters:
        ```luau
        openingFrameName: string -- The name of the frame to open.
        ```
    ]=]
    local function OpenDynamicFrame(openingFrameName: string)
        local dynamicFrameData = dynamicFrames[openingFrameName]
        if not dynamicFrameData then
            Logger.warn(`Dynamic frame {openingFrameName} not found`)
            return
        end

        if table.find(openDynamicFrames, openingFrameName) then
            CloseDynamicFrame(openingFrameName)
            return
        end

        if dynamicFrameData._MethodFlag then
            local flagHandler = dynamicFrameFlagHandlerCache[dynamicFrameData._MethodFlag]
            if not flagHandler then
                Logger.warn(`No dynamic frame flag handler found for method flag {dynamicFrameData._MethodFlag}, cannot open frame {openingFrameName}`)
                return
            end

            if not flagHandler.OpenFrame then
                Logger.warn(`Dynamic frame flag handler for method flag {dynamicFrameData._MethodFlag} does not have an OpenFrame method, cannot open frame {openingFrameName}`)
                return
            end

            flagHandler.OpenFrame(dynamicFrameData._Frame)
        else
            if dynamicFrameData.__OpenFrame then
                dynamicFrameData.__OpenFrame()
            else
                Logger.warn(`Dynamic frame {openingFrameName} does not have an open method, cannot open it`)
                return
            end
        end

        table.insert(openDynamicFrames, openingFrameName)
    end

    --[=[
        Creates the main GUI by loading the device-specific GUI from storage and parenting it to PlayerGui.
    ]=]
    local function CreateMainGui()
        local playerDevice = DeviceUtils.GetDevice()
        local deviceGui: ScreenGui = GuiStorage:WaitForChild(`{playerDevice}Gui`)
        deviceGui.Parent = PlayerGui
        deviceGui.Name = "MainGui"
        InterfaceController.MainGui = deviceGui
    end

    --[=[
        Retrieves an interface from the cache.

        ### Parameters:
        ```luau
        interfaceName: Types.ModuleNames -- The name of the interface to retrieve.
        ```

        ### Returns:
        ```luau
        any? -- The interface or nil if not found.
        ```
    ]=]
    local function Require(interfaceName: Types.ModuleNames)
        if moduleCache[interfaceName] then
            return moduleCache[interfaceName]
        end

        -- Caching a class, if not found.
        local startTime = os.clock()
        local currentTime = startTime
        while currentTime - startTime < MODULE_WAIT_TIMEOUT do
            for _, moduleContainer: Folder in InterfaceContainers do
                local module: ModuleScript? = moduleContainer:FindFirstChild(interfaceName)
                if not module then
                    continue
                end

                local requiredModule = require(module)
                moduleCache[interfaceName] = requiredModule

                local callingFunction = debug.info(2, "n")
                local constructionMethod = RuntimeSettings.CONSTRUCTION_METHOD
                local isCallingFunctionConstructor = callingFunction == constructionMethod
                local isRequiredModuleTable = typeof(requiredModule) == "table"
                if isRequiredModuleTable then
                    local hasRequiredModuleConstructionMethod = requiredModule[constructionMethod] ~= nil
                    local wasRequiredModuleConstructed = requiredModule[RuntimeSettings.CONSTRUCTED_FLAG] == true
                    if isCallingFunctionConstructor and hasRequiredModuleConstructionMethod and not wasRequiredModuleConstructed then
                        requiredModule[constructionMethod]()
                        requiredModule[RuntimeSettings.CONSTRUCTED_FLAG] = true
                    end
                end

                return requiredModule
            end

            task.wait(1)
            currentTime = Workspace:GetServerTimeNow()
        end

        Logger.warn(`Module "{interfaceName}" not found in specified containers, waited {MODULE_WAIT_TIMEOUT} seconds!`)
        return nil
    end

    --[=[
        Gathers all interface modules from the interface containers and sorts them by priority.
    ]=]
    local function CompileInterfaceModuleArray()
        table.clear(interfaceModules)
        LogDebug("Gathering interface modules...")
        for _, interfaceContainer: Folder in InterfaceContainers do
            for _, module: ModuleScript in interfaceContainer:GetChildren() do
                if not module:IsA("ModuleScript") then
                    continue
                end

                -- Filter out template modules.
                if string.find(string.lower(module.Name), "template") then
                    continue
                end

                table.insert(interfaceModules, module)
            end
        end
        
        LogDebug("Sorting interface modules...")
        table.sort(interfaceModules, function(interface1: ModuleScript, interface2: ModuleScript)
            local aPriority = INTERFACE_PRIORITIES[interface1.Name] or DEFAULT_PRIORITY
            local bPriority = INTERFACE_PRIORITIES[interface2.Name] or DEFAULT_PRIORITY
            return aPriority < bPriority
        end)
    end

    --[=[
        Requires and constructs all gathered interface modules in order of priority.
    ]=]
    local function ConstructInterfaceModules()
        LogProgress("Requiring and constructing interface modules...")
        for _, module: ModuleScript in interfaceModules do
            local moduleName = module.Name
            LogDebug(`Requiring {moduleName}...`)

            local interfaceConstructionStartTime = Workspace:GetServerTimeNow()
            local requiredController = Require(moduleName)

            -- Calling init if it exists.
            LogDebug('Requiring successful!')
            if requiredController[RuntimeSettings.CONSTRUCTED_FLAG] then
                LogProgress(`👆🔨 {moduleName} was pre-constructed, skipping construction...`)
            else
                LogDebug(`Starting {moduleName} construction...`)
                if requiredController[RuntimeSettings.CONSTRUCTION_METHOD] then
                    local success = xpcall(requiredController[RuntimeSettings.CONSTRUCTION_METHOD], Logger.error)
                    if not success then
                        Logger.warn(`Failed to construct {moduleName}, will attempt to continue without it.`)
                        table.remove(interfaceModules, table.find(interfaceModules, module))
                        continue
                    end
                else
                    Logger.warn(`Controller {moduleName} is missing construction method {RuntimeSettings.CONSTRUCTION_METHOD}, will attempt to continue without it!`)
                    table.remove(interfaceModules, table.find(interfaceModules, module))
                    continue
                end

                -- Logging time to require and construct.
                local constructTimeTaken = Workspace:GetServerTimeNow() - interfaceConstructionStartTime
                local timeTakenFormatted = math.round(constructTimeTaken * 1000)
                LogProgress(`👆🔨 {moduleName} constructed, took {timeTakenFormatted}ms!`)
            end
        end
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \--

        --[=[
            Initializes all interface submodules by calling their initialization methods.
        ]=]
        local function InitializeInterfaceSubmodules()
            LogProgress("Initializing interface submodules...")
            for _, module: ModuleScript in interfaceModules do
                local moduleName = module.Name
                local controllerRequireStartTime = os.clock()
                local requiredController = Require(moduleName)

                -- Calling init if it exists.
                LogDebug(`Starting {moduleName} initialization...`)
                if requiredController[RuntimeSettings.INITIALIZATION_METHOD] then
                    xpcall(requiredController[RuntimeSettings.INITIALIZATION_METHOD], Logger.warn)
                else
                    Logger.warn(`Controller {moduleName} is missing initialization method {RuntimeSettings.INITIALIZATION_METHOD}!`)
                    continue
                end
                
                -- Logging time to require and initiate.
                local initTimeTaken = os.clock() - controllerRequireStartTime
                local timeTakenFormatted = math.round(initTimeTaken * 1000)
                LogProgress(`👆🔥 {moduleName} initialized, took {timeTakenFormatted}ms!`)
            end
        end

        --// EXPORTS \--
        
        --// RUNTIME \--
        SubmoduleUtils.InitializeChildrenSubmodules(SubmoduleStorage.DynamicFrameFlagHandlers)
        InitializeInterfaceSubmodules()
    end

    --// EXPORTS \--
    InterfaceController.__Init = Init
    InterfaceController.Require = Require:: Types.Modules
    InterfaceController.CloseAllDynamicFrames = CloseAllDynamicFrames
    InterfaceController.CloseGroupDynamicFrames = CloseGroupDynamicFrames
    InterfaceController.CloseDynamicFrame = CloseDynamicFrame
    InterfaceController.OpenDynamicFrame = OpenDynamicFrame
    InterfaceController.DynamicFrameOpened = FastSignal.new()
    InterfaceController.DynamicFrameClosed = FastSignal.new()

    --// RUNTIME \--
    CreateMainGui()

    SubmoduleUtils.ConstructChildrenSubmodules(SubmoduleStorage.DynamicFrameFlagHandlers, {
        ConstructionArguments = {InterfaceController.MainGui},
        Cache = dynamicFrameFlagHandlerCache,
    })

    CompileInterfaceModuleArray()
    ConstructInterfaceModules()
end

return InterfaceController