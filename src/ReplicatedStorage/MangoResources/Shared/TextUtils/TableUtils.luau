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

--// TYPES \\--

type MergeDictionariesOptions = {
	KeysToIgnore: {string} | {},
    Overwrite: boolean,
	ShallowMerge: boolean?
}

type CopyTableOptions = {
	KeysToIgnore: {string} | {},
	RemoveCyclic: boolean?,
	ShallowCopy: boolean?,
}

--// CONSTANTS \\--

local TableUtils = {
	_Enum = {
		SortingFunctions = {
			Ascending = {
				Name = "Ascending",
				Value = function(a, b) return a < b end,
			},
			Descending = {
				Name = "Descending",
				Value = function(a, b) return a > b end,
			},
		}
	}
}

local MergeDictionariesOptionsDefault: MergeDictionariesOptions = {
	KeysToIgnore = {},
	Overwrite = false,
	ShallowMerge = false
}

local CopyTableOptionsDefaults: CopyTableOptions = {
	KeysToIgnore = {},
	RemoveCyclic = false,
	ShallowCopy = false,
}

--// VARIABLES \\--

--// FUNCTIONS \\--

--[=[
		Handles logging of warning messages specific to TableUtils.

		### Parameters:
		```luau
		message: string -- The warning message to log.
		```
]=]
local function LogWarning(message: string)
	warn(`[TableUtils] {message}`)
end

--[=[
        Calculates the number of entries in a table. Extends default support to dictionaries.

        ### Parameters:
        ```luau
        table: table -- The table to count.
        ```

        ### Returns:
        ```luau
        number -- The total number of keys in the table.
        ```
]=]
local function GetTableLength(table: table): number
	local counter = 0
	for _ in table do
		counter += 1
	end
	
	return counter
end

--[=[
        Determines whether a table is array-like or dictionary-like.
        The function compares the sequential length operator result (#table) with the total key count from GetTableLength(table); if both are equal the table is treated as an array, otherwise it is treated as a dictionary.

        ### Parameters:
        ```luau
        table: table -- The table to inspect.
        ```

        ### Returns:
        ```luau
		type: "Array" | "Dictionary" -- The type of the table.
        ```
]=]
local function GetTableType(table: table): "Array" | "Dictionary"
	if #table == GetTableLength(table) then
		return "Array"
	else
		return "Dictionary"
	end
end

--[=[
        Merges fields from supplyTable into priorityTable according to options.

        ### Parameters:
        ```luau
        priorityTable: table -- The table that keeps its values unless overwritten.
        supplyTable: table -- The table that provides fallback or overwrite values.
        options = {
            KeysToIgnore: {string} | {} -- Keys that should not be merged.
            Overwrite: boolean -- Whether differing values overwrite priorityTable.
            ShallowMerge: boolean? -- If false, table fields are merged deeply.
        }
        ```

        ### Returns:
        ```luau
        table -- The merged priority table.
        ```
]=]
local function MergeDictionaries(priorityTable: table, supplyTable: table, options: MergeDictionariesOptions?)
    options = options and MergeDictionaries(options, MergeDictionariesOptionsDefault) or MergeDictionariesOptionsDefault
    
    for id: string, value: any in supplyTable do
		if table.find(options.KeysToIgnore, id) then
			continue
		end

		-- If the value in priority table is nil then write the supply value.
        if priorityTable[id] == nil then
            priorityTable[id] = value
			continue
        end

        -- If the options say that value should be rewritten and the values aren't the same then overwrite values.
        if options.Overwrite and priorityTable[id] ~= value then
			if not options.ShallowMerge and typeof(value) == "table" and typeof(priorityTable[id]) == "table" then
				MergeDictionaries(priorityTable[id], value, options)
			else
				priorityTable[id] = value
			end
        end
    end

    return priorityTable
end

--[=[
        Appends all values from supplyTable to priorityTable in order.

        ### Parameters:
        ```luau
        priorityTable: table -- The destination array table to append into.
        supplyTable: table -- The source array table to read values from.
        ```

        ### Returns:
        ```luau
        table -- The updated destination table.
        ```
]=]
local function MergeArrays(priorityTable: table, supplyTable: table)
    for _, value: any in supplyTable do
        table.insert(priorityTable, value)
    end

    return priorityTable
end

--[=[
        Selects and returns a random key from a non-empty table.

        ### Parameters:
        ```luau
        table: table -- The table to select a key from.
        ```

        ### Returns:
        ```luau
        number | string | nil -- A random key or nil when the table is empty.
        ```
]=]
local function GetRandomTableKey(table: table): number | string | nil
	local tableLength = GetTableLength(table)
	if tableLength <= 0 then
		return nil
	end

	local randomKeyId = math.random(1, tableLength)
	local counter = 1
	for key in table do
		if counter ~= randomKeyId then
			counter += 1
			continue
		end

		return key
	end
end

--[=[
        Searches for the key associated with a given value in a dictionary.

        ### Parameters:
        ```luau
        dictionary: table -- The dictionary to search.
        searchValue: any -- The value to find the key for.
        ```

        ### Returns:
        ```luau
        any? -- The key if found, otherwise nil.
        ```
]=]
local function FindValueInDictionary(dictionary: table, searchValue: any): any?
	for key, value in dictionary do
		if value == searchValue then
			return key
		end
	end
end

--[=[
        Converts a dictionary's values into an array.

        ### Parameters:
        ```luau
        dictionary: table -- The dictionary to convert.
        ```

        ### Returns:
        ```luau
        table -- An array containing the dictionary's values.
        ```
]=]
local function DictionaryToArray(dictionary: table)
	local array = {}
	for _, value in dictionary do
		table.insert(array, value)
	end

	return array
end

--[=[
        Swaps keys and values in a dictionary.

        ### Parameters:
        ```luau
        dictionary: table -- The dictionary to invert.
        ```

        ### Returns:
        ```luau
        table? -- The inverted dictionary or nil if invalid.
        ```
]=]
local function InvertDictionary(dictionary: table): table?
	local invertedDictionary = {}
	for key, value in dictionary do
		invertedDictionary[value] = key
	end

	return invertedDictionary
end

--[=[
        Finds common key-value pairs across multiple dictionaries.

        ### Parameters:
        ```luau
        ...: {any: any?} -- Variable number of dictionaries to compare.
        ```

        ### Returns:
        ```luau
        table -- A dictionary of intersecting key-value pairs.
        ```
]=]
local function DictionaryIntersection(...: {any: any?}): table
	local intersectionDictionary = {}
	local dictionariesToCompare = {...}
	for key, value in dictionariesToCompare[1] do
		local isInAllDictionaries = true
		for _, dictionary in dictionariesToCompare do
			if dictionary[key] == nil then
				isInAllDictionaries = false
				break
			end

			if dictionary[key] ~= value then
				isInAllDictionaries = false
				break
			end
		end

		if isInAllDictionaries then
			intersectionDictionary[key] = value
		end
	end

	return intersectionDictionary
end

--[=[
        Finds common values across multiple arrays.

        ### Parameters:
        ```luau
        ...: {any} -- Variable number of arrays to compare.
        ```

        ### Returns:
        ```luau
        {any} -- An array of intersecting values.
        ```
]=]
local function ArrayIntersection(...: {any}): {any}
	local intersectionArray = {}
	local arraysToCompare = {...}
	for _, value in arraysToCompare[1] do
		local isInAllArrays = true
		for _, array in arraysToCompare do
			if not table.find(array, value) then
				isInAllArrays = false
				break
			end
		end

		if isInAllArrays then
			table.insert(intersectionArray, value)
		end
	end

	return intersectionArray
end

--[=[
        Finds key-value pairs unique to each dictionary compared to the others.

        ### Parameters:
        ```luau
        ...: {any: any?} -- Variable number of dictionaries to compare.
        ```

        ### Returns:
        ```luau
        table -- A dictionary of exceptional key-value pairs.
        ```
]=]
local function DictionaryExceptions(...: {any: any?}): table
	local exceptionDictionary = {}
	local dictionariesToCompare = {...}
	for primaryDictionaryIndex, primaryDictionary in dictionariesToCompare do
		for key, value in primaryDictionary do
			local isInAnyOtherDictionary = false
			for secondaryDictionaryIndex, secondaryDictionary in dictionariesToCompare do
				if primaryDictionaryIndex ~= secondaryDictionaryIndex then
					if secondaryDictionary[key] == value then
						isInAnyOtherDictionary = true
						break
					end
				end
			end

			if not isInAnyOtherDictionary then
				exceptionDictionary[key] = value
			end
		end
	end

	return exceptionDictionary
end

--[=[
        Finds values unique to single arrays compared to others.

        ### Parameters:
        ```luau
        ...: {any} -- Variable number of arrays to compare.
        ```

        ### Returns:
        ```luau
        {any} -- An array of exceptional values.
        ```
]=]
local function ArrayExceptions(...: {any}): {any}
	local exceptionArray = {}
	local arraysToCompare = {...}

	for primaryArrayIndex, primaryArray in arraysToCompare do
		for _, value in primaryArray do
			local isInAnyOtherArray = false
			for secondaryArrayIndex, secondaryArray in arraysToCompare do
				if primaryArrayIndex ~= secondaryArrayIndex and table.find(secondaryArray, value) then
					isInAnyOtherArray = true
					break
				end
			end

			if not isInAnyOtherArray then
				table.insert(exceptionArray, value)
			end
		end
	end

	return exceptionArray
end

--[=[
        Sums all numeric values in an array.

        ### Parameters:
        ```luau
        array: {number} -- The array of numbers to sum.
        ```

        ### Returns:
        ```luau
        number -- The total sum of the array values.
        ```
]=]
local function GetArrayValueSum(array: {number})
	if #array <= 0 then
		return 0
	end

	local sum = 0
	for _, value in array do
		sum += value
	end

	return sum
end

--[=[
        Sorts an array using a predefined sorting method.

        ### Parameters:
        ```luau
        array: table -- The array to sort.
        methodName: string -- The name of the sorting method, use one from TableUtils._Enum.SortingFunctions.
        ```

        ### Returns:
        ```luau
        table -- The sorted array.
        ```
]=]
local function SortArray(array: table, methodName: typeof(TableUtils._Enum.SortingFunctions)): table
	local sortingFunction = TableUtils._Enum.SortingFunctions[methodName.Name]
	if not sortingFunction then
		LogWarning(`Sorting method {methodName} is not valid`)
		return array
	end

	table.sort(array, sortingFunction.Value)
	return array
end

--[=[
        Recursively copies a table while handling self-references to the primary table.

        ### Parameters:
        ```luau
        primaryTable: table -- The root table used for cycle detection and self-reference substitution.
        currentTable: table -- The table to copy at the current recursion depth.
        options = {
            KeysToIgnore: {string} | {} -- Keys to skip when copying.
            RemoveCyclic: boolean? -- When true, skips values that point back to the primary table.
            ShallowCopy: boolean? -- When true, nested tables are not traversed (not applied in this helper).
        }
        ```

        ### Returns:
        ```luau
        table -- The newly created copy of currentTable.
        ```
]=]
local function InternalCopyTable(primaryTable: table, currentTable: table, options: CopyTableOptions?)
	options = options and MergeDictionaries(options, CopyTableOptionsDefaults) or CopyTableOptionsDefaults

	local tableCopy = {}
	for key, value in currentTable do
		if options.RemoveCyclic and value == primaryTable then
			continue
		end

		if typeof(value) == "table" then
			if value == primaryTable then
				tableCopy[key] = tableCopy
			else
				tableCopy[key] = InternalCopyTable(primaryTable, value, options)
			end
		else
			tableCopy[key] = value
		end
	end

	return tableCopy
end

--[=[
        Creates a copy of the given table, supporting optional key filtering and cycle handling.

        ### Parameters:
        ```luau
        originalTable: table -- The table to copy.
        options = {
            KeysToIgnore: {string} | {} -- Keys to skip at the top level.
            RemoveCyclic: boolean? -- When true, skips values that point back to originalTable.
            ShallowCopy: boolean? -- When true, nested tables are not traversed.
        }
        ```

        ### Returns:
        ```luau
        table -- The newly created copy of originalTable.
        ```
]=]
local function CopyTable(originalTable: table, options: CopyTableOptions?)
	options = options and MergeDictionaries(options, CopyTableOptionsDefaults) or CopyTableOptionsDefaults

	local tableCopy = {}
	for key, value in originalTable do
		if table.find(options.KeysToIgnore, key) then
			continue
		end

		if options.RemoveCyclic and value == originalTable then
			continue
		end

		if typeof(value) == "table" then
			if options.ShallowCopy then
				tableCopy[key] = {}
			else
				if value == originalTable then
					tableCopy[key] = tableCopy
				else
					tableCopy[key] = InternalCopyTable(tableCopy, value, options)
				end
			end
		else
			tableCopy[key] = value
		end
	end

	return tableCopy
end

--// EXPORTS \\--
TableUtils.GetTableLength = GetTableLength
TableUtils.GetTableType = GetTableType
TableUtils.MergeDictionaries = MergeDictionaries
TableUtils.MergeArrays = MergeArrays
TableUtils.GetRandomTableKey = GetRandomTableKey
TableUtils.FindValueInDictionary = FindValueInDictionary
TableUtils.DictionaryToArray = DictionaryToArray
TableUtils.InvertDictionary = InvertDictionary
TableUtils.DictionaryIntersection = DictionaryIntersection
TableUtils.ArrayIntersection = ArrayIntersection
TableUtils.DictionaryExceptions = DictionaryExceptions
TableUtils.ArrayExceptions = ArrayExceptions
TableUtils.GetArrayValueSum = GetArrayValueSum
TableUtils.SortArray = SortArray
TableUtils.CopyTable = CopyTable

return TableUtils