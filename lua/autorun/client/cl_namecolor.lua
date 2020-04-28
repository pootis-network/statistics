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

-- Update functions for the name color UI
local update_functions = {}
update_functions['G'] = function(frame, c)
    local c1 = c.mixer1:GetColor()
    local c2 = c.mixer2:GetColor()

    frame.NameTable = {c1.r, c1.g, c1.b, c2.r, c2.g, c2.b}

    -- Blank presets if any changes are made
    c.Presets:SetText('Load a preset...')
end

update_functions['H'] = function(frame, c)

end

update_functions['M'] = function(frame, c)

end

-- Gradient presets
local gradient_presets = {
    ['Blurry Beach'] = {213, 51, 105, 203, 173, 109},
    ['Sublime Vivid'] = {252, 70, 107, 63, 94, 251}
}

-- Config panel functions for the name color UI
-- These create all the relevant settings for the config panel
local config_functions = {}
config_functions['G'] = function(frame, c)
    local yy = 0
    local w = c:GetWide()

    local presets_label = vgui.Create('DLabel', c)
    presets_label:SetSize(128, 24)
    presets_label:SetPos(12, yy)
    presets_label:SetText('')
    function presets_label:Paint(w, h)
        drawShadowText('Presets', 'DonorUI_24', 0, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    yy = yy + 24

    c.Presets = vgui.Create('DComboBox', c)
    c.Presets:SetSize(w - 24, 32)
    c.Presets:SetPos(12, yy)
    for k, v in pairs(gradient_presets) do
        c.Presets:AddChoice(k)
    end
    c.Presets:SetText('Load a preset...')
    function c.Presets:OnSelect(index, v)
        local data = gradient_presets[v]

        c.mixer1:SetColor(Color(data[1], data[2], data[3]))
        c.mixer2:SetColor(Color(data[4], data[5], data[6]))
        frame:TriggerUpdate()
        self:SetText(v)
    end

    yy = yy + 24 + 32

    -- Color 1
    c.mixer1 = vgui.Create('DColorMixer', c)
    c.mixer1:SetPalette(false)
    c.mixer1:SetAlphaBar(false)
    c.mixer1:SetColor(Color(255, 255, 255))
    c.mixer1:SetSize(160, 80)
    c.mixer1:SetPos(12, yy)
    function c.mixer1:ValueChanged()
        frame:TriggerUpdate()
    end

    c.mixer2 = vgui.Create('DColorMixer', c)
    c.mixer2:SetPalette(false)
    c.mixer2:SetAlphaBar(false)
    c.mixer2:SetColor(Color(255, 255, 255))
    c.mixer2:SetSize(160, 80)
    c.mixer2:SetPos(228, yy)
    function c.mixer2:ValueChanged()
        frame:TriggerUpdate()
    end
end

config_functions['H'] = function(frame, c)

end

config_functions['M'] = function(frame, c)

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
    frame.PreviewString = namestring
    frame.Mode = mode
    frame.NameTable = nametbl
    
    function frame:Paint(w, h) 
        local head_h = 32
        draw.RoundedBoxEx(8, 0, 0, w, head_h, Color(0, 168, 255), true, true, false, false)
        draw.RoundedBoxEx(8, 0, head_h, w, h - head_h, Color(200, 214, 229), false, false, true, true)

        drawShadowText('Name Color Customizer', 'DonorUI_24', w/2, head_h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local amount = LocalPlayer():GetNWInt('DonorAmount')

    if amount < 500 then
        local donor_label = vgui.Create('DLabel', frame)
        donor_label:SetText('You need to be a donor to use this!')
        donor_label:SetContentAlignment(5)
        donor_label:SetTextColor(color_white)
        donor_label:Dock(FILL)
        donor_label:SetFont('DonorUI_24')
        return
    end

    local config = vgui.Create('DPanel', frame)
    config:SetSize(400, 356)
    config:SetPos(0, 128)
    function config:Paint() end

    function frame:TriggerUpdate()
        if update_functions[mode] then
            update_functions[mode](frame, config)
        end
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

    if amount > 10000 then
        mode_dropdown:AddChoice('[H] Hue Rainbow')
        mode_dropdown:AddChoice('[M] Multicolor')
    end

    function mode_dropdown:OnSelect(index, value)
        local mode = value[2]
        if mode == frame.Mode then return end
        frame.Mode = mode

        if config_functions[mode] then
            config:Clear()
            config_functions[mode](frame, config)
        end
    end

    local preview_panel = vgui.Create('DPanel', frame)
    preview_panel:SetSize(400 - 24 - 64 - 12, 48)
    preview_panel:SetPos(12, 540)
    function preview_panel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(245, 246, 250))
    end

    function preview_panel:PaintOver(w, h)
        local tbl = nil
        -- Handle name with name color func   
        if name_color_funcs[mode] then
            tbl = name_color_funcs[mode](name, frame.NameTable)
        end
        if not tbl then return end

        surface.SetFont('DonorUI_32')
        local width, height = surface.GetTextSize(name)
        local xx = (w/2) - (width/2)
        local current_c = color_white
        for k,v in pairs(tbl) do
            if type(v) == 'string' then
                local cw = draw.SimpleText(v, 'DonorUI_32', xx, h/2, current_c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                xx = xx + cw
            elseif type(v) == 'table' and v.r then
                current_c = v
            end
        end
    end

    local save_button = vgui.Create('DButton', frame)
    save_button:SetSize(64, 48)
    save_button:SetPos(388 - 64, 540)
    save_button:SetText('')

    function save_button:Paint(w, h)
        local c = Color(0, 168, 255)
        if self:IsHovered() then
            c = Color(0, 151, 230)
        end

        draw.RoundedBox(8, 0, 0, w, h, c)
        drawShadowText('Save', 'DonorUI_24', w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function save_button:DoClick()
        local tbl = table.Copy(frame.NameTable)
        table.insert(tbl, 1, frame.Mode)

        net.Start('UpdateNameColor')
            net.WriteTable(tbl)
        net.SendToServer()
        frame:Close()
    end

    -- Build the settings table with what the server has saved (or the default)
    if config_functions[frame.Mode] then
        config:Clear()
        config_functions[frame.Mode](frame, config)
    end
    frame:TriggerUpdate()

    -- Select the right thing in the mode dropdown
    for k,v in pairs(mode_dropdown.Choices) do
        if v[2] == frame.Mode then
            mode_dropdown:ChooseOptionID(k)
            return
        end
    end
end

concommand.Add('namecolor', function()
    OpenNameCustomizer()
end)