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
    local SystemTextChannel: TextChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Shows a system message in the chat.

        ```luau
        message: string -- The message to display.
        ```
    ]=]--
    local function DisplaySystemMessage(message: string)
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