--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local OPEN_TWEEN_INFO_WHEN_UNSPECIFIED = TweenInfo.new(1, Enum.EasingStyle.Linear)
local CLOSE_TWEEN_INFO_WHEN_UNSPECIFIED = TweenInfo.new(1, Enum.EasingStyle.Linear)
local IMPACT_OPENING_TWEEN_INFO_WHEN_UNSPECIFIED = TweenInfo.new(.06, Enum.EasingStyle.Linear)
local IMPACT_CLOSING_TWEEN_INFO_WHEN_UNSPECIFIED = TweenInfo.new(.06, Enum.EasingStyle.Linear)

--// SERVICES \\--

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// CONSTANTS \\--

--// MODULES \\--

--// VARIABLES \\--

local Hinger = {}

--// ENUMS \\--

-- Door faces.
Hinger.Faces = {
	Front = Vector3.new(0, 0, -.5),
	Back = Vector3.new(0, 0, .5),
	Left = Vector3.new(-.5, 0, 0),
	Right = Vector3.new(.5, 0, 0),
	Top = Vector3.new(0, .5, 0),
	Bottom = Vector3.new(0, -.5, 0)
}

-- Rotation axis.
Hinger.RotationAxis = {
	X = Vector3.new(0, 0, 1),
	Y = Vector3.new(0, 1, 0),
	Z = Vector3.new(1, 0, 0)
}

--// TYPES \\--

type door = Part | MeshPart | BasePart | Model
type face = typeof(Hinger.Faces)
type rotationAxis = typeof(Hinger.RotationAxis)
type hingerOptions = {
	openingTweenInfo: TweenInfo?,
	closingTweenInfo: TweenInfo?,
	impactOpeningTweenInfo: TweenInfo?,
	impactClosingTweenInfo: TweenInfo?
}
type doorActionOptions = {
	tweenInfoOverride: TweenInfo?,
}
type doorImpactOptions = {
	openingTweenInfoOverride: TweenInfo?,
	closingTweenInfoOverride: TweenInfo?,
}

--// FUNCTIONS \\--

-- Sets the door pivot based on door type with local world cframe.
local function SetDoorPivot(door: door, pivotCFrame: CFrame)
	
	-- Checking door type.
	if door:IsA("Model") then

		-- Setting the doors pivots.
		door.PrimaryPart.PivotOffset = pivotCFrame
	else

		-- Setting the doors pivots.
		door.PivotOffset = pivotCFrame
	end
end

-- Toggles the open state of the door.
local function TweenPivot(self: typeof(Hinger), endingPivotCFrame: CFrame, pivotTweenInfo: TweenInfo)

	-- Checking if action tween exists.
	if self.__activeActionTween then
		self.__activeActionTween:Cancel()
	end
	
	-- Setting new door pivot and saving previous door pivot.
	SetDoorPivot(self.door, self.requiredPivotOffset)
	
	-- Setting starting value of cframe value.
	self.__pivotCFrameValue.Value = self.door:GetPivot()

	-- Tweeing the pivot cframe value.
	self.__activeActionTween = TweenService:Create(
		self.__pivotCFrameValue,
		pivotTweenInfo,
		{Value = endingPivotCFrame}
	)
	
	-- Playing tween
	self.__activeActionTween:Play()

	-- Binding door pivot update to render step.
	local renderSteppedConnection = RunService.RenderStepped:Connect(function()

		-- Pivoting to new value.
		self.door:PivotTo(self.__pivotCFrameValue.Value)
	end)

	-- Binding tween completed.
	self.__activeActionTween.Completed:Once(function()

		-- Unbinding render step.
		renderSteppedConnection:Disconnect()
		
		-- Resetting door pivot.
		SetDoorPivot(self.door, self.defaultPivotOffset)

		-- Removing action tween.
		self.__activeActionTween = nil
	end)
end

-- Creates a new hinge instance.
function Hinger.new(door: door, face1: face, face2: face, rotationAxis: rotationAxis, maxAngle: number, options: hingerOptions?) : nil | typeof(Hinger)

	-- Asserting errors.
	assert(door, "Door parameter is invalid")
	assert(face1, "Face1 parameter is invalid")
	assert(face2, "Face2 parameter is invalid")
	assert(maxAngle, "MaxAngle parameter is invalid")
	assert(rotationAxis, "RotationAxis parameter is invalid")

	-- Checking door type.
	if door:IsA("Model") then
		assert(door.PrimaryPart, "Your door model has to have a primary part")
	end
	
	-- Creating a hinge instance.
	local self = setmetatable({
		door = door,
		maxAngle = maxAngle,
		rotationAxis = rotationAxis,
		options = options,
		open = false,
		__pivotCFrameValue = Instance.new("CFrameValue"),
		__isHinge = true,
	}, {__index = Hinger})

	-- Calculating hing angle offset.
	self.doorOpenPivotOffset = CFrame.Angles(CFrame.new((rotationAxis * maxAngle) * (math.pi / 180)):GetComponents())

	-- Checking what the door is.
	if door:IsA("Model") then
		
		-- Getting model bounding box.
		local boxOrientation, boxSize = door:GetBoundingBox()

		-- Getting door model properties.
		self.doorCenterCFrame = boxOrientation
		self.requiredPivotOffset = CFrame.new(boxSize * face1 + boxSize * face2)
		self.defaultPivotOffset = door.PrimaryPart.PivotOffset
	else

		-- Getting part size.
		local partCFrame = door.CFrame
		local partSize = door.Size

		-- Getting door part properties.
		self.doorCenterCFrame = partCFrame
		self.requiredPivotOffset = CFrame.new(partSize * face1 + partSize * face2)
		self.defaultPivotOffset = door.PivotOffset
	end

	return self
end

-- Handles opening a door.
function Hinger:Open(options: doorActionOptions?)

	-- Asserting values.
	assert(self and self.__isHinge, "Please use : on a hinge instance, instead of .")

	-- Checking door state.
	if self.open then
		return warn("Door already closed")
	end

	-- Getting parameters.
	local openTweenInfo = (options and options.tweenInfoOverride) or (self.options and self.options.openingTweenInfo) or OPEN_TWEEN_INFO_WHEN_UNSPECIFIED

	-- Getting closed and opened door pivot
	local startPivotCFrame = self.doorCenterCFrame * self.requiredPivotOffset
	local endPivotCFrame = startPivotCFrame * self.doorOpenPivotOffset

	-- Tweening door hinge.
	TweenPivot(self, endPivotCFrame, openTweenInfo)

	-- Setting door state.
	self.open = true
end

-- Handles closing a door.
function Hinger:Close(options: doorActionOptions?)

	-- Asserting values.
	assert(self and self.__isHinge, "Please use : on a hinge instance, instead of .")

	-- Checking door state.
	if not self.open then
		return warn("Door already closed")
	end

	-- Getting parameters.
	local closeTweenOptions = (options and options.tweenInfoOverride) or (self.options and self.options.closingTweenInfo) or CLOSE_TWEEN_INFO_WHEN_UNSPECIFIED

	-- Getting closed and opened door pivot
	local endPivotCFrame = self.doorCenterCFrame * self.requiredPivotOffset

	-- Tweening door hinge.
	TweenPivot(self, endPivotCFrame, closeTweenOptions)

	-- Setting door state.
	self.open = false
end

-- Creates an impact on the door, like knocking or hitting.
function Hinger:Impact(count: number, angle: number, pauseDuration: number, options: doorImpactOptions)

	-- Asserting errors.
	assert(count, "Count parameter is invalid")
	assert(angle, "Angle parameter is invalid")
	assert(pauseDuration, "PauseDuration parameter is invalid")

	-- Checking if door is closed.
	if self.open then
		return warn(`Impacts only work on closed doors, check Hinge.open property`)
	end

	-- Checking angle.
	if angle > self.maxAngle then
		return warn(`Specified angle {angle} is bigger than the hinge max angle of {self.maxAngle}`)
	end
	
	-- Threading impacts.
	task.spawn(function()
		
		-- Iterating number of impacts.
		for _ = 1, count do

			-- Getting properties.
			local impactOpenTweenInfo = (options and options.openingTweenInfoOverride) or (self.options and self.options.impactOpeningTweenInfo) or IMPACT_OPENING_TWEEN_INFO_WHEN_UNSPECIFIED
			local impactCloseTweenInfo = (options and options.closingTweenInfoOverride) or (self.options and self.options.impactClosingTweenInfo) or IMPACT_CLOSING_TWEEN_INFO_WHEN_UNSPECIFIED

			-- Calculating the start and end frame.
			local startPivotCFrame = self.doorCenterCFrame * self.requiredPivotOffset
			local endPivotCFrame = startPivotCFrame:Lerp(startPivotCFrame * self.doorOpenPivotOffset, angle / self.maxAngle)

			-- Tweening pivot.
			TweenPivot(self, endPivotCFrame, impactOpenTweenInfo)

			-- Delaying closing tween to open tween end.
			task.delay(impactOpenTweenInfo.Time, function()
				TweenPivot(self, startPivotCFrame, impactCloseTweenInfo)
			end)
			
			-- Waiting for pause duration.
			task.wait(pauseDuration)
		end
	end)
	
	return true
end

return Hinger