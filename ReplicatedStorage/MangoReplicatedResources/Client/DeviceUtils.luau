-- SERVICES --

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- CONSTANTS --

-- MODULES --

-- VARIABLES --

local Utils = {}

-- FUNCTIONS

function Utils.GetDevice() -- Get players device
	if (GuiService:IsTenFootInterface()) then
		return "Console"
	elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
		return "Mobile"
	else
		return "Desktop"
	end
end

function Utils.IsMobile() -- Returns true if player is on mobile
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return true
	end
	return false
end

function Utils.IsPC() -- Returns true if player is on pc
	if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return true
	end
	return false
end

return Utils