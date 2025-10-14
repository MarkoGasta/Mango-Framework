--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

--// CONSTANTS \\--

--// MODULES \\--

--// VARIABLES \\--

local WeldUtils = {}

--// FUNCTIONS \\--

local function Weld(p1, p2)
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = p1
	Weld.Part1 = p2
	Weld.Parent = p1
	Weld.Name = p1.Name .. ">" .. p2.Name

	return Weld
end

WeldUtils.Weld = Weld

return WeldUtils