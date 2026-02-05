local Workspace = game:GetService("Workspace")
--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local SoundController = {}
function SoundController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local SoundService = game:GetService("SoundService")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local TableUtils = MangoClient.Require("TableUtils")
    local Janitor = MangoClient.Require("Janitor")
    local Logger = MangoClient.Require("Logger")
    local SoundSettings = MangoClient.Require("SoundSettings")

    --// TYPES \\--

    type SoundSource = {
        soundInstances: table,
        source: Sound,
        parent: BasePart
    }

    type CreateSoundSourceOptions = {
        Looped: boolean,
        NoRepeat: boolean,
        Overlap: boolean,
        PlayOnCreated: boolean,
        RolloffMin: number,
        RolloffMax: number,
        Volume: number,
        SoundIdentifier: string,
    }

    type PlaySoundSourceOptions = {
        Speed: number,
        StartTime: number,
    }

    --// CONSTANTS \\--
    local SoundSourcePartTemplate: BasePart
    local SoundEmitterStorage: Folder
    local SoundSourceOptionsDefaults: CreateSoundSourceOptions = {
        Looped = false,
        NoRepeat = false,
        Overlap = true,
        PlayOnCreated = false,
        RolloffMin = 1,
        RolloffMax = 10,
        Volume = 1,
        SoundIdentifier = "_PLACEHOLDER",
    }

    local PlaySoundSourceOptionsDefaults: PlaySoundSourceOptions = {
        Speed = 1,
        StartTime = 0,
    }
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Sets the volume of the sounds of a sound source.
    
        ### Parameters:
        ```luau
        soundSource: SoundSource -- The sound source to modify.
        newVolume: number -- The new volume value.
        ```
    ]=]
    local function SetSoundSourceVolume(soundSource: SoundSource, newVolume: number)
        for _, soundEmitter: Sound in soundSource.soundInstances do
            soundEmitter.Volume = newVolume
        end

        soundSource.Options.Volume = newVolume
    end

    --[=[
        Plays the already loaded sound from a sound source.
    
        ### Parameters:
        ```luau
        soundSource: SoundSource -- The sound source to play from.
        options: {
            Speed: number,
            StartTime: number,
        }?
        ```
    ]=]
    local function PlaySoundSource(soundSource: SoundSource, options: PlaySoundSourceOptions?)
        options = options and TableUtils.MergeDictionaries(options, PlaySoundSourceOptionsDefaults) or PlaySoundSourceOptionsDefaults

        local soundInstanceCount = #soundSource.soundInstances
        local randomSoundIndex: Sound;
        while not randomSoundIndex or (soundSource.Options.NoRepeat and randomSoundIndex == soundSource._lastPlayedIndex) do
            randomSoundIndex = math.random(1, soundInstanceCount)
        end
        
        local isOverlappingSoundInstance = false
        local randomSound: Sound = soundSource.soundInstances[randomSoundIndex]
        if soundSource.Options.Overlap and randomSound.IsPlaying then
            randomSound = randomSound:Clone()
            randomSound.Parent = soundSource.Parent
            isOverlappingSoundInstance = true
        end

        randomSound.TimePosition = options.StartTime
        randomSound.PlaybackSpeed = options.Speed
        randomSound:Play()
        
        soundSource.__Janitor:Add(randomSound.Ended:Once(function()
            if soundSource.Options.Looped then
                PlaySoundSource(soundSource, options)
            else
                if isOverlappingSoundInstance then
                    randomSound:Destroy()
                end
            end

        end))

        soundSource._lastPlayedIndex = randomSoundIndex
    end

    --[=[
        Creates and configures a Sound instance for the sound source.
    
        ### Parameters:
        ```luau
        soundSource: SoundSource -- The sound source to attach to.
        soundId: string -- The SoundId string.
        ```
    ]=]
    local function CreateSoundInstance(soundSource: SoundSource, soundId: string)
        local sound: Sound = soundSource.__Janitor:Add(Instance.new("Sound"))
        sound.Parent = soundSource.Parent
        sound.Volume = soundSource.Options.Volume
        sound.SoundId = soundId
        sound.RollOffMinDistance = soundSource.Options.RolloffMin
        sound.RollOffMaxDistance = soundSource.Options.RolloffMax
        sound.Name = `{soundSource.Options.SoundIdentifier}_{soundId}`
        table.insert(soundSource.soundInstances, sound)
    end

    --[=[
        Creates a sound source and loads its sound instances.
    
        ### Parameters:
        ```luau
        parent: any -- The parent to attach sound instances to.
        options: {
            Looped: boolean,
            NoRepeat: boolean,
            PlayOnCreated: boolean,
            RolloffMin: number,
            RolloffMax: number,
            Volume: number,
            SoundIdentifier: string,
        }
        ```
    
        ### Returns:
        ```luau
        SoundSource? -- The created sound source or nil if identifier not found.
        ```
    ]=]
    local function CreateSoundSource(parent: any, options: CreateSoundSourceOptions?): SoundSource?
        options = options and TableUtils.MergeDictionaries(options, SoundSourceOptionsDefaults) or SoundSourceOptionsDefaults

        local newSoundSource: SoundSource = {
            __Janitor = Janitor.new(),
            __lastPlayedIndex = nil,
            Options = options,
            Parent = parent,
            soundInstances = {},
            playing = false,
        }

        local soundId: string | table | nil = SoundSettings.SOUND_DATA[options.SoundIdentifier]
        if not soundId then
            Logger.warn(`Sound with identifier {options.SoundIdentifier} doesn't exist`)
            return nil
        end

        -- Checking if the sound id is just an id or an array of ids.
        if typeof(soundId) == "string" then
            CreateSoundInstance(newSoundSource, soundId)
        else
            for _, childSoundId: string in soundId do
                CreateSoundInstance(newSoundSource, childSoundId)
            end
        end
        
        return newSoundSource
    end

    --[=[
        Creates a sound source attached to a BasePart.
    
        ### Parameters:
        ```luau
        part: BasePart -- The part to attach the sound source to.
        options: {
            Looped: boolean,
            NoRepeat: boolean,
            PlayOnCreated: boolean,
            RolloffMin: number,
            RolloffMax: number,
            Volume: number,
            SoundIdentifier: string,
        }
        ```
    
        ### Returns:
        ```luau
        SoundSource -- The created sound source.
        ```
    ]=]
    local function CreateSoundSourceInPart(part: BasePart, options: CreateSoundSourceOptions?): SoundSource
        return CreateSoundSource(part, options)
    end

    --[=[
        Creates a sound source attached to the SoundService.
    
        ### Parameters:
        ```luau
        options: {
            Looped: boolean,
            NoRepeat: boolean,
            PlayOnCreated: boolean,
            RolloffMin: number,
            RolloffMax: number,
            Volume: number,
            SoundIdentifier: string,
        }
        ```
    
        ### Returns:
        ```luau
        SoundSource -- The created sound source.
        ```
    ]=]
    local function CreateSoundSourceInHead(options: CreateSoundSourceOptions?): SoundSource
        return CreateSoundSource(SoundService, options)
    end 

    --[=[
        Creates a sound source at a world position.
    
        ### Parameters:
        ```luau
        position: Vector3 -- The world position to place the sound source.
        options: {
            Looped: boolean,
            NoRepeat: boolean,
            PlayOnCreated: boolean,
            RolloffMin: number,
            RolloffMax: number,
            Volume: number,
            SoundIdentifier: string,
        }
        ```
    
        ### Returns:
        ```luau
        SoundSource -- The created sound source.
        ```
    ]=]
    local function CreateSoundSourceAtPosition(position: Vector3, options: CreateSoundSourceOptions?): SoundSource
        local soundPart: BasePart = SoundSourcePartTemplate:Clone()
        soundPart.CFrame = CFrame.new(position)
        soundPart.Parent = SoundEmitterStorage

        local soundSource: SoundSource = CreateSoundSource(soundPart, options)
        soundSource.__Janitor:Add(soundPart)

        return soundSource
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    SoundController.__Init = Init
    SoundController.CreateSoundSourceInPart = CreateSoundSourceInPart
    SoundController.CreateSoundSourceInHead = CreateSoundSourceInHead
    SoundController.CreateSoundSourceAtPosition = CreateSoundSourceAtPosition
    SoundController.SetSoundSourceVolume = SetSoundSourceVolume
    SoundController.PlaySoundSource = PlaySoundSource

    --// RUNTIME \\--
    SoundSourcePartTemplate = Instance.new("Part")
    SoundSourcePartTemplate.Name = "__SoundSourcePartTemplate"
    SoundSourcePartTemplate.Size = Vector3.new(1, 1, 1)
    SoundSourcePartTemplate.Transparency = 1
    SoundSourcePartTemplate.Anchored = true
    SoundSourcePartTemplate.CanCollide = false
    SoundSourcePartTemplate.Parent = ReplicatedStorage.Cache

    SoundEmitterStorage = Instance.new("Folder")
    SoundEmitterStorage.Name = "__SoundEmitterStorage"
    SoundEmitterStorage.Parent = game.Workspace
end

return SoundController