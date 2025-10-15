--// Script by: MarkoGasta2 \\--

--// CONFIG \\--

local ID_LENGTH = 18
local ID_SYMBOLS = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}
local DESKTOP_BASE_HEIGHT = 1260
local MOBILE_BASE_HEIGHT = 393

--// SERVICES \\--

local Workspace = game:GetService("Workspace")

--// MODULES \\--

local DeviceUtils = require(script.DeviceUtils)
local RunService = game:GetService("RunService")

--// TYPES \\--

--// CONSTANTS \\--

--// VARIABLES \\--

local TextUtils = {}

--// FUNCTIONS \\--

-- Translates a stroke size from a preset resolution to the players resolution. CLIENT ONLY!
local function TranslateStrokeSize(baseStrokeSize: number): number
    
    -- Checking if the code is running on client.
    if not RunService:IsClient() then
        warn("This function is client only!")
        return baseStrokeSize
    end

    -- Getting the height of the players display.
    local playerViewport = Workspace.CurrentCamera.ViewportSize
    local playerViewportHeight = playerViewport.Y

    -- Cheching if viewport height has defaulted.
    if playerViewportHeight == 1 then
        while playerViewportHeight == 1 do
            playerViewportHeight = workspace.CurrentCamera.ViewportSize.Y

            -- Preventing exhaustinon.
            task.wait(0.1)
        end
    end

    -- Calculating scaling factors based on height.
    local heightScale: number

    -- Checking what device the player is on.
    if DeviceUtils.GetDevice() == ("Desktop" or "Console") then
        heightScale = playerViewportHeight / DESKTOP_BASE_HEIGHT
    elseif DeviceUtils.GetDevice() == "Mobile" then
        heightScale = playerViewportHeight / MOBILE_BASE_HEIGHT
    else
        heightScale = playerViewportHeight / DESKTOP_BASE_HEIGHT
    end

    -- Calculate the new text size
    local newStrokeSize = math.ceil(baseStrokeSize * heightScale)
    return newStrokeSize
end

-- Connects a UIStroke's thickness to viewport size changes.
local function ConnectUIStrokeSizeTranslation(uiStroke: UIStroke, baseThickness: number)
    -- Checking if the code is running on client.
    if not RunService:IsClient() then
        warn("ConnectUIStrokeSizeTranslation is client only!")
        return
    end

    -- Verifying parameter types.
    if typeof(uiStroke) ~= "Instance" or not uiStroke:IsA("UIStroke") then
        warn("ConnectUIStrokeSizeTranslation requires a valid UIStroke instance.")
        return
    end

    -- Set initial thickness based on current viewport.
    uiStroke.Thickness = TranslateStrokeSize(baseThickness)
    
    -- Connect to viewport size changes.
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if not uiStroke or not uiStroke.Parent then
            return
        end

        uiStroke.Thickness = TranslateStrokeSize(baseThickness)
    end)
end

local function GenerateIdentifier(): string
    local id = ""

    -- Iterating over each id character.
    for i: number = 1, ID_LENGTH - 1 do
        if i % (ID_LENGTH / 3) == 0 then
            id ..= "-"
        else
            id ..= ID_SYMBOLS[math.random(1, #ID_SYMBOLS)]
        end
    end

    return id
end

-- Generates a random string based on allowed character sets.
local function GenerateRandomString(length: number, capitalLetters: boolean, smallLetters: boolean, number: boolean, symbols: boolean): string
    local chars = {}
    if capitalLetters then
        for i = 65, 90 do -- A-Z
            table.insert(chars, string.char(i))
        end
    end
    if smallLetters then
        for i = 97, 122 do -- a-z
            table.insert(chars, string.char(i))
        end
    end
    if number then
        for i = 48, 57 do -- 0-9
            table.insert(chars, string.char(i))
        end
    end
    if symbols then
        local symbolList = {'!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '=', '+', '[', ']', '{', '}', ';', ':', ',', '.', '<', '>', '?', '/'}
        for _, s in ipairs(symbolList) do
            table.insert(chars, s)
        end
    end
    if #chars == 0 then
        return "" -- No character sets selected
    end
    local result = ""
    for i = 1, length do
        result ..= chars[math.random(1, #chars)]
    end
    return result
end

-- Exporting methods.
TextUtils.GenerateRandomString = GenerateRandomString
TextUtils.GenerateIdentifier = GenerateIdentifier
TextUtils.TranslateStrokeSize = TranslateStrokeSize
TextUtils.ConnectUIStrokeSizeTranslation = ConnectUIStrokeSizeTranslation

return TextUtils