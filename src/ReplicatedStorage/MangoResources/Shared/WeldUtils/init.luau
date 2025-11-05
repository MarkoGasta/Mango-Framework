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

--// MODULES \\--

local TableUtils = require(script.TableUtils)

--// TYPES \\--

type WeldOptions = {
	KeepOffset: boolean?,
}

--// CONSTANTS \\--

local WeldUtils = {}
local WeldOptionsDefaults: WeldOptions = {
	KeepOffset = true,
}

--// VARIABLES \\--

--// FUNCTIONS \\--

--[=[
	Creates a weld between two parts with optional offset preservation.

	### Parameters:
	```luau
	primaryPart: BasePart -- The primary part (Part0) of the weld.
	secondaryPart: BasePart -- The secondary part (Part1) of the weld.
	options = {
		KeepOffset: boolean? -- Whether to preserve the current offset between parts.
	}
	```

	### Returns:
	```luau
	type Weld -- The created weld.
	```
]=]
local function Weld(primaryPart: BasePart, secondaryPart: BasePart, options: WeldOptions?): Weld
	options = options and TableUtils.MergeDictionaries(options, WeldOptionsDefaults) or WeldOptionsDefaults

	local weld = Instance.new("Weld")
	weld.Part0 = primaryPart
	weld.Part1 = secondaryPart

	if options.KeepOffset then
		local primaryCFrame = primaryPart.CFrame
		local secondaryCFrame = secondaryPart.CFrame
		local offsetCFrame = primaryCFrame:Inverse() * secondaryCFrame
		weld.C0 = offsetCFrame
	end

	weld.Parent = primaryPart
	return weld
end

--// RUNTIME \\--

--// EXPORTS \\--
WeldUtils.Weld = Weld

return WeldUtils