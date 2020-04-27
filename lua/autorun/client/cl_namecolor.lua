local name_color_funcs = {}
name_color_funcs['G'] = function(name, cd)
    local new = {}

    -- Do a cool gradient
    for i=1,#name do
        local char = name[i]
        local n = i/(#name)

        local r = cd[1] + (cd[4] - cd[1]) * n
        local g = cd[2] + (cd[5] - cd[2]) * n
        local b = cd[3] + (cd[6] - cd[3]) * n
        table.insert(new, Color(r, g, b))
        table.insert(new, char)
    end

    return new
end

name_color_funcs['H'] = function(name, cd)
    local new = {}

    -- Do a cool rainbow effect
    for i=1,#name do
        local char = name[i]
        local n = (i-1)/(#name)

        local col = HSVToColor(cd[1] + (cd[2]-cd[1]) *n, 1, 1)
        table.insert(new, col)
        table.insert(new, char)
    end

    return new
end

name_color_funcs['M'] = function(name, cd)
    local new = {}

    local stops = math.floor(#cd/3) - 1
    local size = 1/stops

    for i=1,#name do
        local char = name[i]
        local n = (i-1)/#name

        for i=1,stops do
            local s = i/stops

            if n <= s then
                -- Use the sth stop of the gradient
                local stop = (i-1)*3
                local sn = (size - (s - n))/size

                print(cd, stop, size, sn)

                local r = cd[stop+1] + (cd[stop+4] - cd[stop+1]) * sn
                local g = cd[stop+2] + (cd[stop+5] - cd[stop+2]) * sn
                local b = cd[stop+3] + (cd[stop+6] - cd[stop+3]) * sn

                table.insert(new, Color(r, g, b))
                table.insert(new, char)
                break
            end
        end
    end

    return new
end

local OAddText = chat.AddText
function chat.AddText(...)
    local args = { ... }

    for k,v in pairs(args) do
        if type(v) == 'Player' then
            local new = {}

            local cd = v:GetNWString('NameColor', nil)
            if cd and cd != '' and cd != ' ' then
                local name = v:Nick() or '<?>'
                local mode = cd[1]

                cd = string.sub(cd, 2)
                cd = string.Split(cd, ',')

                -- Handle the name color if the mode exists
                if name_color_funcs[mode] then
                    new = name_color_funcs[mode](name, cd)
                else
                    new = {name}
                end
            end

            -- Add a white 'buffer' at the end of each name
            table.insert(new, color_white)

            -- Insert the new 'colored' name into the original table
            table.remove(args, k)
            for _, c in pairs(table.Reverse(new)) do
                table.insert(args, k, c)
            end
        end
    end

    OAddText(unpack(args))
    return true
end

surface.CreateFont("DonorUI_24", {
	font = "Coolvetica",
	size = 24,
})

surface.CreateFont("DonorUI_32", {
	font = "Coolvetica",
	size = 32,
})


local function drawShadowText(text, font, x, y, color, horizontal_align, vertical_align)
    draw.SimpleText(text, font, x + 1, y + 2, Color(0, 0, 0, 150), horizontal_align, vertical_align) -- Shadow first, slightly offset
	return draw.SimpleText(text, font, x, y, color, horizontal_align, vertical_align) -- Regular text
end

local function OpenNameCustomizer()
    local namestring = LocalPlayer():GetNWString('NameColor', 'G213,51,105,203,173,109')
    local mode = namestring[1] or 'G'
    local nametbl = string.sub(namestring, 2)
    nametbl = string.Split(nametbl, ',')
    local name = LocalPlayer():Nick()

    local frame = vgui.Create('DFrame')
    frame:SetSize(400, 600)
    frame:Center()
    frame:SetTitle('')
    frame:MakePopup()
    frame.PreviewString = LocalPlayer():GetNWString('NameColor', 'G213,51,105,203,173,109')
    
    function frame:Paint(w, h)
        local head_h = 32
        draw.RoundedBoxEx(8, 0, 0, w, head_h, Color(0, 168, 255), true, true, false, false)
        draw.RoundedBoxEx(8, 0, head_h, w, h - head_h, Color(220, 221, 225), false, false, true, true)

        drawShadowText('Kool Kids Kolorizer (KKK)', 'DonorUI_24', w/2, head_h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local mode_label = vgui.Create('DLabel', frame)
    mode_label:SetSize(128, 32)
    mode_label:SetPos(12, 48)
    mode_label:SetText('')
    function mode_label:Paint(w, h)
        drawShadowText('Color Mode', 'DonorUI_24', 0, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local mode_dropdown = vgui.Create('DComboBox', frame)
    mode_dropdown:SetSize(376, 32)
    mode_dropdown:SetPos(12, 72)
    mode_dropdown:AddChoice('[G] Gradient')
    mode_dropdown:AddChoice('[H] Hue Rainbow')
    mode_dropdown:AddChoice('[M] Multicolor')

    local preview_panel = vgui.Create('DPanel', frame)
    preview_panel:SetSize(400 - 24, 64)
    preview_panel:SetPos(12, 524)
    function preview_panel:PaintOver(w, h)
        local tbl = nil
        -- Handle name with name color func   
        if name_color_funcs[mode] then
            tbl = name_color_funcs[mode](name, nametbl)
        end
        if not tbl then return end

        surface.SetFont('DonorUI_32')
        local width, height = surface.GetTextSize(name)
        local xx = (w/2) - (width/2)
        local current_c = color_white
        for k,v in pairs(tbl) do
            if type(v) == 'string' then
                local cw = drawShadowText(v, 'DonorUI_32', xx, h/2, current_c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                xx = xx + cw
            elseif type(v) == 'table' and v.r then
                current_c = v
            end
        end
    end
end

concommand.Add('namecolor', function()
    OpenNameCustomizer()
end)