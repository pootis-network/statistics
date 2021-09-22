--- This is a heavily modified version of statistics for our website,
--- if you wish to use this addon:
--- Please use the Master or noGameStats branch, this branch is
--- for noGameStats with a custom database structure.

local db = STATS.Database
--- for reference: DB structure = SteamID64, name, first joined time, last seen time, playtime
STATS.Queries['username_update2'] = db:prepare('UPDATE '..STATS.DB_PREFIX..'_users SET name = ? WHERE steamid64 = ?')
STATS.Queries['playtime_get2'] = db:prepare('SELECT playtime FROM '..STATS.DB_PREFIX..'_users WHERE steamid64 = ?')
STATS.Queries['playtime_new2'] = db:prepare('INSERT IGNORE INTO '..STATS.DB_PREFIX..'_users VALUES(?, ?, ?, ?, 0)')
STATS.Queries['playtime_update2'] = db:prepare('UPDATE '..STATS.DB_PREFIX..'_users SET playtime = ? WHERE steamid64 = ? AND playtime < ?')

-- Get the gamemode name
-- This has an extra check for Minigames
function STATS:GetGamemodeName()
    if GAMEMODE.IsMinigames then
        return "minigames"
    else
        return GAMEMODE_NAME
    end
end

-- Fetch playtime get initial playtime
function STATS:GetInitialPlaytime(ply)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end

    local id = ply:SteamID64()
    if not id then return end

    -- Store the join time
    if not ply.Jointime then ply.Jointime = os.time() end
    if ply.Playtime then return end

    local name = ply:Nick()
    if not name then return end

    local get_query = STATS.Queries['playtime_get2']
    get_query:setString(1, id)
    function get_query:onSuccess(data)
        if type(data) == 'table' and #data > 0 then
            -- Load the existing playtime value
            ply.Playtime = data[1].playtime

            timer.Simple(1, function()
                hook.Call('StatisticsFetchedPlaytime', nil, ply, data[1].playtime)
            end)
        else
            -- No player record currently exists for this user
            -- Insert data
            local new_query = STATS.Queries['playtime_new2']
            new_query:setString(1, id)
            new_query:setString(2, name)
            new_query:setString(3, ply.Jointime)
            new_query:setString(4, ply.Jointime)

            new_query:start()
        end
    end
    get_query:start()
end

-- Store the players current username into the table
function STATS:UpdateUsername(ply)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end

    local id = ply:SteamID64()
    if not id then return end

    local name = ply:Nick()
    if not name then return end

    local name_query = STATS.Queries['username_update2']
    name_query:setString(1, name)
    name_query:setString(2, id)
    name_query:start()
end

-- Update the playtime for this gamemode
function STATS:UpdatePlaytime(ply)
    if not IsValid(ply) then return end
    if !ply.Jointime or !ply.Playtime then
        STATS:GetInitialPlaytime(ply)
        return
    end

    local newtime = ply.Playtime + (os.time() - ply.JoinTime)
    local id = ply:SteamID64()

    local update_query = STATS.Queries['playtime_update2']
    update_query:setNumber(1, newtime)
    update_query:setString(2, id)
    update_query:setNumber(3, newtime) -- Ensure consistency
    update_query:start()
end

hook.Add('PlayerInitialSpawn', 'LoadPlaytimeStatistics', function(ply)
    ply.JoinTime = os.time()
    STATS:GetInitialPlaytime(ply)
    STATS:UpdateUsername(ply)
end)
hook.Add('UpdateStatistics', 'UpdatePlaytimeStatistics', function(ply) STATS:UpdatePlaytime(ply) end)

-- ULX role management based on playtime
hook.Add('StatisticsFetchedPlaytime', 'PlaytimeULXRoles', function(ply, playtime)
    -- no gamemode checks, only check for ULX and some sanity checks.
    --if GAMEMODE_NAME != 'murder' then return end

    if not ULib then return end
    
    local group = ply:GetUserGroup() or nil
    if not group then return end

    -- Update rank based on playtime
    if group == 'user' and playtime >= 36000 then
        ply:ChatPrint('Congratulations for playing for 10h!')
        ply:ChatPrint('You have been promoted to Respected [1]')
        ply:ChatPrint('This rank has access to a couple of basic commands.')
        ply:ChatPrint('Type !menu to learn more.')
        ply:SetUserGroup( 'respected' )
    elseif group == 'respected' and playtime >= 86400 then
        ply:ChatPrint('You have played for over a day!')
        ply:ChatPrint('You have been promoted to Respected [2]')
        ply:ChatPrint('If you were considering a staff application, being this rank will help immensely.')
        ply:SetUserGroup( 'respected2' )
    elseif group == 'respected2' and playtime >= 180000 then
        ply:ChatPrint('You have played for 50h.')
        ply:ChatPrint('You have been promoted to Respected [3]')
        ply:ChatPrint('This rank has access to !vote and !ghost')
        ply:SetUserGroup( 'respected3' )
    elseif group == 'respected3' and playtime >= 360000 then
        ply:ChatPrint('Thankyou for your endless support of Pootis Network.')
        ply:ChatPrint('You have been promoted to Respected [4]')
        ply:ChatPrint('This is currently the final respected rank.')
        ply:SetUserGroup( 'respected4' )
    end
end)