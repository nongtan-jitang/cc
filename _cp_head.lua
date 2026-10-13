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
