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

local RunService = game:GetService("RunService")

--// CONFIG \\--

local CLIENT_LABEL = "CLIENT 👤"
local SERVER_LABEL = "SERVER 🖥️"

--// MODULES \\--

--// TYPES \\--

type MessageOptions = {
    PrintCallstack: boolean,
}

--// CONSTANTS \\--

local InfoMessageOptionsDefault: MessageOptions = {
    PrintCallstack = false,
}

local WarnMessageOptionsDefault: MessageOptions = {
    PrintCallstack = true,
}

--// VARIABLES \\--

local Logger = {}

--// FUNCTIONS \\--

--- Handles formatting and logging with any passed function.
--- @param message string The message to log.
--- @param logFunction function The logging function to use (print, warn, error).
local function Log(message: string, logFunction: (message: string) -> nil, options: MessageOptions)
    local stackLabel = RunService:IsClient() and CLIENT_LABEL or SERVER_LABEL
    local printString = `[{stackLabel} / {DateTime.now():FormatLocalTime("HH:mm:ss.SSS", "en-us")}] >>\n{message}\n`

    -- Checking options.
    if options.PrintCallstack then
        printString ..= `Callstack:\n{debug.traceback(nil, 3)}`
    end

    -- Logging using logging function.
    pcall(logFunction, printString)
end

--[=[
        ```luau
        local function a()

        end
        ```
]=]
function Logger.info(message: string, options: MessageOptions?)
    local definedOptions = options or InfoMessageOptionsDefault

    -- Formatting and printing.
    Log(message, print, definedOptions)
end

-- Logs warning to console.
function Logger.warn(message: string, options: MessageOptions?)
    local definedOptions = options or WarnMessageOptionsDefault
    
    -- Formatting and printing.
    Log(message, warn, definedOptions)
end

-- Logs error to console.
function Logger.error(message: string, options: MessageOptions?)
    local definedOptions = options or WarnMessageOptionsDefault

    -- Formatting and printing.
    Log(message, error, definedOptions)
end

return Logger