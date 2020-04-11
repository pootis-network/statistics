STATS = {}
STATS.Queries = {}

STATS.UpdateTime = 120

-- Include the database helper immediately
include('database.lua')

local supported_gamemodes = {
    ["murder"] = true,
}
-- Load gamemode-specific statistics managers
hook.Add('Initialize', 'LoadGamemodeStatistics', function()
    if supported_gamemodes[GAMEMODE_NAME] then
        include('stats/gamemodes/' .. GAMEMODE_NAME .. '.lua')
    end
end)

-- Update statistics hook handler
function STATS:UpdateStatistics()
    for k,v in pairs(player.GetAll()) do
        if v:IsBot() then continue end
        if not v:SteamID64() then continue end

        hook.Call('UpdateStatistics', nil, v)
    end
end

timer.Create('UpdateStatisticsTimer', STATS.UpdateTime or 120, 0, function()
    STATS:UpdateStatistics()
end)

-- Last-ditch attempt to save before shutdown
-- This hook is probably called too late for queries to run, but it's worth a try
hook.Add('ShutDown', 'SaveStatisticsOnShutdown', function()
    STATS:UpdateStatistics()
end)

-- Load component modules
include('stats_playtime.lua')
include('stats_donor.lua')
include('stats_location.lua')