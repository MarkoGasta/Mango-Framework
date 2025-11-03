--// Script by: MarkoGasta2 \--

--// CONFIG \--

--// SERVICES \--

local ServerStorage = game:GetService('ServerStorage')
local RobloxBadgeService = game:GetService('BadgeService')

--// MODULES \--

local MangoServer = require(ServerStorage.MangoServer)
local Logger = MangoServer.Require('Logger')
local BadgeSettings = MangoServer.Require('BadgeSettings')

--// TYPES \--

--// CONSTANTS \--

--// VARIABLES \--

local BadgeService = {}

--// FUNCTIONS \--

-- Awars a badge to the player.
local function AwardBadge(player: Player, badgeId: string)

    -- Checking if badge exists.
    local badgeData = BadgeSettings["BADGE_DATA"][badgeId]
    if not badgeData then
        return Logger.warn(`Badge with badgeId {badgeId} does not exist.`)
    end
    
    -- Check if the player already has the badge
    local success, hasBadge: boolean = xpcall(function()
        return RobloxBadgeService:UserHasBadgeAsync(player.UserId, badgeData["ID"])
    end, function(err: string)
        Logger.warn(err)
    end)

    -- Check if the player already has the badge or if the awarding was successful.
    if not success or hasBadge then
        return
    end

    -- Award the badge
    xpcall(function()
        RobloxBadgeService:AwardBadge(player.UserId, badgeData["ID"])
    end, function(err: string)
        Logger.warn(`Failed to award badge to player {player.Name} with badgeId {badgeId}. Error: {err}`)
    end)
end

-- Awards all the players in the game a badge.
local function AwardAllPlayers(badgeId: string)
    for _, player in game.Players:GetPlayers() do
        AwardBadge(player, badgeId)
    end
end

-- Exporting methods.
BadgeService.AwardBadge = AwardBadge
BadgeService.AwardAllPlayers = AwardAllPlayers

-- Initiation method.
function BadgeService.Init()

end

return BadgeService