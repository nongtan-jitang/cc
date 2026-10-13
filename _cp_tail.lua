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
