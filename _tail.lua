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
