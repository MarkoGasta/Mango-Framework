--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local UserInputService = game:GetService("UserInputService")

--// CONSTANTS \\--

--// MODULES \\--

local Janitor = require(script.Janitor)

--// VARIABLES \\--

local InputSwitch = {}
InputSwitch.__index = InputSwitch

--// FUNCTIONS \\--

function InputSwitch.new(input : Enum.KeyCode | Enum.UserInputType, callback : (any) -> (any)) : (nil | typeof(InputSwitch))
	local self = setmetatable({}, InputSwitch)
	
	self._janitor = Janitor.new() : typeof(Janitor)
	
	if not input then
		return
	end
	
	if not callback then
		return
	end
	
	self._janitor:Add(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == input or input.UserInputType == input then
			callback(true)
		end
	end))
	
	self._janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == input or input.UserInputType == input then
			callback(false)
		end
	end))
	
	return self
end

function InputSwitch:Disconnect()
	
	self._janitor:Cleanup()
	
end

return InputSwitch