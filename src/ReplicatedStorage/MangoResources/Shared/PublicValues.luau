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
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--// CONFIG \\--

local VALUE_FOLDER_NAME = "_PublicValueStorage"
local INFINITE_YIELD_WARN_TIME = 10
local ERROR_LOGGING = true

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

local PublicValues = {}
local ValueFolder: Folder

--// VARIABLES \\--


--// FUNCTIONS \\--

--[=[
	Logs an error message to the console if error logging is enabled.

	### Parameters:
	```luau
	message: string -- The error message to log.
	```
]=]
local function LogError(message: string)
	if not ERROR_LOGGING then
		return
	end

	warn(`[PublicValues] {message}`)
end

--[=[
	Creates a new Configuration instance to store a public value.

	### Parameters:
	```luau
	valueName: string -- The name of the value instance.
	```

	### Returns:
	```luau
	Configuration -- The created Configuration instance.
	```
]=]
local function CreateValueInstance(valueName: string)
	local valueInstance = Instance.new("Configuration")
	valueInstance.Name = valueName
	valueInstance.Parent = ValueFolder
	return valueInstance
end

--[=[
	Retrieves the Configuration instance for a public value by name.

	### Parameters:
	```luau
	valueName: string -- The name of the value instance to retrieve.
	```

	### Returns:
	```luau
	Configuration? -- The Configuration instance if found, nil otherwise.
	```
]=]
local function GetValueInstance(valueName: string)
	return ValueFolder:FindFirstChild(valueName)
end

--[=[
	Gets the changed signal for a public value that fires when the value changes.

	### Parameters:
	```luau
	valueName: string -- The name of the value to monitor.
	```

	### Returns:
	```luau
	RBXScriptSignal? -- The attribute changed signal if the value exists, nil otherwise.
	```
]=]
local function GetValueChangedSignal(valueName: string)
	if not valueName then
		LogError(`Argument "valueName" missing`)
		return nil
	end

	local valueInstance = GetValueInstance(valueName)
	if not valueInstance then
		return nil
	end

	return valueInstance:GetAttributeChangedSignal("Value")
end

--[=[
	Retrieves the current value of a public value by name.

	### Parameters:
	```luau
	valueName: string -- The name of the value to retrieve.
	```

	### Returns:
	```luau
	any -- The stored value, or nil if not found.
	```
]=]
local function GetValue(valueName: string)
	if not valueName then
		LogError(`Argument "valueName" missing`)
		return
	end

	local valueConfiguration = GetValueInstance(valueName)
	if not valueConfiguration then
		return
	end

	-- Getting the value instance from the value configuration.
	local valueInstance = HttpService:JSONDecode(valueConfiguration:GetAttribute("Value"))
	return valueInstance.__Value
end

--[=[
	Destroys a public value by name.

	### Parameters:
	```luau
	valueName: string -- The name of the value to destroy.
	```
]=]
local function DestroyValue(valueName: string)
	if not valueName then
		LogError(`Argument "valueName" missing`)
		return
	end

	local valueInstance = GetValueInstance(valueName)
	if valueInstance then
		valueInstance:Destroy()
	end
end

--[=[
	Yields until a public value is set or the timeout is reached.

	### Parameters:
	```luau
	valueName: string -- The name of the value to wait for.
	timeout: number? -- Optional timeout in seconds.
	```

	### Returns:
	```luau
	any -- The value when found, or nil if timeout is reached.
	```
]=]
local function WaitForValue(valueName: string, timeout: number?)
	if not valueName then
		LogError(`Argument "valueName" missing`)
		return nil
	end

	local startTime = os.clock()
	local currentTime = startTime
	while GetValue(valueName) == nil do
		if timeout and (currentTime - startTime) >= timeout then
			return nil
		end

		if math.round(currentTime - startTime) == INFINITE_YIELD_WARN_TIME and not timeout then
			LogError(`Waiting for value "{valueName}" is yielding for over {INFINITE_YIELD_WARN_TIME} seconds.` ..
			`\n\n` ..
			`Traceback: {debug.traceback()}`)
		end

		currentTime = os.clock()
		task.wait(1)
	end

	return GetValue(valueName)
end

--[=[
	Sets a public value that can be accessed from both server and client.

	### Parameters:
	```luau
	valueName: string -- The name of the value to set.
	value: any -- The value to store.
	```
]=]
local function SetValue(valueName: string, value: any)
	if not valueName then
		LogError(`Argument "valueName" missing`)
		return
	end

	if typeof(valueName) ~= "string" then
		LogError(`Argument "valueName" must be of type string, got {typeof(valueName)}`)
		return
	end

	if not value then
		LogError(`Argument "value" missing`)
		return
	end

	if RunService:IsClient() then
		LogError(`This method can only be used by the server`)
		return
	end

	local valueInstance = GetValueInstance(valueName)
	if not valueInstance then
		valueInstance = CreateValueInstance(valueName)
	end

	-- Defining value instance properties.
	valueInstance:SetAttribute("Value", HttpService:JSONEncode({
		__ValueName = valueName,
		__Value = value
	}))
end

--// RUNTIME \\--

-- Creating a folder to store the shared values, if it doesn't already exist.
ValueFolder = ReplicatedStorage:FindFirstChild(VALUE_FOLDER_NAME):: Folder?
if not ValueFolder then
	ValueFolder = Instance.new("Folder")
	ValueFolder.Parent = ReplicatedStorage
	ValueFolder.Name = VALUE_FOLDER_NAME
end

--// EXPORTS \\--
PublicValues.GetValueChangedSignal = GetValueChangedSignal
PublicValues.WaitForValue = WaitForValue
PublicValues.GetValue = GetValue
PublicValues.SetValue = SetValue
PublicValues.DestroyValue = DestroyValue

return PublicValues