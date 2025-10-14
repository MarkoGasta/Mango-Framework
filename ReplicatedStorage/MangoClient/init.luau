--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES \\--

local Types = require(script.Types)

--// TYPES \\--

--// CONSTANTS \\--

local ClassFolders = {
    ReplicatedFirst,
    ReplicatedStorage:WaitForChild("Controllers"),
    ReplicatedStorage:WaitForChild("Settings"),
    ReplicatedStorage:WaitForChild("Packages"),
    ReplicatedStorage:WaitForChild("Resources"),
    ReplicatedStorage:WaitForChild("MangoControllers"),
    ReplicatedStorage:WaitForChild("MangoReplicatedResources"),
}

--// VARIABLES \\--

local MangoClient = {
    Global = {}
}
local requiredClasses = {}

--// FUNCTIONS \\--

-- Returns a required class.
local function Require(className: Types.classNames, _loopIter: number?)
    
    -- Checking if class was previously required.
    if requiredClasses[className] then
        return requiredClasses[className]
    end

    -- Finding class by name.
    for _, classFolder: Folder in ClassFolders do
        for _, class: ModuleScript in classFolder:GetDescendants() do
            
            -- Checking class name.
            if class.Name ~= className then
                continue
            end

            -- Checking if class is descendant of another class.
            if class:FindFirstAncestorWhichIsA("ModuleScript") then
                continue
            end

            local requiredClass = require(class)
            
            -- Caching and returning class.
            requiredClasses[class.Name] = requiredClass
            return requiredClass
        end
    end

    -- Delaying looking through modules again in case game hasn't loaded it fully yet.
    if not _loopIter or (_loopIter and _loopIter < 20) then
        task.wait(0.1)
        return Require(className, _loopIter and _loopIter + 1 or 1)
    elseif _loopIter and _loopIter >= 20 then
        warn(`Couldn't find module {className}, check if it exists or is miss spelled`)
    end
end

-- Exporting methods.
MangoClient.Require = Require:: Types.classValues

return MangoClient