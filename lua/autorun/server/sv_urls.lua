util.AddNetworkString('StatisticsOpenURL')

local function openurl(ply, url)
    net.Start('StatisticsOpenURL')
        net.WriteString(url)
    net.Send(ply)
end

local chat_commands = {
    ['!steamgroup'] = function(ply)
        openurl(ply, 'https://steamcommunity.com/groups/pootistf2official')
    end,
    ['!stats'] = function(ply)
        if not ply.Playtime or not ply.JoinTime then return end
        local seconds = ply.Playtime + (os.time() - ply.JoinTime)

        if seconds > 10800 then
            local hours = math.Round(seconds/3600, 1)
            ply:ChatPrint('You have played for ' .. hours .. ' hours.')
        else
            local minutes = math.Round(seconds/60, 1)
            ply:ChatPrint('You have played for' .. minutes .. ' minutes')
        end
    end,
    ['!namecolor'] = function(ply)
        ply:ConCommand('namecolor')
    end,

    ['!namecolour'] = function(ply)
        ply:ConCommand('namecolor')
    end,
}

hook.Add('PlayerSay', 'StatisticsChatCommands', function(ply, txt)
    local message = string.lower(txt)
    if chat_commands[message] then
        chat_commands[message](ply)
    end
end)

hook.Add('PlayerSay', 'StopSpaceSpam',  function(ply, text)
    local clean = string.TrimRight(text)
    if clean == "" then return false end
end)