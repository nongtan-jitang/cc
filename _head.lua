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
