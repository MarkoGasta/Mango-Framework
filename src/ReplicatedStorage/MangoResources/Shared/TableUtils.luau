--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

--// TYPES \\--

type MergeDictionariesOptions = {
	ignoreKeys: {string} | {},
    overwriteValues: boolean,
	deepMerge: boolean?
}

type DeepCopyOptions = {
	ignoreKeys: {string} | {},
	removeCyclic: boolean?
}

type ShallowCopyOptions = {
	ignoreKeys: {string} | {},
	removeCyclic: boolean?
}

--// CONSTANTS \\--

local MergeDictionariesOptionsDefault: MergeDictionariesOptions = {
	ignoreKeys = {},
    overwriteValues = false,
	deepMerge = false
}

local DeepCopyOptionsDefaults = {
	ignoreKeys = {},
	removeCyclic = false
}

local ShallowCopyOptionsDefaults = {
	ignoreKeys = {},
	removeCyclic = false
}

--// VARIABLES \\--

local TableUtils = {}
local sortingFunctions = {
	Ascending = function(a, b) return a < b end,
	Descending = function(a, b) return a > b end,
}

--// FUNCTIONS \\--

-- Combines two dictionaries together with priority.
local function MergeDictionaries(priorityTable: table, supplyTable: table, options: MergeDictionariesOptions?)

    -- Setting options defaults.
    options = options and MergeDictionaries(options, MergeDictionariesOptionsDefault) or MergeDictionariesOptionsDefault
    
    -- Merging table values.
    for id: string, value: any in supplyTable do
		
		-- If the id is in ignore keys then skip it.
		if table.find(options.ignoreKeys, id) then
			continue
		end

		-- If the value in priority table is nil then write the supply value.
        if priorityTable[id] == nil then
            priorityTable[id] = value
			continue
        end

        -- If the options say that value should be rewritten and the values aren't the same then overwrite values.
        if options.overwriteValues and priorityTable[id] ~= value then
			if options.deepMerge and typeof(value) == "table" and typeof(priorityTable[id]) == "table" then
				MergeDictionaries(priorityTable[id], value, options)
			else
				priorityTable[id] = value
			end
        end
    end

    return priorityTable
end

-- Combines two arrays together, merging their values.
local function MergeArrays(array1: table, array2: table)
    
    -- Iterating over second arrays values.
    for _, value: any in array2 do
        table.insert(array1, value)
    end

    return array1
end

local function GetDictionaryLength(dictionary : {}) : IntValue
	local counter = 0
	for _, _ in pairs(dictionary) do
		counter += 1
	end
	return counter
end

local function GetRandomFromDictionary(dictionary : {})
	local len = GetDictionaryLength(dictionary)
	if len == 0 then
		return nil
	end

	local rand = math.random(1, len)

	local counter = 1
	for id, _ in dictionary do
		if counter ~= rand then
			counter += 1 
			continue
		end

		return id
	end
end

local function GetFromDictionaryByID(dictionary : {}, id : number)
	local counter = 0
	for strid in dictionary do

		counter += 1
		if counter ~= id then continue end

		return strid
	end

	return nil
end

local function FindInDictionary(dictionary : table, searchValue : number)
	
	-- Iterating over all entries in dictionary.
	for id, value in dictionary do
		
		-- Checking if value is == passed value.
		if value == searchValue then
			return id
		end
	end

	return
end

local function DictionaryToArray(dictionary: table)
	local array = {}
	for _, value in pairs(dictionary) do
		table.insert(array, value)
	end
	return array
end

-- Swaps the positions of keys and values in a dictionary.
local function SwapDictionaryKeysAndValues(dictionary: table)
	local swappedDictionary = {}
	for key, value in dictionary do
		swappedDictionary[value] = key
	end
	return swappedDictionary
end

local function Difference(a: table, b: table)
	local differenceTable = {}

	for _, v in a do
		if v ~= nil and not table.find(b, v) then
			table.insert(differenceTable, v)
		end
	end

	for _, v in b do
		if v ~= nil and not table.find(b, v) and not table.find(differenceTable, v) then
			table.insert(differenceTable, v)
		end
	end

	return differenceTable
end

local function OrderDifference(a: table, b: table)
	local differenceTable = {}

	for i: number, v: any in a do
		if v ~= nil and b[i] ~= v then
			table.insert(differenceTable, v)
		end
	end

	for i: number, v: any in b do
		if v ~= nil and a[i] ~= v and not table.find(differenceTable, v) then
			table.insert(differenceTable, v)
		end
	end

	return differenceTable
end

-- Sum all values in array.
--- @return number sum
local function SumArray(array: {number})
	local sum = 0
	for _, value in array do
		sum += value
	end
	return sum
end

-- Sorts an array with one of the predefined sorting methods.
-- Sorting methods: "Ascending", "Descending"
local function SortArray(array: {any}, method: string): {any}
	local sortingFunction = sortingFunctions[method]
	if not sortingFunction then
		warn(`Sorting method ${method} is not valid`)
		return array
	end

	table.sort(array, sortingFunction)
	return array
end

local function DeepCopy(original: table, options: DeepCopyOptions?, seen: table?)    
	local copy = {}
	options = options and MergeDictionaries(options, DeepCopyOptionsDefaults) or DeepCopyOptionsDefaults
	seen = seen or {}
	seen[original] = true

	-- Loop through the original table to clone
	for key, value in original do
		if table.find(options.ignoreKeys, key) then
			continue
		end

		if type(key) == "string" and string.match(key, "^_") then
			continue
		end

		if type(value) == "table" then
			if options.removeCyclic and seen[value] then
				-- Remove top-level cyclical reference
				continue
			end
			copy[key] = DeepCopy(value, options, seen)
		else
			copy[key] = value
		end
	end

	seen[original] = nil
	return copy
end

local function ShallowCopy(original: table, options: ShallowCopyOptions?)
	local copy = {}
	options = options and MergeDictionaries(options, ShallowCopyOptionsDefaults) or ShallowCopyOptionsDefaults

	-- For cycle detection, only need to check if value is original (self-reference) or references original
	for key, value in original do
		if table.find(options.ignoreKeys, key) then
			continue
		end

		if type(key) == "string" and string.match(key, "^_") then
			continue
		end

		if options.removeCyclic and type(value) == "table" and value == original then
			-- Remove top-level cyclical reference
			continue
		end

		copy[key] = value
	end

	return copy
end

-- Exporting methods.
TableUtils.ShallowCopy = ShallowCopy
TableUtils.MergeDictionaries = MergeDictionaries
TableUtils.MergeArrays = MergeArrays
TableUtils.GetDictionaryLength = GetDictionaryLength
TableUtils.GetRandomFromDictionary = GetRandomFromDictionary
TableUtils.GetFromDictionaryByID = GetFromDictionaryByID
TableUtils.DictionaryToArray = DictionaryToArray
TableUtils.SwapDictionaryKeysAndValues = SwapDictionaryKeysAndValues
TableUtils.SortArray = SortArray
TableUtils.FindInDictionary = FindInDictionary
TableUtils.OrderDifference = OrderDifference
TableUtils.Difference = Difference
TableUtils.DeepCopy = DeepCopy
TableUtils.SumArray = SumArray

return TableUtils