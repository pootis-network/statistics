local db = STATS.Database
STATS.Queries['murder_get'] = db:prepare('SELECT * FROM stats_murder WHERE steamid64 = ?')
STATS.Queries['murder_update'] = db:prepare('UPDATE stats_murder SET loot = ?, murders = ?, shot_murderer = ?, shot_innocent = ? WHERE steamid64 = ?')
STATS.Queries['murder_new'] = db:prepare('INSERT INTO stats_murder VALUES (?, 0, 0, 0, 0)')
STATS.Queries['murder_map'] = db:prepare('INSERT INTO murder_maps VALUES(?, ?, ?, ?)')

function STATS:FetchMurderStats(ply)
    if ply:IsBot() then return end
    local id = ply:SteamID64()
    if not id then return end

    ply.MurderStats = {}

    local q = STATS.Queries['murder_get']
    q:setString(1, id)
    function q:onSuccess(data)
        if type(data) == 'table' and #data > 0 then
            ply.MurderStats = data[1]
        else
            local q2 = STATS.Queries['murder_new']
            q2:setString(1, id)
            q2:start()

            ply.MurderStats = {
                ['loot'] = 0,
                ['murders'] = 0,
                ['shot_murderer'] = 0,
                ['shot_innocent'] = 0
            }
        end
    end
    q:start()
end

function STATS:SaveMurderStats(ply)
    if not ply.MurderStats then return end
    local id = ply:SteamID64()

    local q = STATS.Queries['murder_update']
    q:setNumber(1, ply.MurderStats['loot'])
    q:setNumber(2, ply.MurderStats['murders'])
    q:setNumber(3, ply.MurderStats['shot_murderer'])
    q:setNumber(4, ply.MurderStats['shot_innocent'])
    q:setString(5, id)
    q:start()
end

hook.Add('PlayerInitialSpawn', 'UpdateMurderStatistics', function(ply) STATS:FetchMurderStats(ply) end)
hook.Add('UpdateStatistics', 'UpdateMurderStatistics', function(ply) STATS:SaveMurderStats(ply) end)

-- Track loot pickups
hook.Add('PlayerPickupLoot', 'MurderLootStatistic', function(ply)
    if !ply.MurderStats then return end
    if !ply.MurderStats['loot'] then ply.MurderStats['loot'] = 0 end
    ply.MurderStats['loot'] = ply.MurderStats['loot'] + 1
end)

-- Track various death events
hook.Add('PlayerDeath', 'MurderKillStatistics', function(victim, inflictor, attacker)
    if GAMEMODE.RoundStage != GAMEMODE.Round.Playing then return end

    if victim == attacker then return end
    if not attacker:IsPlayer() then return end
    if not attacker.MurderStats then return end

    if not victim:GetMurderer() then
        if attacker:GetMurderer() then
            -- Murderer has killed an innocent
            if !attacker.MurderStats['murders'] then attacker.MurderStats['murders'] = 0 end
            attacker.MurderStats['murders'] = attacker.MurderStats['murders'] + 1
        else
            -- Innocent has killed an innocent
            if !attacker.MurderStats['shot_innocent'] then attacker.MurderStats['shot_innocent'] = 0 end
            attacker.MurderStats['shot_innocent'] = attacker.MurderStats['shot_innocent'] + 1
        end
    else
        -- Innocent has killed the murderer
        if !attacker.MurderStats['shot_murderer'] then attacker.MurderStats['shot_murderer'] = 0 end
        attacker.MurderStats['shot_murderer'] = attacker.MurderStats['shot_murderer'] + 1
    end
end)

-- Track map voting
hook.Add('MapVoteWon', 'MurderMapStatistics', function(map, total, votes)
    local current_time = os.date('%Y-%m-%d %H:%M:%S', os.time())
    local q = STATS.Queries['murder_map']
    q:setString(1, current_time)
    q:setString(2, map)
    q:setNumber(3, player.GetCount())
    q:setNumber(4, votes)
    q:start()
end)