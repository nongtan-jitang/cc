--炼金桌自动合成（CC:Tweaked / 血魔法3 E6E）
--注意：炼金桌要配置好输入输出；终端字体显示不了中文，所以运行时打印都是英文短句
local direction = "left" -- 脉冲发送位置 合成仓相较于海龟的位置 记得调脉冲模式 使用ae可无视，记得开阻挡，或者用脉冲也行
local redstone_flag = true -- 默认使用脉冲模式
local check_delay = 0.5 -- 默认检测合成完毕延迟 0.5s
local output_name = "refinedstorage:interface" -- 默认产物输出位置rs物品接口，使用ae需调整

-- 下面这段是自动生成的配方表（来自你本地的 BloodMagic jar + E6E expert 的 KubeJS）。
-- 装载时会拿海龟手里的原料自动匹配配方：同一种原料在配方里出现几次，就占几个格子、放几份。
-- 匹配不上时才退回用下面的 per_craft / craft_amount 手动份数。
local per_craft = 1 -- 兜底：每种原料占 1 格
local craft_amount = {
    -- ["bloodmagic:weak_tau"] = 3,   -- 想手动指定时写这里（优先级低于自动匹配）
}

local input_slots = 6 -- 海龟用第 1~6 格装原料
local table_input_slots = 6 -- 炼金桌的输入格数（0~5 号格，固定 6 个）
local feed_settle = 0.3 -- 收到 turtle_inventory 后等一小会儿，确保整批原料都到齐再发料
local craft_timeout = 60 -- 等产物超过这么久就打印一次提醒（秒）
local hint_delay = 15 -- 装料后超过这么久还没动静就先提示一次（秒）
local drain_on_timeout = false -- true = 超时后把桌子里的东西抽回接口，免得一直占着桌子
local verbose = true -- 打印海龟原料和桌子内容（调试用，跑顺了可以改 false）

-- 海龟在有线网络上的名字（脚本启动时还会自动校正一次）
local turtle_inv = "turtle_1"
-- ==== AUTO GENERATED: BloodMagic-1.16.4-3.1.13-39.jar + E6E expert kubejs ====
-- need = 配方里每种原料出现的次数（= 要占几个格子）; nbt=true 的条目脚本分不清 NBT，不参与自动匹配
local TAG_ITEMS = {
    ["bloodmagic:arc/cuttingfluid"] = { ["bloodmagic:basiccuttingfluid"]=true, ["bloodmagic:intermediatecuttingfluid"]=true },
    ["forge:cobblestone"] = { ["atum:limestone_cracked"]=true, ["byg:cobbled_ether_stone"]=true, ["byg:dacite_cobblestone"]=true, ["byg:red_rock"]=true, ["byg:scoria_cobblestone"]=true, ["byg:soapstone"]=true, ["chipped:cobblestone_1"]=true, ["chipped:cobblestone_10"]=true, ["chipped:cobblestone_11"]=true, ["chipped:cobblestone_12"]=true, ["chipped:cobblestone_13"]=true, ["chipped:cobblestone_14"]=true, ["chipped:cobblestone_15"]=true, ["chipped:cobblestone_16"]=true, ["chipped:cobblestone_17"]=true, ["chipped:cobblestone_18"]=true, ["chipped:cobblestone_2"]=true, ["chipped:cobblestone_3"]=true, ["chipped:cobblestone_4"]=true, ["chipped:cobblestone_5"]=true, ["chipped:cobblestone_6"]=true, ["chipped:cobblestone_7"]=true, ["chipped:cobblestone_8"]=true, ["chipped:cobblestone_9"]=true, ["create:andesite_cobblestone"]=true, ["create:dark_scoria_cobblestone"]=true, ["create:diorite_cobblestone"]=true, ["create:dolomite_cobblestone"]=true, ["create:gabbro_cobblestone"]=true, ["create:granite_cobblestone"]=true, ["create:limestone_cobblestone"]=true, ["create:scoria_cobblestone"]=true, ["create:weathered_limestone_cobblestone"]=true, ["minecraft:cobblestone"]=true, ["quark:cobbedstone"]=true, ["quark:cobbled_deepslate"]=true, ["undergarden:depthrock"]=true, ["undergarden:shiverstone"]=true, ["undergarden:tremblecrust"]=true },
    ["forge:crops"] = { ["atum:emmer"]=true, ["atum:flax"]=true, ["byg:blueberries"]=true, ["byg:crimson_berries"]=true, ["byg:green_apple"]=true, ["farmersdelight:cabbage"]=true, ["farmersdelight:cabbage_leaf"]=true, ["farmersdelight:onion"]=true, ["farmersdelight:rice"]=true, ["farmersdelight:tomato"]=true, ["occultism:datura"]=true, ["simplefarming:barley"]=true, ["simplefarming:broccoli"]=true, ["simplefarming:cantaloupe"]=true, ["simplefarming:cassava"]=true, ["simplefarming:corn"]=true, ["simplefarming:cotton"]=true, ["simplefarming:cucumber"]=true, ["simplefarming:eggplant"]=true, ["simplefarming:ginger"]=true, ["simplefarming:honeydew"]=true, ["simplefarming:kenaf_fiber"]=true, ["simplefarming:lettuce"]=true, ["simplefarming:oat"]=true, ["simplefarming:onion"]=true, ["simplefarming:pea_pod"]=true, ["simplefarming:peanut"]=true, ["simplefarming:pepper"]=true, ["simplefarming:radish"]=true, ["simplefarming:rice"]=true, ["simplefarming:rye"]=true, ["simplefarming:sorghum"]=true, ["simplefarming:soybean"]=true, ["simplefarming:spinach"]=true, ["simplefarming:squash"]=true, ["simplefarming:sweet_potato"]=true, ["simplefarming:tomato"]=true, ["simplefarming:turnip"]=true, ["simplefarming:yam"]=true, ["simplefarming:zucchini"]=true, ["supplementaries:flax"]=true, ["sushigocrafting:cucumber"]=true, ["sushigocrafting:rice"]=true, ["sushigocrafting:sesame_seed"]=true, ["sushigocrafting:soy_bean"]=true, ["sushigocrafting:wasabi_root"]=true },
    ["forge:crops/nether_wart"] = { ["atum:anputs_fingers_spores"]=true },
    ["forge:crops/wheat"] = { ["simplefarming:barley"]=true, ["simplefarming:oat"]=true, ["simplefarming:rice"]=true, ["simplefarming:rye"]=true },
    ["forge:dusts/charcoal"] = { ["emendatusenigmatica:charcoal_dust"]=true, ["mekanism:dust_charcoal"]=true },
    ["forge:dusts/coal"] = { ["bloodmagic:coalsand"]=true, ["emendatusenigmatica:coal_dust"]=true, ["mekanism:dust_coal"]=true },
    ["forge:dusts/iron"] = { ["bloodmagic:ironsand"]=true, ["emendatusenigmatica:iron_dust"]=true, ["immersiveengineering:dust_iron"]=true, ["mekanism:dust_iron"]=true, ["occultism:iron_dust"]=true, ["pedestals:dustiron"]=true, ["thermal:iron_dust"]=true },
    ["forge:dusts/lapis"] = { ["emendatusenigmatica:lapis_dust"]=true, ["mekanism:dust_lapis_lazuli"]=true, ["thermal:lapis_dust"]=true },
    ["forge:dusts/obsidian"] = { ["emendatusenigmatica:obsidian_dust"]=true, ["mekanism:dust_obsidian"]=true, ["occultism:obsidian_dust"]=true },
    ["forge:dusts/regalium"] = { ["emendatusenigmatica:regalium_dust"]=true },
    ["forge:dusts/saltpeter"] = { ["bloodmagic:saltpeter"]=true, ["emendatusenigmatica:potassium_nitrate_dust"]=true, ["immersiveengineering:dust_saltpeter"]=true },
    ["forge:dusts/sulfur"] = { ["bloodmagic:sulfur"]=true, ["eidolon:sulfur"]=true, ["emendatusenigmatica:sulfur_dust"]=true, ["immersiveengineering:dust_sulfur"]=true, ["mekanism:dust_sulfur"]=true, ["thermal:sulfur_dust"]=true },
    ["forge:dyes/yellow"] = { ["mekanism:dust_sulfur"]=true },
    ["forge:glass"] = { ["chipped:acacia_wood_glass_1"]=true, ["chipped:acacia_wood_glass_2"]=true, ["chipped:acacia_wood_glass_3"]=true, ["chipped:acacia_wood_glass_4"]=true, ["chipped:acacia_wood_glass_5"]=true, ["chipped:acacia_wood_glass_6"]=true, ["chipped:birch_wood_glass_1"]=true, ["chipped:birch_wood_glass_2"]=true, ["chipped:birch_wood_glass_3"]=true, ["chipped:birch_wood_glass_4"]=true, ["chipped:birch_wood_glass_5"]=true, ["chipped:birch_wood_glass_6"]=true, ["chipped:black_stained_glass_1"]=true, ["chipped:black_stained_glass_2"]=true, ["chipped:black_stained_glass_3"]=true, ["chipped:black_stained_glass_4"]=true, ["chipped:black_stained_glass_5"]=true, ["chipped:black_stained_glass_6"]=true, ["chipped:black_stained_glass_7"]=true, ["chipped:black_stained_glass_8"]=true, ["chipped:black_stained_glass_pane_1"]=true, ["chipped:black_stained_glass_pane_2"]=true, ["chipped:black_stained_glass_pane_3"]=true, ["chipped:black_stained_glass_pane_4"]=true, ["chipped:black_stained_glass_pane_5"]=true, ["chipped:black_stained_glass_pane_6"]=true, ["chipped:black_stained_glass_pane_7"]=true, ["chipped:black_stained_glass_pane_8"]=true, ["chipped:blue_stained_glass_1"]=true, ["chipped:blue_stained_glass_2"]=true, ["chipped:blue_stained_glass_3"]=true, ["chipped:blue_stained_glass_4"]=true, ["chipped:blue_stained_glass_5"]=true, ["chipped:blue_stained_glass_6"]=true, ["chipped:blue_stained_glass_7"]=true, ["chipped:blue_stained_glass_8"]=true, ["chipped:blue_stained_glass_pane_1"]=true, ["chipped:blue_stained_glass_pane_2"]=true, ["chipped:blue_stained_glass_pane_3"]=true, ["chipped:blue_stained_glass_pane_4"]=true, ["chipped:blue_stained_glass_pane_5"]=true, ["chipped:blue_stained_glass_pane_6"]=true, ["chipped:blue_stained_glass_pane_7"]=true, ["chipped:blue_stained_glass_pane_8"]=true, ["chipped:brown_stained_glass_1"]=true, ["chipped:brown_stained_glass_2"]=true, ["chipped:brown_stained_glass_3"]=true, ["chipped:brown_stained_glass_4"]=true, ["chipped:brown_stained_glass_5"]=true, ["chipped:brown_stained_glass_6"]=true, ["chipped:brown_stained_glass_7"]=true, ["chipped:brown_stained_glass_8"]=true, ["chipped:brown_stained_glass_pane_1"]=true, ["chipped:brown_stained_glass_pane_2"]=true, ["chipped:brown_stained_glass_pane_3"]=true, ["chipped:brown_stained_glass_pane_4"]=true, ["chipped:brown_stained_glass_pane_5"]=true, ["chipped:brown_stained_glass_pane_6"]=true, ["chipped:brown_stained_glass_pane_7"]=true, ["chipped:brown_stained_glass_pane_8"]=true, ["chipped:crimson_wood_glass_1"]=true, ["chipped:crimson_wood_glass_2"]=true, ["chipped:crimson_wood_glass_3"]=true, ["chipped:crimson_wood_glass_4"]=true, ["chipped:crimson_wood_glass_5"]=true, ["chipped:crimson_wood_glass_6"]=true, ["chipped:cyan_stained_glass_1"]=true, ["chipped:cyan_stained_glass_2"]=true, ["chipped:cyan_stained_glass_3"]=true, ["chipped:cyan_stained_glass_4"]=true, ["chipped:cyan_stained_glass_5"]=true, ["chipped:cyan_stained_glass_6"]=true, ["chipped:cyan_stained_glass_7"]=true, ["chipped:cyan_stained_glass_8"]=true, ["chipped:cyan_stained_glass_pane_1"]=true, ["chipped:cyan_stained_glass_pane_2"]=true, ["chipped:cyan_stained_glass_pane_3"]=true, ["chipped:cyan_stained_glass_pane_4"]=true, ["chipped:cyan_stained_glass_pane_5"]=true, ["chipped:cyan_stained_glass_pane_6"]=true, ["chipped:cyan_stained_glass_pane_7"]=true, ["chipped:cyan_stained_glass_pane_8"]=true, ["chipped:dark_oak_wood_glass_1"]=true, ["chipped:dark_oak_wood_glass_2"]=true, ["chipped:dark_oak_wood_glass_3"]=true, ["chipped:dark_oak_wood_glass_4"]=true, ["chipped:dark_oak_wood_glass_5"]=true, ["chipped:dark_oak_wood_glass_6"]=true, ["chipped:glass_1"]=true, ["chipped:glass_10"]=true, ["chipped:glass_11"]=true, ["chipped:glass_12"]=true, ["chipped:glass_13"]=true, ["chipped:glass_14"]=true, ["chipped:glass_2"]=true, ["chipped:glass_3"]=true, ["chipped:glass_4"]=true, ["chipped:glass_5"]=true, ["chipped:glass_6"]=true, ["chipped:glass_7"]=true, ["chipped:glass_8"]=true, ["chipped:glass_9"]=true, ["chipped:gray_stained_glass_1"]=true, ["chipped:gray_stained_glass_2"]=true, ["chipped:gray_stained_glass_3"]=true, ["chipped:gray_stained_glass_4"]=true, ["chipped:gray_stained_glass_5"]=true, ["chipped:gray_stained_glass_6"]=true, ["chipped:gray_stained_glass_7"]=true, ["chipped:gray_stained_glass_8"]=true, ["chipped:gray_stained_glass_pane_1"]=true, ["chipped:gray_stained_glass_pane_2"]=true, ["chipped:gray_stained_glass_pane_3"]=true, ["chipped:gray_stained_glass_pane_4"]=true, ["chipped:gray_stained_glass_pane_5"]=true, ["chipped:gray_stained_glass_pane_6"]=true, ["chipped:gray_stained_glass_pane_7"]=true, ["chipped:gray_stained_glass_pane_8"]=true, ["chipped:green_stained_glass_1"]=true, ["chipped:green_stained_glass_2"]=true, ["chipped:green_stained_glass_3"]=true, ["chipped:green_stained_glass_4"]=true, ["chipped:green_stained_glass_5"]=true, ["chipped:green_stained_glass_6"]=true, ["chipped:green_stained_glass_7"]=true, ["chipped:green_stained_glass_8"]=true, ["chipped:green_stained_glass_pane_1"]=true, ["chipped:green_stained_glass_pane_2"]=true, ["chipped:green_stained_glass_pane_3"]=true, ["chipped:green_stained_glass_pane_4"]=true, ["chipped:green_stained_glass_pane_5"]=true, ["chipped:green_stained_glass_pane_6"]=true, ["chipped:green_stained_glass_pane_7"]=true, ["chipped:green_stained_glass_pane_8"]=true, ["chipped:jungle_wood_glass_1"]=true, ["chipped:jungle_wood_glass_2"]=true, ["chipped:jungle_wood_glass_3"]=true, ["chipped:jungle_wood_glass_4"]=true, ["chipped:jungle_wood_glass_5"]=true, ["chipped:jungle_wood_glass_6"]=true, ["chipped:light_blue_stained_glass_1"]=true, ["chipped:light_blue_stained_glass_2"]=true, ["chipped:light_blue_stained_glass_3"]=true, ["chipped:light_blue_stained_glass_4"]=true, ["chipped:light_blue_stained_glass_5"]=true, ["chipped:light_blue_stained_glass_6"]=true, ["chipped:light_blue_stained_glass_7"]=true, ["chipped:light_blue_stained_glass_8"]=true, ["chipped:light_blue_stained_glass_pane_1"]=true, ["chipped:light_blue_stained_glass_pane_2"]=true, ["chipped:light_blue_stained_glass_pane_3"]=true, ["chipped:light_blue_stained_glass_pane_4"]=true, ["chipped:light_blue_stained_glass_pane_5"]=true, ["chipped:light_blue_stained_glass_pane_6"]=true, ["chipped:light_blue_stained_glass_pane_7"]=true, ["chipped:light_blue_stained_glass_pane_8"]=true, ["chipped:light_gray_stained_glass_1"]=true, ["chipped:light_gray_stained_glass_2"]=true, ["chipped:light_gray_stained_glass_3"]=true, ["chipped:light_gray_stained_glass_4"]=true, ["chipped:light_gray_stained_glass_5"]=true, ["chipped:light_gray_stained_glass_6"]=true, ["chipped:light_gray_stained_glass_7"]=true, ["chipped:light_gray_stained_glass_8"]=true, ["chipped:light_gray_stained_glass_pane_1"]=true, ["chipped:light_gray_stained_glass_pane_2"]=true, ["chipped:light_gray_stained_glass_pane_3"]=true, ["chipped:light_gray_stained_glass_pane_4"]=true, ["chipped:light_gray_stained_glass_pane_5"]=true, ["chipped:light_gray_stained_glass_pane_6"]=true, ["chipped:light_gray_stained_glass_pane_7"]=true, ["chipped:light_gray_stained_glass_pane_8"]=true, ["chipped:lime_stained_glass_1"]=true, ["chipped:lime_stained_glass_2"]=true, ["chipped:lime_stained_glass_3"]=true, ["chipped:lime_stained_glass_4"]=true, ["chipped:lime_stained_glass_5"]=true, ["chipped:lime_stained_glass_6"]=true, ["chipped:lime_stained_glass_7"]=true, ["chipped:lime_stained_glass_8"]=true, ["chipped:lime_stained_glass_pane_1"]=true, ["chipped:lime_stained_glass_pane_2"]=true, ["chipped:lime_stained_glass_pane_3"]=true, ["chipped:lime_stained_glass_pane_4"]=true, ["chipped:lime_stained_glass_pane_5"]=true, ["chipped:lime_stained_glass_pane_6"]=true, ["chipped:lime_stained_glass_pane_7"]=true, ["chipped:lime_stained_glass_pane_8"]=true, ["chipped:magenta_stained_glass_1"]=true, ["chipped:magenta_stained_glass_2"]=true, ["chipped:magenta_stained_glass_3"]=true, ["chipped:magenta_stained_glass_4"]=true, ["chipped:magenta_stained_glass_5"]=true, ["chipped:magenta_stained_glass_6"]=true, ["chipped:magenta_stained_glass_7"]=true, ["chipped:magenta_stained_glass_8"]=true, ["chipped:magenta_stained_glass_pane_1"]=true, ["chipped:magenta_stained_glass_pane_2"]=true, ["chipped:magenta_stained_glass_pane_3"]=true, ["chipped:magenta_stained_glass_pane_4"]=true, ["chipped:magenta_stained_glass_pane_5"]=true, ["chipped:magenta_stained_glass_pane_6"]=true, ["chipped:magenta_stained_glass_pane_7"]=true, ["chipped:magenta_stained_glass_pane_8"]=true, ["chipped:oak_wood_glass_1"]=true, ["chipped:oak_wood_glass_2"]=true, ["chipped:oak_wood_glass_3"]=true, ["chipped:oak_wood_glass_4"]=true, ["chipped:oak_wood_glass_5"]=true, ["chipped:oak_wood_glass_6"]=true, ["chipped:orange_stained_glass_1"]=true, ["chipped:orange_stained_glass_2"]=true, ["chipped:orange_stained_glass_3"]=true, ["chipped:orange_stained_glass_4"]=true, ["chipped:orange_stained_glass_5"]=true, ["chipped:orange_stained_glass_6"]=true, ["chipped:orange_stained_glass_7"]=true, ["chipped:orange_stained_glass_8"]=true, ["chipped:orange_stained_glass_pane_1"]=true, ["chipped:orange_stained_glass_pane_2"]=true, ["chipped:orange_stained_glass_pane_3"]=true, ["chipped:orange_stained_glass_pane_4"]=true, ["chipped:orange_stained_glass_pane_5"]=true, ["chipped:orange_stained_glass_pane_6"]=true, ["chipped:orange_stained_glass_pane_7"]=true, ["chipped:orange_stained_glass_pane_8"]=true, ["chipped:pink_stained_glass_1"]=true, ["chipped:pink_stained_glass_2"]=true, ["chipped:pink_stained_glass_3"]=true, ["chipped:pink_stained_glass_4"]=true, ["chipped:pink_stained_glass_5"]=true, ["chipped:pink_stained_glass_6"]=true, ["chipped:pink_stained_glass_7"]=true, ["chipped:pink_stained_glass_8"]=true, ["chipped:pink_stained_glass_pane_1"]=true, ["chipped:pink_stained_glass_pane_2"]=true, ["chipped:pink_stained_glass_pane_3"]=true, ["chipped:pink_stained_glass_pane_4"]=true, ["chipped:pink_stained_glass_pane_5"]=true, ["chipped:pink_stained_glass_pane_6"]=true, ["chipped:pink_stained_glass_pane_7"]=true, ["chipped:pink_stained_glass_pane_8"]=true, ["chipped:purple_stained_glass_1"]=true, ["chipped:purple_stained_glass_2"]=true, ["chipped:purple_stained_glass_3"]=true, ["chipped:purple_stained_glass_4"]=true, ["chipped:purple_stained_glass_5"]=true, ["chipped:purple_stained_glass_6"]=true, ["chipped:purple_stained_glass_7"]=true, ["chipped:purple_stained_glass_8"]=true, ["chipped:purple_stained_glass_pane_1"]=true, ["chipped:purple_stained_glass_pane_2"]=true, ["chipped:purple_stained_glass_pane_3"]=true, ["chipped:purple_stained_glass_pane_4"]=true, ["chipped:purple_stained_glass_pane_5"]=true, ["chipped:purple_stained_glass_pane_6"]=true, ["chipped:purple_stained_glass_pane_7"]=true, ["chipped:purple_stained_glass_pane_8"]=true, ["chipped:red_stained_glass_1"]=true, ["chipped:red_stained_glass_2"]=true, ["chipped:red_stained_glass_3"]=true, ["chipped:red_stained_glass_4"]=true, ["chipped:red_stained_glass_5"]=true, ["chipped:red_stained_glass_6"]=true, ["chipped:red_stained_glass_7"]=true, ["chipped:red_stained_glass_8"]=true, ["chipped:red_stained_glass_pane_1"]=true, ["chipped:red_stained_glass_pane_2"]=true, ["chipped:red_stained_glass_pane_3"]=true, ["chipped:red_stained_glass_pane_4"]=true, ["chipped:red_stained_glass_pane_5"]=true, ["chipped:red_stained_glass_pane_6"]=true, ["chipped:red_stained_glass_pane_7"]=true, ["chipped:red_stained_glass_pane_8"]=true, ["chipped:spruce_wood_glass_1"]=true, ["chipped:spruce_wood_glass_2"]=true, ["chipped:spruce_wood_glass_3"]=true, ["chipped:spruce_wood_glass_4"]=true, ["chipped:spruce_wood_glass_5"]=true, ["chipped:spruce_wood_glass_6"]=true, ["chipped:warped_wood_glass_1"]=true, ["chipped:warped_wood_glass_2"]=true, ["chipped:warped_wood_glass_3"]=true, ["chipped:warped_wood_glass_4"]=true, ["chipped:warped_wood_glass_5"]=true, ["chipped:warped_wood_glass_6"]=true, ["chipped:white_stained_glass_1"]=true, ["chipped:white_stained_glass_2"]=true, ["chipped:white_stained_glass_3"]=true, ["chipped:white_stained_glass_4"]=true, ["chipped:white_stained_glass_5"]=true, ["chipped:white_stained_glass_6"]=true, ["chipped:white_stained_glass_7"]=true, ["chipped:white_stained_glass_8"]=true, ["chipped:white_stained_glass_pane_1"]=true, ["chipped:white_stained_glass_pane_2"]=true, ["chipped:white_stained_glass_pane_3"]=true, ["chipped:white_stained_glass_pane_4"]=true, ["chipped:white_stained_glass_pane_5"]=true, ["chipped:white_stained_glass_pane_6"]=true, ["chipped:white_stained_glass_pane_7"]=true, ["chipped:white_stained_glass_pane_8"]=true, ["chipped:yellow_stained_glass_1"]=true, ["chipped:yellow_stained_glass_2"]=true, ["chipped:yellow_stained_glass_3"]=true, ["chipped:yellow_stained_glass_4"]=true, ["chipped:yellow_stained_glass_5"]=true, ["chipped:yellow_stained_glass_6"]=true, ["chipped:yellow_stained_glass_7"]=true, ["chipped:yellow_stained_glass_8"]=true, ["chipped:yellow_stained_glass_pane_1"]=true, ["chipped:yellow_stained_glass_pane_2"]=true, ["chipped:yellow_stained_glass_pane_3"]=true, ["chipped:yellow_stained_glass_pane_4"]=true, ["chipped:yellow_stained_glass_pane_5"]=true, ["chipped:yellow_stained_glass_pane_6"]=true, ["chipped:yellow_stained_glass_pane_7"]=true, ["chipped:yellow_stained_glass_pane_8"]=true, ["connectedglass:borderless_glass"]=true, ["connectedglass:borderless_glass_black"]=true, ["connectedglass:borderless_glass_blue"]=true, ["connectedglass:borderless_glass_brown"]=true, ["connectedglass:borderless_glass_cyan"]=true, ["connectedglass:borderless_glass_gray"]=true, ["connectedglass:borderless_glass_green"]=true, ["connectedglass:borderless_glass_light_blue"]=true, ["connectedglass:borderless_glass_light_gray"]=true, ["connectedglass:borderless_glass_lime"]=true, ["connectedglass:borderless_glass_magenta"]=true, ["connectedglass:borderless_glass_orange"]=true, ["connectedglass:borderless_glass_pink"]=true, ["connectedglass:borderless_glass_purple"]=true, ["connectedglass:borderless_glass_red"]=true, ["connectedglass:borderless_glass_white"]=true, ["connectedglass:borderless_glass_yellow"]=true, ["connectedglass:clear_glass"]=true, ["connectedglass:clear_glass_black"]=true, ["connectedglass:clear_glass_blue"]=true, ["connectedglass:clear_glass_brown"]=true, ["connectedglass:clear_glass_cyan"]=true, ["connectedglass:clear_glass_gray"]=true, ["connectedglass:clear_glass_green"]=true, ["connectedglass:clear_glass_light_blue"]=true, ["connectedglass:clear_glass_light_gray"]=true, ["connectedglass:clear_glass_lime"]=true, ["connectedglass:clear_glass_magenta"]=true, ["connectedglass:clear_glass_orange"]=true, ["connectedglass:clear_glass_pink"]=true, ["connectedglass:clear_glass_purple"]=true, ["connectedglass:clear_glass_red"]=true, ["connectedglass:clear_glass_white"]=true, ["connectedglass:clear_glass_yellow"]=true, ["connectedglass:scratched_glass"]=true, ["connectedglass:scratched_glass_black"]=true, ["connectedglass:scratched_glass_blue"]=true, ["connectedglass:scratched_glass_brown"]=true, ["connectedglass:scratched_glass_cyan"]=true, ["connectedglass:scratched_glass_gray"]=true, ["connectedglass:scratched_glass_green"]=true, ["connectedglass:scratched_glass_light_blue"]=true, ["connectedglass:scratched_glass_light_gray"]=true, ["connectedglass:scratched_glass_lime"]=true, ["connectedglass:scratched_glass_magenta"]=true, ["connectedglass:scratched_glass_orange"]=true, ["connectedglass:scratched_glass_pink"]=true, ["connectedglass:scratched_glass_purple"]=true, ["connectedglass:scratched_glass_red"]=true, ["connectedglass:scratched_glass_white"]=true, ["connectedglass:scratched_glass_yellow"]=true, ["connectedglass:tinted_borderless_glass"]=true, ["connectedglass:tinted_borderless_glass_black"]=true, ["connectedglass:tinted_borderless_glass_blue"]=true, ["connectedglass:tinted_borderless_glass_brown"]=true, ["connectedglass:tinted_borderless_glass_cyan"]=true, ["connectedglass:tinted_borderless_glass_gray"]=true, ["connectedglass:tinted_borderless_glass_green"]=true, ["connectedglass:tinted_borderless_glass_light_blue"]=true, ["connectedglass:tinted_borderless_glass_light_gray"]=true, ["connectedglass:tinted_borderless_glass_lime"]=true, ["connectedglass:tinted_borderless_glass_magenta"]=true, ["connectedglass:tinted_borderless_glass_orange"]=true, ["connectedglass:tinted_borderless_glass_pink"]=true, ["connectedglass:tinted_borderless_glass_purple"]=true, ["connectedglass:tinted_borderless_glass_red"]=true, ["connectedglass:tinted_borderless_glass_white"]=true, ["connectedglass:tinted_borderless_glass_yellow"]=true, ["connectedglass:tinted_glass"]=true, ["darkutils:dark_glass"]=true, ["minecraft:black_stained_glass"]=true, ["minecraft:black_stained_glass_pane"]=true, ["minecraft:blue_stained_glass"]=true, ["minecraft:blue_stained_glass_pane"]=true, ["minecraft:brown_stained_glass"]=true, ["minecraft:brown_stained_glass_pane"]=true, ["minecraft:cyan_stained_glass"]=true, ["minecraft:cyan_stained_glass_pane"]=true, ["minecraft:glass"]=true, ["minecraft:gray_stained_glass"]=true, ["minecraft:gray_stained_glass_pane"]=true, ["minecraft:green_stained_glass"]=true, ["minecraft:green_stained_glass_pane"]=true, ["minecraft:light_blue_stained_glass"]=true, ["minecraft:light_blue_stained_glass_pane"]=true, ["minecraft:light_gray_stained_glass"]=true, ["minecraft:light_gray_stained_glass_pane"]=true, ["minecraft:lime_stained_glass"]=true, ["minecraft:lime_stained_glass_pane"]=true, ["minecraft:magenta_stained_glass"]=true, ["minecraft:magenta_stained_glass_pane"]=true, ["minecraft:orange_stained_glass"]=true, ["minecraft:orange_stained_glass_pane"]=true, ["minecraft:pink_stained_glass"]=true, ["minecraft:pink_stained_glass_pane"]=true, ["minecraft:purple_stained_glass"]=true, ["minecraft:purple_stained_glass_pane"]=true, ["minecraft:red_stained_glass"]=true, ["minecraft:red_stained_glass_pane"]=true, ["minecraft:white_stained_glass"]=true, ["minecraft:white_stained_glass_pane"]=true, ["minecraft:yellow_stained_glass"]=true, ["minecraft:yellow_stained_glass_pane"]=true, ["quark:black_framed_glass"]=true, ["quark:blue_framed_glass"]=true, ["quark:brown_framed_glass"]=true, ["quark:cyan_framed_glass"]=true, ["quark:dirty_glass"]=true, ["quark:framed_glass"]=true, ["quark:gray_framed_glass"]=true, ["quark:green_framed_glass"]=true, ["quark:light_blue_framed_glass"]=true, ["quark:light_gray_framed_glass"]=true, ["quark:lime_framed_glass"]=true, ["quark:magenta_framed_glass"]=true, ["quark:orange_framed_glass"]=true, ["quark:pink_framed_glass"]=true, ["quark:purple_framed_glass"]=true, ["quark:red_framed_glass"]=true, ["quark:white_framed_glass"]=true, ["quark:yellow_framed_glass"]=true, ["resourcefulbees:honey_glass"]=true, ["resourcefulbees:honey_glass_player"]=true, ["undergarden:sediment_glass"]=true, ["valhelsia_structures:metal_framed_glass"]=true },
    ["forge:ingots"] = { ["@{id=astralsorcery:starmetal_ingot; required=False}"]=true, ["@{id=create:refined_radiance; required=False}"]=true, ["@{id=create:shadow_steel; required=False}"]=true, ["@{id=industrialforegoing:pink_slime_ingot; required=False}"]=true, ["@{id=mythicbotany:alfsteel_ingot; required=False}"]=true, ["@{id=redstone_arsenal:flux_ingot; required=False}"]=true, ["aquaculture:neptunium_ingot"]=true, ["architects_palette:sunmetal_brick"]=true, ["astralsorcery:starmetal_ingot"]=true, ["atum:khnumite"]=true, ["atum:nebu_ingot"]=true, ["betterendforge:aeternium_ingot"]=true, ["betterendforge:terminite_ingot"]=true, ["betterendforge:thallasium_ingot"]=true, ["bloodmagic:ingot_hellforged"]=true, ["botania:elementium_ingot"]=true, ["botania:gaia_ingot"]=true, ["botania:manasteel_ingot"]=true, ["botania:terrasteel_ingot"]=true, ["byg:blue_nether_brick"]=true, ["byg:yellow_nether_brick"]=true, ["create:andesite_alloy"]=true, ["create:brass_ingot"]=true, ["create:copper_ingot"]=true, ["create:zinc_ingot"]=true, ["eidolon:arcane_gold_ingot"]=true, ["eidolon:lead_ingot"]=true, ["eidolon:pewter_ingot"]=true, ["emendatusenigmatica:aluminum_ingot"]=true, ["emendatusenigmatica:brass_ingot"]=true, ["emendatusenigmatica:bronze_ingot"]=true, ["emendatusenigmatica:cast_iron_ingot"]=true, ["emendatusenigmatica:cobalt_ingot"]=true, ["emendatusenigmatica:constantan_ingot"]=true, ["emendatusenigmatica:copper_ingot"]=true, ["emendatusenigmatica:electrum_ingot"]=true, ["emendatusenigmatica:enderium_ingot"]=true, ["emendatusenigmatica:invar_ingot"]=true, ["emendatusenigmatica:iridium_ingot"]=true, ["emendatusenigmatica:lead_ingot"]=true, ["emendatusenigmatica:lumium_ingot"]=true, ["emendatusenigmatica:nickel_ingot"]=true, ["emendatusenigmatica:osmium_ingot"]=true, ["emendatusenigmatica:signalum_ingot"]=true, ["emendatusenigmatica:silver_ingot"]=true, ["emendatusenigmatica:steel_ingot"]=true, ["emendatusenigmatica:tin_ingot"]=true, ["emendatusenigmatica:uranium_ingot"]=true, ["emendatusenigmatica:zinc_ingot"]=true, ["immersiveengineering:ingot_aluminum"]=true, ["immersiveengineering:ingot_constantan"]=true, ["immersiveengineering:ingot_copper"]=true, ["immersiveengineering:ingot_electrum"]=true, ["immersiveengineering:ingot_hop_graphite"]=true, ["immersiveengineering:ingot_lead"]=true, ["immersiveengineering:ingot_nickel"]=true, ["immersiveengineering:ingot_silver"]=true, ["immersiveengineering:ingot_steel"]=true, ["immersiveengineering:ingot_uranium"]=true, ["industrialforegoing:pink_slime_ingot"]=true, ["kubejs:hot_compressed_iron_ingot"]=true, ["kubejs:superheated_steel_ingot"]=true, ["materialis:fairy_ingot"]=true, ["mekanism:ingot_bronze"]=true, ["mekanism:ingot_copper"]=true, ["mekanism:ingot_lead"]=true, ["mekanism:ingot_osmium"]=true, ["mekanism:ingot_refined_glowstone"]=true, ["mekanism:ingot_refined_obsidian"]=true, ["mekanism:ingot_steel"]=true, ["mekanism:ingot_tin"]=true, ["mekanism:ingot_uranium"]=true, ["minecraft:netherite_scrap"]=true, ["mythicbotany:alfsteel_ingot"]=true, ["naturesaura:infused_iron"]=true, ["naturesaura:sky_ingot"]=true, ["naturesaura:tainted_gold"]=true, ["occultism:copper_ingot"]=true, ["occultism:iesnium_ingot"]=true, ["occultism:silver_ingot"]=true, ["pneumaticcraft:ingot_iron_compressed"]=true, ["powah:steel_energized"]=true, ["powah:uraninite"]=true, ["tconstruct:cobalt_ingot"]=true, ["tconstruct:copper_ingot"]=true, ["tconstruct:hepatizon_ingot"]=true, ["tconstruct:knightslime_ingot"]=true, ["tconstruct:manyullyn_ingot"]=true, ["tconstruct:pig_iron_ingot"]=true, ["tconstruct:queens_slime_ingot"]=true, ["tconstruct:rose_gold_ingot"]=true, ["tconstruct:scorched_brick"]=true, ["tconstruct:seared_brick"]=true, ["tconstruct:slimesteel_ingot"]=true, ["tconstruct:soulsteel_ingot"]=true, ["tconstruct:tinkers_bronze_ingot"]=true, ["thermal:bronze_ingot"]=true, ["thermal:constantan_ingot"]=true, ["thermal:copper_ingot"]=true, ["thermal:electrum_ingot"]=true, ["thermal:enderium_ingot"]=true, ["thermal:invar_ingot"]=true, ["thermal:lead_ingot"]=true, ["thermal:lumium_ingot"]=true, ["thermal:nickel_ingot"]=true, ["thermal:signalum_ingot"]=true, ["thermal:silver_ingot"]=true, ["thermal:tin_ingot"]=true, ["undergarden:cloggrum_ingot"]=true, ["undergarden:forgotten_ingot"]=true, ["undergarden:froststeel_ingot"]=true, ["undergarden:regalium_ingot"]=true, ["undergarden:utherium_ingot"]=true },
    ["forge:ingots/silicon_bronze"] = { ["tconstruct:tinkers_bronze_ingot"]=true },
    ["forge:ingots/utherium"] = { ["undergarden:utherium_ingot"]=true },
    ["forge:mushrooms"] = { ["betterendforge:bolux_mushroom"]=true, ["betterendforge:chorus_mushroom_raw"]=true, ["betterendforge:mossy_glowshroom_sapling"]=true, ["betterendforge:small_jellyshroom"]=true, ["betterendforge:umbrella_tree_sapling"]=true, ["botania:black_mushroom"]=true, ["botania:blue_mushroom"]=true, ["botania:brown_mushroom"]=true, ["botania:cyan_mushroom"]=true, ["botania:gray_mushroom"]=true, ["botania:green_mushroom"]=true, ["botania:light_blue_mushroom"]=true, ["botania:light_gray_mushroom"]=true, ["botania:lime_mushroom"]=true, ["botania:magenta_mushroom"]=true, ["botania:orange_mushroom"]=true, ["botania:pink_mushroom"]=true, ["botania:purple_mushroom"]=true, ["botania:red_mushroom"]=true, ["botania:white_mushroom"]=true, ["botania:yellow_mushroom"]=true, ["byg:black_puff"]=true, ["byg:blue_glowshroom"]=true, ["byg:death_cap"]=true, ["byg:embur_wart"]=true, ["byg:fungal_imparius"]=true, ["byg:green_mushroom"]=true, ["byg:imparius_mushroom"]=true, ["byg:purple_glowshroom"]=true, ["byg:shulkren_fungus"]=true, ["byg:soul_shroom"]=true, ["byg:soul_shroom_spore_end"]=true, ["byg:sythian_fungus"]=true, ["byg:weeping_milkcap"]=true, ["byg:wood_blewit"]=true, ["minecraft:brown_mushroom"]=true, ["minecraft:red_mushroom"]=true, ["projectvibrantjourneys:bark_mushroom"]=true, ["projectvibrantjourneys:glowcap"]=true, ["quark:glowshroom"]=true, ["undergarden:blood_mushroom"]=true, ["undergarden:indigo_mushroom"]=true, ["undergarden:ink_mushroom"]=true, ["undergarden:veil_mushroom"]=true },
    ["forge:nuggets/aluminum"] = { ["emendatusenigmatica:aluminum_nugget"]=true, ["immersiveengineering:nugget_aluminum"]=true },
    ["forge:nuggets/cloggrum"] = { ["undergarden:cloggrum_nugget"]=true },
    ["forge:nuggets/froststeel"] = { ["undergarden:froststeel_nugget"]=true },
    ["forge:nuggets/regalium"] = { ["undergarden:regalium_nugget"]=true },
    ["forge:nuggets/silver"] = { ["emendatusenigmatica:silver_nugget"]=true, ["immersiveengineering:nugget_silver"]=true, ["occultism:silver_nugget"]=true, ["thermal:silver_nugget"]=true },
    ["forge:nuggets/uranium"] = { ["emendatusenigmatica:uranium_nugget"]=true, ["immersiveengineering:nugget_uranium"]=true, ["mekanism:nugget_uranium"]=true },
    ["forge:ores/gold"] = { ["byg:blue_nether_gold_ore"]=true, ["byg:brimstone_nether_gold_ore"]=true, ["emendatusenigmatica:gold_andesite_ore"]=true, ["emendatusenigmatica:gold_basalt_ore"]=true, ["emendatusenigmatica:gold_blackstone_ore"]=true, ["emendatusenigmatica:gold_blue_netherrack_ore"]=true, ["emendatusenigmatica:gold_brimstone_ore"]=true, ["emendatusenigmatica:gold_c_limestone_ore"]=true, ["emendatusenigmatica:gold_chunk"]=true, ["emendatusenigmatica:gold_cryptic_stone_ore"]=true, ["emendatusenigmatica:gold_deepslate_ore"]=true, ["emendatusenigmatica:gold_diorite_ore"]=true, ["emendatusenigmatica:gold_end_stone_ore"]=true, ["emendatusenigmatica:gold_ether_stone_ore"]=true, ["emendatusenigmatica:gold_flavolite_ore"]=true, ["emendatusenigmatica:gold_gabbro_ore"]=true, ["emendatusenigmatica:gold_granite_ore"]=true, ["emendatusenigmatica:gold_gravel_ore"]=true, ["emendatusenigmatica:gold_jasper_ore"]=true, ["emendatusenigmatica:gold_marble_ore"]=true, ["emendatusenigmatica:gold_mossy_stone_ore"]=true, ["emendatusenigmatica:gold_netherrack_ore"]=true, ["emendatusenigmatica:gold_nylium_soul_soil_ore"]=true, ["emendatusenigmatica:gold_ore"]=true, ["emendatusenigmatica:gold_raw_marble_ore"]=true, ["emendatusenigmatica:gold_sand_ore"]=true, ["emendatusenigmatica:gold_scoria_ore"]=true, ["emendatusenigmatica:gold_slate_ore"]=true, ["emendatusenigmatica:gold_soul_soil_ore"]=true, ["emendatusenigmatica:gold_subzero_ash_ore"]=true, ["emendatusenigmatica:gold_sulphuric_rock_ore"]=true, ["emendatusenigmatica:gold_violecite_ore"]=true, ["emendatusenigmatica:gold_weathered_limestone_ore"]=true },
    ["forge:ores/iron"] = { ["atum:iron_ore"]=true, ["emendatusenigmatica:iron_andesite_ore"]=true, ["emendatusenigmatica:iron_basalt_ore"]=true, ["emendatusenigmatica:iron_blackstone_ore"]=true, ["emendatusenigmatica:iron_blue_netherrack_ore"]=true, ["emendatusenigmatica:iron_brimstone_ore"]=true, ["emendatusenigmatica:iron_c_limestone_ore"]=true, ["emendatusenigmatica:iron_chunk"]=true, ["emendatusenigmatica:iron_cryptic_stone_ore"]=true, ["emendatusenigmatica:iron_deepslate_ore"]=true, ["emendatusenigmatica:iron_diorite_ore"]=true, ["emendatusenigmatica:iron_end_stone_ore"]=true, ["emendatusenigmatica:iron_ether_stone_ore"]=true, ["emendatusenigmatica:iron_flavolite_ore"]=true, ["emendatusenigmatica:iron_gabbro_ore"]=true, ["emendatusenigmatica:iron_granite_ore"]=true, ["emendatusenigmatica:iron_gravel_ore"]=true, ["emendatusenigmatica:iron_jasper_ore"]=true, ["emendatusenigmatica:iron_marble_ore"]=true, ["emendatusenigmatica:iron_mossy_stone_ore"]=true, ["emendatusenigmatica:iron_netherrack_ore"]=true, ["emendatusenigmatica:iron_nylium_soul_soil_ore"]=true, ["emendatusenigmatica:iron_ore"]=true, ["emendatusenigmatica:iron_raw_marble_ore"]=true, ["emendatusenigmatica:iron_sand_ore"]=true, ["emendatusenigmatica:iron_scoria_ore"]=true, ["emendatusenigmatica:iron_slate_ore"]=true, ["emendatusenigmatica:iron_soul_soil_ore"]=true, ["emendatusenigmatica:iron_subzero_ash_ore"]=true, ["emendatusenigmatica:iron_sulphuric_rock_ore"]=true, ["emendatusenigmatica:iron_violecite_ore"]=true, ["emendatusenigmatica:iron_weathered_limestone_ore"]=true, ["undergarden:iron_ore"]=true },
    ["forge:rods/blaze"] = { ["atum:efreet_heart"]=true },
    ["forge:sand"] = { ["byg:black_sand"]=true, ["byg:blue_sand"]=true, ["byg:end_sand"]=true, ["byg:pink_sand"]=true, ["byg:purple_sand"]=true, ["byg:white_sand"]=true },
    ["forge:shards/ender"] = { ["betterendforge:ender_shard"]=true },
    ["forge:slimeballs"] = { ["betterendforge:gelatine"]=true, ["byg:embur_gel_ball"]=true, ["industrialforegoing:pink_slime"]=true, ["minecraft:slime_ball"]=true, ["tconstruct:blood_slime_ball"]=true, ["tconstruct:ender_slime_ball"]=true, ["tconstruct:ichor_slime_ball"]=true, ["tconstruct:sky_slime_ball"]=true, ["undergarden:goo_ball"]=true },
    ["forge:stone"] = { ["architects_palette:limestone"]=true, ["atum:limestone"]=true, ["betterendforge:azure_jadestone"]=true, ["betterendforge:flavolite"]=true, ["betterendforge:sandy_jadestone"]=true, ["betterendforge:sulphuric_rock"]=true, ["betterendforge:violecite"]=true, ["betterendforge:virid_jadestone"]=true, ["byg:dacite"]=true, ["byg:ether_stone"]=true, ["byg:mossy_stone"]=true, ["byg:overgrown_dacite"]=true, ["byg:overgrown_stone"]=true, ["byg:podzol_dacite"]=true, ["byg:red_rock"]=true, ["byg:rocky_stone"]=true, ["byg:scoria_stone"]=true, ["byg:soapstone"]=true, ["byg:sythian_nylium"]=true, ["chipped:andesite_1"]=true, ["chipped:andesite_10"]=true, ["chipped:andesite_11"]=true, ["chipped:andesite_12"]=true, ["chipped:andesite_13"]=true, ["chipped:andesite_14"]=true, ["chipped:andesite_15"]=true, ["chipped:andesite_16"]=true, ["chipped:andesite_17"]=true, ["chipped:andesite_18"]=true, ["chipped:andesite_2"]=true, ["chipped:andesite_3"]=true, ["chipped:andesite_4"]=true, ["chipped:andesite_5"]=true, ["chipped:andesite_6"]=true, ["chipped:andesite_7"]=true, ["chipped:andesite_8"]=true, ["chipped:andesite_9"]=true, ["chipped:diorite_1"]=true, ["chipped:diorite_10"]=true, ["chipped:diorite_11"]=true, ["chipped:diorite_12"]=true, ["chipped:diorite_13"]=true, ["chipped:diorite_14"]=true, ["chipped:diorite_15"]=true, ["chipped:diorite_16"]=true, ["chipped:diorite_17"]=true, ["chipped:diorite_18"]=true, ["chipped:diorite_2"]=true, ["chipped:diorite_3"]=true, ["chipped:diorite_4"]=true, ["chipped:diorite_5"]=true, ["chipped:diorite_6"]=true, ["chipped:diorite_7"]=true, ["chipped:diorite_8"]=true, ["chipped:diorite_9"]=true, ["chipped:granite_1"]=true, ["chipped:granite_10"]=true, ["chipped:granite_11"]=true, ["chipped:granite_12"]=true, ["chipped:granite_13"]=true, ["chipped:granite_14"]=true, ["chipped:granite_15"]=true, ["chipped:granite_16"]=true, ["chipped:granite_17"]=true, ["chipped:granite_18"]=true, ["chipped:granite_2"]=true, ["chipped:granite_3"]=true, ["chipped:granite_4"]=true, ["chipped:granite_5"]=true, ["chipped:granite_6"]=true, ["chipped:granite_7"]=true, ["chipped:granite_8"]=true, ["chipped:granite_9"]=true, ["chipped:stone_1"]=true, ["chipped:stone_10"]=true, ["chipped:stone_11"]=true, ["chipped:stone_12"]=true, ["chipped:stone_13"]=true, ["chipped:stone_14"]=true, ["chipped:stone_15"]=true, ["chipped:stone_16"]=true, ["chipped:stone_17"]=true, ["chipped:stone_18"]=true, ["chipped:stone_2"]=true, ["chipped:stone_3"]=true, ["chipped:stone_4"]=true, ["chipped:stone_5"]=true, ["chipped:stone_6"]=true, ["chipped:stone_7"]=true, ["chipped:stone_8"]=true, ["chipped:stone_9"]=true, ["create:dark_scoria"]=true, ["create:dolomite"]=true, ["create:gabbro"]=true, ["create:limestone"]=true, ["create:polished_dark_scoria"]=true, ["create:polished_dolomite"]=true, ["create:polished_gabbro"]=true, ["create:polished_limestone"]=true, ["create:polished_scoria"]=true, ["create:polished_weathered_limestone"]=true, ["create:scoria"]=true, ["create:weathered_limestone"]=true, ["masonry:stonecarvedcreeper"]=true, ["masonry:stonecarvedderp"]=true, ["masonry:stonecarvedvillager"]=true, ["masonry:stonecarvedwither"]=true, ["masonry:stonecarvedwriting"]=true, ["masonry:stonecolumn"]=true, ["masonry:stonecut"]=true, ["masonry:stonediamondpavers"]=true, ["masonry:stoneengraved"]=true, ["masonry:stonepanels"]=true, ["masonry:stonepavers"]=true, ["masonry:stonepillar"]=true, ["masonry:stonepolished"]=true, ["masonry:stoneroughcut"]=true, ["masonry:stonetiled"]=true, ["minecraft:andesite"]=true, ["minecraft:diorite"]=true, ["minecraft:granite"]=true, ["minecraft:stone"]=true, ["pneumaticcraft:compressed_stone"]=true, ["pneumaticcraft:reinforced_stone"]=true, ["quark:basalt"]=true, ["quark:brimstone"]=true, ["quark:jasper"]=true, ["quark:limestone"]=true, ["quark:marble"]=true, ["quark:myalite"]=true, ["quark:permafrost"]=true, ["quark:polished_basalt"]=true, ["quark:polished_jasper"]=true, ["quark:polished_limestone"]=true, ["quark:polished_marble"]=true, ["quark:polished_myalite"]=true, ["quark:polished_slate"]=true, ["quark:slate"]=true, ["undergarden:depthrock"]=true, ["undergarden:shiverstone"]=true, ["undergarden:tremblecrust"]=true },
    ["forge:string"] = { ["atum:linen_thread"]=true, ["undergarden:twistytwig"]=true },
    ["minecraft:coals"] = { ["byg:anthracite"]=true, ["byg:lignite"]=true, ["emendatusenigmatica:bitumen_gem"]=true, ["immersivepetroleum:bitumen"]=true, ["minecraft:charcoal"]=true, ["minecraft:coal"]=true, ["thermal:bitumen"]=true, ["undergarden:ditchbulb"]=true },
    ["minecraft:leaves"] = { ["/ars_nouveau:\w+_leaves/"]=true, ["architects_palette:twisted_leaves"]=true, ["atmospheric:aspen_leaves"]=true, ["atmospheric:flowering_morado_leaves"]=true, ["atmospheric:grimwood_leaves"]=true, ["atmospheric:kousa_leaves"]=true, ["atmospheric:morado_leaves"]=true, ["atmospheric:rosewood_leaves"]=true, ["atmospheric:yucca_leaves"]=true, ["atum:palm_leaves"]=true, ["betterendforge:dragon_tree_leaves"]=true, ["betterendforge:lacugrove_leaves"]=true, ["betterendforge:lucernia_leaves"]=true, ["betterendforge:pythadendron_leaves"]=true, ["betterendforge:tenanea_leaves"]=true, ["byg:araucaria_leaves"]=true, ["byg:aspen_leaves"]=true, ["byg:baobab_leaves"]=true, ["byg:blooming_witch_hazel_leaves"]=true, ["byg:blue_enchanted_leaves"]=true, ["byg:blue_spruce_leaves"]=true, ["byg:brown_birch_leaves"]=true, ["byg:brown_oak_leaves"]=true, ["byg:brown_zelkova_leaves"]=true, ["byg:cika_leaves"]=true, ["byg:cypress_leaves"]=true, ["byg:ebony_leaves"]=true, ["byg:ether_leaves"]=true, ["byg:fir_leaves"]=true, ["byg:flowering_indigo_jacaranda_leaves"]=true, ["byg:flowering_jacaranda_leaves"]=true, ["byg:flowering_nightshade_leaves"]=true, ["byg:flowering_orchard_leaves"]=true, ["byg:flowering_palo_verde_leaves"]=true, ["byg:green_apple_skyris_leaves"]=true, ["byg:green_enchanted_leaves"]=true, ["byg:holly_berry_leaves"]=true, ["byg:holly_leaves"]=true, ["byg:indigo_jacaranda_leaves"]=true, ["byg:jacaranda_leaves"]=true, ["byg:joshua_leaves"]=true, ["byg:lament_leaves"]=true, ["byg:mahogany_leaves"]=true, ["byg:mangrove_leaves"]=true, ["byg:maple_leaves"]=true, ["byg:nightshade_leaves"]=true, ["byg:orange_birch_leaves"]=true, ["byg:orange_oak_leaves"]=true, ["byg:orange_spruce_leaves"]=true, ["byg:orchard_leaves"]=true, ["byg:palm_leaves"]=true, ["byg:palo_verde_leaves"]=true, ["byg:pine_leaves"]=true, ["byg:pink_cherry_leaves"]=true, ["byg:rainbow_eucalyptus_leaves"]=true, ["byg:red_birch_leaves"]=true, ["byg:red_maple_leaves"]=true, ["byg:red_oak_leaves"]=true, ["byg:red_spruce_leaves"]=true, ["byg:redwood_leaves"]=true, ["byg:ripe_joshua_leaves"]=true, ["byg:ripe_orchard_leaves"]=true, ["byg:silver_maple_leaves"]=true, ["byg:skyris_leaves"]=true, ["byg:white_cherry_leaves"]=true, ["byg:willow_leaves"]=true, ["byg:witch_hazel_leaves"]=true, ["byg:withering_oak_leaves"]=true, ["byg:yellow_birch_leaves"]=true, ["byg:yellow_spruce_leaves"]=true, ["byg:zelkova_leaves"]=true, ["environmental:blue_wisteria_leaves"]=true, ["environmental:cherry_leaves"]=true, ["environmental:pink_wisteria_leaves"]=true, ["environmental:purple_wisteria_leaves"]=true, ["environmental:white_wisteria_leaves"]=true, ["environmental:willow_leaves"]=true, ["integrateddynamics:menril_leaves"]=true, ["minecraft:acacia_leaves"]=true, ["minecraft:birch_leaves"]=true, ["minecraft:dark_oak_leaves"]=true, ["minecraft:jungle_leaves"]=true, ["minecraft:oak_leaves"]=true, ["minecraft:spruce_leaves"]=true, ["naturesaura:ancient_leaves"]=true, ["naturesaura:decayed_leaves"]=true, ["naturesaura:golden_leaves"]=true, ["occultism:otherworld_leaves"]=true, ["occultism:otherworld_leaves_natural"]=true, ["projectvibrantjourneys:aspen_leaves"]=true, ["projectvibrantjourneys:baobab_leaves"]=true, ["projectvibrantjourneys:berried_juniper_leaves"]=true, ["projectvibrantjourneys:cottonwood_leaves"]=true, ["projectvibrantjourneys:fir_leaves"]=true, ["projectvibrantjourneys:joshua_leaves"]=true, ["projectvibrantjourneys:juniper_leaves"]=true, ["projectvibrantjourneys:mangrove_leaves"]=true, ["projectvibrantjourneys:orange_maple_leaves"]=true, ["projectvibrantjourneys:palm_leaves"]=true, ["projectvibrantjourneys:pine_leaves"]=true, ["projectvibrantjourneys:pink_sakura_leaves"]=true, ["projectvibrantjourneys:purple_maple_leaves"]=true, ["projectvibrantjourneys:red_maple_leaves"]=true, ["projectvibrantjourneys:redwood_leaves"]=true, ["projectvibrantjourneys:tamarack_leaves"]=true, ["projectvibrantjourneys:white_sakura_leaves"]=true, ["projectvibrantjourneys:willow_leaves"]=true, ["quark:blue_blossom_leaves"]=true, ["quark:lavender_blossom_leaves"]=true, ["quark:orange_blossom_leaves"]=true, ["quark:pink_blossom_leaves"]=true, ["quark:red_blossom_leaves"]=true, ["quark:yellow_blossom_leaves"]=true, ["sushigocrafting:avocado_leaves"]=true, ["tconstruct:earth_slime_leaves"]=true, ["tconstruct:ender_slime_leaves"]=true, ["tconstruct:sky_slime_leaves"]=true, ["undergarden:grongle_leaves"]=true, ["undergarden:smogstem_leaves"]=true, ["undergarden:wigglewood_leaves"]=true, ["upgrade_aquatic:river_leaves"]=true },
    ["minecraft:saplings"] = { ["architects_palette:twisted_sapling"]=true, ["ars_nouveau:blue_archwood_sapling"]=true, ["ars_nouveau:green_archwood_sapling"]=true, ["ars_nouveau:purple_archwood_sapling"]=true, ["ars_nouveau:red_archwood_sapling"]=true, ["atmospheric:aspen_sapling"]=true, ["atmospheric:grimwood_sapling"]=true, ["atmospheric:kousa_sapling"]=true, ["atmospheric:morado_sapling"]=true, ["atmospheric:rosewood_sapling"]=true, ["atmospheric:yucca_sapling"]=true, ["atum:palm_sapling"]=true, ["betterendforge:dragon_tree_sapling"]=true, ["betterendforge:helix_tree_sapling"]=true, ["betterendforge:lacugrove_sapling"]=true, ["betterendforge:lucernia_sapling"]=true, ["betterendforge:mossy_glowshroom_sapling"]=true, ["betterendforge:pythadendron_sapling"]=true, ["betterendforge:tenanea_sapling"]=true, ["betterendforge:umbrella_tree_sapling"]=true, ["byg:araucaria_sapling"]=true, ["byg:aspen_sapling"]=true, ["byg:baobab_sapling"]=true, ["byg:blue_enchanted_sapling"]=true, ["byg:blue_spruce_sapling"]=true, ["byg:brown_birch_sapling"]=true, ["byg:brown_oak_sapling"]=true, ["byg:brown_zelkova_sapling"]=true, ["byg:cika_sapling"]=true, ["byg:cypress_sapling"]=true, ["byg:ebony_sapling"]=true, ["byg:ether_sapling"]=true, ["byg:fir_sapling"]=true, ["byg:green_enchanted_sapling"]=true, ["byg:holly_sapling"]=true, ["byg:indigo_jacaranda_sapling"]=true, ["byg:jacaranda_sapling"]=true, ["byg:lament_sapling"]=true, ["byg:mahogany_sapling"]=true, ["byg:mangrove_sapling"]=true, ["byg:maple_sapling"]=true, ["byg:nightshade_sapling"]=true, ["byg:orange_birch_sapling"]=true, ["byg:orange_oak_sapling"]=true, ["byg:orange_spruce_sapling"]=true, ["byg:orchard_sapling"]=true, ["byg:palm_sapling"]=true, ["byg:palo_verde_sapling"]=true, ["byg:pine_sapling"]=true, ["byg:pink_cherry_sapling"]=true, ["byg:rainbow_eucalyptus_sapling"]=true, ["byg:red_birch_sapling"]=true, ["byg:red_maple_sapling"]=true, ["byg:red_oak_sapling"]=true, ["byg:red_spruce_sapling"]=true, ["byg:redwood_sapling"]=true, ["byg:silver_maple_sapling"]=true, ["byg:skyris_sapling"]=true, ["byg:white_cherry_sapling"]=true, ["byg:willow_sapling"]=true, ["byg:witch_hazel_sapling"]=true, ["byg:withering_oak_sapling"]=true, ["byg:yellow_birch_sapling"]=true, ["byg:zelkova_sapling"]=true, ["environmental:blue_wisteria_sapling"]=true, ["environmental:cherry_sapling"]=true, ["environmental:pink_wisteria_sapling"]=true, ["environmental:purple_wisteria_sapling"]=true, ["environmental:white_wisteria_sapling"]=true, ["environmental:willow_sapling"]=true, ["integrateddynamics:menril_sapling"]=true, ["minecraft:acacia_sapling"]=true, ["minecraft:birch_sapling"]=true, ["minecraft:dark_oak_sapling"]=true, ["minecraft:jungle_sapling"]=true, ["minecraft:oak_sapling"]=true, ["minecraft:spruce_sapling"]=true, ["occultism:otherworld_sapling"]=true, ["occultism:otherworld_sapling_natural"]=true, ["projectvibrantjourneys:aspen_sapling"]=true, ["projectvibrantjourneys:baobab_sapling"]=true, ["projectvibrantjourneys:cottonwood_sapling"]=true, ["projectvibrantjourneys:fir_sapling"]=true, ["projectvibrantjourneys:joshua_sapling"]=true, ["projectvibrantjourneys:juniper_sapling"]=true, ["projectvibrantjourneys:mangrove_sapling"]=true, ["projectvibrantjourneys:orange_maple_sapling"]=true, ["projectvibrantjourneys:palm_sapling"]=true, ["projectvibrantjourneys:pine_sapling"]=true, ["projectvibrantjourneys:pink_sakura_sapling"]=true, ["projectvibrantjourneys:purple_maple_sapling"]=true, ["projectvibrantjourneys:red_maple_sapling"]=true, ["projectvibrantjourneys:redwood_sapling"]=true, ["projectvibrantjourneys:tamarack_sapling"]=true, ["projectvibrantjourneys:white_sakura_sapling"]=true, ["projectvibrantjourneys:willow_sapling"]=true, ["quark:blue_blossom_sapling"]=true, ["quark:lavender_blossom_sapling"]=true, ["quark:orange_blossom_sapling"]=true, ["quark:pink_blossom_sapling"]=true, ["quark:red_blossom_sapling"]=true, ["quark:yellow_blossom_sapling"]=true, ["simplefarming:apple_sapling"]=true, ["simplefarming:apricot_sapling"]=true, ["simplefarming:banana_sapling"]=true, ["simplefarming:cherry_sapling"]=true, ["simplefarming:mango_sapling"]=true, ["simplefarming:olive_sapling"]=true, ["simplefarming:orange_sapling"]=true, ["simplefarming:pear_sapling"]=true, ["simplefarming:plum_sapling"]=true, ["sushigocrafting:avocado_sapling"]=true, ["tconstruct:earth_slime_sapling"]=true, ["tconstruct:ender_slime_sapling"]=true, ["tconstruct:sky_slime_sapling"]=true, ["undergarden:grongle_sapling"]=true, ["undergarden:smogstem_sapling"]=true, ["undergarden:wigglewood_sapling"]=true, ["upgrade_aquatic:river_sapling"]=true },
    ["minecraft:wool"] = { ["atum:linen_black"]=true, ["atum:linen_blue"]=true, ["atum:linen_brown"]=true, ["atum:linen_cyan"]=true, ["atum:linen_gray"]=true, ["atum:linen_green"]=true, ["atum:linen_light_blue"]=true, ["atum:linen_light_gray"]=true, ["atum:linen_lime"]=true, ["atum:linen_magenta"]=true, ["atum:linen_orange"]=true, ["atum:linen_pink"]=true, ["atum:linen_purple"]=true, ["atum:linen_red"]=true, ["atum:linen_white"]=true, ["atum:linen_yellow"]=true, ["chipped:black_wool_1"]=true, ["chipped:black_wool_10"]=true, ["chipped:black_wool_11"]=true, ["chipped:black_wool_12"]=true, ["chipped:black_wool_13"]=true, ["chipped:black_wool_14"]=true, ["chipped:black_wool_15"]=true, ["chipped:black_wool_16"]=true, ["chipped:black_wool_17"]=true, ["chipped:black_wool_18"]=true, ["chipped:black_wool_2"]=true, ["chipped:black_wool_3"]=true, ["chipped:black_wool_4"]=true, ["chipped:black_wool_5"]=true, ["chipped:black_wool_6"]=true, ["chipped:black_wool_7"]=true, ["chipped:black_wool_8"]=true, ["chipped:black_wool_9"]=true, ["chipped:blue_wool_1"]=true, ["chipped:blue_wool_10"]=true, ["chipped:blue_wool_11"]=true, ["chipped:blue_wool_12"]=true, ["chipped:blue_wool_13"]=true, ["chipped:blue_wool_14"]=true, ["chipped:blue_wool_15"]=true, ["chipped:blue_wool_16"]=true, ["chipped:blue_wool_17"]=true, ["chipped:blue_wool_18"]=true, ["chipped:blue_wool_2"]=true, ["chipped:blue_wool_3"]=true, ["chipped:blue_wool_4"]=true, ["chipped:blue_wool_5"]=true, ["chipped:blue_wool_6"]=true, ["chipped:blue_wool_7"]=true, ["chipped:blue_wool_8"]=true, ["chipped:blue_wool_9"]=true, ["chipped:brown_wool_1"]=true, ["chipped:brown_wool_10"]=true, ["chipped:brown_wool_11"]=true, ["chipped:brown_wool_12"]=true, ["chipped:brown_wool_13"]=true, ["chipped:brown_wool_14"]=true, ["chipped:brown_wool_15"]=true, ["chipped:brown_wool_16"]=true, ["chipped:brown_wool_17"]=true, ["chipped:brown_wool_18"]=true, ["chipped:brown_wool_2"]=true, ["chipped:brown_wool_3"]=true, ["chipped:brown_wool_4"]=true, ["chipped:brown_wool_5"]=true, ["chipped:brown_wool_6"]=true, ["chipped:brown_wool_7"]=true, ["chipped:brown_wool_8"]=true, ["chipped:brown_wool_9"]=true, ["chipped:cyan_wool_1"]=true, ["chipped:cyan_wool_10"]=true, ["chipped:cyan_wool_11"]=true, ["chipped:cyan_wool_12"]=true, ["chipped:cyan_wool_13"]=true, ["chipped:cyan_wool_14"]=true, ["chipped:cyan_wool_15"]=true, ["chipped:cyan_wool_16"]=true, ["chipped:cyan_wool_17"]=true, ["chipped:cyan_wool_18"]=true, ["chipped:cyan_wool_2"]=true, ["chipped:cyan_wool_3"]=true, ["chipped:cyan_wool_4"]=true, ["chipped:cyan_wool_5"]=true, ["chipped:cyan_wool_6"]=true, ["chipped:cyan_wool_7"]=true, ["chipped:cyan_wool_8"]=true, ["chipped:cyan_wool_9"]=true, ["chipped:gray_wool_1"]=true, ["chipped:gray_wool_10"]=true, ["chipped:gray_wool_11"]=true, ["chipped:gray_wool_12"]=true, ["chipped:gray_wool_13"]=true, ["chipped:gray_wool_14"]=true, ["chipped:gray_wool_15"]=true, ["chipped:gray_wool_16"]=true, ["chipped:gray_wool_17"]=true, ["chipped:gray_wool_18"]=true, ["chipped:gray_wool_2"]=true, ["chipped:gray_wool_3"]=true, ["chipped:gray_wool_4"]=true, ["chipped:gray_wool_5"]=true, ["chipped:gray_wool_6"]=true, ["chipped:gray_wool_7"]=true, ["chipped:gray_wool_8"]=true, ["chipped:gray_wool_9"]=true, ["chipped:green_wool_1"]=true, ["chipped:green_wool_10"]=true, ["chipped:green_wool_11"]=true, ["chipped:green_wool_12"]=true, ["chipped:green_wool_13"]=true, ["chipped:green_wool_14"]=true, ["chipped:green_wool_15"]=true, ["chipped:green_wool_16"]=true, ["chipped:green_wool_17"]=true, ["chipped:green_wool_18"]=true, ["chipped:green_wool_2"]=true, ["chipped:green_wool_3"]=true, ["chipped:green_wool_4"]=true, ["chipped:green_wool_5"]=true, ["chipped:green_wool_6"]=true, ["chipped:green_wool_7"]=true, ["chipped:green_wool_8"]=true, ["chipped:green_wool_9"]=true, ["chipped:light_blue_wool_1"]=true, ["chipped:light_blue_wool_10"]=true, ["chipped:light_blue_wool_11"]=true, ["chipped:light_blue_wool_12"]=true, ["chipped:light_blue_wool_13"]=true, ["chipped:light_blue_wool_14"]=true, ["chipped:light_blue_wool_15"]=true, ["chipped:light_blue_wool_16"]=true, ["chipped:light_blue_wool_17"]=true, ["chipped:light_blue_wool_18"]=true, ["chipped:light_blue_wool_2"]=true, ["chipped:light_blue_wool_3"]=true, ["chipped:light_blue_wool_4"]=true, ["chipped:light_blue_wool_5"]=true, ["chipped:light_blue_wool_6"]=true, ["chipped:light_blue_wool_7"]=true, ["chipped:light_blue_wool_8"]=true, ["chipped:light_blue_wool_9"]=true, ["chipped:light_gray_wool_1"]=true, ["chipped:light_gray_wool_10"]=true, ["chipped:light_gray_wool_11"]=true, ["chipped:light_gray_wool_12"]=true, ["chipped:light_gray_wool_13"]=true, ["chipped:light_gray_wool_14"]=true, ["chipped:light_gray_wool_15"]=true, ["chipped:light_gray_wool_16"]=true, ["chipped:light_gray_wool_17"]=true, ["chipped:light_gray_wool_18"]=true, ["chipped:light_gray_wool_2"]=true, ["chipped:light_gray_wool_3"]=true, ["chipped:light_gray_wool_4"]=true, ["chipped:light_gray_wool_5"]=true, ["chipped:light_gray_wool_6"]=true, ["chipped:light_gray_wool_7"]=true, ["chipped:light_gray_wool_8"]=true, ["chipped:light_gray_wool_9"]=true, ["chipped:lime_wool_1"]=true, ["chipped:lime_wool_10"]=true, ["chipped:lime_wool_11"]=true, ["chipped:lime_wool_12"]=true, ["chipped:lime_wool_13"]=true, ["chipped:lime_wool_14"]=true, ["chipped:lime_wool_15"]=true, ["chipped:lime_wool_16"]=true, ["chipped:lime_wool_17"]=true, ["chipped:lime_wool_18"]=true, ["chipped:lime_wool_2"]=true, ["chipped:lime_wool_3"]=true, ["chipped:lime_wool_4"]=true, ["chipped:lime_wool_5"]=true, ["chipped:lime_wool_6"]=true, ["chipped:lime_wool_7"]=true, ["chipped:lime_wool_8"]=true, ["chipped:lime_wool_9"]=true, ["chipped:magenta_wool_1"]=true, ["chipped:magenta_wool_10"]=true, ["chipped:magenta_wool_11"]=true, ["chipped:magenta_wool_12"]=true, ["chipped:magenta_wool_13"]=true, ["chipped:magenta_wool_14"]=true, ["chipped:magenta_wool_15"]=true, ["chipped:magenta_wool_16"]=true, ["chipped:magenta_wool_17"]=true, ["chipped:magenta_wool_18"]=true, ["chipped:magenta_wool_2"]=true, ["chipped:magenta_wool_3"]=true, ["chipped:magenta_wool_4"]=true, ["chipped:magenta_wool_5"]=true, ["chipped:magenta_wool_6"]=true, ["chipped:magenta_wool_7"]=true, ["chipped:magenta_wool_8"]=true, ["chipped:magenta_wool_9"]=true, ["chipped:orange_wool_1"]=true, ["chipped:orange_wool_10"]=true, ["chipped:orange_wool_11"]=true, ["chipped:orange_wool_12"]=true, ["chipped:orange_wool_13"]=true, ["chipped:orange_wool_14"]=true, ["chipped:orange_wool_15"]=true, ["chipped:orange_wool_16"]=true, ["chipped:orange_wool_17"]=true, ["chipped:orange_wool_18"]=true, ["chipped:orange_wool_2"]=true, ["chipped:orange_wool_3"]=true, ["chipped:orange_wool_4"]=true, ["chipped:orange_wool_5"]=true, ["chipped:orange_wool_6"]=true, ["chipped:orange_wool_7"]=true, ["chipped:orange_wool_8"]=true, ["chipped:orange_wool_9"]=true, ["chipped:pink_wool_1"]=true, ["chipped:pink_wool_10"]=true, ["chipped:pink_wool_11"]=true, ["chipped:pink_wool_12"]=true, ["chipped:pink_wool_13"]=true, ["chipped:pink_wool_14"]=true, ["chipped:pink_wool_15"]=true, ["chipped:pink_wool_16"]=true, ["chipped:pink_wool_17"]=true, ["chipped:pink_wool_18"]=true, ["chipped:pink_wool_2"]=true, ["chipped:pink_wool_3"]=true, ["chipped:pink_wool_4"]=true, ["chipped:pink_wool_5"]=true, ["chipped:pink_wool_6"]=true, ["chipped:pink_wool_7"]=true, ["chipped:pink_wool_8"]=true, ["chipped:pink_wool_9"]=true, ["chipped:purple_wool_1"]=true, ["chipped:purple_wool_10"]=true, ["chipped:purple_wool_11"]=true, ["chipped:purple_wool_12"]=true, ["chipped:purple_wool_13"]=true, ["chipped:purple_wool_14"]=true, ["chipped:purple_wool_15"]=true, ["chipped:purple_wool_16"]=true, ["chipped:purple_wool_17"]=true, ["chipped:purple_wool_18"]=true, ["chipped:purple_wool_2"]=true, ["chipped:purple_wool_3"]=true, ["chipped:purple_wool_4"]=true, ["chipped:purple_wool_5"]=true, ["chipped:purple_wool_6"]=true, ["chipped:purple_wool_7"]=true, ["chipped:purple_wool_8"]=true, ["chipped:purple_wool_9"]=true, ["chipped:red_wool_1"]=true, ["chipped:red_wool_10"]=true, ["chipped:red_wool_11"]=true, ["chipped:red_wool_12"]=true, ["chipped:red_wool_13"]=true, ["chipped:red_wool_14"]=true, ["chipped:red_wool_15"]=true, ["chipped:red_wool_16"]=true, ["chipped:red_wool_17"]=true, ["chipped:red_wool_18"]=true, ["chipped:red_wool_2"]=true, ["chipped:red_wool_3"]=true, ["chipped:red_wool_4"]=true, ["chipped:red_wool_5"]=true, ["chipped:red_wool_6"]=true, ["chipped:red_wool_7"]=true, ["chipped:red_wool_8"]=true, ["chipped:red_wool_9"]=true, ["chipped:white_wool_1"]=true, ["chipped:white_wool_10"]=true, ["chipped:white_wool_11"]=true, ["chipped:white_wool_12"]=true, ["chipped:white_wool_13"]=true, ["chipped:white_wool_14"]=true, ["chipped:white_wool_15"]=true, ["chipped:white_wool_16"]=true, ["chipped:white_wool_17"]=true, ["chipped:white_wool_18"]=true, ["chipped:white_wool_2"]=true, ["chipped:white_wool_3"]=true, ["chipped:white_wool_4"]=true, ["chipped:white_wool_5"]=true, ["chipped:white_wool_6"]=true, ["chipped:white_wool_7"]=true, ["chipped:white_wool_8"]=true, ["chipped:white_wool_9"]=true, ["chipped:yellow_wool_1"]=true, ["chipped:yellow_wool_10"]=true, ["chipped:yellow_wool_11"]=true, ["chipped:yellow_wool_12"]=true, ["chipped:yellow_wool_13"]=true, ["chipped:yellow_wool_14"]=true, ["chipped:yellow_wool_15"]=true, ["chipped:yellow_wool_16"]=true, ["chipped:yellow_wool_17"]=true, ["chipped:yellow_wool_18"]=true, ["chipped:yellow_wool_2"]=true, ["chipped:yellow_wool_3"]=true, ["chipped:yellow_wool_4"]=true, ["chipped:yellow_wool_5"]=true, ["chipped:yellow_wool_6"]=true, ["chipped:yellow_wool_7"]=true, ["chipped:yellow_wool_8"]=true, ["chipped:yellow_wool_9"]=true, ["minecraft:black_wool"]=true, ["minecraft:blue_wool"]=true, ["minecraft:brown_wool"]=true, ["minecraft:cyan_wool"]=true, ["minecraft:gray_wool"]=true, ["minecraft:green_wool"]=true, ["minecraft:light_blue_wool"]=true, ["minecraft:light_gray_wool"]=true, ["minecraft:lime_wool"]=true, ["minecraft:magenta_wool"]=true, ["minecraft:orange_wool"]=true, ["minecraft:pink_wool"]=true, ["minecraft:purple_wool"]=true, ["minecraft:red_wool"]=true, ["minecraft:white_wool"]=true, ["minecraft:yellow_wool"]=true },
}

local RECIPES = {
{ id="bloodmagic:alchemytable/basic_cutting_fluid_sigil", out="bloodmagic:basiccuttingfluid", need={ ["#forge:dusts/coal"]=1, ["#forge:dusts/redstone"]=1, ["#forge:gunpowder"]=1, ["bloodmagic:plantoil"]=1, ["bloodmagic:watersigil"]=1, ["minecraft:sugar"]=1 } },
{ id="bloodmagic:alchemytable/intermediate_cutting_fluid", out="bloodmagic:intermediatecuttingfluid", need={ ["#forge:dusts/glowstone"]=1, ["#forge:dusts/sulfur"]=1, ["#forge:gunpowder"]=1, ["bloodmagic:tauoil"]=1, ["minecraft:potion"]=1, ["minecraft:sugar"]=1 } },
{ id="bloodmagic:alchemytable/intermediate_cutting_fluid_sigil", out="bloodmagic:intermediatecuttingfluid", need={ ["#forge:dusts/glowstone"]=1, ["#forge:dusts/sulfur"]=1, ["#forge:gunpowder"]=1, ["bloodmagic:tauoil"]=1, ["bloodmagic:watersigil"]=1, ["minecraft:sugar"]=1 } },
{ id="bloodmagic:alchemytable/combinational", out="bloodmagic:combinationalcatalyst", need={ ["#forge:dusts/coal"]=1, ["bloodmagic:simplecatalyst"]=1, ["minecraft:brown_mushroom"]=1, ["minecraft:red_mushroom"]=1, ["minecraft:slime_ball"]=1 } },
{ id="bloodmagic:alchemytable/simple_catalyst", out="bloodmagic:simplecatalyst", need={ ["#forge:crops/nether_wart"]=1, ["#forge:dusts/glowstone"]=1, ["#forge:dusts/redstone"]=1, ["#forge:gunpowder"]=1, ["minecraft:sugar"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/death_essence", out="eidolon:death_essence", need={ ["eidolon:zombie_heart"]=1, ["projectvibrantjourneys:charred_bones"]=1, ["undergarden:ditchbulb"]=1, ["undergarden:ink_mushroom"]=1, ["undergarden:raw_dweller_meat"]=1 } },
{ id="bloodmagic:alchemytable/bow_power_anointment", out="bloodmagic:bow_power_anointment", need={ ["#forge:nuggets/iron"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:depthrock_pebble"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/bow_velocity_anointment", out="bloodmagic:bow_velocity_anointment", need={ ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:raw_gwibling"]=1, ["undergarden:utheric_shard"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/composite_router_filter", out="bloodmagic:itemrouterfiltercomposite", need={ ["#forge:dusts/glowstone"]=1, ["#forge:dusts/redstone"]=1, ["bloodmagic:componentframeparts"]=1, ["bloodmagic:infusedslate"]=1 } },
{ id="bloodmagic:alchemytable/curios_upgrade", out="bloodmagic:upgradetome", need={ ["#forge:dusts/iron"]=1, ["#forge:ingots/gold"]=1, ["bloodmagic:soulsnare"]=1, ["minecraft:paper"]=1 } },
{ id="bloodmagic:alchemytable/cycling_catalyst", out="bloodmagic:cyclingcatalyst", need={ ["#forge:dyes/green"]=1, ["#forge:gems/lapis"]=2, ["#forge:sand"]=1, ["bloodmagic:simplecatalyst"]=1 } },
{ id="bloodmagic:alchemytable/enchant_router_filter", out="bloodmagic:itemrouterfilterenchant", need={ ["#forge:dusts/redstone"]=1, ["bloodmagic:componentframeparts"]=1, ["minecraft:enchanted_book"]=1, ["minecraft:paper"]=1 } },
{ id="bloodmagic:alchemytable/fortune_anointment", out="bloodmagic:fortune_anointment", need={ ["#forge:nuggets/regalium"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:indigo_mushroom"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/hidden_knowledge_anointment", out="bloodmagic:hidden_knowledge_anointment", need={ ["#forge:nuggets/cloggrum"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:veil_mushroom"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/holy_water_anointment", out="bloodmagic:holy_water_anointment", need={ ["#forge:nuggets/silver"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:shimmerweed"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/looting_anointment", out="bloodmagic:looting_anointment", need={ ["#forge:nuggets/regalium"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:underbeans"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/melee_damage_anointment", out="bloodmagic:melee_anointment", need={ ["#forge:nuggets/froststeel"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:dweller_steak"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/melee_damage_anointment_2", out="bloodmagic:melee_anointment_2", need={ ["#forge:gems/quartz"]=1, ["bloodmagic:melee_anointment"]=1, ["bloodmagic:strong_tau"]=1, ["minecraft:blaze_powder"]=1 } },
{ id="bloodmagic:alchemytable/melee_damage_anointment_l", out="bloodmagic:melee_anointment_l", need={ ["#forge:gems/quartz"]=1, ["bloodmagic:melee_anointment"]=1, ["bloodmagic:tauoil"]=1, ["minecraft:blaze_powder"]=1 } },
{ id="bloodmagic:alchemytable/mod_router_filter", out="bloodmagic:itemrouterfiltermoditems", need={ ["#forge:dusts/redstone"]=1, ["#forge:dyes/yellow"]=1, ["bloodmagic:componentframeparts"]=1, ["bloodmagic:reinforcedslate"]=1 } },
{ id="bloodmagic:alchemytable/quick_draw_anointment", out="bloodmagic:quick_draw_anointment", need={ ["#forge:nuggets/aluminum"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:raw_gloomper_leg"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/reagent_binding", out="bloodmagic:reagentbinding", need={ ["#forge:ingots/utherium"]=1, ["#forge:nuggets/regalium"]=1, ["undergarden:blood_mushroom"]=1, ["undergarden:goo_ball"]=1 } },
{ id="bloodmagic:alchemytable/reagent_fastminer", out="bloodmagic:reagentfastminer", need={ ["undergarden:blisterberry"]=1, ["undergarden:cloggrum_ingot"]=1, ["undergarden:gloomper_leg"]=1, ["undergarden:roasted_underbeans"]=3 } },
{ id="bloodmagic:alchemytable/reagent_lava", out="bloodmagic:reagentlava", need={ ["#forge:dusts/sulfur"]=1, ["alexsmobs:bone_serpent_tooth"]=1, ["ars_nouveau:red_archwood_wood"]=1, ["minecraft:magma_cream"]=1 } },
{ id="bloodmagic:alchemytable/reagent_suppression", out="bloodmagic:reagentsuppression", need={ ["#forge:ingots/gold"]=1, ["bloodmagic:teleposer"]=1, ["bloodmagic:voidsigil"]=1, ["minecraft:bucket"]=1 } },
{ id="bloodmagic:alchemytable/reagent_teleposition", out="bloodmagic:reagentteleposition", need={ ["#forge:ingots/gold"]=1, ["bloodmagic:teleposer"]=1, ["minecraft:chorus_fruit"]=1, ["minecraft:ender_pearl"]=1 } },
{ id="bloodmagic:alchemytable/reagent_water", out="bloodmagic:reagentwater", need={ ["#forge:dusts/lapis"]=1, ["minecraft:kelp"]=1, ["minecraft:prismarine_shard"]=1, ["upgrade_aquatic:thrasher_tooth"]=1 } },
{ id="bloodmagic:alchemytable/router_filter", out="bloodmagic:itemrouterfilterexact", need={ ["#forge:dusts/redstone"]=1, ["#forge:dyes/red"]=1, ["#forge:leather"]=1, ["bloodmagic:componentframeparts"]=1 } },
{ id="bloodmagic:alchemytable/silk_touch_anointment", out="bloodmagic:silk_touch_anointment", need={ ["#forge:nuggets/cloggrum"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:goo_ball"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/smelting_anointment", out="bloodmagic:smelting_anointment", need={ ["#forge:nuggets/uranium"]=1, ["bloodmagic:slate_vial"]=1, ["naturesaura:aura_bottle"]=1, ["undergarden:ditchbulb"]=1 }, nbt=true },
{ id="bloodmagic:alchemytable/tag_router_filter", out="bloodmagic:itemrouterfilteroredict", need={ ["#forge:dusts/redstone"]=1, ["#forge:ingots"]=1, ["bloodmagic:componentframeparts"]=1, ["minecraft:clay_ball"]=1 } },
{ id="bloodmagic:alchemytable/weak_filling", out="bloodmagic:weakfillingagent", need={ ["bloodmagic:simplecatalyst"]=1, ["minecraft:crimson_fungus"]=1, ["minecraft:sugar_cane"]=1, ["minecraft:warped_fungus"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/fossil_bait", out="meetyourfight:fossil_bait", need={ ["#forge:dusts/lapis"]=1, ["aquaculture:fish_bones"]=1, ["minecraft:fermented_spider_eye"]=1, ["undergarden:raw_dweller_meat"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/shadow_gem", out="eidolon:shadow_gem", need={ ["astralsorcery:nocturnal_powder"]=1, ["atum:nuit_godshard"]=1, ["eidolon:death_essence"]=2, ["eidolon:soul_shard"]=2 } },
{ id="occultism:crafting/chalk_gold_impure", out="occultism:chalk_gold_impure", need={ ["architects_palette:sunmetal_blend"]=1, ["bloodmagic:plantoil"]=1, ["naturesaura:gold_powder"]=1, ["occultism:chalk_white_impure"]=1 } },
{ id="occultism:crafting/chalk_purple_impure", out="occultism:chalk_purple_impure", need={ ["betterendforge:enchanted_petal"]=1, ["bloodmagic:plantoil"]=1, ["eidolon:ender_calx"]=1, ["occultism:chalk_white_impure"]=1 } },
{ id="occultism:crafting/chalk_red_impure", out="occultism:chalk_red_impure", need={ ["bloodmagic:plantoil"]=1, ["create:cinder_flour"]=1, ["occultism:afrit_essence"]=1, ["occultism:chalk_white_impure"]=1 } },
{ id="astralsorcery:altar/nocturnal_powder", out="astralsorcery:nocturnal_powder", need={ ["#forge:dusts/obsidian"]=2, ["astralsorcery:illumination_powder"]=1, ["undergarden:ink_mushroom"]=1 } },
{ id="bloodmagic:alchemytable/component_frame_parts", out="bloodmagic:componentframeparts", need={ ["#forge:glass"]=1, ["#forge:stone"]=1, ["bloodmagic:blankslate"]=1 } },
{ id="bloodmagic:alchemytable/grass_block", out="minecraft:grass_block", need={ ["minecraft:bone_meal"]=1, ["minecraft:dirt"]=1, ["minecraft:wheat_seeds"]=1 } },
{ id="bloodmagic:alchemytable/gunpowder", out="minecraft:gunpowder", need={ ["#forge:dusts/saltpeter"]=1, ["#forge:dusts/sulfur"]=1, ["#minecraft:coals"]=1 } },
{ id="bloodmagic:alchemytable/leather_from_flesh", out="minecraft:leather", need={ ["minecraft:flint"]=1, ["minecraft:rotten_flesh"]=4, ["minecraft:water_bucket"]=1 } },
{ id="bloodmagic:alchemytable/leather_from_flesh_sigil", out="minecraft:leather", need={ ["bloodmagic:watersigil"]=1, ["minecraft:flint"]=1, ["minecraft:rotten_flesh"]=4 } },
{ id="bloodmagic:alchemytable/mundane_lengthening", out="bloodmagic:mundanelengtheningcatalyst", need={ ["#forge:dusts/redstone"]=2, ["bloodmagic:simplecatalyst"]=1, ["bloodmagic:weak_tau"]=1 } },
{ id="bloodmagic:alchemytable/mundane_power", out="bloodmagic:mundanepowercatalyst", need={ ["#forge:dusts/glowstone"]=2, ["bloodmagic:simplecatalyst"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/reagent_air", out="bloodmagic:reagentair", need={ ["alexsmobs:tarantula_hawk_wing_fragment"]=1, ["ars_nouveau:wilden_wing"]=1, ["quark:bottled_cloud"]=1 } },
{ id="bloodmagic:alchemytable/reagent_blood_light", out="bloodmagic:reagentbloodlight", need={ ["undergarden:droopvine_item"]=2, ["undergarden:glowing_kelp"]=1, ["undergarden:shard_torch"]=1 } },
{ id="bloodmagic:alchemytable/reagent_growth", out="bloodmagic:reagentgrowth", need={ ["#minecraft:saplings"]=2, ["minecraft:sugar_cane"]=1, ["thermal:phytogro"]=1 } },
{ id="bloodmagic:alchemytable/reagent_magnetism", out="bloodmagic:reagentmagnetism", need={ ["ars_nouveau:mana_fiber"]=1, ["eidolon:gold_inlay"]=1, ["minecraft:lodestone"]=1 } },
{ id="bloodmagic:alchemytable/reagent_sight", out="bloodmagic:reagentsight", need={ ["bloodmagic:divinationsigil"]=1, ["glassential:glass_ghostly"]=2, ["undergarden:glowing_kelp"]=1 } },
{ id="darkutils:crafting/anchor_plate", out="darkutils:anchor_plate", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_blindness", out="darkutils:rune_blindness", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["naturesaura:aura_bottle"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_fatigue", out="darkutils:rune_fatigue", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_fire", out="darkutils:rune_fire", need={ ["alexsmobs:lava_bottle"]=1, ["bloodmagic:lavasigil"]=1, ["darkutils:blank_plate"]=1 } },
{ id="darkutils:crafting/rune_glowing", out="darkutils:rune_glowing", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_hunger", out="darkutils:rune_hunger", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_nausea", out="darkutils:rune_nausea", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["occultism:datura"]=1 } },
{ id="darkutils:crafting/rune_poison", out="darkutils:rune_poison", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_slowness", out="darkutils:rune_slowness", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_weakness", out="darkutils:rune_weakness", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="darkutils:crafting/rune_wither", out="darkutils:rune_wither", need={ ["bloodmagic:watersigil"]=1, ["darkutils:blank_plate"]=1, ["minecraft:potion"]=1 }, nbt=true },
{ id="enigmatica:base/bloodmagic/alchemytable/bulbis_phycelium", out="byg:bulbis_phycelium", need={ ["byg:bulbis_sprouts"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/end_mycelium", out="betterendforge:end_mycelium", need={ ["#forge:mushrooms"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/ether_phylium", out="byg:ether_phylium", need={ ["byg:ether_foliage"]=1, ["byg:ether_soil"]=1, ["minecraft:bone_meal"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/ether_soil", out="byg:ether_soil", need={ ["byg:ether_foliage"]=1, ["minecraft:bone_meal"]=1, ["minecraft:dirt"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/imparius_phylium", out="byg:imparius_phylium", need={ ["byg:imparius_vine"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/ivis_phylium", out="byg:ivis_phylium", need={ ["byg:ivis_sprout"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/mycelium", out="minecraft:mycelium", need={ ["#forge:mushrooms"]=1, ["minecraft:bone_meal"]=1, ["minecraft:dirt"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/mycelium_netherrack", out="byg:mycelium_netherrack", need={ ["#forge:mushrooms"]=1, ["minecraft:bone_meal"]=1, ["minecraft:netherrack"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/nightshade_phylium", out="byg:nightshade_phylium", need={ ["byg:nightshade_sprouts"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/podzol", out="minecraft:podzol", need={ ["#minecraft:leaves"]=1, ["minecraft:bone_meal"]=1, ["minecraft:dirt"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/shulkren_phylium", out="byg:shulkren_phylium", need={ ["byg:shulkren_moss_blanket"]=1, ["minecraft:bone_meal"]=1, ["minecraft:end_stone"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/vermilion_sculk", out="byg:vermilion_sculk", need={ ["byg:ether_stone"]=1, ["byg:vermilion_sculk_growth"]=1, ["minecraft:bone_meal"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/crimson_essence", out="eidolon:crimson_essence", need={ ["#forge:crops/nether_wart"]=1, ["#forge:dusts/sulfur"]=1, ["|minecraft:crimson_roots|undergarden:blisterberry"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/cutting_essence", out="kubejs:cutting_essence", need={ ["#forge:dusts/charcoal"]=1, ["alexsmobs:komodo_spit"]=1, ["alexsmobs:rattlesnake_rattle"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/intermediatecuttingfluid", out="bloodmagic:intermediatecuttingfluid", need={ ["bloodmagic:basiccuttingfluid"]=1, ["bloodmagic:lavasigil"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/teleposerfocus", out="bloodmagic:teleposerfocus", need={ ["#forge:ingots/silicon_bronze"]=1, ["#forge:shards/ender"]=1, ["eidolon:enchanted_ash"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/weakbloodshard_from_flask", out="bloodmagic:weakbloodshard", need={ ["botania:brew_flask"]=1, ["eidolon:crimson_essence"]=1, ["occultism:afrit_essence"]=1 }, nbt=true },
{ id="enigmatica:expert/bloodmagic/alchemytable/weakbloodshard_from_incense", out="bloodmagic:weakbloodshard", need={ ["botania:incense_stick"]=1, ["eidolon:crimson_essence"]=1, ["occultism:afrit_essence"]=1 }, nbt=true },
{ id="enigmatica:expert/bloodmagic/alchemytable/weakbloodshard_from_vial", out="bloodmagic:weakbloodshard", need={ ["botania:brew_vial"]=1, ["eidolon:crimson_essence"]=1, ["occultism:afrit_essence"]=1 }, nbt=true },
{ id="occultism:crafting/chalk_white_impure", out="occultism:chalk_white_impure", need={ ["bloodmagic:plantoil"]=1, ["occultism:burnt_otherstone"]=2, ["occultism:otherworld_ashes"]=3 } },
{ id="astralsorcery:altar/illumination_powder", out="astralsorcery:illumination_powder", need={ ["#forge:dusts/regalium"]=4, ["undergarden:glowing_kelp"]=1 } },
{ id="bloodmagic:alchemytable/arcane_ash", out="bloodmagic:arcaneashes", need={ ["ars_nouveau:magic_clay"]=1, ["minecraft:blaze_powder"]=1 } },
{ id="bloodmagic:alchemytable/basic_cutting_fluid", out="bloodmagic:basiccuttingfluid", need={ ["bloodmagic:plantoil"]=1, ["kubejs:cutting_essence"]=1 } },
{ id="bloodmagic:alchemytable/bow_power_anointment_2", out="bloodmagic:bow_power_anointment_2", need={ ["bloodmagic:bow_power_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/bow_power_anointment_l", out="bloodmagic:bow_power_anointment_l", need={ ["bloodmagic:bow_power_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/bow_velocity_anointment_2", out="bloodmagic:bow_velocity_anointment_2", need={ ["bloodmagic:bow_velocity_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/bow_velocity_anointment_l", out="bloodmagic:bow_velocity_anointment_l", need={ ["bloodmagic:bow_velocity_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/bread", out="minecraft:bread", need={ ["#forge:crops/wheat"]=1, ["minecraft:sugar"]=1 } },
{ id="bloodmagic:alchemytable/clay_from_sand", out="minecraft:clay", need={ ["#forge:sand"]=2, ["minecraft:water_bucket"]=1 } },
{ id="bloodmagic:alchemytable/clay_from_sand_sigil", out="minecraft:clay", need={ ["#forge:sand"]=2, ["bloodmagic:watersigil"]=1 } },
{ id="bloodmagic:alchemytable/explosive_powder", out="bloodmagic:explosivepowder", need={ ["#forge:dusts/coal"]=1, ["#forge:gunpowder"]=2 } },
{ id="bloodmagic:alchemytable/filter/composite_enchant_filter", out="bloodmagic:itemrouterfiltercomposite", need={ ["#forge:slimeballs"]=1, ["bloodmagic:itemrouterfilterenchant"]=1 } },
{ id="bloodmagic:alchemytable/filter/composite_mod_filter", out="bloodmagic:itemrouterfiltercomposite", need={ ["#forge:slimeballs"]=1, ["bloodmagic:itemrouterfiltermoditems"]=1 } },
{ id="bloodmagic:alchemytable/filter/composite_tag_filter", out="bloodmagic:itemrouterfiltercomposite", need={ ["#forge:slimeballs"]=1, ["bloodmagic:itemrouterfilteroredict"]=1 } },
{ id="bloodmagic:alchemytable/fortune_anointment_2", out="bloodmagic:fortune_anointment_2", need={ ["bloodmagic:fortune_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/fortune_anointment_l", out="bloodmagic:fortune_anointment_l", need={ ["bloodmagic:fortune_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/hidden_knowledge_anointment_2", out="bloodmagic:hidden_knowledge_anointment_2", need={ ["bloodmagic:hidden_knowledge_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/hidden_knowledge_anointment_l", out="bloodmagic:hidden_knowledge_anointment_l", need={ ["bloodmagic:hidden_knowledge_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/holy_water_anointment_2", out="bloodmagic:holy_water_anointment_2", need={ ["bloodmagic:holy_water_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/holy_water_anointment_l", out="bloodmagic:holy_water_anointment_l", need={ ["bloodmagic:holy_water_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/looting_anointment_2", out="bloodmagic:looting_anointment_2", need={ ["bloodmagic:looting_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/looting_anointment_l", out="bloodmagic:looting_anointment_l", need={ ["bloodmagic:looting_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/melee_anointment_2", out="bloodmagic:melee_anointment_2", need={ ["bloodmagic:melee_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/melee_anointment_l", out="bloodmagic:melee_anointment_l", need={ ["bloodmagic:melee_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/plantoil_from_beets", out="bloodmagic:plantoil", need={ ["#forge:crops/beetroot"]=3, ["minecraft:bone_meal"]=1 } },
{ id="bloodmagic:alchemytable/plantoil_from_carrots", out="bloodmagic:plantoil", need={ ["#forge:crops/carrot"]=3, ["minecraft:bone_meal"]=1 } },
{ id="bloodmagic:alchemytable/plantoil_from_taters", out="bloodmagic:plantoil", need={ ["#forge:crops/potato"]=3, ["minecraft:bone_meal"]=1 } },
{ id="bloodmagic:alchemytable/plantoil_from_wheat", out="bloodmagic:plantoil", need={ ["#forge:crops"]=3, ["minecraft:bone_meal"]=1 } },
{ id="bloodmagic:alchemytable/quick_draw_anointment_2", out="bloodmagic:quick_draw_anointment_2", need={ ["bloodmagic:quick_draw_anointment"]=1, ["bloodmagic:strong_tau"]=1 } },
{ id="bloodmagic:alchemytable/quick_draw_anointment_l", out="bloodmagic:quick_draw_anointment_l", need={ ["bloodmagic:quick_draw_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/reagent_holding", out="bloodmagic:reagentholding", need={ ["alexsmobs:kangaroo_hide"]=2, ["ars_nouveau:mana_fiber"]=2 } },
{ id="bloodmagic:alchemytable/reagent_void", out="bloodmagic:reagentvoid", need={ ["astralsorcery:nocturnal_powder"]=3, ["eidolon:ender_calx"]=1 } },
{ id="bloodmagic:alchemytable/saltpeter", out="bloodmagic:saltpeter", need={ ["#forge:dusts/coal"]=1, ["bloodmagic:plantoil"]=2 } },
{ id="bloodmagic:alchemytable/sand_gold", out="bloodmagic:goldsand", need={ ["#bloodmagic:arc/cuttingfluid"]=1, ["#forge:ores/gold"]=1 } },
{ id="bloodmagic:alchemytable/sand_iron", out="bloodmagic:ironsand", need={ ["#bloodmagic:arc/cuttingfluid"]=1, ["#forge:ores/iron"]=1 } },
{ id="bloodmagic:alchemytable/sigil_lava_bucket", out="minecraft:lava_bucket", need={ ["bloodmagic:lavasigil"]=1, ["minecraft:bucket"]=1 } },
{ id="bloodmagic:alchemytable/sigil_water_bottle", out="minecraft:potion", need={ ["bloodmagic:watersigil"]=1, ["minecraft:glass_bottle"]=1 } },
{ id="bloodmagic:alchemytable/sigil_water_bucket", out="minecraft:water_bucket", need={ ["bloodmagic:watersigil"]=1, ["minecraft:bucket"]=1 } },
{ id="bloodmagic:alchemytable/silk_touch_anointment_l", out="bloodmagic:silk_touch_anointment_l", need={ ["bloodmagic:silk_touch_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/slate_vial", out="bloodmagic:slate_vial", need={ ["#forge:glass"]=5, ["bloodmagic:blankslate"]=1 } },
{ id="bloodmagic:alchemytable/smelting_anointment_l", out="bloodmagic:smelting_anointment_l", need={ ["bloodmagic:smelting_anointment"]=1, ["bloodmagic:tauoil"]=1 } },
{ id="bloodmagic:alchemytable/sulfur_from_lava", out="bloodmagic:sulfur", need={ ["#forge:cobblestone"]=1, ["minecraft:lava_bucket"]=1 } },
{ id="bloodmagic:alchemytable/sulfur_from_sigil", out="bloodmagic:sulfur", need={ ["#forge:cobblestone"]=1, ["bloodmagic:lavasigil"]=1 } },
{ id="bloodmagic:alchemytable/tau_oil", out="bloodmagic:tauoil", need={ ["bloodmagic:weak_tau"]=3, ["minecraft:bone_meal"]=1 } },
{ id="bloodmagic:alchemytable/upgrade_brilliance", out="bloodmagic:upgradetome", need={ ["#forge:gems/diamond"]=5, ["bloodmagic:reagentbinding"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/cured_rubber", out="thermal:cured_rubber", need={ ["#forge:dusts/sulfur"]=1, ["industrialforegoing:dryrubber"]=2 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/brown_rune", out="quark:brown_rune", need={ ["quark:green_rune"]=1, ["quark:red_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/cyan_rune", out="quark:cyan_rune", need={ ["quark:blue_rune"]=1, ["quark:green_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/gray_rune", out="quark:gray_rune", need={ ["quark:black_rune"]=1, ["quark:white_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/green_rune", out="quark:green_rune", need={ ["quark:blue_rune"]=1, ["quark:yellow_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/light_gray_rune", out="quark:light_gray_rune", need={ ["quark:gray_rune"]=1, ["quark:white_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/pink_rune", out="quark:pink_rune", need={ ["quark:red_rune"]=1, ["quark:white_rune"]=1 } },
{ id="enigmatica:expert/bloodmagic/alchemytable/purple_rune", out="quark:purple_rune", need={ ["quark:blue_rune"]=1, ["quark:red_rune"]=1 } },
{ id="bloodmagic:alchemytable/cobweb", out="minecraft:cobweb", need={ ["#forge:string"]=3 } },
{ id="bloodmagic:alchemytable/flint_from_gravel", out="minecraft:flint", need={ ["minecraft:gravel"]=3 } },
{ id="bloodmagic:alchemytable/gold_ore_from_gilded", out="minecraft:gold_nugget", need={ ["minecraft:gilded_blackstone"]=1 } },
{ id="bloodmagic:alchemytable/nether_wart_from_block", out="minecraft:nether_wart", need={ ["minecraft:nether_wart_block"]=1 } },
{ id="bloodmagic:alchemytable/sand_coal", out="emendatusenigmatica:coal_dust", need={ ["minecraft:coal"]=2 } },
{ id="bloodmagic:alchemytable/string", out="minecraft:string", need={ ["#minecraft:wool"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/basalz_powder", out="thermal:basalz_powder", need={ ["#forge:rods/basalz"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/blaze_powder", out="minecraft:blaze_powder", need={ ["#forge:rods/blaze"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/blitz_powder", out="thermal:blitz_powder", need={ ["#forge:rods/blitz"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/blizz_powder", out="thermal:blizz_powder", need={ ["#forge:rods/blizz"]=1 } },
{ id="enigmatica:base/bloodmagic/alchemytable/quartz", out="minecraft:quartz", need={ ["byg:quartzite_sand"]=3 } },
}
-- ==== AUTO GENERATED END ====

local expect = require "cc.expect"

local function checked_resume(co, ...)
    local ok, result = coroutine.resume(co, ...)
    if not ok then
        error(debug.traceback(co, result), 0)
    end
    return result
end

local function create_runner(init)
    expect(1, init, "function")

    local active, active_n = {}, 0

    local function spawn(fn, ...)
        expect(1, fn, "function")

        local co = coroutine.create(fn)
        local result = checked_resume(co, ...)
        if coroutine.status(co) ~= "dead" then
            active_n = active_n + 1
            active[active_n] = {
                co = co,
                filter = result or false
            }
        end
    end

    spawn(init, spawn)
    while active_n > 0 do
        local event = table.pack(os.pullEventRaw())
        local event_name = event[1]
        for i = active_n, 1, -1 do
            local task = active[i]
            if not task.filter or task.filter == event_name or event_name == "terminate" then
                local filter = checked_resume(task.co, table.unpack(event, 1, event.n))
                if coroutine.status(task.co) == "dead" then
                    table.remove(active, i)
                    active_n = active_n - 1
                else
                    task.filter = filter or false
                end
            end
        end
    end
end
--参考以下链接
--https://github.com/cc-tweaked/CC-Tweaked/issues/1734
--https://computercraft.info/wiki/Os.pullEvent
--https://web.archive.org/web/20230213155922/http://www.computercraft.info/forums2/index.php?/topic/25670-bbs-guide-to-coroutines/

-- 用有线 modem 的 getNameLocal() 校正海龟在网络上的名字
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        local ok, wireless = pcall(peripheral.call, side, "isWireless")
        if ok and not wireless then
            local ok2, local_name = pcall(peripheral.call, side, "getNameLocal")
            if ok2 and local_name then turtle_inv = local_name end
        end
    end
end
print("turtle_inv =", turtle_inv)

local output = peripheral.find(output_name)
assert(output ~= nil, "Can't find output: " .. output_name)
output = peripheral.getName(output)

local tables, known, busy, size_of = {}, {}, {}, {}
local warned_insert, last_nomatch = {}, {}

local function table_items(name)
    return peripheral.call(name, "list") or {}
end

local function describe(items, limit)
    local desc = {}
    for i = 1, (limit or 8) do
        if items[i] then
            desc[#desc + 1] = ("%d:%s x%d"):format(i, items[i].name, items[i].count)
        end
    end
    return #desc > 0 and table.concat(desc, ", ") or "(empty)"
end

-- 海龟身上现在有哪些原料（第 1~16 格都列出来，方便确认物品名和有没有放错格子）
local function describe_turtle()
    local desc = {}
    for i = 1, 16 do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local d = turtle.getItemDetail(i)
            desc[#desc + 1] = ("%d:%s x%d"):format(i, d and d.name or "?", n)
        end
    end
    return #desc > 0 and table.concat(desc, ", ") or "(empty)"
end

-- 海龟当前的原料（物品名 -> 总数量）和被占用的格子数
local function turtle_state()
    local available, kinds = {}, 0
    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local d = turtle.getItemDetail(i)
            if d then
                available[d.name] = (available[d.name] or 0) + n
                kinds = kinds + 1
            end
        end
    end
    return available, kinds
end

-- 某个物品名在海龟的第几格（取第一格）
local function turtle_slot_of(item)
    for i = 1, input_slots do
        if turtle.getItemCount(i) > 0 then
            local d = turtle.getItemDetail(i)
            if d and d.name == item then return i end
        end
    end
end

-- 海龟当前每种原料的名字（用来识别桌子里的旧残留）
local function turtle_ingredients()
    local names = {}
    for i = 1, input_slots do
        if turtle.getItemCount(i) > 0 then
            local d = turtle.getItemDetail(i)
            if d then names[d.name] = true end
        end
    end
    return names
end

local function amount_of(item)
    return craft_amount[item] or per_craft
end

-- ===== 配方匹配（自动表）=====================================================
-- 配方条目的三种写法： "minecraft:redstone"（具体物品）/ "#forge:dusts/redstone"（标签）
--                     / "|a|b"（二选一）
local function key_matches(key, item)
    local head = key:sub(1, 1)

    if head == "#" then
        local tag = key:sub(2)
        local map = TAG_ITEMS[tag]
        if map then return map[item] == true end

        -- 标签没解析出来时退化成名字匹配：取标签最后一段，去掉末尾 s，看物品名里有没有
        local leaf = tag:match("([^/]+)$") or tag
        leaf = leaf:gsub("s$", "")
        local path = item:match(":(.+)$") or item
        return leaf ~= "" and path:find(leaf, 1, true) ~= nil
    elseif head == "|" then
        for id in key:gmatch("[^|]+") do
            if id == item then return true end
        end
        return false
    else
        return key == item
    end
end

-- 用海龟手里的原料去匹配配方，返回摆放计划（key / 用哪个物品 / 几份 / 产出）
-- 先只信"全是具体物品 / 已解析标签"的配方，实在没有再退到靠名字猜标签的那批，减少摆错的风险
local function key_trusted(key)
    if key:sub(1, 1) == "#" then return TAG_ITEMS[key:sub(2)] ~= nil end
    if key:sub(1, 1) == "|" then
        for id in key:gmatch("[^|]+") do
            if id:sub(1, 1) == "#" and not TAG_ITEMS[id:sub(2)] then return false end
        end
    end
    return true
end

local function recipe_trusted(r)
    for k in pairs(r.need) do
        if not key_trusted(k) then return false end
    end
    return true
end

local function match_recipe(available)
    local kinds = {}
    for name in pairs(available) do kinds[#kinds + 1] = name end

    for pass = 1, 2 do
        for _, r in ipairs(RECIPES) do
            if not r.nbt and (pass == 2 or recipe_trusted(r)) then
                local keys = {}
                for k in pairs(r.need) do keys[#keys + 1] = k end

                if #keys <= #kinds then
                    local used, plan, ok = {}, {}, true
                    for _, k in ipairs(keys) do
                        local chosen
                        for _, name in ipairs(kinds) do
                            if not used[name] and key_matches(k, name) and (available[name] or 0) >= r.need[k] then
                                chosen = name
                                break
                            end
                        end
                        if not chosen then ok = false break end
                        used[chosen] = true
                        plan[#plan + 1] = { item = chosen, count = r.need[k] }
                    end
                    if ok then return plan, r end
                end
            end
        end
    end
end

-- 没匹配到配方时，列出几条"最接近"的配方（含每种原料需要多少 / 海龟手里有多少），方便看出差在哪
local function diagnose(available)
    local kinds = {}
    for name in pairs(available) do kinds[#kinds + 1] = name end

    local scored = {}
    for _, r in ipairs(RECIPES) do
        if not r.nbt then
            local hit, total, parts = 0, 0, {}
            for k, n in pairs(r.need) do
                total = total + 1
                local have = 0
                for _, name in ipairs(kinds) do
                    if key_matches(k, name) then have = have + (available[name] or 0) end
                end
                if have >= n then hit = hit + 1 end
                parts[#parts + 1] = ("%s x%d(have %d)"):format(k, n, have)
            end
            scored[#scored + 1] = { r = r, hit = hit, total = total, parts = parts }
        end
    end

    table.sort(scored, function(a, b)
        if a.hit ~= b.hit then return a.hit > b.hit end
        return a.total < b.total
    end)

    for i = 1, math.min(3, #scored) do
        local s = scored[i]
        print(("    [near-miss %d/%d] %s needs: %s")
            :format(s.hit, s.total, s.r.out or s.r.id, table.concat(s.parts, ", ")))
    end
end

-- ===== 装料 =================================================================
-- 按自动匹配出的计划装料：每种原料占 need 个空格子，每格 1 个
local function load_plan(name, plan)
    local mark, moved, failed = nil, 0, {}

    for _, p in ipairs(plan) do
        local src = turtle_slot_of(p.item)
        if not src then
            failed[#failed + 1] = 0
        else
            if not mark then mark = p.item end
            for _ = 1, p.count do
                local items = table_items(name)
                local target
                for s = 1, table_input_slots do
                    if items[s] == nil then target = s break end
                end

                if target == nil then
                    failed[#failed + 1] = src
                    break
                end

                local placed = peripheral.call(name, "pullItems", turtle_inv, src, 1, target)
                if placed > 0 then
                    moved = moved + 1
                else
                    failed[#failed + 1] = src
                    break
                end
            end
        end
    end

    return mark, moved, failed
end

-- 海龟里的原料够不够一份（兜底方式：按 craft_amount / per_craft）
local function has_full_set()
    local kinds = 0
    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            kinds = kinds + 1
            local d = turtle.getItemDetail(i)
            local want = amount_of(d and d.name)
            if n < want then return false, kinds end
        end
    end
    return kinds > 0, kinds
end

local function add_table(name)
    if known[name] then return end
    known[name] = true
    busy[name] = false
    local size = peripheral.call(name, "size")
    assert(size >= 7, name .. ": only " .. tostring(size) .. " slots visible, check the table's I/O config (D U N S W E)")
    size_of[name] = size
    table.insert(tables, name)
    print(("table %s (%d slots)"):format(name, size))
end

for _, name in pairs(peripheral.getNames()) do
    if string.match(name, "alchemytable_") ~= nil then
        add_table(name)
    end
end
assert(#tables > 0, "no alchemytable_* peripheral found, check the wired network")

-- 启动时打印桌子上现有的东西（不清空，避免误抽掉你的血之宝珠）
for _, name in ipairs(tables) do
    print(("[%s] contents: %s"):format(name, describe(table_items(name), size_of[name])))
end

local function pulse()
    redstone.setOutput(direction, false)
    sleep(0.05)
    redstone.setOutput(direction, true)
end

--[[ 清掉桌子里的旧东西：非空格的项数必须正好等于配方的项数，
     上一次没合成成功的残留会让项数变多、配方永远匹配不上。
     只清两种：①最后一格（按输入输出配置，最后一格就是输出格）
               ②装着"海龟当前也有的那种原料"的格子（= 上次的残留）
     别的东西（血之宝珠、炼金瓶之类）一律不碰。 ]]
local function clean_table(name, ing_names)
    local items = table_items(name)
    local drained = {}
    for i = 1, size_of[name] do
        local it = items[i]
        if it and (i == size_of[name] or ing_names[it.name]) then
            peripheral.call(output, "pullItems", name, i)
            drained[#drained + 1] = ("%d:%s"):format(i, it.name)
        end
    end
    if #drained > 0 then
        print(("[%s] cleaned old stuff: %s"):format(name, table.concat(drained, ", ")))
    end
end

-- 兜底装料：每种原料占 amount_of() 个空格子，每格 1 个
local function load_one_set(name)
    local mark, moved, failed = nil, 0, {}

    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local detail = turtle.getItemDetail(i)
            local item = detail and detail.name
            local want = amount_of(item)
            if not mark then mark = item end

            for _ = 1, want do
                local items = table_items(name)
                local target
                for s = 1, table_input_slots do
                    if items[s] == nil then target = s break end
                end

                if target == nil then
                    failed[#failed + 1] = i
                    break
                end

                local placed = peripheral.call(name, "pullItems", turtle_inv, i, 1, target)
                if placed > 0 then
                    moved = moved + 1
                else
                    failed[#failed + 1] = i
                    break
                end
            end
        end
    end

    return mark, moved, failed
end

-- 记录每一格现在的内容（用来判断"合成后新增了什么"）
local function snapshot(name)
    local items = table_items(name)
    local snap = {}
    for i = 1, size_of[name] do
        local it = items[i]
        snap[i] = it and (it.name .. "x" .. it.count) or nil
    end
    return snap
end

-- 数一下桌子输入格里现在有几个非空项（要等于配方项数才能合成）
local function entry_count(name)
    local items = table_items(name)
    local n = 0
    for i = 1, table_input_slots do
        if items[i] ~= nil then n = n + 1 end
    end
    return n
end

-- 等合成完毕 -> 只抽新增/变化过的格子 -> 这张桌子重新变空闲
local function wait_and_collect(name, mark, before)
    local waited, hinted = 0, false
    while true do
        sleep(check_delay)
        waited = waited + check_delay
        local items = table_items(name)

        local done = false
        local first = items[1] and items[1].name or nil
        if first ~= mark then done = true end -- 第 1 格的原料被消耗/变成产物
        if not done then
            for i = 1, size_of[name] do
                local it = items[i]
                local now = it and (it.name .. "x" .. it.count) or nil
                if now and now ~= before[i] then done = true break end
            end
        end
        if done then break end

        if not hinted and waited >= hint_delay then
            hinted = true
            print(("[%s] no craft after %ds - check: (1) craft_amount / recipe table (2) blood orb tier / LP (3) entries in table = %d")
                :format(name, hint_delay, entry_count(name)))
        end

        if waited >= craft_timeout then
            waited = 0
            print(("[%s] still nothing after %ds, giving up this round"):format(name, craft_timeout))
            if drain_on_timeout then
                print(("[%s] drain_on_timeout = true: moving everything back to the interface"):format(name))
                for i = 1, size_of[name] do
                    peripheral.call(output, "pullItems", name, i)
                end
                busy[name] = false
                os.queueEvent("turtle_inventory")
                return
            end
        end
    end

    -- 只抽"装料时没有、现在有"的格子：也就是产物（和桶之类的剩余物），不会碰别的格子
    local after = table_items(name)
    local pulled = 0
    for i = 1, size_of[name] do
        local it = after[i]
        local now = it and (it.name .. "x" .. it.count) or nil
        if now and now ~= before[i] then
            peripheral.call(output, "pullItems", name, i)
            pulled = pulled + 1
        end
    end
    if verbose then
        print(("[%s] done, pulled %d slots -> %s"):format(name, pulled, describe(table_items(name), size_of[name])))
    end

    busy[name] = false
    os.queueEvent("turtle_inventory") -- 叫醒装载循环：还有料的话就继续喂别的空桌子
end

if (turtle.getItemCount(1) ~= 0) then
    os.queueEvent("turtle_inventory")
else
    if redstone_flag then
        pulse() -- 海龟是空的，先催一次合成仓给料
    end
end

create_runner(function(spawn)
    -- 新桌子接入网络时自动登记
    spawn(function()
        while true do
            local _, name = os.pullEvent("peripheral")
            if type(name) == "string" and string.match(name, "alchemytable_") ~= nil then
                add_table(name)
            end
        end
    end)

    -- 装载循环：海龟里有料、又有空桌子时，给每张空桌子各发一份（所有桌子并行合成）
    spawn(function()
        while true do
            local loaded = false
            for _, name in ipairs(tables) do
                if not busy[name] then
                    local available = turtle_state()
                    local plan, recipe = match_recipe(available)

                    if plan then
                        if verbose then
                            print(("[%s] recipe %s%s | turtle: %s"):format(name,
                                recipe.out or "?",
                                recipe.tag and (" [" .. recipe.tag .. "]") or "",
                                describe_turtle()))
                        end

                        clean_table(name, turtle_ingredients())
                        local mark, moved, failed = load_plan(name, plan)
                        if moved > 0 then
                            if #failed > 0 and not warned_insert[name] then
                                warned_insert[name] = true
                                print(("[%s] could not place all ingredients (only %d input slots)")
                                    :format(name, table_input_slots))
                            end

                            local before = snapshot(name)
                            if verbose then
                                print(("[%s] loaded %d entries -> %s"):format(name, moved, describe(table_items(name), size_of[name])))
                            end

                            busy[name] = true
                            if redstone_flag then pulse() end
                            spawn(function() wait_and_collect(name, mark, before) end)
                            loaded = true
                            sleep(0.05)
                        end
                    elseif has_full_set() then
                        -- 没匹配到配方表里的配方，退回手动份数，并打印几条"最接近"的配方便于排查
                        local sig = describe_turtle()
                        if last_nomatch[name] ~= sig then
                            last_nomatch[name] = sig
                            print(("[%s] no recipe matched, using per_craft/craft_amount | turtle: %s"):format(name, sig))
                            diagnose(available)
                        end

                        clean_table(name, turtle_ingredients())
                        local mark, moved, failed = load_one_set(name)
                        if moved > 0 then
                            if #failed > 0 and not warned_insert[name] then
                                warned_insert[name] = true
                                local slots = {}
                                for _, i in ipairs(failed) do slots[#slots + 1] = tostring(i) end
                                print(("[%s] could not place all of turtle slot(s) %s (only %d input slots)")
                                    :format(name, table.concat(slots, ","), table_input_slots))
                            end

                            local before = snapshot(name)
                            if verbose then
                                print(("[%s] loaded %d entries -> %s"):format(name, moved, describe(table_items(name), size_of[name])))
                            end

                            busy[name] = true
                            if redstone_flag then pulse() end
                            spawn(function() wait_and_collect(name, mark, before) end)
                            loaded = true
                            sleep(0.05)
                        end
                    end
                end
            end
            if not loaded then
                os.pullEvent("turtle_inventory")
                sleep(feed_settle)
            end
        end
    end)
end)
