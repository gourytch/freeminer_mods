dofile (base .. 'utf8to32.lua')

--
-- all font glyphs resides in textures/name/[0-F]/[0-f]{4}.png
--

local function repr (v)
    local t = type(v)
    if t == "string" then
        return "'" .. v .. "'"
    elseif t == "table" then
        local s = ""
        for k,v in pairs (v) do
            if s ~= "" then
                s = s .. ", "
            end
            s = s .. "[" ..repr (k) .. "]=" .. repr (v)
        end
        return "{" .. s .. "}"
    else
        return tostring (v)
    end
end



Font = {}
Font.__index = Font
setmetatable (Font, {
    __call = function (cls, ...) return cls.new (...) end,
})


function Font.new (name)
    local self = setmetatable ({}, Font)
    self.meta = {
        ['codenames']   = {},
        ['namecodes']   = {},
--        ['params']      = {},
        ['codepoints']  = {},
        ['name']        = '',
        ['face_name']   = '',
        ['image_file']  = '',
        ['cell_width']  = 0,
        ['cell_height'] = 0,
        ['num_colors']  = 0,
        ['num_glyphs']  = 0
    }

    if name ~= nil then
        self:load_meta (name)
    end
    return self
end -- Font:new


function Font:load_meta (name)
    local f, err = io.open (name, "r")
    if err then
        print ("[x] load_meta error: " .. err)
        return nil
    end

    self.meta = {
        ['codenames']   = {},
        ['namecodes']   = {},
--        ['params']      = {},
        ['codepoints']  = {},
        ['name']        = '',
        ['face_name']   = '',
        ['image_file']  = '',
        ['cell_width']  = 0,
        ['cell_height'] = 0,
        ['num_colors']  = 0,
        ['num_glyphs']  = 0
    }

    local mapping = false
    for line in f:lines () do
        if mapping then -- section with codepoint & codename pairs
            local code, name = string.match (line, "^([%w_]+) *(.*)$")
            self.meta.codenames [code] = name
            self.meta.namecodes [name] = code
        else
            local k, args = string.match (line, "^([%w_]+) *(.*)$")
            if not k then -- end of varnames, mapping section will follows
                mapping = true
            elseif k == 'CODEPOINTS' then -- key with multiple values
                for w in string.gmatch (args, "(%w+)") do
                    table.insert (self.meta.codepoints, w)
                end
            else -- all others are pairs
                local v = string.match (args, "^ *([^ ]*.-) *$")
--                meta ['params'][k] = v
                if k == 'NAME' then
                    self.meta.name = v
                elseif k == 'FACE_NAME' then
                    self.meta.face_name = v
                elseif k == 'CELL_WIDTH' then
                    self.meta.cell_width = tonumber (v)
                elseif k == 'CELL_HEIGHT' then
                    self.meta.cell_height = tonumber (v)
                elseif k == 'NUM_COLORS' then
                    self.meta.num_colors = tonumber (v)
                elseif k == 'NUM_GLYPHS' then
                    self.meta.num_glyphs = tonumber (v)
                end
            end -- end of pairs
        end  -- end of param section
    end -- end of line loop
    f:close ()
end -- Font:load_meta


function Font:generate_line (text, x_offs, y_offs, x_max)
    local i       = 1
    local x       = x_offs
    local ret     = ""
    local color   = 0
    local utext = utf8to32 (text)

    while true do
        local u = utext [i]
        if u == nil or u == 0x000 then
            print ("last char at position" .. i)
            break
        end
        local code = string.format ("%04x", u)
        print ("code = " .. code .. " at position " .. i)
        local draw_it = true
        -- color switch &0..&9|&A..&F|&a..&f
        if 0x0026 == u then -- U+0026 AMPERSAND
            if i < #utext then -- not last character
                local v = utext [i + 1]
                local vcode = string.format ("%04x", v)
                print ("vcode " .. vcode .. "  at position " .. i+1)
                if 0x0026 == v then -- double ampersand - just print it
                    i = i + 1 -- skip first one but draw second one
                elseif 0x0030 <= v and v <= 0x0039 then -- [0..9]
                    color = v - 0x0030
                    i = i + 1 -- skip first char
                    draw_it = false  -- do not draw second char
                elseif 0x0041 <= v and v <= 0x0046 then -- [A..F]
                    color = 10 + v - 0x0041
                    i = i + 1 -- skip first char
                    draw_it = false  -- do not draw second char
                elseif 0x0061 <= v and v <= 0x0066 then -- [a..f]
                    color = 10 + v - 0x0061
                    i = i + 1 -- skip first char
                    draw_it = false  -- do not draw second char
                else
                    print ("[!] bad color code & + " .. vcode)
                end -- something not in format &[0-9A-Fa-f]
            else
                print ("[!] color prefix at last char position")
            end
            if self.meta.num_colors <= color then
                print ("[!] color value is too high. reset it to 0")
                color = 0
            end
        end -- end color parsing
        if draw_it then
            if self.meta.codenames [code] ~= nil then
                local x_next = x + self.meta.cell_width
                if x_next < x_max then
                    local fname = string.format ("%s/%X/%s.png",
                    self.meta.name, color, code)
                    ret = ret .. ":" .. x .. "," .. y_offs .. "=" .. fname
                    x = x_next
                else
                    break
                end
            else -- has no glyph
                print ("[!] code " .. code .. " has no glyph")
            end
        end
        i = i + 1 -- next u32 char
    end -- while
    return ret
end -- Font:generate_line


font_meta = base .. 'clR6x12.meta'
font = Font (font_meta)
print ("font loaded, name:" ..
    font.meta.name .. ", " ..
    font.meta.num_glyphs .. " glyphs")

