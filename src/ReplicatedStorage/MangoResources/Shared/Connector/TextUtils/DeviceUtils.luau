--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local DeviceUtils = {}

--// FUNCTIONS \\--

-- Returns players device.
function DeviceUtils.GetDevice()
	if (GuiService:IsTenFootInterface()) then
		return "Console"
	elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
		return "Mobile"
	else
		return "Desktop"
	end
end

return DeviceUtils