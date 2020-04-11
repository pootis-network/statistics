local db = STATS.Database
STATS.Queries['donor_get'] = db:prepare('SELECT * FROM donor WHERE steamid64 = ?')

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

hook.Add('PlayerInitialSpawn', 'LoadDonorStatistics', function(ply)
    STATS:GetDonorStatus(ply)
end)