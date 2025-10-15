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

-- Type checking flags:
--!strict

--// SERVICES \\--

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG \\--

local MODULE_WAIT_TIMEOUT = 10
local MODULE_CONTAINERS = {
    ReplicatedFirst,
    ReplicatedStorage:WaitForChild("Controllers"),
    ReplicatedStorage:WaitForChild("Settings"),
    ReplicatedStorage:WaitForChild("Resources"),
    ReplicatedStorage:WaitForChild("MangoControllers"),
    ReplicatedStorage:WaitForChild("MangoResources"),
}

--// MODULES \\--

local Types = require(script.Types)

--// TYPES \\--

--// CONSTANTS \\--

local MangoClient = {
    Global = {}
}

--// VARIABLES \\--

local moduleCache = {}

--// FUNCTIONS \\--

--- Caches a module required externally.
--- @param moduleName string The name of the module.
--- @param module table The module to cache.
local function CacheModule(moduleName: string, module: table)
    moduleCache[moduleName] = module
end

--- Uses a class name to require or return a cached class.
local function Require(moduleName: Types.ModuleNames): Types.Modules
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end

    -- Caching a class, if not found.
    local startTime = os.clock()
    local currentTime = startTime
    while currentTime - startTime < MODULE_WAIT_TIMEOUT do
        for _, moduleContainer: Folder in MODULE_CONTAINERS do
            local module: ModuleScript? = moduleContainer:FindFirstChild(moduleName, true)
            if not module then
                continue
            end

            -- Only cache top level modules.
            if module:FindFirstAncestorOfClass("ModuleScript") then
                continue
            end

            local requiredModule = require(module)
            moduleCache[moduleName] = requiredModule
            return requiredModule
        end

        currentTime = os.clock()
        task.wait(1)
    end
end

--// EXPORTS \\--
MangoClient.CacheModule = CacheModule
MangoClient.Require = Require

return MangoClient