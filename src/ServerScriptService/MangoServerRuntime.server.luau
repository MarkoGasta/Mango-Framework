--[[
-----------------------------------------------------------------------------
Last Updated - 15. Oct 2025.
Copyright 2025 MarkoGasta @ Studio Blackout

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the“Software”),
to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
-----------------------------------------------------------------------------
]]--

--// SERVICES \\--
local ServerStorage = game:GetService("ServerStorage")

--// CONFIG \\--
local DEBUG_LOGGING = false
local PROGRES_LOGGING = true
local GAME_SERVICE_REQUIRED = true
local SERVICE_CONTAINERS = {
    ServerStorage:WaitForChild("Services"),
    -- ServerStorage:WaitForChild("MangoServices")
}

--// MODULES \\--
local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
local PublicValues = MangoServer.Require("PublicValues")
local TableUtils = MangoServer.Require('TableUtils')
local Logger = MangoServer.Require("Logger")
local RuntimeSettings = MangoServer.Require('RuntimeSettings')

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--
local services = {}

--// FUNCTIONS \\--

--- Wrapper for logging progress messages.
--- @param message string The message to log.
local function LogProgress(message: string)
    if not PROGRES_LOGGING then
        return
    end

    Logger.info(message)
    MangoServer.Global.LoadProgressString = message
end

--- Wrapper for logging debug messages.
--- @param message string The message to log.
local function LogDebug(message: string)
    if not DEBUG_LOGGING then
        return
    end

    Logger.info(message)
    MangoServer.Global.LoadProgressString = message
end

--// RUNTIME \\--

-- Checking if all the required data is present.
if not RuntimeSettings then
    Logger.warn("RuntimeSettings module not found, please create it in your local settings folder! (ReplicatedStorage.Settings)")
    return
end

if not RuntimeSettings.DEFAULT_PRIORITY then
    Logger.warn("DEFAULT_PRIORITY not found, please add it to your RuntimeSettings module!")
    return
end

if not RuntimeSettings.SERVICE_PRIORITIES then
    Logger.warn("SERVICE_PRIORITIES not found, please add it to your RuntimeSettings module!")
    return
end

-- Getting services from all destinations.
LogProgress(`Initiating server runtime...`)
LogDebug("Gathering services...")
for _, serviceContainer: Folder in SERVICE_CONTAINERS do
    TableUtils.MergeArrays(services, serviceContainer:GetChildren())
end

-- Sorting services.
LogDebug("Sorting services by priority...")
table.sort(services, function(service1: ModuleScript, service2: ModuleScript)
    local service1Priority = RuntimeSettings.SERVICE_PRIORITIES[service1.Name] or RuntimeSettings.DEFAULT_PRIORITY
    local service2Priority = RuntimeSettings.SERVICE_PRIORITIES[service2.Name] or RuntimeSettings.DEFAULT_PRIORITY

    return service1Priority < service2Priority
end)

-- Constructing services.
LogDebug("Constructing services...")
for _, service: ModuleScript in services do
    local serviceName = service.Name
    if table.find(RuntimeSettings.DISABLED_SERVICES, serviceName) then
        LogDebug(`Service {serviceName} is disabled, skipping construction...`)
        continue
    end

    LogDebug(`Requiring {serviceName}...`)
    local serviceConstructionStartTime = os.clock()
    local requiredService = MangoServer.Require(serviceName)

    -- Calling Construct if it exists.
    LogDebug('Requiring successful!')
    LogDebug(`Starting {serviceName} construction...`)
    if requiredService[RuntimeSettings.CONSTRUCTED_FLAG] then
        LogProgress(`🔨 {serviceName} was pre-constructed, skipping construction...`)
    else
        if requiredService[RuntimeSettings.CONSTRUCTION_METHOD] then
            local success = xpcall(requiredService[RuntimeSettings.CONSTRUCTION_METHOD], Logger.error)
            if not success then
                Logger.warn(`Failed to construct {serviceName}, will attempt to continue without it.`)
                table.remove(services, table.find(services, service))
                continue
            end
        else
            Logger.warn(`{serviceName} is missing construction method {RuntimeSettings.CONSTRUCTION_METHOD}, will attempt to continue without it!`)
            table.remove(services, table.find(services, service))
            continue
        end
        
        -- Logging time to require and construct.
        local constructTimeTaken = os.clock() - serviceConstructionStartTime
        local timeTakenFormatted = math.round(constructTimeTaken * 1000)
        LogProgress(`🔨 {serviceName} constructed, took {timeTakenFormatted}ms!`)
    end
end

-- Initializing controllers.
-- Initializing services.
LogDebug("Initializing services...")
for _, service: ModuleScript in services do
    local serviceName = service.Name
    if table.find(RuntimeSettings.DISABLED_SERVICES, serviceName) then
        LogDebug(`Service {serviceName} is disabled, skipping initialization...`)
        continue
    end

    local serviceRequireStartTime = os.clock()
    local requiredService = MangoServer.Require(serviceName)

    -- Calling Init if it exists.
    LogDebug(`Starting {serviceName} initialization...`)
    if requiredService[RuntimeSettings.INITIALIZATION_METHOD] then
        xpcall(requiredService[RuntimeSettings.INITIALIZATION_METHOD], Logger.warn)
    else
        Logger.error(`{serviceName} is missing initialization method {RuntimeSettings.INITIALIZATION_METHOD}!`)
        continue
    end
    
    -- Logging time to require and initiate.
    local initTimeTaken = os.clock() - serviceRequireStartTime
    local timeTakenFormatted = math.round(initTimeTaken * 1000)
    LogProgress(`🔥 {serviceName} initialized, took {timeTakenFormatted}ms!`)
end

-- Starting game service.
local GameService = MangoServer.Require('GameService')
if GameService and GAME_SERVICE_REQUIRED then
    if GameService.Start then
        GameService.Start()
    else
        Logger.warn(`GameService is missing a Start method!`)
    end
else
    Logger.warn("GameService not found, please ensure it exists in your Services folder! (ServerStorage.Services)")
end

-- Setting server loaded to true.
PublicValues.SetValue("ServerLoaded", true)
LogProgress("Server runtime initialized!")