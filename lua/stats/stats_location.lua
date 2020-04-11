local db = STATS.Database
STATS.Queries['location_get'] = db:prepare('SELECT * FROM location_css WHERE steamid64 = ?')
STATS.Queries['location_update'] = db:prepare('UPDATE location_css SET last_seen = ?, last_ip = ?, country = ?, region = ? WHERE steamid64 = ?')
STATS.Queries['location_update_date'] = db:prepare('UPDATE location_css SET last_seen = ? WHERE steamid64 = ?')
STATS.Queries['location_new'] = db:prepare('INSERT IGNORE INTO location_css VALUES(?, ?, ?, ?, ?)')
STATS.Queries['dates_add'] = db:prepare('INSERT IGNORE INTO play_dates VALUES(?, ?)')

local function updateFullInfo(ip, id, current_date, new)
    local api_url = 'http://api.ipstack.com/' .. ip .. '?access_key=' .. STATS.IP_ACCESS .. '&format=1'
    http.Fetch(api_url, function(body)
        local json = util.JSONToTable(body)
        local country = json['country_name'] or '[?]'
        local region = json['region_name'] or '[?]'

        -- Handle database
        if new then
            local q = STATS.Queries['location_update']
            q:setString(1, id)
            q:setString(2, current_date)
            q:setString(3, ip)
            q:setString(4, country)
            q:setString(5, region)
            q:start()
        else
            local q = STATS.Queries['location_update']
            q:setString(1, current_date)
            q:setString(2, ip)
            q:setString(3, country)
            q:setString(4, region)
            q:setString(5, id)
            q:start()
        end
    end)
end

function STATS:StoreVisit(ply)
    if not IsValid(ply) then return end
    if ply:IsBot() then return end
    local id = ply:SteamID64()
    if not id then return end

    local ip = ply:IPAddress()
    -- testing quickfix I'm so sorry
    if ip == 'loopback' and ply:SteamID64() == '76561198067202125' then
        ip = '103.44.34.122:27015'
    elseif ip == 'loopback' then
        return
    end

    -- Strip port
    local idx = string.find(ip, ':')
    if idx then
        ip = string.sub(ip, 1,  - 1)
    end

    local current_date = os.date('%Y-%m-%d', os.time())

    -- Location updating
    local q = STATS.Queries['location_get']
    q:setString(1, id)
    function q:onSuccess(data)
        if type(data) == 'table' and #data > 0 then
            local old_ip = data[1].last_ip
            if old_ip != ip then
                updateFullInfo(ip, id, current_date, false)
            else
                -- Update only the last time seen
                local q2 = STATS.Queries['location_update_date']
                q2:setString(1, current_date)
                q2:setString(2, id)
                q2:start()
            end
        else
            updateFullInfo(ip, id, current_date, true)
        end
    end
    q:start()

    -- Update play dates
    local q = STATS.Queries['dates_add']
    q:setString(1, id)
    q:setString(2, current_date)
    q:start()
    print('Storing location!')
end

hook.Add('PlayerInitialSpawn', 'LoadLocationStatistics', function(ply)
    STATS:StoreVisit(ply)
end)