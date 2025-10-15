--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local TableUtils = {}

--// FUNCTIONS \\--

-- Combines two arrays together, merging their values.
local function MergeArrays(array1: table, array2: table)
    
    -- Iterating over second arrays values.
    for _, value: any in array2 do
        table.insert(array1, value)
    end

    return array1
end

-- Returns an array filled with indexes from the passed dictionary.
local function GetIndexes(dictionary: table)
	local indexes = {}

	-- Iterating over the dictionary.
	for index, _ in pairs(dictionary) do
		table.insert(indexes, index)
	end

	return indexes
end

-- The function used for deep copying a table.
local function DeepCopy(original: table)	
	local copy = {}

	-- Loop through the original table to clone
	for key, value in original do
		if type(key) == "string" and string.match(key, "^_") then
			continue
		end
        
		copy[key] = type(value) == "table" and DeepCopy(value) or value
	end

	return copy
end

-- Exporting methods.
TableUtils.MergeArrays = MergeArrays
TableUtils.DeepCopy = DeepCopy
TableUtils.GetIndexes = GetIndexes

return TableUtils