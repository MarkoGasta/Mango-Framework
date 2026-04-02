--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

--// SERVICES \\--
local RunService = game:GetService("RunService")

--// CONFIG \\--
local CLASS_IGNORE_FIELDS = {
    "METHOD_CONTEXTS",
    "new",
    "__index",
}

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--
local RehydratorUtils = {}

--// FUNCTIONS \\--

--[=[
        Gets the current runtime execution context.

        ### Returns:
        ```luau
        string -- The current runtime context name.
        ```
]=]
local function GetRunContext()
    if RunService:IsServer() then
        return "Server"
    elseif RunService:IsClient() then
        return "Client"
    else
        return "Unknown"
    end
end

--[=[
        Warns when a method is called from an unsupported runtime context.

        ### Parameters:
        ```luau
        methodName: string -- The class method name that was called.
        instance: table -- The class instance containing rehydration metadata.
        ```
]=]
local function OutOfContextFallback(methodName: string, instance)
    warn(`[Rehydrator] Method :{methodName}() is not available in the {GetRunContext()} context of {instance.RHDClassData.ClassName}.`)
end

--[=[
        Collects class methods that are valid for the current runtime context.

        ### Parameters:
        ```luau
        instance: table -- The instance containing class metadata.
        ```

        ### Returns:
        ```luau
        {[string]: (...any) -> any} -- A dictionary of callable methods.
        ```
]=]
local function GetContextMethods(instance): {[string]: (...any) -> any}
    local classData = instance.RHDClassData
    if not classData then
        return {}
    end

    local classValue = classData.__ClassValue
    if not classValue then
        return {}
    end

    local methods = {}
    for methodName: string, method: (...any) -> any in classValue do
        if typeof(method) ~= "function" then
            continue
        end

        if table.find(CLASS_IGNORE_FIELDS, methodName) then
            continue
        end

        if classValue.METHOD_CONTEXTS then
            local methodContext = classValue.METHOD_CONTEXTS[methodName]
            if methodContext and methodContext ~= GetRunContext() then
                method = function()
                    OutOfContextFallback(methodName, instance)
                end
            end
        end

        methods[methodName] = method
    end

    return methods
end

--[=[
        Applies a method lookup metatable using context-filtered methods.

        ### Parameters:
        ```luau
        instance: table -- The instance table to hydrate.
        ```
]=]
local function HydrateInstance(instance: table): ()
    setmetatable(instance, {
        __index = GetContextMethods(instance),
    })
end

--[=[
        Wraps class constructors to inject rehydration metadata and behavior.

        ### Parameters:
        ```luau
        classContainers: {Instance} -- The containers holding class ModuleScripts.
        ```
]=]
local function InterceptConstructors(classContainers: {Instance})
    for _, container in classContainers do
        for _, class in container:GetChildren() do
            if not class:IsA("ModuleScript") then
                continue
            end

            local classValue = require(class)
            if type(classValue) ~= "table" then
                continue
            end

            local constructor = classValue.new
            if type(constructor) ~= "function" then
                continue
            end

            classValue.new = function(...)
                local instance: table = constructor(...)
                instance.RHDClassData = {
                    __ClassValue = classValue,
                    ClassName = class.Name,
                }

                HydrateInstance(instance)
                return instance
            end
        end
    end
end

--// EXPORTS \\--
RehydratorUtils.HydrateInstance = HydrateInstance
RehydratorUtils.InterceptConstructors = InterceptConstructors

--// RUNTIME \\--

return RehydratorUtils