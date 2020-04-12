local db = STATS.Database
STATS.Queries['username_update'] = db:prepare('UPDATE playtime SET username = ? WHERE steamid64 = ?')
STATS.Queries['playtime_get'] = db:prepare('SELECT * FROM playtime WHERE steamid64 = ?')
STATS.Queries['playtime_new'] = db:prepare('INSERT IGNORE INTO playtime VALUES(?, 0, ?)')
STATS.Queries['playtime_update'] = db:prepare('UPDATE playtime SET playtime = ? WHERE steamid64 = ? AND playtime < ?')

function STATS:GetInitialPlaytime(ply)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end
    local id = ply:SteamID64()
    if not id then return end

    if not ply.JoinTime then ply.JoinTime = os.time() end
    if ply.Playtime then return end

    local q1 = STATS.Queries['playtime_get']
    q1:setString(1, id)
    function q1:onSuccess(data)
        if type(data) == 'table' and #data > 0 then
            ply.Playtime = data[1].playtime
            
            local q2 = STATS.Queries['username_update']
            q2:setString(1, ply:Nick() or '?')
            q2:setString(2, id)
            q2:start()

            timer.Simple(2, function()
                hook.Call('StatisticsFetchedPlaytime', nil, ply, data[1].playtime)
            end)
        else
            local q2 = STATS.Queries['playtime_new']
            q2:setString(1, id)
            q2:setString(2, ply:Nick() or '?')
            q2:start()
        end
    end
    q1:start()
end

function STATS:UpdatePlaytime(ply)
    if not IsValid(ply) then return end
    if !ply.JoinTime or !ply.Playtime then
        STATS:GetInitialPlaytime(ply)
        return
    end

    local conntime = os.time() - ply.JoinTime
    local newtime = ply.Playtime + conntime
    local id = ply:SteamID64()

    local q = STATS.Queries['playtime_update']
    q:setNumber(1, newtime)
    q:setString(2, id)
    q:setNumber(3, newtime) -- ensure consistency

    q:start()
end

hook.Add('PlayerInitialSpawn', 'LoadPlaytimeStatistics', function(ply)
    ply.JoinTime = os.time()
    STATS:GetInitialPlaytime(ply)
end)
hook.Add('UpdateStatistics', 'UpdatePlaytimeStatistics', function(ply) STATS:UpdatePlaytime(ply) end)

-- Maestro role management based on playtime
hook.Add('StatisticsFetchedPlaytime', 'PlaytimeMaestroRoles', function(ply, playtime)
    if not masetro then return end
    local group = ply:GetUserGroup() or nil
    if not group then return end

    -- Update rank based on playtime
    if group == 'user' and playtime >= 36000 then
        ply:ChatPrint('Congratulations for playing for 10h!')
        ply:ChatPrint('You have been promoted to Respected [1]')
        ply:ChatPrint('This rank has access to a couple of basic commands.')
        ply:ChatPrint('Type !menu to learn more.')
        maestro.userrank( ply, 'respected' )
    elseif group == 'respected' and playtime >= 86400 then
        ply:ChatPrint('You have played for over a day!')
        ply:ChatPrint('You have been promoted to Respected [2]')
        ply:ChatPrint('If you were considering a staff application, being this rank will help immensely.')
        maestro.userrank( ply, 'respected2' )
    elseif group == 'respected2' and playtime >= 180000 then
        ply:ChatPrint('You have played for 50h.')
        ply:ChatPrint('You have been promoted to Respected [3]')
        ply:ChatPrint('This rank has access to !vote and !ghost')
        maestro.userrank( ply, 'respected3' )
    elseif group == 'respected3' and playtime >= 360000 then
        ply:ChatPrint('Thankyou for your endless support of Fluffy Servers.')
        ply:ChatPrint('You have been promoted to Respected [4]')
        ply:ChatPrint('This is currently the final respected rank.')
        maestro.userrank( ply, 'respected4' )
    end
end)