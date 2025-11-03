--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

--// SERVICES \\--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// MODULES \\--

local MangoClient = require(ReplicatedStorage.MangoClient)
local Janitor = MangoClient.Require("Janitor")
local Logger = MangoClient.Require("Logger")
local TableUtils = MangoClient.Require("TableUtils")
local SoundSettings = MangoClient.Require("SoundSettings")

--// TYPES \\--

type SoundSource = {
    soundInstances: table,
    source: Sound,
    parent: BasePart
}
type SoundSourceOptions = {
    isLooped: boolean,
    noRepeat: boolean,
    rolloffMin: number,
    rolloffMax: number,
    volume: number,
    soundIdentifier: string,
}
type SoundEmitter = {
    janitor: typeof(Janitor.new),
    sounds: table,
    emitterPart: Part,
    LoadExistingSound: (self: SoundEmitter, sound: Sound) -> Sound,
}
type PlaySoundSourceOptions = {
    speed: number,
    startTime: number,
}

--// CONSTANTS \\--

local SoundEmitterStorage: Folder = workspace.Cache.SoundEmitters
local SoundSourceOptionsDefaults: SoundSourceOptions = {
    isLooped = false,
    noRepeat = false,
    rolloffMin = 1,
    rolloffMax = 10,
    volume = 1,
    soundIdentifier = "_PLACEHOLDER"
}

local PlaySoundSourceOptionsDefaults: PlaySoundSourceOptions = {
    speed = 1,
    startTime = 0,
}

--// VARIABLES \\--

local SoundController = {}

--// FUNCTIONS \\--

-- Sets the volume of the sounds of a sound source.
local function SetSoundSourceVolume(soundSource: SoundSource, newVolume: number)
    
    -- Iterating over all sound source sound emitters.
    for _, soundEmitter: Sound in soundSource.soundInstances do
        soundEmitter.Volume = newVolume
    end
end

-- Creates a sound instances and adds it to the sound instance cache.
local function CreateSoundInstance(self: table, soundId: string)
    local sound: Sound = self._janitor:Add(Instance.new("Sound"))
    sound.Parent = self.parent
    sound.Volume = self.options.volume
    sound.SoundId = soundId
    sound.RollOffMinDistance = self.options.rolloffMin
    sound.RollOffMaxDistance = self.options.rolloffMax
    table.insert(self.soundInstances, sound)
end

-- Plays the already loaded sound from a sound source.
local function PlayLoadedSoundFromSoundSource(soundSource: SoundSource, options: PlaySoundSourceOptions)

    -- Setting options default values.
    options = options and TableUtils.MergeDictionaries(options, PlaySoundSourceOptionsDefaults) or PlaySoundSourceOptionsDefaults

    -- Picking a random sound instnace to play the sound from.
    -- If there is only one sound that sound will always be played so there is no need for a single sound handler.
    local soundInstanceCount = #soundSource.soundInstances
    local randomSound: Sound;

    -- Picking a random sound then checking if it should repeat.
    repeat
        randomSound = soundSource.soundInstances[math.random(1, soundInstanceCount)]
    until (soundSource.options.noRepeat and randomSound ~= soundSource._playingSound) or not soundSource.options.noRepeat

    -- Setting this sound as the previously played sound.
    soundSource._playingSound = randomSound
    
    -- Playing sound from the beginning.
    randomSound.TimePosition = options.startTime
    randomSound.PlaybackSpeed = options.speed
    randomSound:Play()
    randomSound.Ended:Once(function()

        -- Checking if the sound should be looped.
        if not soundSource.options.isLooped then
            return
        end

        PlayLoadedSoundFromSoundSource(soundSource, options)
    end)
end

-- Plays an audio, from it's settings entry, on a sound source.
local function PlaySoundFromSoundSource(soundSource: SoundSource, soundIdentifier: string, options: PlaySoundSourceOptions)

    -- Getting sound from passed identifier and checking if it exists.
    local soundId: string | table = SoundSettings["SOUND_IDS"][soundIdentifier]
    if not soundId then
        return Logger.warn(`Sound with identifier {soundIdentifier} doesn't exist`)
    end

    -- Destroying previous sound instances.
    for _, soundInstance: Sound in soundSource.soundInstances do
        soundInstance:Destroy()
    end

    -- Clearing sound source sound instance array.
    table.clear(soundSource.soundInstances)

    -- Checking if the sound id is just an id or an array of ids.
    if typeof(soundId) == "string" then
        CreateSoundInstance(soundSource, soundId)
    else
        
        -- Creating a sound instance for each sound id from array.
        for _, soundId: string in soundId do
            CreateSoundInstance(soundSource, soundId)
        end
    end
    
    -- Playing the newly loaded sound.
    PlayLoadedSoundFromSoundSource(soundSource, options)
end

-- Creates a group of sound sources.
-- TODO: Finish groups!
local function CreateSoundSourceGroup(soundSources: {SoundSource})
    
    -- Defining instance properties.
    local soundSourceGroup = {
        soundSources = soundSources,
        _janitor = Janitor.new()
    }

    -- Iterating over all passes sound sources.
    for _, soundSource: SoundSource in soundSources do
        soundSourceGroup._janitor:Add(soundSource._janitor)
    end

    return soundSourceGroup
end

-- Creates a sound source instance, a sound parented to a provided part.
local function CreateSoundSource(parent: BasePart | string, options: SoundSourceOptions?): SoundSource
    
    -- Setting option defaults.
    options = options and TableUtils.MergeDictionaries(options, SoundSourceOptionsDefaults) or SoundSourceOptionsDefaults

    -- Checking if the parent is a sound emitter name.
    if typeof(parent) == "string" then
        
        -- Getting sound emitter and checking if it exists.
        local emitterPart: BasePart = SoundEmitterStorage:FindFirstChild(parent)
        if emitterPart then
            parent = emitterPart
        else
            return Logger.warn(`Sound emitter {parent} doesn't exists in {SoundEmitterStorage:GetFullName()}`)
        end
    end

    -- Getting sound from passed identifier and checking if it exists.
    local soundId: string | table | nil = SoundSettings["SOUND_IDS"][options.soundIdentifier]
    if not soundId then
        return Logger.warn(`Sound with identifier {options.soundIdentifier} doesn't exist`)
    end

    -- Defining instance properties.
    local soundSource: SoundSource = {
        soundInstances = {},
        parent = parent,
        options = options,
        _janitor = Janitor.new(),
    }

    -- Checking if the sound id is just an id or an array of ids.
    if soundId then
        if typeof(soundId) == "string" then
            CreateSoundInstance(soundSource, soundId)
        else
            
            -- Creating a sound instance for each sound id from array.
            for _, soundId: string in soundId do
                CreateSoundInstance(soundSource, soundId)
            end
        end
    end

    return soundSource
end

-- Creates a sound source in the sound service, plays sounds in players head.

--- Creates a local sound source using the provided options.
local function CreateLocalSoundSource(options: SoundSourceOptions?)
    return CreateSoundSource(SoundService, options)
end

-- Exporting methods.
SoundController.SetSoundSourceVolume = SetSoundSourceVolume
SoundController.CreateSoundSource = CreateSoundSource
SoundController.CreateLocalSoundSource = CreateLocalSoundSource
SoundController.PlayLoadedSoundFromSoundSource = PlayLoadedSoundFromSoundSource
SoundController.PlaySoundFromSoundSource = PlaySoundFromSoundSource

-- Initiation method.
function SoundController.Init()
    
end

return SoundController