--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

--// CONSTANTS \\--

--// MODULES \\--

--// VARIABLES \\--

local NumberUtils = {}

--// FUNCTIONS \\--

local function NumberToName(number : any)
	number = tostring(number or ""):match("^0*(.*)$")
	if #number == 0 then return "zero" end
	if #number > 3 then
		local x = {"thousand", "million", "billion", "trillion", "quadrillion", "quintillion", "sextillion", "septillion", "octillion", "nonillion"}
		local y = {"", "un", "duo", "tre", "quattuor", "quin", "sex", "septen", "octo", "novem"}
		local z = {"t", "dec", "vigint", "trigint", "quadragint", "quinquagint", "sexagint", "septuagint", "octogint", "nonagint"}
		for i = 2, #z do
			for j = 1, #y do
				x[#x+1] = y[j]..z[i].."illion"
			end
		end
		y[3], y[10] = "do", "ovem"
		local v = {"cen", "ducen", "trecen", "quadringen", "quingen", "sescen", "septingen", "optingen", "nongen"}
		for h = 1, #v do
			for i = 1, #z do
				for j = 1, #y do
					x[#x+1] = v[h]..y[j]..z[i].."illion"
				end
			end
		end
		x[#x+1] = "millillion"
		local c = (#number - 1)%3 + 1
		local remain = number:sub(c+1)
		return NumberToName(number:sub(1, c)).." "..x[math.ceil(#number/3)-1]..(remain:find("[^0]") and " "..NumberToName(remain) or "")
	end
	local a = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine"}
	local b = {"", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"}
	local c = {[0] = "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"}
	if #number == 1 then
		return a[tonumber(number)]
	elseif #number == 2 then
		local ones = tonumber(number:sub(2, 2))
		local tens = tonumber(number:sub(1, 1))
		if tens == 1 then
			return c[ones]
		elseif ones == 0 then
			return b[tens]
		else
			return b[tens].." "..a[ones]
		end
	elseif #number == 3 then
		local rest = NumberToName(number:sub(2))
		return a[tonumber(number:sub(1, 1))].." hundred"..(rest == "zero" and "" or " "..rest)
	end
end

local function AbbreviateNumber(number : number)
	local curAbbreav = ''
	local curNum = number
	
	local abbreavs = {
		{value = 10^3, abbrev = 'k'},
		{value = 10^6, abbrev = 'M'},
		{value = 10^9, abbrev = 'B'},
		{value = 10^12, abbrev = 'Qa'},
		{value = 10^15, abbrev = 'Qi'},
		{value = 10^18, abbrev = 'Sx'},
	}

	for _, data in abbreavs do
		if number / data.value < 1 then break end

		curAbbreav = data.abbrev
		curNum = math.floor(number / (data.value / 10)) / 10
	end

	return tostring(curNum) .. curAbbreav
end

local function CommaNumber(number : number)
	local formatted = number
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

NumberUtils.NumberToName = NumberToName
NumberUtils.CommaNumber = CommaNumber
NumberUtils.AbbreviateNumber = AbbreviateNumber

return NumberUtils