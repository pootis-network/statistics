util.AddNetworkString('UpdateNameColor')

local db = STATS.Database
STATS.Queries['donor_get'] = db:prepare('SELECT * FROM donor WHERE steamid64 = ?')
STATS.Queries['donor_update'] = db:prepare('UPDATE donor SET colorstring = ? WHERE steamid64 = ?')

function STATS:GetDonorStatus(ply)
    if ply:IsBot() then return end
    if ply:GetNWBool('Donor') then return end
    local id = ply:SteamID64()
    if not id then return end

    local q = STATS.Queries['donor_get']
    q:setString(1, id)
    function q:onSuccess(data)
        if type(data) == 'table' and #data > 0 then
            ply:SetNWBool('Donor', true)
            ply:SetNWInt('DonorAmount', data[1]['amount'])
            ply:SetNWString('NameColor', data[1]['colorstring'])
        end
    end
    q:start()
end

function STATS:UpdateDonorStatus(ply, tbl)
    -- Validate the name color table to ensure that nobody does sketchy stuff
    local mode = tbl[1]
    local namestring = nil
    if mode == 'G' then
        if #tbl != 7 then return end
        for i=2,7 do
            tbl[i] = math.Clamp(tbl[i], 0, 255)
        end

    elseif mode == 'H' then
        if #tbl != 3 then return end
        tbl[2] = math.Clamp(tbl[2], 0, 360)
        tbl[3] = math.Clamp(tbl[3], 0, 360)

    elseif mode == 'M' then
        if #tbl != math.floor((#tbl-1)/3) then return end
        for i=2,#tbl do
            tbl[i] = math.Clamp(tbl[i], 0, 255)
        end

    else
        -- Invalid mode
        return
    end

    namestring = table.concat(tbl, ',')
    if not namestring then return end
    ply:SetNWString('NameColor', namestring)

    local id = ply:SteamID64()
    if not id then return end
    
    -- Update the database
    local q = STATS.Queries['donor_update']
    q:setString(1, namestring)
    q:setString(2, namestring)
    q:start()
end

hook.Add('PlayerInitialSpawn', 'LoadDonorStatistics', function(ply)
    STATS:GetDonorStatus(ply)
end)

net.Receive('UpdateNameColor', function(len, ply)
    if ply:GetNWInt('DonorAmount', 0) < 500 then
        if ply.spamwarn then ply:Kick() else ply.spamwarn = true end
        return
    end

    local details = net.ReadTable()
    STATS:UpdateDonorStatus(ply, details)
end)