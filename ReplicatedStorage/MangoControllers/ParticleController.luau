--// Script by: MarkoGasta2 \--

--// CONFIG \--

--// SERVICES \--

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--// MODULES \--

local MangoClient = require(ReplicatedStorage.MangoClient)
local Logger = MangoClient.Require('Logger')

--// TYPES \--

--// CONSTANTS \--

local ParticleEmitters: Folder = ReplicatedStorage.Assets:FindFirstChild("ParticleEmitters")

--// VARIABLES \--

local ParticleController = {}
local particleEmitterCache = {}

--// FUNCTIONS \--

-- Creates a particle emitter temporary parent part.
local function CreateTemporaryParentPart(cFrame: CFrame): Part
    local temporaryParentPart: Part = Instance.new('Part')
    temporaryParentPart.Size = Vector3.new(0.1, 0.1, 0.1)
    temporaryParentPart.CFrame = cFrame
    temporaryParentPart.Transparency = 1
    temporaryParentPart.CanCollide = false
    temporaryParentPart.Anchored = true
    temporaryParentPart.Parent = workspace:FindFirstChild('Cache')
    
    return temporaryParentPart
end

-- Emits number of particles from the specified particle emitter.
local function EmitParticles(emitterName: string, numberOfParticles: number, cFrame: CFrame)
    local particleEmitterInstances: {ParticleEmitter} = particleEmitterCache[emitterName]
    if not particleEmitterInstances then
        return Logger.warn(`Particle emitter {emitterName} doesn't exist`)
    end

    -- Defining locals.
    local temporaryParentPart: Part = CreateTemporaryParentPart(cFrame)
    
    -- Cloning particle emitters.
    local longestParticleLifetime: number = 0
    for _, particleEmitter: ParticleEmitter in particleEmitterInstances do
        local clonedParticleEmitter: ParticleEmitter = particleEmitter:Clone()
        clonedParticleEmitter.Parent = temporaryParentPart
        clonedParticleEmitter:Emit(numberOfParticles)

        -- Getting the longest particle lifetime.
        if clonedParticleEmitter.Lifetime.Max > longestParticleLifetime then
            longestParticleLifetime = clonedParticleEmitter.Lifetime.Max
        end
    end

    -- Destroying the temporary parent part after the longest particle lifetime.
    task.delay(longestParticleLifetime, function()
        if temporaryParentPart then
            temporaryParentPart:Destroy()
        end
    end)
end

-- Exporting methods.
ParticleController.EmitParticles = EmitParticles

-- Initiation method.
function ParticleController.Init()
    
    -- Caching particle emitters.
    if ParticleEmitters then
        for _, particleEmitter: Folder in ParticleEmitters:GetChildren() do
            local particleEmitterName: string = particleEmitter.Name
            local particleEmitterInstances: {ParticleEmitter} = particleEmitter:GetChildren()

            particleEmitterCache[particleEmitterName] = particleEmitterInstances
        end
    end
end

return ParticleController