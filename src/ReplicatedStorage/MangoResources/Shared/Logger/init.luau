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

local TableUtils = require(script.TableUtils)

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


--[=[
        Handles formatting and logging using the given function.

        ### Parameters:
        ```luau
        message: string -- The message to log.
        logFunction: (message: string) -> any -- The function used to output the message.
        options: {
            PrintCallstack: boolean -- Whether to print the callstack with the message.
        }
        ```
]=]
local function Log(message: string, logFunction: (message: string) -> any, options: MessageOptions)
    local stackLabel = RunService:IsClient() and CLIENT_LABEL or SERVER_LABEL
    local printString = `[{stackLabel} / {DateTime.now():FormatLocalTime("HH:mm:ss.SSS", "en-us")}] >>\n{message}\n`

    -- Checking options.
    if options.PrintCallstack then
        printString ..= `Callstack:\n{debug.traceback(nil, 3)}`
    end

    -- Logging using logging function.
    local messageThread = task.spawn(logFunction, printString)
    while coroutine.status(messageThread) == "running" do
        task.wait()
    end
end

--[=[
        Logs info message to console.

        ### Parameters:
        ```luau
        message: string -- The message to log.
        options = {
            PrintCallstack: boolean -- Whether to print the callstack with the message.
        }
        ```
]=]
local function Info(message: string, options: MessageOptions?)
    options = options and TableUtils.MergeDictionaries(options, InfoMessageOptionsDefault) or InfoMessageOptionsDefault
    Log(message, print, options)
end


--[=[
        Logs warning message to console.

        ### Parameters:
        ```luau
        message: string -- The message to log.
        options = {
            PrintCallstack: boolean -- Whether to print the callstack with the message.
        }
        ```
]=]
local function Warn(message: string, options: MessageOptions?)
    options = options and TableUtils.MergeDictionaries(options, WarnMessageOptionsDefault) or WarnMessageOptionsDefault
    Log(message, warn, options)
end

--[=[
        Logs error message to console.

        ### Parameters:
        ```luau
        message: string -- The message to log.
        options = {
            PrintCallstack: boolean -- Whether to print the callstack with the message.
        }
        ```
]=]
local function Error(message: string, options: MessageOptions?)
    options = options and TableUtils.MergeDictionaries(options, WarnMessageOptionsDefault) or WarnMessageOptionsDefault
    Log(message, error, options)
end

--// EXPORTS \\--
Logger.info = Info
Logger.warn = Warn
Logger.error = Error

return Logger