-- testblock mod
local modname = "testblock"
dofile (minetest.get_modpath (modname) .. "/bit.lua")
dofile (minetest.get_modpath (modname) .. "/utf8to32.lua")
dofile (minetest.get_modpath (modname) .. "/makepage.lua")

testblock = {}

local text1 = function ()
--    return mkstring ({'0048', '0065', '006c', '006c', '006f', 'fffe'})
--    return mkstring ({'041f','0440','0438','0432','0435','0442','0021'})
    return build_plain_page ('CA8',
[[     &1Вольнолюбивые стихи&0

Если птице отрезать руки,
Если ноги отрезать тоже,
Эта птица умрет от скуки,
Потому что сидеть не сможет...

У поэта отнимешь рифму -
Что клешню оторвешь у краба,
Потому что поэт без рифмы -
Все равно что мужик без бабы!

&4(C) &8А.Арканов]])

end


local text2 = function ()
--    return mkstring ({'0048', '0065', '006c', '006c', '006f', 'fffe'})
--    return mkstring ({'041f','0440','0438','0432','0435','0442','0021'})
    return build_textured_page ('page1.png',
[[&cСтишок 3

&1Р&0ебенка привязали за ноги к жигулям.
&1О&0н чиркал по асфальту руками и лицом.
&1А&0 папа посильнее нажал ногой на газ,
&1Ч&0тоб высыпались зубы у сына изо рта.

&1Н&0а резких поворотах сын бился головой
&1О&0 ближние машины и каменный бордюр.
&1Н&0а третьем светофоре он был еще живой,
&1Н&0а пятом светофоре он сделался мертвец.
&4Хе... 
&71:0 в пользу девочек.
]])

end

local testcolor = function ()
    return "new 8,8,F00>store R>new 8,8,0F0>store G>new 8,8,00F>store B" ..
           ">new 16,16,F>apply R,4,1>apply G,1,7>apply B,7,5>store Pix" ..
           ">new 16,16,50000000>store Shadow" ..
           ">new 32,32,FCD080>apply Shadow,7,8>apply Pix,5,5"
end

minetest.register_node ("testblock:box1", {
    description = "Test Block #1",
    tile_images = { "[imagebuild new 1,1,F00", 
                    "[imagebuild new 4,4,00F",
                    text1 (),
                    "[imagebuild " .. testcolor (),
                    text2 (),
                    "[imagebuild new 4,4,FA4",
                    },
    inventory_image = minetest.inventorycube ("rainbow.png^[verticalframe:6:0", 
                                              "rainbow.png^[verticalframe:6:1", 
                                              "rainbow.png^[verticalframe:6:2"),
    paramtype = "light",
    light_source = LIGHT_MAX - 1;
    groups = { snappy = 1,
               choppy = 2,
               oddly_breakable_by_hand = 2,
               flammable = 3},
--    drop = 'default:stick 3',
    sounds = default.node_sound_wood_defaults (),

})

minetest.register_craft ({
    output = 'testblock:box1',
    recipe = {{'default:stick', 'default:stick', ''},
              {'default:stick',              '', ''},
              {             '',              '', ''}}
})

minetest.register_craft({
    type = "fuel",
    recipe = "testblock:box1",
    burntime = 300,
})

minetest.register_alias ("tb1", "testblock:box1")