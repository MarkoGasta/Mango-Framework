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

--// CONFIG \\--

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local InstanceUtils = {}    

--// FUNCTIONS \\--

--[=[
	Finds a child instance using a dot-separated path string.

	### Parameters:
	```luau
	parent: Instance -- The parent instance to start the search from.
	path: string -- Dot-separated path to the target instance.
	```

	### Returns:
	```luau
	Instance? -- The found instance, or nil if not found within timeout.
	```
]=]
local function FindChildWithStringPath(parent: Instance, path: string)
    local currentInstance: Instance = parent
    local pathSegments = string.split(path, ".")

    for _, segment in pathSegments do
        currentInstance = currentInstance:WaitForChild(segment, 5)
        if not currentInstance then
            return nil
        end
    end

    return currentInstance
end

--// RUNTIME \\--

--// EXPORTS \\--
InstanceUtils.FindChildWithStringPath = FindChildWithStringPath

return InstanceUtils