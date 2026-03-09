--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local InterfaceControllerInterface = {}
function InterfaceControllerInterface.__Construct(mainGui: ScreenGui)

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local Connector = MangoClient.Require("Connector")
    local Logger = MangoClient.Require("Logger")
    local TableUtils = MangoClient.Require("TableUtils")
    
    --// TYPES \\--
    type ButtonHoverEffectOptions = {
        DefaultScale: number,
        HoverScale: number,
        DefaultTweenInfo: TweenInfo,
        HoverTweenInfo: TweenInfo,
    }

    type ButtonClickEffectOptions = {
        DefaultScale: number,
        ClickedScale: number,
        DefaultTweenInfo: TweenInfo,
        ClickedTweenInfo: TweenInfo,
    }

    --// CONSTANTS \\--
    local ButtonHoverEffectOptionsDefaults: ButtonHoverEffectOptions = {
        DefaultScale = 1,
        HoverScale = 1.025,
        DefaultTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        HoverTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    }

    local ButtonClickEffectOptionsDefaults: ButtonClickEffectOptions = {
        DefaultScale = 1,
        ClickedScale = 0.95,
        DefaultTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        ClickedTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    }
    
    --// VARIABLES \\--
    local objectDynamicScalers = {}

    --// FUNCTIONS \\--

    --[=[
        Creates a dynamic scaler for a GUI object.

        ### Parameters:
        ```luau
        object: GuiObject -- The object to create the scaler for.
        ```

        ### Returns:
        ```luau
        UIScale -- The created UIScale instance.
        ```
    ]=]
    local function CreateObjectDynamicScaler(object: GuiObject): UIScale
        local newDynamicScalerInstance = Instance.new("UIScale")
        newDynamicScalerInstance.Parent = object
        newDynamicScalerInstance.Name = "__DynamicScaler"
        newDynamicScalerInstance.Scale = 1

        local newScalerValue = Instance.new("NumberValue")
        newScalerValue.Parent = newDynamicScalerInstance
        newScalerValue.Name = "ScaleValue"
        newScalerValue.Value = 1
        Connector.Connect(newScalerValue.Changed, function()
            newDynamicScalerInstance.Scale = newScalerValue.Value
        end)

        local newDynamicScaler = {
            Scaler = newDynamicScalerInstance,
            ScalerValue = newScalerValue,
            scalerComponents = {}
        }

        objectDynamicScalers[object] = newDynamicScaler
        return newDynamicScaler
    end

    --[=[
        Adds a scaling component to a dynamic scaler.

        ### Parameters:
        ```luau
        dynamicScaler: table -- The dynamic scaler to add the component to.
        componentIdentifier: string -- A unique identifier for the component.
        ```

        ### Returns:
        ```luau
        NumberValue -- The created NumberValue instance representing the component's scale.
        ```
    ]=]
    local function AddDynamicScalerComponent(dynamicScaler: table, componentIdentifier: string)
        if dynamicScaler.scalerComponents[componentIdentifier] then
            Logger.warn(`Component with identifier {componentIdentifier} already exists, cannot add it again`)
            return
        end

        local newComponentValue = Instance.new("NumberValue")
        newComponentValue.Parent = dynamicScaler.Scaler
        newComponentValue.Name = componentIdentifier
        newComponentValue.Value = 1
        Connector.Connect(newComponentValue.Changed, function()
            local totalScale = 1
            for _, componentValue: NumberValue in dynamicScaler.scalerComponents do
                totalScale *= componentValue.Value
            end

            dynamicScaler.ScalerValue.Value = totalScale
        end)

        dynamicScaler.scalerComponents[componentIdentifier] = newComponentValue
        return newComponentValue
    end

    --[=[
        Applies a hover effect to a button.

        ### Parameters:
        ```luau
        button: GuiButton -- The button to apply the effect to.
        options = {
            DefaultScale: number = 1 -- The default scale.
            HoverScale: number = 1.025 -- The hover scale.
            DefaultTweenInfo: TweenInfo -- The tween info for default state.
            HoverTweenInfo: TweenInfo -- The tween info for hover state.
        }
        ```
    ]=]
    local function ApplyButtonHoverEffect(hoverObject: GuiButton, scaleObject: GuiObject, options: ButtonHoverEffectOptions?)
        options = options and TableUtils.MergeDictionaries(options, ButtonHoverEffectOptionsDefaults) or ButtonHoverEffectOptionsDefaults

        if typeof(hoverObject) ~= "Instance" or not hoverObject:IsA("GuiButton") then
            Logger.warn(`Invalid hover object provided for button hover effect, expected GuiButton, got {typeof(hoverObject)}`)
            return
        end

        if typeof(scaleObject) ~= "Instance" or not scaleObject:IsA("GuiObject") then
            Logger.warn(`Invalid scale object provided for button hover effect, expected GuiObject, got {typeof(scaleObject)}`)
            return
        end
        
        local dynamicScaler = objectDynamicScalers[scaleObject] or CreateObjectDynamicScaler(scaleObject)
        local hoverScalerComponent = AddDynamicScalerComponent(dynamicScaler, `HOVER_EFFECT`)
        hoverScalerComponent.Value = options.DefaultScale
        
        Connector.Connect(hoverObject.MouseEnter, function()
            TweenService:Create(hoverScalerComponent, options.HoverTweenInfo, {
                Value = options.HoverScale,
            }):Play()
        end)

        Connector.Connect(hoverObject.MouseLeave, function()
            TweenService:Create(hoverScalerComponent, options.DefaultTweenInfo, {
                Value = options.DefaultScale,
            }):Play()
        end)
    end

    --[=[
        Applies a click effect to a button.

        ### Parameters:
        ```luau
        button: GuiButton -- The button to apply the effect to.
        options = {
            DefaultScale: number = 1 -- The default scale.
            ClickedScale: number = 0.95 -- The clicked scale.
            DefaultTweenInfo: TweenInfo -- The tween info for default state.
            ClickedTweenInfo: TweenInfo -- The tween info for clicked state.
        }
        ```
    ]=]
    local function ApplyButtonClickEffect(clickObject: GuiButton, scaleObject: GuiObject, options: ButtonClickEffectOptions?)
        options = options and TableUtils.MergeDictionaries(options, ButtonClickEffectOptionsDefaults) or ButtonClickEffectOptionsDefaults

        if typeof(clickObject) ~= "Instance" or not clickObject:IsA("GuiButton") then
            Logger.warn(`Invalid click object provided for button click effect, expected GuiButton, got {typeof(clickObject)}`)
            return
        end

        if typeof(scaleObject) ~= "Instance" or not scaleObject:IsA("GuiObject") then
            Logger.warn(`Invalid scale object provided for button click effect, expected GuiObject, got {typeof(scaleObject)}`)
            return
        end
        
        local dynamicScaler = objectDynamicScalers[scaleObject] or CreateObjectDynamicScaler(scaleObject)
        local clickScalerComponent = AddDynamicScalerComponent(dynamicScaler, `CLICK_EFFECT`)
        Connector.Connect(clickObject.Activated, function()
            TweenService:Create(clickScalerComponent, options.ClickedTweenInfo, {
                Value = options.ClickedScale,
            }):Play()

            task.delay(options.ClickedTweenInfo.Time, function()
                TweenService:Create(clickScalerComponent, options.DefaultTweenInfo, {
                    Value = options.DefaultScale,
                }):Play()
            end)
        end)
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    InterfaceControllerInterface.__Init = Init
    InterfaceControllerInterface.ApplyButtonHoverEffect = ApplyButtonHoverEffect
    InterfaceControllerInterface.ApplyButtonClickEffect = ApplyButtonClickEffect

    --// RUNTIME \\--
end

return InterfaceControllerInterface