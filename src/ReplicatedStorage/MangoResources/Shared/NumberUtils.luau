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

--// CONFIG \\--

local ABBREVIATION_OVERFLOW_SUFFIX = "+"
local ABBREVIATION_SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
}

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

local NumberUtils = {}

--// VARIABLES \\--

--// FUNCTIONS \\--

--[=[
	Formats a number by inserting commas as thousands separators in the integer part.

	### Parameters:
	```luau
	number: number -- The number to format.
	```

	### Returns:
	```luau
	string -- The formatted number string with commas.
	```
]=]
local function SeparateNumber(number: number): string
	local numberString = tostring(number)

	-- Split the number into integer and decimal parts.
	local integerPart, decimalPart = string.match(numberString, "([^.]*)%.?(.*)")

	-- Insert commas into the integer part.
	integerPart = string.reverse(integerPart)
	integerPart = string.gsub(integerPart, "(%d%d%d)", "%1,")
	integerPart = string.reverse(integerPart)
	if string.sub(integerPart, 1, 1) == "," then
		integerPart = string.sub(integerPart, 2)
	end

	-- Reconstruct the number with decimal part if it exists.
	if decimalPart ~= "" then
		return integerPart .. "." .. decimalPart
	else
		return integerPart
	end
end

--[=[
	Abbreviates a number using suffixes (K, M, B, T, etc.).

	### Parameters:
	```luau
	number: number -- The number to abbreviate.
	```

	### Returns:
	```luau
	string -- The abbreviated number string with appropriate suffix.
	```
]=]
local function AbbreviateNumber(number: number): string
	local isNegative = number < 0
	local absoluteNumber = math.abs(number)

	if absoluteNumber < 1000 then
		return tostring(number)
	end

	local suffixIndex = 1
	while absoluteNumber >= 1000 and suffixIndex < #ABBREVIATION_SUFFIXES do
		absoluteNumber = absoluteNumber / 1000
		suffixIndex = suffixIndex + 1
	end

	local suffix = ABBREVIATION_SUFFIXES[suffixIndex]
	if suffixIndex >= #ABBREVIATION_SUFFIXES and absoluteNumber >= 1000 then
		absoluteNumber = 999.99
		suffix = suffix .. ABBREVIATION_OVERFLOW_SUFFIX
	end

	local formattedValue = string.format("%.2f", absoluteNumber)
	return (isNegative and "-" or "") .. formattedValue .. suffix
end

--// RUNTIME \\--

--// EXPORTS \\--
NumberUtils.SeparateNumber = SeparateNumber
NumberUtils.AbbreviateNumber = AbbreviateNumber
return NumberUtils