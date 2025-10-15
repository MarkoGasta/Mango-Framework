--// Script by: MarkoGasta2 \--

--// CONFIG \--

--// SERVICES \--

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// MODULES \--

--// TYPES \--

--// CONSTANTS \--

--// VARIABLES \--

local ModelTween = {}

--// FUNCTIONS \--

-- Creates a model tween.
local function Create(model: Model, tweenInfo: TweenInfo, properties: table)

    -- Getting starting values.
    local startingCFrame = model:GetPivot()
    
    -- Creating a number value used for tweening properties.
    local tweenNumberValue = Instance.new("NumberValue")
    tweenNumberValue.Value = 0

    -- Tweening number value.
    local numberValueTween = TweenService:Create(tweenNumberValue, tweenInfo, {
        Value = 1
    })

    -- Binding update.
    local runServiceConnection = RunService.Stepped:Connect(function()
        
        -- Checking for CFrame property.
        local goalCFrame = properties.CFrame
        if goalCFrame then
            model:PivotTo(startingCFrame:Lerp(goalCFrame, tweenNumberValue.Value))
        end
    end)

    -- Connecting tween completed.
    numberValueTween.Completed:Once(function()
        tweenNumberValue:Destroy()
        numberValueTween:Destroy()
        runServiceConnection:Disconnect()
    end)

    return numberValueTween
end

-- Exporting methods.
ModelTween.Create = Create

return ModelTween