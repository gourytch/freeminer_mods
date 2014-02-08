--[[
before using this module you should be load bit and utf8to32 files
like that
local modname = "testblock"
dofile (minetest.get_modpath (modname) .. "/bit.lua")
dofile (minetest.get_modpath (modname) .. "/utf8to32.lua")
dofile (minetest.get_modpath (modname) .. "/makepage.lua")
]]


local mk_commands = function (v)
    -- hardcoded font properties definition
    local fontname = "font.png"
    local CODEPOINTS_txt="0020 0021 0022 0023 0024 0025 0026 0027 0028 0029 002a 002b 002c 002d 002e 002f 0030 0031 0032 0033 0034 0035 0036 0037 0038 0039 003a 003b 003c 003d 003e 003f 0040 0041 0042 0043 0044 0045 0046 0047 0048 0049 004a 004b 004c 004d 004e 004f 0050 0051 0052 0053 0054 0055 0056 0057 0058 0059 005a 005b 005c 005d 005e 005f 0060 0061 0062 0063 0064 0065 0066 0067 0068 0069 006a 006b 006c 006d 006e 006f 0070 0071 0072 0073 0074 0075 0076 0077 0078 0079 007a 007b 007c 007d 007e 0410 0430 0411 0431 0412 0432 0413 0433 0414 0434 0415 0435 0401 0451 0416 0436 0417 0437 0418 0438 0419 0439 041a 043a 041b 043b 041c 043c 041d 043d 041e 043e 041f 043f 0420 0440 0421 0441 0422 0442 0423 0443 0424 0444 0425 0445 0426 0446 0427 0447 0428 0448 0429 0449 042a 044a 042b 044b 042c 044c 042d 044d 042e 044e 042f 044f"
    local NUM_VARIATIONS=27
    ---------------------------------------
    local indexes = {}
    local i = 0
    for u in string.gmatch (CODEPOINTS_txt, "[^%s]+") do 
        indexes [u] = i
        i = i + 1
    end
    local cw, ch = 16, 32
    local gap = 3
    local w = 0
    local x, y = gap, gap
    local clr = 0
    local s = ""
    for _,c  in ipairs (v) do
        local t = type (c)
--        print ("c=(" .. t .. ")["..c.."]")
        if t == 'number' then
            clr = (0 <= c and c < NUM_VARIATIONS) and c or 0
--            print ("selected variation: " .. tostring (clr))
        elseif c == '000d' or c == '000a' then -- carriage return
--            print ("next line")
            x = gap
            y = y + ch
        else -- just put out glyph
--            print ("type glyph for ".. c)
            local ix = indexes [c]
            if ix then
                local cx = ix * cw
                local cy = clr * ch
                s = s .. ">bitblt F," .. x .. "," .. y
                                      .. "," .. cx .. "," .. cy 
                                      .. "," .. cw .. "," .. ch
            else
                s = s .. ">apply NoCh," .. x .. "," .. y
            end
            x = x + cw
            if w < x + gap then
                w = x + gap
            end
        end
    end
    local h = y + ch + gap
    local z = (w < h) and h or w
    s = ">fit "..z..","..z..">store Paper" ..
        ">new "..cw..","..ch..",F03>store NoCh" ..
        ">load "..fontname..">store F" ..
        ">restore Paper" .. s
    return s
end

local mk_codepoints = function (txt)
    local u32 = utf8to32 (txt)
    local ret = {}
    local got_amp = false
    for _, u in ipairs (u32) do
        local add_this = true
        if u == 0 then
--            print "*ZERO*"
            if got_amp then
                u = 0x0039 -- insert last '&'
            else
                add_this = false
            end
        elseif got_amp then -- got ampersand at prev. step
            if 0x0030 <= u and u <= 0x0039 then -- 0..9 -- variation number
                table.insert (ret, (u - 0x0030)) -- add 0..9, type int
                add_this = false -- do not add as codepoint
            elseif 0x0041 <= u and u <= 0x0046 then -- A..F -- variation number
                table.insert (ret, ( 0x000A + u - 0x0041 )) -- add 10..15, type int
                add_this = false -- do not add as codepoint
            elseif 0x0061 <= u and u <= 0x0066 then -- a..f -- variation number
                table.insert (ret, ( 0x000A + u - 0x0061 )) -- add 10..15, type int
                add_this = false -- do not add as codepoint
            end
            got_amp = false -- reset flag
        elseif u == 0x0026 then -- AMPERSAND
            got_amp = true
            add_this = false
        end

        if add_this then
            table.insert (ret, string.format ("%04x", u))
        end
    end
    return ret
end

-- makepage generates commands for [imagebuild

function make_text_commands (text)
    return mk_commands (mk_codepoints (text))
end


function build_plain_page (color, text)
    return "[imagebuild new 1,1,"..color..mk_commands (mk_codepoints (text))
end


function build_textured_page (texname, text)
    return "[imagebuild load "..texname..mk_commands (mk_codepoints (text))
end
