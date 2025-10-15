--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local ID_LENGTH = 18
local ID_SYMBOLS = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}
local DESKTOP_BASE_HEIGHT = 1260
local MOBILE_BASE_HEIGHT = 393


--// SERVICES \\--

local Workspace = game:GetService("Workspace")

--// MODULES \\--

local DeviceUtils = require(script.DeviceUtils)

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local TextUtils = {}

--// FUNCTIONS \\--

-- Generates a unique identifier.
local function GenerateIdentifier(): string
    local id = ""

    -- Iterating over each id character.
    for i: number = 1, ID_LENGTH - 1 do
        if i % (ID_LENGTH / 3) == 0 then
            id ..= "-"
        else
            id ..= ID_SYMBOLS[math.random(1, #ID_SYMBOLS)]
        end
    end

    return id
end

-- Exporting methods.
TextUtils.GenerateIdentifier = GenerateIdentifier

return TextUtils