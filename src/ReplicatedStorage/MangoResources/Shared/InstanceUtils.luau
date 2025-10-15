--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

--// MODULES \\--

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local InstanceUtils = {}    

--// FUNCTIONS \\--

--- Finds a child instance by traversing a string-based path.
--- @param parent Instance The parent instance to start the search from.
--- @param path string The dot-separated path to the child instance.
--- @return Instance? child The child instance if found, or nil if not found.
function InstanceUtils.FindChildWithStringPath(parent: Instance, path: string)
    local currentInstance: Instance = parent
    local pathSegments = string.split(path, ".")

    for _, segment in pathSegments do
        currentInstance = currentInstance:WaitForChild(segment, 5)
        if not currentInstance then
            return nil
        end
    end

    return currentInstance
end

return InstanceUtils