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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// CONFIG \\--

local DEBUG_LOGGING = false
local PROGRES_LOGGING = true
local GAME_CONTROLLER_REQUIRED = true
local CONTROLLER_CONTAINERS = {
    ReplicatedStorage:WaitForChild("Controllers"),
    ReplicatedStorage:WaitForChild("MangoControllers"),
}

--// MODULES \\--

local MangoClient = require(ReplicatedStorage.MangoClient)
local SubmoduleUtils = MangoClient.Require("SubmoduleUtils")
local PublicValues = MangoClient.Require("PublicValues")
local TableUtils = MangoClient.Require('TableUtils')
local Logger = MangoClient.Require("Logger")
local RuntimeSettings = MangoClient.Require('RuntimeSettings')

--// TYPES \\--

--// CONSTANTS \\--

local Player = Players.LocalPlayer

--// VARIABLES \\--

local controllers = {}

--// FUNCTIONS \\--

--- Wrapper for logging progress messages.
--- @param message string The message to log.
local function LogProgress(message: string)
    MangoClient.Global.LoadProgressString = message
    if not PROGRES_LOGGING then
        return
    end

    Logger.info(message)
end

--- Wrapper for logging debug messages.
--- @param message string The message to log.
local function LogDebug(message: string)
    MangoClient.Global.LoadProgressString = message
    if not DEBUG_LOGGING then
        return
    end

    Logger.info(message)
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

if not RuntimeSettings.CONTROLLER_PRIORITIES then
    Logger.warn("CONTROLLER_PRIORITIES not found, please add it to your RuntimeSettings module!")
    return
end

-- Initiating client runtime.
LogProgress(`Initiating client runtime...`)
LogDebug("Gathering controllers...")
for _, controllerContainer: Folder in CONTROLLER_CONTAINERS do
    TableUtils.MergeArrays(controllers, controllerContainer:GetChildren())
end

-- Sorting controllers by their priority.
LogDebug("Sorting controllers by priority...")
table.sort(controllers, function(controller1: ModuleScript, controller2: ModuleScript)
    local controller1Priority = RuntimeSettings.CONTROLLER_PRIORITIES[controller1.Name] or RuntimeSettings.DEFAULT_PRIORITY
    local controller2Priority = RuntimeSettings.CONTROLLER_PRIORITIES[controller2.Name] or RuntimeSettings.DEFAULT_PRIORITY

    return controller1Priority < controller2Priority
end)

-- Waiting for game to load.
if not game:IsLoaded() then
    LogDebug(`Waiting for the game.Loaded...`)
    game.Loaded:Wait()
end

-- Waiting for server to load all services.
if not PublicValues.GetValue("ServerLoaded") then
    LogProgress(`Waiting for the server to load...`)
    PublicValues.WaitForValue("ServerLoaded", 120)
end

-- Constructing controllers.
LogDebug("Constructing controllers...")
for _, controller: ModuleScript in controllers do
    LogDebug(`Requiring {controller.Name}...`)
    local controllerConstructionStartTime = os.clock()
    local requiredController = MangoClient.Require(controller.Name)

    -- Calling init if it exists.
    LogDebug('Requiring successful!')
    if requiredController[RuntimeSettings.CONSTRUCTED_FLAG] then
        LogProgress(`🔨 {controller.Name} was pre-constructed, skipping construction...`)
    else
        LogDebug(`Starting {controller.Name} construction...`)
        if requiredController[RuntimeSettings.CONSTRUCTION_METHOD] then
            local success = xpcall(requiredController[RuntimeSettings.CONSTRUCTION_METHOD], Logger.error)
            if not success then
                Logger.warn(`Failed to construct {controller.Name}, will attempt to continue without it.`)
                table.remove(controllers, table.find(controllers, controller))
                continue
            end
        else
            Logger.warn(`Controller {controller.Name} is missing construction method {RuntimeSettings.CONSTRUCTION_METHOD}, will attempt to continue without it!`)
            table.remove(controllers, table.find(controllers, controller))
            continue
        end

        -- Logging time to require and construct.
        local constructTimeTaken = os.clock() - controllerConstructionStartTime
        local timeTakenFormatted = math.round(constructTimeTaken * 1000)
        LogProgress(`🔨 {controller.Name} constructed, took {timeTakenFormatted}ms!`)
    end
end

-- Initializing controllers.
LogDebug("Initializing controllers...")
for _, controller: ModuleScript in controllers do
    local controllerRequireStartTime = os.clock()
    local requiredController = MangoClient.Require(controller.Name)

    -- Calling init if it exists.
    LogDebug(`Starting {controller.Name} initialization...`)
    if requiredController[RuntimeSettings.INITIALIZATION_METHOD] then
        xpcall(requiredController[RuntimeSettings.INITIALIZATION_METHOD], Logger.warn)
    else
        Logger.warn(`Controller {controller.Name} is missing initialization method {RuntimeSettings.INITIALIZATION_METHOD}!`)
        continue
    end
    
    -- Logging time to require and initiate.
    local initTimeTaken = os.clock() - controllerRequireStartTime
    local timeTakenFormatted = math.round(initTimeTaken * 1000)
    LogProgress(`🔥 {controller.Name} initialized, took {timeTakenFormatted}ms!`)
end

-- Client has loaded.
MangoClient.Global.ClientLoaded = true
LogProgress("Client runtime initialized!")

-- Starting game and notifying server player has loaded.
local GameController = MangoClient.Require("GameController")
if GameController and GAME_CONTROLLER_REQUIRED then
    if GameController.Start then
        GameController.Start()
    else
        Logger.warn(`GameController is missing a Start method!`)
    end
else
    Logger.warn("GameController not found, please ensure it exists in your Controllers folder! (ReplicatedStorage.Controllers)")
end