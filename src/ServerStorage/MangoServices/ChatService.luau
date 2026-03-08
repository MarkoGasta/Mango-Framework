--[[
    Written by MarkoGasta2 @ Studio Blackout
]]--

local ChatService = {}
function ChatService.__Construct()

    --// SERVICES \\--
    local TextChatService = game:GetService("TextChatService")
    local ServerStorage = game:GetService("ServerStorage")

    --// CONFIG \\--

    --// MODULES \\--
    local MangoServer = require(ServerStorage:WaitForChild("MangoServer"))
    local RemoteService = MangoServer.Require("RemoteService")

    --// TYPES \\--

    --// CONSTANTS \\--
    
    --// VARIABLES \\--

    --// FUNCTIONS \\--

    --[=[
        Sends a system chat message. This function supports rich text.

        ### Parameters:
        ```luau
        message: string -- The text to display to all clients.
        ```
    ]=]
    local function SendSystemMessage(message: string)
        RemoteService.FireAllClients("CHAT_SERVICE_DISPLAY_SYSTEM_MESSAGE", message)
    end

    -- Initializes the service.
    local function Init()
        
        --// FUNCTION \\--

        --// EXPORTS \\--

        --// RUNTIME \\--
    end

    --// EXPORTS \\--
    ChatService.__Init = Init
    ChatService.SendSystemMessage = SendSystemMessage

    --// RUNTIME \\--
    RemoteService.CreateRemoteEvent("CHAT_SERVICE_DISPLAY_SYSTEM_MESSAGE")
end

return ChatService