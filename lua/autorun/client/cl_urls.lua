net.Receive('StatisticsOpenURL', function()
    local url = net.ReadString()
    gui.OpenURL(url)
end)

local advert_messages = {
    'Like the server? Join our steam group by typing !steamgroup',
    'Join our discord at https://discord.gg/xPrKvt9 (or type !discord)',
    'Type !donate to open our donation page and help fund Pootis Network',
    'Servers are expensive - donate to us & keep us alive.',
    'All the cool kids are in our discord - type !discord to join us!',
    'Thanks for playing on Pootis Network! Your support is appreciated <3',
    'Friendly reminder to give our staff team love!',
    'Join our community - type !discord & !steamgroup',
    'Type @ before your message to contact any online staff',
    'You can use !stats to check your playtime. You get respected ranks at 10, 24, 50, and 100 hours.',
    'Remember to have fun and treat everyone nicely!',
    'Join our discord at https://discord.gg/xPrKvt9 (or type !discord)' -- supposed to be twice
}

timer.Create('CommandAdverts', 200, 0, function()
    LocalPlayer():ChatPrint(table.Random(advert_messages))
end)