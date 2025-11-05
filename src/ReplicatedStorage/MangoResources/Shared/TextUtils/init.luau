--[[
-----------------------------------------------------------------------------
Last Updated - 3. Nov. 2025.
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

--// CONFIG \\--

local DEFAULT_ID_LENGTH = 18
local AVAILABLE_CHARACTERS = {
    CapitalLetters = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    },
    SmallLetters = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
    },
    Numbers = {
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    },
    Symbols = {
        "!", "@", "#", "$", "%", "&", "*", "(", ")", "-", "_", "=", "+", "[", "]", "{", "}", ";", ":", ",", ".", "<", ">", "?",
    }
}

--// MODULES \\--

local TableUtils = require(script.TableUtils)

--// TYPES \\--

type RandomStringOptions = {
    CapitalLetters: boolean,
    SmallLetters: boolean,
    Numbers: boolean,
    Symbols: boolean
}

--// CONSTANTS \\--

local RandomStringOptionsDefaults: RandomStringOptions = {
    CapitalLetters = true,
    SmallLetters = true,
    Numbers = false,
    Symbols = false,
}

--// VARIABLES \\--

local TextUtils = {}

--// FUNCTIONS \--

--[=[
	Generates a random string based on specified character options.

	### Parameters:
	```luau
	length: number -- The length of the string to generate.
    options = {
        CapitalLetters: boolean = true, -- Include capital letters A-Z
        SmallLetters: boolean = true,   -- Include small letters a-z
        Numbers: boolean = true, -- Include numbers 0-9
        Symbols: boolean = false -- Include symbols !@#$%^&*()-_+=[]{};:,.<>?
    }
	```

	### Returns:
	```luau
	string -- A random string with characters from selected categories.
	```
]=]
local function GenerateRandomString(length: number, options: RandomStringOptions): string
    options = options and TableUtils.MergeDictionaries(options, RandomStringOptionsDefaults) or RandomStringOptionsDefaults

    local characterPool = {}
    local resultString = ""
    if options.CapitalLetters then
        for _, capitalLetterCharacter in AVAILABLE_CHARACTERS.CapitalLetters do
            table.insert(characterPool, capitalLetterCharacter)
        end
    end

    if options.SmallLetters then
        for _, smallLetterCharacter in AVAILABLE_CHARACTERS.SmallLetters do
            table.insert(characterPool, smallLetterCharacter)
        end
    end

    if options.Numbers then
        for _, numberCharacter in AVAILABLE_CHARACTERS.Numbers do
            table.insert(characterPool, numberCharacter)
        end
    end

    if options.Symbols then
        for _, symbolCharacter in AVAILABLE_CHARACTERS.Symbols do
            table.insert(characterPool, symbolCharacter)
        end
    end

    while string.len(resultString) < length do
        resultString ..= characterPool[math.random(1, #characterPool)]
    end

    return resultString
end

--[=[
	Generates a random alphanumeric identifier string.
    The resulting identifier should be checked against existing identifiers for uniqueness.

	### Returns:
	```luau
	string -- A random identifier string of default length.
	```
]=]
local function GenerateIdentifier(): string
    return GenerateRandomString(DEFAULT_ID_LENGTH, {
        Numbers = true,
    })
end

-- Exporting methods.
TextUtils.GenerateRandomString = GenerateRandomString
TextUtils.GenerateIdentifier = GenerateIdentifier

return TextUtils