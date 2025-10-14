--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local CLIENT_LABEL = "CLIENT 👤"
local SERVER_LABEL = "SERVER 🖥️"

--// SERVICES \\--

local RunService = game:GetService("RunService")

--// MODULES \\--

--// TYPES \\--

type MessageOptions = {
    printCallstack: boolean,
}

--// CONSTANTS \\--

local InfoMessageOptionsDefault: MessageOptions = {
    printCallstack = false,
}

local WarnMessageOptionsDefault: MessageOptions = {
    printCallstack = true,
}

--// VARIABLES \\--

local Logger = {}

--// FUNCTIONS \\--

-- Handles formatting and logging with any passed function.
local function Log(message: string, logFunction: (message: string) -> nil, options: MessageOptions)
    local stackLabel = RunService:IsClient() and CLIENT_LABEL or SERVER_LABEL
    local printString = `[{stackLabel} / {DateTime.now():FormatLocalTime("HH:mm:ss.SSS", "en-us")}] >>\n{message}\n`

    -- Checking options.
    if options.printCallstack then
        printString ..= `Callstack:\n{debug.traceback(nil, 3)}`
    end

    -- Logging using logging function.
    logFunction(printString)
end

-- Logs information to console.
function Logger.info(message: string, options: MessageOptions?)
    options = options or InfoMessageOptionsDefault

    -- Formatting and printing.
    Log(message, print, options)
end

-- Logs warning to console.
function Logger.warn(message: string, options: MessageOptions?)
    options = options or WarnMessageOptionsDefault
    
    -- Formatting and printing.
    Log(message, warn, options)
end

return Logger