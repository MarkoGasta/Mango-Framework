--!strict
--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local VALUE_FOLDER_NAME = "_PublicValueStorage"

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--// CONSTANTS \\--

--// MODULES \\--

--// VARIABLES \\--

local PublicValues = {}
local valuesFolder: Folder

--// FUNCTIONS \\--

-- Gets or creates a configuration instance in the value storage that stores a value instance.
local function GetConfigurationInstance(valueName: string, noCreate: boolean?)
	
	-- Getting value configuration from storage and checking if it exists.
	local valueInstance = valuesFolder:FindFirstChild(valueName)
	if valueInstance then

		-- Returing existing value configuration.
		return valueInstance
	else

		-- Checks wether it is prohibited to create a new configuration.
		if noCreate then
			return nil
		end

		-- Creating a new value configuration.
		local newValueInstance = Instance.new("Configuration")
		newValueInstance.Parent = valuesFolder
		newValueInstance.Name = valueName
		return newValueInstance
	end
end

-- Returns value changed signal.
function PublicValues.GetValueChangedSignal(name : string)
	
	-- Return conditions.
	if not name then
		return warn(`[ERROR] Name can't be nil.`)
	end

	local value = valuesFolder:FindFirstChild(name)
	if not value then
		return nil
	end

	return value:GetAttributeChangedSignal("Value")
end

-- Gets a public value.
function PublicValues.GetValue(valueName: string)

	-- Asserting arguments.
	assert(valueName, `Argument #1 missing. Expected string, got nil`)

	-- Checking wether the value exists, warn user if it doesn't and return.
	local valueConfiguration = GetConfigurationInstance(valueName, true)
	if not valueConfiguration then
		return warn(`Value {valueName} doesn't exist`)
	end

	-- Getting the value instance from the value configuration.
	local valueInstance = HttpService:JSONDecode(valueConfiguration:GetAttribute("Value"))
	return valueInstance.valueContents
end

-- Sets or creates a public value.
function PublicValues.SetValue(valueName: string, valueContents: any)

	-- Asserting arguments.
	assert(valueName, `Argument #1 missing. Expected string, got nil`)
	assert(valueContents ~= nil, `Argument #2 missing. Expected string, got nil`)
	assert(RunService:IsServer(), `This method can only be used by the server`)
	
	-- Creating a value instance.
	local valueInstance = {
		valueName = valueName,
		valueContents = valueContents:: typeof(valueContents),
		valueType = typeof(valueContents),
	}

	-- Caching created value as JSON string under random id.
	GetConfigurationInstance(valueName):SetAttribute("Value", HttpService:JSONEncode(valueInstance))
end

-- This section runs any time the module is required.
-- Creating a folder to store the shared values, if it doesn't already exist.
if ReplicatedStorage:FindFirstChild(VALUE_FOLDER_NAME) then
	valuesFolder = ReplicatedStorage[VALUE_FOLDER_NAME]
else
	valuesFolder = Instance.new("Folder")
	valuesFolder.Parent = ReplicatedStorage
	valuesFolder.Name = VALUE_FOLDER_NAME
end

return PublicValues