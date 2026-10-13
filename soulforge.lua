--血魔法3 狱火锻炉（Hellfire Forge / bloodmagic:soulforge）自动合成
--注意：意志槽里要先放好东西（能存恶魔意志的物品，比如充过能的地狱魂石），否则锻炉永远不会开始合成
local direction = "left" -- 脉冲发送位置 合成仓相较于海龟的位置 记得调脉冲模式 使用ae可无视，记得开阻挡，或者用脉冲也行
local redstone_flag = true -- 默认使用脉冲模式
local check_delay = 0.5 -- 默认检测合成完毕延迟 0.5s
local output_name = "refinedstorage:interface" -- 默认产物输出位置rs物品接口，使用ae需调整

local per_craft = 1 -- 一份配方里每种原料几个（狱火锻炉的配方都是每种 1 个）
local input_slots = 6 -- 海龟用第 1~6 格装原料（锻炉只有 4 个材料槽，超过 4 种会装不进去并提示）
local feed_settle = 0.3 -- 收到 turtle_inventory 后等一小会儿，确保整批原料都到齐再发料
local craft_timeout = 60 -- 等产物超过这么久就打印一次提醒（秒）
local verbose = true -- 每次装料后打印锻炉里现在有什么（调试用，跑顺了可以改 false）

-- 槽位布局：modem 贴在狱火锻炉的哪一面（填错会导致抽错格子，所以请确认真实情况）
--   "side" = 侧面（南北东西）：材料 1~4 / 意志 5 / 产物 6   <- 1.16.x 永远是这个
--   "up"   = 正上方：       材料 2~5 / 意志 1 / 产物 6
--   "down" = 正下方：       材料 2~5 / 意志 6 / 产物 1
-- 多台锻炉 modem 方位不同时，可以写成 table：
--   local layout = { default = "side", ["bloodmagic:soulforge_1"] = "up" }
local layout = "side"

-- 海龟在有线网络上的名字（截图里是 turtle_2，脚本启动时还会自动校正一次）
local turtle_inv = "turtle_2"

local LAYOUTS = {
    side = { key = "side", desc = "modem 在侧面", mat = { 1, 2, 3, 4 }, gem = 5, out = 6 },
    up   = { key = "up", desc = "modem 在正上方", mat = { 2, 3, 4, 5 }, gem = 1, out = 6 },
    down = { key = "down", desc = "modem 在正下方", mat = { 2, 3, 4, 5 }, gem = 6, out = 1 },
}
assert(LAYOUTS[type(layout) == "table" and (layout.default or "side") or layout], "layout 只能填 \"side\" / \"up\" / \"down\"")

local function layout_for(name)
    if type(layout) == "table" then
        return LAYOUTS[layout[name] or layout.default or "side"]
    end
    return LAYOUTS[layout]
end

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

local forge_list, known, busy = {}, {}, {}
local warned_out, warned_will, warned_stray, warned_insert = {}, {}, {}, {}

local function forge_items(name)
    return peripheral.call(name, "list") or {}
end

local function describe(items)
    local desc = {}
    for i = 1, 6 do
        if items[i] then
            desc[#desc + 1] = ("%d:%s x%d"):format(i, items[i].name, items[i].count)
        end
    end
    return #desc > 0 and table.concat(desc, ", ") or "(空)"
end

-- 海龟身上现在有哪些原料（第 1~16 格都列出来，方便发现原料被放到了后面几格）
local function describe_turtle()
    local desc = {}
    for i = 1, 16 do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local d = turtle.getItemDetail(i)
            desc[#desc + 1] = ("%d:%s x%d"):format(i, d and d.name or "?", n)
        end
    end
    return #desc > 0 and table.concat(desc, ", ") or "(空)"
end

local function add_forge(name)
    if known[name] then return end
    known[name] = true
    busy[name] = false
    local lay = layout_for(name)
    assert(peripheral.call(name, "size") == 6, name .. " 不是狱火锻炉？（应该是 6 格：4 材料 + 1 意志 + 1 产物）")
    table.insert(forge_list, name)
    print(("[%s] 已登记，布局按「%s」：材料槽 %s / 意志槽 %d / 产物槽 %d")
        :format(name, lay.desc, table.concat(lay.mat, ","), lay.gem, lay.out))
end

for _, name in pairs(peripheral.getNames()) do
    if string.match(name, "soulforge_") ~= nil then
        add_forge(name)
    end
end
assert(#forge_list > 0, "没有找到 soulforge 外设（狱火锻炉），检查有线网络")

-- 启动时打印锻炉里现有的东西（不要清空：意志槽里的东西要留着）
for _, name in ipairs(forge_list) do
    local lay = layout_for(name)
    local items = forge_items(name)
    print(("[%s] 现有内容: %s"):format(name, describe(items)))

    -- 只提示、不动作：东西出现在 layout=side 的产物槽(6)或材料槽首格(1)时，可能说明 modem 方位设错了
    local filled = {}
    for i = 1, 6 do
        if items[i] then filled[#filled + 1] = i end
    end
    if #filled == 1 and lay.key == "side" and (filled[1] == 1 or filled[1] == 6) then
        print(("[%s] 提示：唯一的东西在第 %d 格。如果你把存意志的物品放在了意志槽，它应该在第 5 格——"):format(name, filled[1]))
        print("        这说明 modem 可能贴在锻炉的正上方(up)或正下方(down)，请把脚本里的 layout 改成对应值")
    end
end

local function pulse()
    redstone.setOutput(direction, false)
    sleep(0.05)
    redstone.setOutput(direction, true)
end

-- 海龟里的原料够不够一份（第 1~input_slots 格里每种都要有 per_craft 个）
local function has_full_set()
    local kinds = 0
    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            kinds = kinds + 1
            if n < per_craft then return false, kinds end
        end
    end
    return kinds > 0, kinds
end

-- 原料被放到海龟更后面的格子里了：提醒一下（脚本只用第 1~input_slots 格）
local function check_stray_items()
    if warned_stray[1] then return end
    for i = input_slots + 1, 16 do
        if turtle.getItemCount(i) > 0 then
            warned_stray[1] = true
            print(("提示：海龟第 %d 格里也有物品，但脚本只用第 1~%d 格装原料（挪到前面，或改 input_slots）")
                :format(i, input_slots))
            return
        end
    end
end

-- 锻炉完全空的话，说明没放意志物品，合成不会开始
local function check_will(name, lay)
    local items = forge_items(name)
    for i = 1, 6 do
        if items[i] then return end
    end
    if not warned_will[name] then
        warned_will[name] = true
        print(("[%s] 锻炉是空的：意志槽(第 %d 格)要先放一枚存有恶魔意志的物品（地狱魂石/恶魔意志），否则不会开始合成")
            :format(name, lay.gem))
    end
end

-- 把一份原料显式放进材料槽（指定 toSlot，所以地狱魂石这类意志物品不可能跑到意志槽里去）
local function load_one_set(name, lay)
    local moved, failed = 0, {}
    local next_slot = 1

    for i = 1, input_slots do
        local n = turtle.getItemCount(i)
        if n and n > 0 then
            local placed = 0
            while placed == 0 and next_slot <= #lay.mat do
                -- 这个材料槽放不进去（比如被别的残留占着）就换下一个
                placed = peripheral.call(name, "pullItems", turtle_inv, i, per_craft, lay.mat[next_slot])
                if placed == 0 then next_slot = next_slot + 1 end
            end

            if placed > 0 then
                moved = moved + 1
            else
                failed[#failed + 1] = i
            end
        end
    end

    return moved, failed
end

-- 等产物出现 -> 只抽产物槽 -> 这张锻炉重新变空闲
-- 前提：装料时产物槽是空的（装载循环已经保证），所以这里绝不会抽到"原本就在炉子里的东西"
local function wait_and_collect(name, lay)
    local waited = 0
    while true do
        sleep(check_delay)
        waited = waited + check_delay
        if forge_items(name)[lay.out] ~= nil then break end

        if waited >= craft_timeout then
            waited = 0
            print(("[%s] 等了 %d 秒还没出产物，检查：①意志够不够 ②材料槽里的东西是否正好是配方所需 ③layout 是否设对（第 %d 格没等到东西）")
                :format(name, craft_timeout, lay.out))
        end
    end

    peripheral.call(output, "pullItems", name, lay.out, 64)

    busy[name] = false
    os.queueEvent("turtle_inventory") -- 叫醒装载循环：还有料的话就继续喂别的空闲锻炉
end

if (turtle.getItemCount(1) ~= 0) then
    os.queueEvent("turtle_inventory")
else
    if redstone_flag then
        pulse() -- 海龟是空的，先催一次合成仓给料
    end
end

create_runner(function(spawn)
    -- 新锻炉接入网络时自动登记
    spawn(function()
        while true do
            local _, name = os.pullEvent("peripheral")
            if type(name) == "string" and string.match(name, "soulforge_") ~= nil then
                add_forge(name)
            end
        end
    end)

    -- 装载循环：海龟里有料、又有空闲锻炉时，给每张锻炉各发一份（所有锻炉并行合成）
    spawn(function()
        while true do
            local loaded = false
            for _, name in ipairs(forge_list) do
                if not busy[name] and has_full_set() then
                    local lay = layout_for(name)

                    -- 安全铁律：产物槽里已经有东西就完全不碰这台锻炉（既不装料也不抽取）
                    if forge_items(name)[lay.out] ~= nil then
                        if not warned_out[name] then
                            warned_out[name] = true
                            print(("[%s] 第 %d 格（按 layout=%s 是产物槽）里已经有东西：%s")
                                :format(name, lay.out, lay.key, describe(forge_items(name))))
                            print("        脚本不会动它。请手动取走；如果那格其实是你放意志物品的格子，说明 layout 设错了，改成 up / down")
                        end
                    else
                        check_will(name, lay)
                        check_stray_items()

                        if verbose then
                            print(("[%s] 海龟原料: %s"):format(name, describe_turtle()))
                        end

                        local moved, failed = load_one_set(name, lay)
                        if moved > 0 then
                            if #failed > 0 and not warned_insert[name] then
                                warned_insert[name] = true
                                local slots = {}
                                for _, i in ipairs(failed) do slots[#slots + 1] = tostring(i) end
                                print(("[%s] 海龟第 %s 格的原料没能装进锻炉（材料槽只有 4 个，或 layout 设错了）")
                                    :format(name, table.concat(slots, ",")))
                            end
                            if verbose then
                                print(("[%s] 装入 %d 种 -> 现在: %s"):format(name, moved, describe(forge_items(name))))
                            end

                            busy[name] = true
                            if redstone_flag then pulse() end -- 催合成仓放下一批料
                            spawn(function() wait_and_collect(name, lay) end)
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
