--农夫乐事 厨锅自动烹饪（CC:Tweaked）
--厨锅 9 格：1~6 输入 / 7 显示（做好的菜暂存）/ 8 容器（碗、瓶子）/ 9 成品
--热源由你自己处理（火/营火/岩浆/岩浆块/燃烧的炉灶，中间可垫漏斗）
--注意：厨锅配方是无序的，但同一种原料要占几个格子就得放几份（一格一个）
local direction = "left" -- 脉冲发送位置 合成仓相较于海龟的位置 记得调脉冲模式
local redstone_flag = true -- 默认使用脉冲模式
local check_delay = 0.5 -- 轮询间隔（秒）
local output_name = "refinedstorage:interface" -- 成品输出口（rs 物品接口，AE 自行改）

-- 下面这段是自动生成的配方表（来自你本地各 mod jar 的 cooking 配方 + E6E 的 KubeJS）。
-- 装载时会拿海龟手里的原料自动匹配配方：同一种原料在配方里出现几次，就占几个格子、放几份。
local per_craft = 1 -- 兜底：匹配不上时每种原料占 1 格
local craft_amount = {
    -- ["minecraft:beetroot"] = 2,   -- 想手动覆盖时写这里（自动匹配优先）
}

local input_slots = 6 -- 海龟第 1~6 格装原料
local container_index = 8 -- 厨锅的容器格（1~6 输入 / 7 显示 / 8 容器 / 9 成品）
-- 有些配方数据里没写容器，但实际必须往容器格放容器才能出杯（饮料就是空玻璃瓶）。
-- 按"产物物品 → 容器"在这里补，没写的就用配方表里的 container：
local container_by_output = {
    ["farmersdelight:hot_cocoa"] = "minecraft:glass_bottle",
    ["farmersdelight:apple_cider"] = "minecraft:glass_bottle",
    ["farmersdelight:melon_juice"] = "minecraft:glass_bottle",
    -- 汤/炖菜如果也需要碗，照着写，例如：
    -- ["farmersdelight:beef_stew"] = "minecraft:bowl",
}
local container_slot = 7 -- 兜底：海龟第 7 格放容器（碗/瓶）；优先会去海龟所有格子里找配方要的那种容器
local container_keep = 16 -- 厨锅容器格里至少留这么多个容器
local collect_output = true -- 没找到导出外设时，是否直接抽厨锅的成品槽
local export_peripheral = "chute" -- 成品导出外设的名字关键字（机械动力溜槽 create:chute_9 → 写 "chute"）；nil = 不用
local export_poll = 1 -- 每隔几秒去导出外设看一次
local feed_settle = 0.3 -- 收到 turtle_inventory 后等一会儿再发料
local cook_timeout = 60 -- 等成品/等原料超时提醒（秒）
local verbose = true -- 打印细节（跑顺了可改 false）
local turtle_inv = "turtle_1" -- 海龟在网络上的名字（启动时自动校正）
-- ==== AUTO GENERATED: 各 mod jar 的 cooking 配方 + E6E kubejs ====
-- need = 配方里每种原料出现的次数（= 要占厨锅几个输入格）
local TAG_ITEMS = {
    ["farmersdelight:cabbage_roll_ingredients"] = { ["abnormals_delight:duck_fillet"]=true, ["abnormals_delight:perch_slice"]=true, ["abnormals_delight:pike_slice"]=true, ["abnormals_delight:venison_shanks"]=true, ["alexsmobs:blobfish"]=true, ["alexsmobs:crocodile_egg"]=true, ["alexsmobs:emu_egg"]=true, ["aquaculture:arapaima"]=true, ["aquaculture:atlantic_cod"]=true, ["aquaculture:atlantic_halibut"]=true, ["aquaculture:atlantic_herring"]=true, ["aquaculture:bayad"]=true, ["aquaculture:blackfish"]=true, ["aquaculture:bluegill"]=true, ["aquaculture:boulti"]=true, ["aquaculture:brown_shrooma"]=true, ["aquaculture:brown_trout"]=true, ["aquaculture:capitaine"]=true, ["aquaculture:carp"]=true, ["aquaculture:catfish"]=true, ["aquaculture:fish_fillet_raw"]=true, ["aquaculture:gar"]=true, ["aquaculture:minnow"]=true, ["aquaculture:muskellunge"]=true, ["aquaculture:pacific_halibut"]=true, ["aquaculture:perch"]=true, ["aquaculture:pink_salmon"]=true, ["aquaculture:piranha"]=true, ["aquaculture:pollock"]=true, ["aquaculture:rainbow_trout"]=true, ["aquaculture:red_grouper"]=true, ["aquaculture:red_shrooma"]=true, ["aquaculture:smallmouth_bass"]=true, ["aquaculture:synodontis"]=true, ["aquaculture:tambaqui"]=true, ["aquaculture:tuna"]=true, ["atum:quail_egg"]=true, ["betterendforge:bolux_mushroom"]=true, ["betterendforge:chorus_mushroom_raw"]=true, ["betterendforge:end_fish_raw"]=true, ["betterendforge:mossy_glowshroom_sapling"]=true, ["betterendforge:small_jellyshroom"]=true, ["betterendforge:umbrella_tree_sapling"]=true, ["botania:black_mushroom"]=true, ["botania:blue_mushroom"]=true, ["botania:brown_mushroom"]=true, ["botania:cyan_mushroom"]=true, ["botania:gray_mushroom"]=true, ["botania:green_mushroom"]=true, ["botania:light_blue_mushroom"]=true, ["botania:light_gray_mushroom"]=true, ["botania:lime_mushroom"]=true, ["botania:magenta_mushroom"]=true, ["botania:orange_mushroom"]=true, ["botania:pink_mushroom"]=true, ["botania:purple_mushroom"]=true, ["botania:red_mushroom"]=true, ["botania:white_mushroom"]=true, ["botania:yellow_mushroom"]=true, ["byg:black_puff"]=true, ["byg:blue_glowshroom"]=true, ["byg:death_cap"]=true, ["byg:embur_wart"]=true, ["byg:fungal_imparius"]=true, ["byg:green_mushroom"]=true, ["byg:imparius_mushroom"]=true, ["byg:purple_glowshroom"]=true, ["byg:shulkren_fungus"]=true, ["byg:soul_shroom"]=true, ["byg:soul_shroom_spore_end"]=true, ["byg:sythian_fungus"]=true, ["byg:weeping_milkcap"]=true, ["byg:wood_blewit"]=true, ["environmental:duck"]=true, ["environmental:duck_egg"]=true, ["environmental:koi"]=true, ["environmental:venison"]=true, ["farmersdelight:bacon"]=true, ["farmersdelight:chicken_cuts"]=true, ["farmersdelight:cod_slice"]=true, ["farmersdelight:minced_beef"]=true, ["farmersdelight:mutton_chops"]=true, ["farmersdelight:salmon_slice"]=true, ["minecraft:beef"]=true, ["minecraft:beetroot"]=true, ["minecraft:brown_mushroom"]=true, ["minecraft:carrot"]=true, ["minecraft:chicken"]=true, ["minecraft:cod"]=true, ["minecraft:egg"]=true, ["minecraft:mutton"]=true, ["minecraft:porkchop"]=true, ["minecraft:potato"]=true, ["minecraft:rabbit"]=true, ["minecraft:red_mushroom"]=true, ["minecraft:salmon"]=true, ["minecraft:tropical_fish"]=true, ["minecraft:turtle_egg"]=true, ["nethers_delight:hoglin_loin"]=true, ["projectvibrantjourneys:bark_mushroom"]=true, ["projectvibrantjourneys:glowcap"]=true, ["quark:glowshroom"]=true, ["simplefarming:raw_bacon"]=true, ["simplefarming:raw_chicken_wings"]=true, ["sushigocrafting:raw_tuna"]=true, ["sushigocrafting:shrimp"]=true, ["undergarden:blood_mushroom"]=true, ["undergarden:indigo_mushroom"]=true, ["undergarden:ink_mushroom"]=true, ["undergarden:raw_gwibling"]=true, ["undergarden:veil_mushroom"]=true, ["upgrade_aquatic:lionfish"]=true, ["upgrade_aquatic:perch"]=true, ["upgrade_aquatic:pike"]=true },
    ["farmersdelight:wolf_prey"] = { ["abnormals_delight:duck_fillet"]=true, ["abnormals_delight:venison_shanks"]=true, ["environmental:duck"]=true, ["environmental:venison"]=true, ["farmersdelight:chicken_cuts"]=true, ["farmersdelight:mutton_chops"]=true, ["minecraft:chicken"]=true, ["minecraft:mutton"]=true, ["minecraft:rabbit"]=true, ["simplefarming:raw_chicken_wings"]=true },
    ["forge:cooked_eggs"] = { ["environmental:fried_egg"]=true, ["farmersdelight:fried_egg"]=true, ["simplefarming:cooked_egg"]=true },
    ["forge:crops/cabbage"] = { ["farmersdelight:cabbage"]=true, ["farmersdelight:cabbage_leaf"]=true },
    ["forge:crops/onion"] = { ["farmersdelight:onion"]=true, ["simplefarming:onion"]=true },
    ["forge:crops/rice"] = { ["farmersdelight:rice"]=true, ["simplefarming:rice"]=true, ["sushigocrafting:rice"]=true },
    ["forge:crops/tomato"] = { ["farmersdelight:tomato"]=true, ["simplefarming:tomato"]=true },
    ["forge:dusts/charcoal"] = { ["emendatusenigmatica:charcoal_dust"]=true, ["mekanism:dust_charcoal"]=true },
    ["forge:dusts/coal"] = { ["bloodmagic:coalsand"]=true, ["emendatusenigmatica:coal_dust"]=true, ["mekanism:dust_coal"]=true },
    ["forge:dusts/ender"] = { ["emendatusenigmatica:ender_dust"]=true },
    ["forge:dusts/gold"] = { ["bloodmagic:goldsand"]=true, ["emendatusenigmatica:gold_dust"]=true, ["immersiveengineering:dust_gold"]=true, ["mekanism:dust_gold"]=true, ["occultism:gold_dust"]=true, ["pedestals:dustgold"]=true, ["thermal:gold_dust"]=true },
    ["forge:dusts/sulfur"] = { ["bloodmagic:sulfur"]=true, ["eidolon:sulfur"]=true, ["emendatusenigmatica:sulfur_dust"]=true, ["immersiveengineering:dust_sulfur"]=true, ["mekanism:dust_sulfur"]=true, ["thermal:sulfur_dust"]=true },
    ["forge:eggs"] = { ["alexsmobs:crocodile_egg"]=true, ["alexsmobs:emu_egg"]=true, ["atum:quail_egg"]=true, ["environmental:duck_egg"]=true, ["minecraft:egg"]=true, ["minecraft:turtle_egg"]=true },
    ["forge:milk"] = { ["farmersdelight:milk_bottle"]=true, ["minecraft:milk_bucket"]=true },
    ["forge:pasta"] = { ["farmersdelight:raw_pasta"]=true, ["simpledelights:squash_noodles"]=true, ["simplefarming:noodles"]=true },
    ["forge:raw_beef"] = { ["farmersdelight:minced_beef"]=true, ["minecraft:beef"]=true },
    ["forge:raw_chicken"] = { ["farmersdelight:chicken_cuts"]=true, ["minecraft:chicken"]=true, ["simplefarming:raw_chicken_wings"]=true },
    ["forge:raw_fishes"] = { ["abnormals_delight:perch_slice"]=true, ["abnormals_delight:pike_slice"]=true, ["alexsmobs:blobfish"]=true, ["aquaculture:arapaima"]=true, ["aquaculture:atlantic_cod"]=true, ["aquaculture:atlantic_halibut"]=true, ["aquaculture:atlantic_herring"]=true, ["aquaculture:bayad"]=true, ["aquaculture:blackfish"]=true, ["aquaculture:bluegill"]=true, ["aquaculture:boulti"]=true, ["aquaculture:brown_shrooma"]=true, ["aquaculture:brown_trout"]=true, ["aquaculture:capitaine"]=true, ["aquaculture:carp"]=true, ["aquaculture:catfish"]=true, ["aquaculture:fish_fillet_raw"]=true, ["aquaculture:gar"]=true, ["aquaculture:minnow"]=true, ["aquaculture:muskellunge"]=true, ["aquaculture:pacific_halibut"]=true, ["aquaculture:perch"]=true, ["aquaculture:pink_salmon"]=true, ["aquaculture:piranha"]=true, ["aquaculture:pollock"]=true, ["aquaculture:rainbow_trout"]=true, ["aquaculture:red_grouper"]=true, ["aquaculture:red_shrooma"]=true, ["aquaculture:smallmouth_bass"]=true, ["aquaculture:synodontis"]=true, ["aquaculture:tambaqui"]=true, ["aquaculture:tuna"]=true, ["betterendforge:end_fish_raw"]=true, ["environmental:koi"]=true, ["farmersdelight:cod_slice"]=true, ["farmersdelight:salmon_slice"]=true, ["minecraft:cod"]=true, ["minecraft:salmon"]=true, ["minecraft:tropical_fish"]=true, ["sushigocrafting:raw_tuna"]=true, ["sushigocrafting:shrimp"]=true, ["undergarden:raw_gwibling"]=true, ["upgrade_aquatic:lionfish"]=true, ["upgrade_aquatic:perch"]=true, ["upgrade_aquatic:pike"]=true },
    ["forge:raw_fishes/cod"] = { ["aquaculture:atlantic_cod"]=true, ["farmersdelight:cod_slice"]=true, ["minecraft:cod"]=true },
    ["forge:raw_fishes/perch"] = { ["abnormals_delight:perch_slice"]=true, ["upgrade_aquatic:perch"]=true },
    ["forge:raw_mutton"] = { ["farmersdelight:mutton_chops"]=true, ["minecraft:mutton"]=true },
    ["forge:raw_pork"] = { ["farmersdelight:bacon"]=true, ["minecraft:porkchop"]=true, ["simplefarming:raw_bacon"]=true },
    ["forge:salad_ingredients"] = { ["farmersdelight:cabbage"]=true, ["farmersdelight:cabbage_leaf"]=true, ["simplefarming:lettuce"]=true, ["simplefarming:spinach"]=true },
    ["forge:vegetables"] = { ["betterendforge:amber_root_raw"]=true, ["farmersdelight:onion"]=true, ["farmersdelight:tomato"]=true, ["minecraft:beetroot"]=true, ["minecraft:carrot"]=true, ["minecraft:potato"]=true, ["simplefarming:broccoli"]=true, ["simplefarming:cassava"]=true, ["simplefarming:corn"]=true, ["simplefarming:cucumber"]=true, ["simplefarming:eggplant"]=true, ["simplefarming:ginger"]=true, ["simplefarming:habanero"]=true, ["simplefarming:lettuce"]=true, ["simplefarming:onion"]=true, ["simplefarming:pea_pod"]=true, ["simplefarming:pepper"]=true, ["simplefarming:radish"]=true, ["simplefarming:sorghum"]=true, ["simplefarming:soybean"]=true, ["simplefarming:spinach"]=true, ["simplefarming:squash"]=true, ["simplefarming:sweet_potato"]=true, ["simplefarming:tomato"]=true, ["simplefarming:turnip"]=true, ["simplefarming:yam"]=true, ["simplefarming:zucchini"]=true, ["sushigocrafting:cucumber"]=true, ["sushigocrafting:soy_bean"]=true },
}

local RECIPES = {
{ id="farmersdelight:cooking/stuffed_pumpkin_block", out="farmersdelight:stuffed_pumpkin_block", container="minecraft:pumpkin", need={ ["#forge:crops/rice"]=1, ["#forge:vegetables"]=1, ["farmersdelight:brown_mushroom_colony"]=1, ["farmersdelight:tomato_sauce"]=1, ["minecraft:baked_potato"]=1, ["minecraft:sweet_berries"]=1 } },
{ id="farmersdelight:cooking/stuffed_pumpkin_block", out="farmersdelight:stuffed_pumpkin_block", container="minecraft:pumpkin", need={ ["#forge:crops/rice"]=1, ["#forge:vegetables"]=1, ["farmersdelight:tomato_sauce"]=1, ["minecraft:baked_potato"]=1, ["minecraft:brown_mushroom"]=1, ["minecraft:sweet_berries"]=1 } },
{ id="farmersdelight:cooking/vegetable_noodles", out="farmersdelight:vegetable_noodles", container="", need={ ["#forge:pasta"]=1, ["#forge:salad_ingredients"]=1, ["#forge:vegetables"]=1, ["minecraft:brown_mushroom"]=1, ["minecraft:carrot"]=1 } },
{ id="farmersdelight:cooking/baked_cod_stew", out="farmersdelight:baked_cod_stew", container="", need={ ["#forge:crops/tomato"]=1, ["#forge:eggs"]=1, ["#forge:raw_fishes/cod"]=1, ["minecraft:potato"]=1 } },
{ id="farmersdelight:cooking/chicken_soup", out="farmersdelight:chicken_soup", container="", need={ ["#forge:raw_chicken"]=1, ["#forge:salad_ingredients"]=1, ["#forge:vegetables"]=1, ["minecraft:carrot"]=1 } },
{ id="farmersdelight:cooking/dog_food", out="farmersdelight:dog_food", container="", need={ ["#farmersdelight:wolf_prey"]=1, ["#forge:crops/rice"]=1, ["minecraft:bone_meal"]=1, ["minecraft:rotten_flesh"]=1 } },
{ id="farmersdelight:cooking/dumplings", out="farmersdelight:dumplings", container="", need={ ["#forge:crops/cabbage"]=1, ["#forge:crops/onion"]=1, ["|#forge:raw_chicken|#forge:raw_pork|#forge:raw_beef|minecraft:brown_mushroom"]=1, ["farmersdelight:wheat_dough"]=1 } },
{ id="farmersdelight:cooking/fried_rice", out="farmersdelight:fried_rice", container="", need={ ["#forge:crops/onion"]=1, ["#forge:crops/rice"]=1, ["#forge:eggs"]=1, ["minecraft:carrot"]=1 } },
{ id="farmersdelight:cooking/noodle_soup", out="farmersdelight:noodle_soup", container="", need={ ["#forge:cooked_eggs"]=1, ["#forge:pasta"]=1, ["#forge:raw_pork"]=1, ["minecraft:dried_kelp"]=1 } },
{ id="farmersdelight:cooking/pumpkin_soup", out="farmersdelight:pumpkin_soup", container="", need={ ["#forge:milk"]=1, ["#forge:raw_pork"]=1, ["#forge:salad_ingredients"]=1, ["farmersdelight:pumpkin_slice"]=1 } },
{ id="farmersdelight:cooking/pyttipanna", out="immersivecooking:pyttipanna", container="", need={ ["#forge:raw_beef"]=1, ["#forge:raw_pork"]=1, ["immersivecooking:diced_onion"]=1, ["immersivecooking:potato_cubes"]=3 } },
{ id="farmersdelight:cooking/rabbit_stew", out="minecraft:rabbit_stew", container="minecraft:bowl", need={ ["|minecraft:brown_mushroom|minecraft:red_mushroom"]=1, ["|minecraft:rabbit|minecraft:cooked_rabbit"]=1, ["minecraft:baked_potato"]=1, ["minecraft:carrot"]=1 } },
{ id="farmersdelight:cooking/ratatouille", out="farmersdelight:ratatouille", container="", need={ ["#forge:crops/onion"]=1, ["#forge:crops/tomato"]=1, ["#forge:vegetables"]=1, ["minecraft:beetroot"]=1 } },
{ id="farmersdelight:cooking/squid_ink_pasta", out="farmersdelight:squid_ink_pasta", container="", need={ ["#forge:crops/tomato"]=1, ["#forge:pasta"]=1, ["#forge:raw_fishes"]=1, ["minecraft:ink_sac"]=1 } },
{ id="farmersdelight:cooking/vegetable_soup", out="farmersdelight:vegetable_soup", container="", need={ ["#forge:salad_ingredients"]=1, ["minecraft:beetroot"]=1, ["minecraft:carrot"]=1, ["minecraft:potato"]=1 } },
{ id="abnormals_delight:perch_with_mushrooms", out="abnormals_delight:perch_with_mushrooms", container="minecraft:bowl", need={ ["#forge:crops/rice"]=1, ["#forge:crops/tomato"]=1, ["#forge:raw_fishes/perch"]=1, ["minecraft:red_mushroom"]=1 } },
{ id="farmersdelight:cooking/beef_stew", out="farmersdelight:beef_stew", container="", need={ ["#forge:raw_beef"]=1, ["minecraft:carrot"]=1, ["minecraft:potato"]=1 } },
{ id="farmersdelight:cooking/fish_stew", out="farmersdelight:fish_stew", container="", need={ ["#forge:crops/onion"]=1, ["#forge:raw_fishes"]=1, ["farmersdelight:tomato_sauce"]=1 } },
{ id="farmersdelight:cooking/hot_cocoa", out="farmersdelight:hot_cocoa", container="", need={ ["#forge:milk"]=1, ["minecraft:cocoa_beans"]=2, ["minecraft:sugar"]=1 } },
{ id="farmersdelight:cooking/pasta_with_meatballs", out="farmersdelight:pasta_with_meatballs", container="", need={ ["#forge:pasta"]=1, ["farmersdelight:minced_beef"]=1, ["farmersdelight:tomato_sauce"]=1 } },
{ id="farmersdelight:cooking/pasta_with_mutton_chop", out="farmersdelight:pasta_with_mutton_chop", container="", need={ ["#forge:pasta"]=1, ["#forge:raw_mutton"]=1, ["farmersdelight:tomato_sauce"]=1 } },
{ id="enigmatica:expert/farmersdelight/cooking/glistering_melon_slice", out="minecraft:glistering_melon_slice", container="", need={ ["#forge:dusts/gold"]=1, ["eidolon:enchanted_ash"]=1, ["minecraft:melon_slice"]=4 } },
{ id="enigmatica:expert/farmersdelight/cooking/golden_apple", out="minecraft:golden_apple", container="", need={ ["#forge:dusts/gold"]=1, ["eidolon:enchanted_ash"]=1, ["minecraft:apple"]=4 } },
{ id="enigmatica:expert/farmersdelight/cooking/golden_carrot", out="minecraft:golden_carrot", container="", need={ ["#forge:dusts/gold"]=1, ["eidolon:enchanted_ash"]=1, ["minecraft:carrot"]=4 } },
{ id="enigmatica:expert/farmersdelight/cooking/gunpowder", out="minecraft:gunpowder", container="", need={ ["#forge:dusts/charcoal"]=1, ["#forge:dusts/sulfur"]=1, ["eidolon:enchanted_ash"]=1 } },
{ id="farmersdelight:cooking/apple_cider", out="farmersdelight:apple_cider", container="", need={ ["minecraft:apple"]=2, ["minecraft:sugar"]=1 } },
{ id="farmersdelight:cooking/cabbage_rolls", out="farmersdelight:cabbage_rolls", container="", need={ ["#farmersdelight:cabbage_roll_ingredients"]=1, ["#forge:crops/cabbage"]=1 } },
{ id="farmersdelight:cooking/cheese_block", out="simplefarming:cheese_block", container="", need={ ["minecraft:milk_bucket"]=1, ["simplefarming:vinegar"]=1 } },
{ id="farmersdelight:cooking/mushroom_stew", out="minecraft:mushroom_stew", container="minecraft:bowl", need={ ["minecraft:brown_mushroom"]=1, ["minecraft:red_mushroom"]=1 } },
{ id="enigmatica:expert/farmersdelight/cooking/ender_calx", out="eidolon:ender_calx", container="", need={ ["#forge:dusts/ender"]=1, ["eidolon:enchanted_ash"]=1 } },
{ id="enigmatica:expert/farmersdelight/cooking/leather", out="minecraft:leather", container="", need={ ["eidolon:enchanted_ash"]=1, ["minecraft:rotten_flesh"]=5 } },
{ id="enigmatica:expert/farmersdelight/cooking/sulfur_dust", out="emendatusenigmatica:sulfur_dust", container="", need={ ["#forge:dusts/coal"]=1, ["eidolon:enchanted_ash"]=1 } },
{ id="farmersdelight:cooking/beetroot_soup", out="minecraft:beetroot_soup", container="minecraft:bowl", need={ ["minecraft:beetroot"]=3 } },
{ id="farmersdelight:cooking/cooked_rice", out="farmersdelight:cooked_rice", container="", need={ ["#forge:crops/rice"]=1 } },
{ id="farmersdelight:cooking/tomato_sauce", out="farmersdelight:tomato_sauce", container="", need={ ["#forge:crops/tomato"]=2 } },
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

-- 成品导出外设（机械动力溜槽之类）：厨锅的成品槽被它抽走，脚本再从它这里抽到接口
local export_name = nil
if export_peripheral then
    for _, n in ipairs(peripheral.getNames()) do
        if string.match(n, export_peripheral) then export_name = n break end
    end
end
if export_name then
    print(("export peripheral = %s (%d slots)"):format(export_name, peripheral.call(export_name, "size")))
elseif export_peripheral then
    print("no '" .. export_peripheral .. "' peripheral found, will fall back to pulling the pot's own output slot")
end

local pots, known, busy, size_of, learned = {}, {}, {}, {}, {}
local last_nomatch, warned = {}, {}

-- 读厨锅内容；外设掉线/被拆掉时不再报错，并把这张锅从列表里移除（重新连上会自动加回来）
local function pot_items(name)
    local ok, items = pcall(peripheral.call, name, "list")
    if not ok or type(items) ~= "table" then
        if known[name] then
            known[name] = nil
            busy[name] = nil
            learned[name] = nil
            for i = #pots, 1, -1 do
                if pots[i] == name then table.remove(pots, i) end
            end
            print(("[%s] peripheral is gone, removed (reconnects will re-add it)"):format(name))
        end
        return {}
    end
    return items
end

local function describe(items, limit)
    local desc = {}
    for i = 1, (limit or 9) do
        if items[i] then
            desc[#desc + 1] = ("%d:%s x%d"):format(i, items[i].name, items[i].count)
        end
    end
    return #desc > 0 and table.concat(desc, ", ") or "(empty)"
end

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

local function amount_of(item)
    return craft_amount[item] or per_craft
end

local function snapshot(name)
    local items = pot_items(name)
    local snap = {}
    for i = 1, size_of[name] do
        local it = items[i]
        snap[i] = it and (it.name .. "x" .. it.count) or nil
    end
    return snap
end

local function turtle_slot_of(item)
    for i = 1, input_slots do
        if turtle.getItemCount(i) > 0 then
            local d = turtle.getItemDetail(i)
            if d and d.name == item then return i end
        end
    end
end

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

-- ===== 配方匹配（自动表）=====================================================
local function key_matches(key, item)
    local head = key:sub(1, 1)

    if head == "#" then
        local tag = key:sub(2)
        local map = TAG_ITEMS[tag]
        if map and map[item] == true then return true end

        -- 标签表里没有这个物品时，也按"物品名里含标签末段"再猜一次（例如 #forge:milk ↔ farmersdelight:milk_bottle）
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
            if pass == 2 or recipe_trusted(r) then
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

local function diagnose(available)
    local kinds = {}
    for name in pairs(available) do kinds[#kinds + 1] = name end

    local scored = {}
    for _, r in ipairs(RECIPES) do
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
-- 把 1 个物品放进第一个"能接受它的空格子"（厨锅的输入/容器/成品是按面过滤的，所以不写死槽号）
local function put_one(name, from_slot)
    for s = 1, size_of[name] do
        if pot_items(name)[s] == nil then
            local ok, placed = pcall(peripheral.call, name, "pullItems", turtle_inv, from_slot, 1, s)
            if ok and placed and placed > 0 then return s end
        end
    end
end

local function load_plan(name, plan)
    local mark, moved = nil, 0
    for _, p in ipairs(plan) do
        local src = turtle_slot_of(p.item)
        if src then
            if not mark then mark = p.item end
            for _ = 1, p.count do
                local s = put_one(name, src)
                if s then
                    moved = moved + 1
                    if verbose then print(("[%s] +%s -> slot %d"):format(name, p.item, s)) end
                else
                    print(("[%s] could not insert %s (no free slot accepts it on this modem face)"):format(name, p.item))
                    break
                end
            end
        end
    end
    return mark, moved
end

-- 兜底装料：每种原料占 amount_of() 个格子
local function load_fallback(name)
    local mark, moved = nil, 0
    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local d = turtle.getItemDetail(i)
            local item = d and d.name
            local want = amount_of(item)
            if not mark then mark = item end
            for _ = 1, want do
                local s = put_one(name, i)
                if s then
                    moved = moved + 1
                    if verbose then print(("[%s] +%s -> slot %d"):format(name, item, s)) end
                else
                    break
                end
            end
        end
    end
    return mark, moved
end

local function has_full_set()
    local kinds = 0
    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            kinds = kinds + 1
            local d = turtle.getItemDetail(i)
            if n < amount_of(d and d.name) then return false end
        end
    end
    return kinds > 0
end

local function slot_holding(name, item)
    local items = pot_items(name)
    for i = 1, size_of[name] do
        if items[i] and items[i].name == item then return i, items[i].count end
    end
end

-- 这张配方要什么容器：优先用 container_by_output 里按产物补的，其次用配方表里的 container
local function recipe_container(recipe)
    if not recipe then return nil end
    local byOut = recipe.out and container_by_output[recipe.out]
    if byOut and byOut ~= "" then return byOut end
    if recipe.container and recipe.container ~= "" then return recipe.container end
    return nil
end

-- 在海龟里找容器：优先找这张配方要的那个容器（任何格子都行），找不到再用 container_slot 指定的格子
local function find_container_slot(recipe)
    local want = recipe_container(recipe)
    if want then
        for i = 1, 16 do
            if turtle.getItemCount(i) > 0 then
                local d = turtle.getItemDetail(i)
                if d and d.name == want then return i, d.name end
            end
        end
    end
    if container_slot and turtle.getItemCount(container_slot) > 0 then
        local d = turtle.getItemDetail(container_slot)
        if d then return container_slot, d.name end
    end
end

-- 补容器：只往厨锅的容器格（container_index，默认 8）里放，绝不会塞进输入格
local function keep_containers(name, recipe, warned)
    local from, item = find_container_slot(recipe)
    if not from then
        local want = recipe_container(recipe)
        if want and verbose and not warned.container then
            warned.container = true
            print(("[%s] no %s in the turtle: put it in ANY turtle slot"):format(name, want))
        end
        return
    end

    local s = container_index or learned[name].container
    if not s or s > size_of[name] then return end
    learned[name].container = s

    local cur = pot_items(name)[s]
    local have = 0
    if cur then
        if cur.name ~= item then
            if verbose and not warned.container then
                warned.container = true
                print(("[%s] slot %d already has %s, not %s (take it out by hand?)"):format(name, s, cur.name, item))
            end
            return
        end
        have = cur.count
    end

    if have < container_keep then
        local ok, moved = pcall(peripheral.call, name, "pullItems", turtle_inv, from, container_keep - have, s)
        if ok and moved and moved > 0 then
            if verbose then
                print(("[%s] topped up %d x %s into slot %d"):format(name, moved, item, s))
            end
        else
            -- 有些面不能用槽号指定：不指定槽号时，厨锅会按面自己路由（侧面 → 容器格）
            local ok2, moved2 = pcall(peripheral.call, name, "pullItems", turtle_inv, from, container_keep - have)
            if ok2 and moved2 and moved2 > 0 then
                local now = pot_items(name)[s]
                if now and now.name == item then
                    print(("[%s] topped up %d x %s (auto-routed into slot %d)"):format(name, moved2, item, s))
                else
                    print(("[%s] %d x %s was inserted but NOT into slot %d - it went to a wrong slot, take it out / check the modem face")
                        :format(name, moved2, item, s))
                end
            elseif verbose and not warned.container then
                warned.container = true
                print(("[%s] cannot insert %s into slot %d from this modem face - containers go in from a SIDE of the pot")
                    :format(name, item, s))
            end
        end
    end
end

local function add_pot(name)
    if known[name] then return end
    known[name] = true
    busy[name] = false
    size_of[name] = peripheral.call(name, "size")
    learned[name] = {}
    table.insert(pots, name)
    print(("cooking pot %s (%d slots visible)"):format(name, size_of[name]))
end

for _, name in pairs(peripheral.getNames()) do
    if string.match(name, "cooking_pot") ~= nil then
        add_pot(name)
    end
end
assert(#pots > 0, "no cooking_pot peripheral found (farmersdelight:cooking_pot_*), check the wired network")

for _, name in ipairs(pots) do
    print(("[%s] contents: %s"):format(name, describe(pot_items(name), size_of[name])))
end

local function pulse()
    redstone.setOutput(direction, false)
    sleep(0.05)
    redstone.setOutput(direction, true)
end

-- 清掉厨锅里上次剩下的东西（输入格 + 已知的显示/成品格），容器格不动
local function clean_pot(name)
    local items = pot_items(name)
    local l = learned[name]
    local drained = {}
    for i = 1, size_of[name] do
        local it = items[i]
        if it and i ~= l.container and (i <= input_slots or i == l.meal or i == l.out) then
            pcall(peripheral.call, output, "pullItems", name, i)
            drained[#drained + 1] = ("%d:%s"):format(i, it.name)
        end
    end
    if #drained > 0 then
        print(("[%s] cleaned leftovers: %s"):format(name, table.concat(drained, ", ")))
    end
end

-- 等某个格子从"没有/不同"变成新东西，返回格子号
local function wait_new_item(name, before, timeout, what)
    local waited = 0
    while true do
        sleep(check_delay)
        waited = waited + check_delay
        local items = pot_items(name)
        for i = 1, size_of[name] do
            local it = items[i]
            if it and it.name ~= before[i] then
                print(("[%s] %s appeared in slot %d: %s x%d"):format(name, what, i, it.name, it.count))
                return i, it.name
            end
        end
        if waited >= timeout then
            print(("[%s] waited %ds for %s, giving up this round"):format(name, timeout, what))
            return nil
        end
    end
end

-- 等菜做好（显示槽出现东西），必要时补容器，然后把成品抽到接口
local function cook_and_collect(name, recipe)
    local l = learned[name]

    local before = snapshot(name)
    if not l.meal then
        l.meal = wait_new_item(name, before, cook_timeout, "cooked meal")
        if not l.meal then
            busy[name] = false
            os.queueEvent("turtle_inventory")
            return
        end
    end

    keep_containers(name, recipe, warned)

    -- 认成品格：显示槽之外"新出现东西"的那一格
    local out = l.out
    if not out then
        local before2 = snapshot(name)
        local waited = 0
        while waited < cook_timeout and not out do
            sleep(check_delay)
            waited = waited + check_delay
            local items = pot_items(name)
            for i = 1, size_of[name] do
                local it = items[i]
                if it and it.name ~= before2[i] and i ~= l.meal and i ~= l.container then
                    out = i
                    l.out = i
                    print(("[%s] output slot = %d"):format(name, i))
                    break
                end
            end
        end
    end

    if not out then
        print(("[%s] no output slot found (container wrong? no heat? modem face not allowed?)"):format(name))
        busy[name] = false
        os.queueEvent("turtle_inventory")
        return
    end

    if export_name then
        -- 产物流向溜槽，交给下面的导出协程，这里不用管
        if verbose then
            print(("[%s] meal ready; %s will be drained to the interface"):format(name, export_name))
        end
    elseif collect_output then
        local waited = 0
        while pot_items(name)[out] == nil and waited < cook_timeout do
            sleep(check_delay)
            waited = waited + check_delay
        end

        local ok, moved = pcall(peripheral.call, output, "pullItems", name, out, 64)
        if not ok or not moved or moved == 0 then
            print(("[%s] cannot pull slot %d from this modem face - put the modem/wired modem at the pot's bottom, or use a hopper/chute under the pot"):format(name, out))
        elseif verbose then
            print(("[%s] collected %d from slot %d -> %s"):format(name, moved, out, describe(pot_items(name), size_of[name])))
        end
    else
        if verbose then
            print(("[%s] meal ready; output left for your own extraction"):format(name))
        end
    end

    busy[name] = false
    os.queueEvent("turtle_inventory")
end

if (turtle.getItemCount(1) ~= 0) then
    os.queueEvent("turtle_inventory")
else
    if redstone_flag then
        pulse()
    end
end

create_runner(function(spawn)
    spawn(function()
        while true do
            local _, name = os.pullEvent("peripheral")
            if type(name) == "string" and string.match(name, "cooking_pot") ~= nil then
                add_pot(name)
            end
        end
    end)

    -- 导出协程：把溜槽（导出外设）里的成品不停抽到接口
    spawn(function()
        while true do
            if export_name then
                local ok, size = pcall(peripheral.call, export_name, "size")
                if ok and size then
                    local items = pot_items(export_name)
                    local total = 0
                    for i = 1, size do
                        if items[i] then
                            local ok, moved = pcall(peripheral.call, output, "pullItems", export_name, i, 64)
                            if ok then total = total + (moved or 0) end
                        end
                    end
                    if total > 0 and verbose then
                        print(("[%s] exported %d items -> interface"):format(export_name, total))
                    end
                end
            end
            sleep(export_poll)
        end
    end)

    spawn(function()
        while true do
            local loaded = false
            for _, name in ipairs(pots) do
                if not busy[name] then
                    local available = {}
                    for i = 1, input_slots do
                        local n = turtle.getItemCount(i)
                        if n and n > 0 then
                            local d = turtle.getItemDetail(i)
                            if d then available[d.name] = (available[d.name] or 0) + n end
                        end
                    end

                    local plan, recipe = match_recipe(available)
                    local mark, moved

                    if plan then
                        if verbose then
                            print(("[%s] recipe %s | turtle: %s"):format(name, recipe.out or "?", describe_turtle()))
                        end
                        clean_pot(name)
                        keep_containers(name, recipe, warned)
                        mark, moved = load_plan(name, plan)
                    elseif has_full_set() then
                        local sig = describe_turtle()
                        if last_nomatch[name] ~= sig then
                            last_nomatch[name] = sig
                            print(("[%s] no recipe matched, using per_craft/craft_amount | turtle: %s"):format(name, sig))
                            diagnose(available)
                        end
                        clean_pot(name)
                        keep_containers(name, nil, warned)
                        mark, moved = load_fallback(name)
                    end

                    if moved and moved > 0 then
                        if verbose then
                            print(("[%s] loaded %d entries -> %s"):format(name, moved, describe(pot_items(name), size_of[name])))
                        end
                        busy[name] = true
                        if redstone_flag then pulse() end
                        spawn(function() cook_and_collect(name, recipe) end)
                        loaded = true
                        sleep(0.05)
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
