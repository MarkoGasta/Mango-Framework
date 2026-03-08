--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local ChatController = {}
function ChatController.__Construct()

    --// SERVICES \\--
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TextChatService = game:GetService("TextChatService")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoClient = require(ReplicatedStorage:WaitForChild("MangoClient"))
    local RemoteController = MangoClient.Require("RemoteController")

    --// TYPES \\--

    --// CONSTANTS \\--
    local GeneralTextChannel: TextChannel = TextChatService.TextChannels.RBXGeneral
    local SystemTextChannel: TextChannel = TextChatService.TextChannels.RBXSystem
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--
    local function DisplaySystemMessage(message: string)
        -- GeneralTextChannel:DisplaySystemMessage(message)
        SystemTextChannel:DisplaySystemMessage(message)
    end

    -- Initializes the controller.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    ChatController.__Init = Init

    --// RUNTIME \\--
    RemoteController.OnClientEvent("CHAT_SERVICE_DISPLAY_SYSTEM_MESSAGE", DisplaySystemMessage)
end

return ChatController