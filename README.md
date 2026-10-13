# alchemytable-cc

CC:Tweaked 海龟 × 血魔法3（Blood Magic 3）炼金术桌自动化脚本，支持**多张炼金桌并行合成**。

脚本基于 [MC百科教程《CC:Tweaked 在血魔法炼金术桌自动化的应用》](https://www.mcmod.cn/post/4291.html)（原作者 hinyb，pastebin `zAUY6TDX`）修改而来，修掉了原脚本的两个坑，并把"一次只喂一张桌子"改成"所有桌子并行开工"。

仓库里现在有两份脚本：

- `alchemytable.lua` —— 炼金术桌（`alchemytable_*`）
- `soulforge.lua` —— 狱火锻炉（Hellfire Forge，`bloodmagic:soulforge_*`），见文末章节

## 前置条件

- Minecraft 1.16.5+ / CC:Tweaked 1.94.0 及以上（需要 CC 自带的通用 `inventory` 外设，即 `size` / `list` / `pullItems`）
- 炼金术桌先配置好输入输出，并且 `peripheral.call(name, "size") == 7`
- 一条有线网络（有线调制解调器 + 网络线缆）把 **海龟、所有炼金桌、产物输出口** 连在一起，调制解调器记得右键开启
- 海龟旁有能放料的"合成仓"，`direction` 指向它，并调成脉冲模式

## 配置项

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `direction` | `"left"` | 红石脉冲输出方向（合成仓相对于海龟的方向） |
| `redstone_flag` | `true` | 是否用脉冲催合成仓放料 |
| `check_delay` | `0.5` | 轮询"合成是否完成"的间隔（秒） |
| `output_name` | `"refinedstorage:interface"` | 产物输出口的外设类型（AE 用户自行改） |
| `per_craft` | `1` | 每种原料默认放**几份**（= 占桌子几个格子，每格 1 个） |
| `craft_amount` | `{}` | 按物品名覆盖份数，给"同一种原料出现多次"的配方用，例如 `["minecraft:sweet_berries"] = 3` |
| `input_slots` | `6` | 海龟用第 1~6 格装原料 |
| `table_input_slots` | `6` | 炼金桌的输入格数（固定 6 个，别改） |
| `craft_timeout` | `60` | 等产物超过这么久就提醒一次（并提示检查份数/宝珠/LP） |
| `hint_delay` | `15` | 装料后超过这么久还没动静就先提示一次（并打印桌子当前的项数） |
| `drain_on_timeout` | `false` | 超时后是否把桌子里的东西抽回接口，避免一直占着桌子 |
| `verbose` | `true` | 打印海龟原料和桌子内容（调试用） |
| `feed_settle` | `0.3` | 收到 `turtle_inventory` 后等一小会儿，确保整批原料都到齐 |
| `turtle_inv` | `"turtle_1"` | 海龟在有线网络上的名字，启动时会用 `getNameLocal()` 自动校正 |

## 工作流程

1. 启动时扫描网络上的 `alchemytable_*`，打印桌上现有内容（**不清空**，避免误抽掉血之宝珠）
2. 海龟第 1~6 格 = 每种原料一格；每种都够它该占的份数时，给**每张空闲的桌子各发一份**——**每种原料占 `份数` 个独立格子，每格放 1 个**，然后脉冲催料
3. 每张桌子一个协程：轮询桌子，第 1 格变化或出现新格子即视为合成完毕，**只抽"装料时没有、现在有"的格子**（产物和容器剩余物），桌子重新变空闲
4. 有新桌子接入网络（`peripheral` 事件）会自动登记

### 同一种原料出现多次的配方（重要）

炼金桌的配方匹配是**按"非空输入格的项数 + 每格的物品种类"**来的，跟堆叠数量无关，源码写得很直白（[BloodMagicRecipeRegistrar.getAlchemyTable](https://github.com/WayofTime/BloodMagic/blob/1.16.3/src/main/java/wayoftime/bloodmagic/impl/BloodMagicRecipeRegistrar.java)）：

```java
if (recipe.getInput().size() != input.size()) continue;   // 项数必须相等
...
if (ingredient.test(input.get(i))) { matched = true; recipeInput.remove(j); }   // 只看种类，不看数量
```

- `input` = 6 个输入格里**非空**的那些（每个格子算 1 项，格子里堆几个无所谓）；
- 配方本体是 `List<Ingredient>`，**没有数量字段**。

所以 **JEI 里同一种原料画了几个图标，它就要占几个格子**（例如 tau_oil：弱命果 ×3 + 骨粉 ×1 = 4 项 = 4 个格子）。

**脚本现在自带配方表**（从 `BloodMagic-1.16.4-3.1.13-39.jar` 的 `data/bloodmagic/recipes/alchemytable/*.json` + E6E expert 的 `kubejs/server_scripts/.../recipetypes/bloodmagic/alchemytable.js` 生成，合并 E6E 覆盖后共 122 条）：

- 装载时拿海龟手里的原料**自动匹配**，算出每种要占几个格子（两遍匹配：先只用"全是具体物品 / 已解析标签"的配方，减少摆错风险）；
- 匹配不上时才退回 `per_craft` / `craft_amount` 手动份数，并打印 `no recipe matched ...`：

```lua
local per_craft = 1                 -- 兜底：每种占 1 格
local craft_amount = {
    -- ["bloodmagic:weak_tau"] = 3, -- 想手动覆盖某条配方时写这里（自动匹配优先）
}
```

- 标签（`#forge:dusts/redstone` 之类）已从所有 mod jar 的 `data/*/tags/items/**` 解析成具体物品（29 个）；少数没解析到的退化成"物品名里含标签末段"的模糊匹配；
- 带 NBT 的条目（药水、灵气瓶那种）CC 分不清 NBT，标记 `nbt=true` **不参与自动匹配**，这种配方用 `craft_amount` 手动处理；
- 更新整合包后可用 `D:\mc\gen_recipes.ps1`（改里面的实例路径）重新生成并自动拼出 `alchemytable.lua`。

脚本为此做了三件事：

1. **只用空格子**：每种原料的每一份都放进一个**空**输入格，绝不再往已有物品的格子里叠（叠进去只算 1 项，配方就永远配不上，表现就是"两个原料跑进同一个格子"）；
2. **装料前清残留**：非空项数必须正好等于配方项数，上一次失败的残留会让项数变多。所以装载前会把①最后一格（按输入输出配置就是输出格）②装着"海龟当前也有的那种原料"的格子，抽回接口，并打印 `cleaned old stuff: ...`；血之宝珠、炼金瓶之类一律不碰；
3. **打印项数**：`loaded N entries -> ...` 里的 N 就是桌子现在的项数，拿去和 JEI 里一排图标的总数对照，不相等就说明 `craft_amount` 还没配对。

> 终端默认字体显示不了中文，所以脚本运行时打印的都是英文短句（注释和本文档仍是中文）。

## 相对原脚本的改动

1. **海龟名字**：原脚本写 `"turtle_" .. os.getComputerID()`。有线网络上的外设名是 `类型_编号`，编号由 CC 内部按类型单独计数（`ServerContext.getNextId("peripheral." + 类型)`），和电脑 ID 是两套号段，所以经常对不上，报
   `Source 'turtle_x' does not exist`。现在写死实际名字，并在启动时用有线调制解调器的 `getNameLocal()` 自动校正。
   （海龟**看不到自己**在 `peripheral.getNames()` 里的名字，CC 把自己的名字从 modem 的远端列表里排除了，只能问 `getNameLocal()`。）
2. **一张桌子只拿一份配方**：原脚本 `for _ = 1, item_count` 按**个数**搬运，把海龟某一格的整叠原料一个个塞进桌子的第 1、2、3…格，超过 7 格就报
   `To slot out of range (between 1 and 7)`。现在每种原料只搬 `per_craft` 个。
3. **多桌并行**：原脚本用 `machine_list[1]` 取一张桌子、做完再换下一张，同一时间只有一张桌子在工作；现在所有空闲桌子同时开工。
4. **事件参数**：原脚本 `os.pullEvent("peripheral")` 没接收参数，直接用全局变量 `name`（nil），新桌子接入时会报
   `bad argument #1 to 'match' (string expected, got nil)`。现在改成 `local _, name = os.pullEvent("peripheral")`。

## 用法

把 `alchemytable.lua` 拷到海龟上（`edit` 里 Ctrl+V 粘贴，或用 `pastebin` / `wget`），然后：

```
alchemytable
```

启动时会打印：

```
turtle_inv = turtle_1
alchemy table found: alchemytable_0
...
```

如果打印出来的 `turtle_inv` 和你写死的不一样，把脚本里 `local turtle_inv = "turtle_1"` 改成打印出来的值即可（一般不用管，会自动用真实名字）。

## 已知限制

- 完成判定沿用原逻辑：轮询桌子第 1 格，要求放进去的第一种原料在合成后一定会变化（被消耗或变成产物），否则会一直等下去。
- `per_craft` 对所有原料统一生效；如果配方里不同原料数量不同，需要自己扩展成按物品名配置。
- 海龟里如果混进了非当前配方的物品，`has_full_set()` 会一直不满足，脚本会停在等待状态（不会报错）。

## 上传到 GitHub

本目录自带 `push-to-github.ps1`，在本目录下执行：

```powershell
pwsh -File .\push-to-github.ps1                                  # 建 public 仓库并推送
pwsh -File .\push-to-github.ps1 -RepoName 我的仓库名 -Visibility private
```

脚本会自动 `git init / add / commit`，然后：

- 装了 [GitHub CLI](https://cli.github.com/) 且已 `gh auth login` → 直接 `gh repo create ... --push`，全自动；
- 没装 gh → 让你输入用户名和仓库名，并推到 `https://github.com/<用户名>/<仓库名>.git`（先在网页上建一个**空仓库**，密码处粘贴 Personal Access Token）。

也可以手动来一遍：

```powershell
cd D:\mc\alchemytable-cc
git init -b main
git add .
git commit -m "Add CC:Tweaked alchemy table automation script"
gh repo create alchemytable-cc --public --source=. --remote=origin --push
```

## 狱火锻炉（Hellfire Forge）版：soulforge.lua

血魔法3 的狱火锻炉（`bloodmagic:soulforge`，[MC百科词条](https://www.mcmod.cn/item/545594.html)）也能用同一套思路自动化，脚本见 `soulforge.lua`，逻辑与炼金术桌版一致，差异如下：

| 项目 | 炼金术桌版 | 狱火锻炉版 |
| --- | --- | --- |
| 外设匹配 | `alchemytable_` | `soulforge_`（在线名字形如 `bloodmagic:soulforge_0`） |
| 槽位 | 7 格（材料 + 产物） | 6 格：4 个材料槽 + 1 个意志槽 + 1 个产物槽 |
| 发料 | 指定 toSlot 放进第 1、2…格 | 指定 toSlot 放进**材料槽**（按 modem 方位推导出的槽号） |
| 完成判定 | 第 1 格物品变化 | 产物槽出现物品 |
| 收产物 | 抽 1~7 格 | 只抽产物槽，绝不碰意志槽 |
| 原料格数 | 海龟 1~6 格 | 海龟 1~6 格（`input_slots = 6`，超过 4 种会提示装不进去） |

锻炉的关键机制（来自 [TileSoulForge.java](https://github.com/WayofTime/BloodMagic/blob/1.20.1/src/main/java/wayoftime/bloodmagic/common/tile/TileSoulForge.java)、[TileInventory.java](https://github.com/WayofTime/BloodMagic/blob/1.20.1/src/main/java/wayoftime/bloodmagic/common/tile/TileInventory.java)）：

- 底层 6 格：`0~3` 材料槽、`4` 意志槽（只收 `IDemonWillGem` / `IDemonWill`）、`5` 产物槽；
- 材料槽里有配方所需物品、并且锻炉里（材料槽或意志槽）有足够恶魔意志时才开始合成，默认 5 秒（100 tick）；
- 每次合成从每个非空材料槽扣 1 个物品，意志按配方的 `soulDrain` 一次性扣掉；
- 意志槽放一枚能存意志的物品（地狱魂石）就能长期用：锻炉会以 1 意志/t 从所在灵域自动吸气；
- **槽位号的坑**：CC 看到的槽位来自 Forge 的 `SidedInvWrapper`，[`getSlotsForFace()`](https://github.com/WayofTime/BloodMagic/blob/1.20.1/src/main/java/wayoftime/bloodmagic/common/tile/TileSoulForge.java) 的排列取决于 modem 贴在锻炉哪一面：
  - modem 在侧面（南北东西）：槽 1~4 = 材料，槽 5 = 意志，槽 6 = 产物；
  - modem 在**正上方**：槽 1 = 意志，槽 2~5 = 材料，槽 6 = 产物；
  - modem 在**正下方**：槽 1 = 产物，槽 2~5 = 材料，槽 6 = 意志。
- **为什么必须显式指定材料槽**：意志槽也接受 `IDemonWillGem`（也就是地狱魂石）。如果像炼金术桌那样"不指定 toSlot 让容器自己塞"，当 modem 在正上方时 CC 的 1 号槽就是意志槽，要升级的低等级魂石会被塞进意志槽而不是材料槽，配方永远匹配不上。现在脚本按上表显式 `toSlot` 到材料槽，魂石不可能再跑偏。
- **布局靠配置，不靠猜**：脚本里 `layout = "side"`（默认）/ `"up"` / `"down"`，也支持按锻炉名分别指定：

  ```lua
  local layout = { default = "side", ["bloodmagic:soulforge_1"] = "up" }
  ```

  - 1.16.x（E6E 这类整合包）的 `TileSoulForge` 没有实现 `ISidedInventory`，[TileInventory](https://github.com/WayofTime/BloodMagic/blob/1.16.3/src/main/java/wayoftime/bloodmagic/tile/TileInventory.java) 给的是无方向的 `InvWrapper`，永远都是"材料 1~4 / 意志 5 / 产物 6"，所以填默认的 `side` 即可。
  - 另外 1.16.x 的 `isItemValidForSlot()` 恒为 `true`：意志槽、产物槽也都能被塞进东西，所以"显式指定材料槽"比"让锻炉自己选槽"安全得多。
- **安全铁律（防止抽错东西）**：装载循环在动一台锻炉之前会先看配置的**产物槽是不是空的**；只要里面有东西（残留产物，或者 layout 设错导致那格其实是意志槽），脚本就**完全不碰这台锻炉**（不装料也不抽取），只打印提示让手动处理 / 改 `layout`。同时 `wait_and_collect` 只在"装料时产物槽是空的、之后长出了东西"时才抽取——绝不会把原本就在炉子里的东西抽走。
  - 早期版本曾用"锻炉里唯一那件东西在第几格"去猜 `layout`，猜成 `down` 时会把 CC 第 1 格当成产物槽，若实际是 `side` 的意志槽在第 6 格、产物在第 1 格……就会把不参与合成的魂石抽进 RS。现在这个猜测逻辑已经删掉，只保留"提示你可能是 up/down"的打印。

使用步骤：

1. 锻炉材料槽清空，意志槽放一枚存有恶魔意志的物品（地狱魂石/恶魔意志物品）；
2. 海龟第 1~6 格各放一种配方原料（每种 ≥ 1 个；脚本每种只拿 `per_craft` 个，剩下的留给下一轮）；
3. 运行 `soulforge`，启动时会打印 `turtle_inv`、每张锻炉的现有内容、当前使用的布局和槽号（例如 `[xxx] 现有内容: 5:bloodmagic:... x1`，第 5 格就是意志槽，说明 `layout = "side"` 正确）；
4. 每次装料默认会打印一行 `[xxx] 装入 N 种 -> 现在: ...`（`verbose = false` 可关掉），一眼就能看出魂石有没有进材料槽；
5. 之后靠脉冲催合成仓补料（和炼金术桌版一样）。

已知限制：

- `per_craft` 必须是"配方每格的数量"（狱火锻炉配方都是每种 1 个）。**不要**把整叠塞进锻炉：那样它会连续合成、产物堆在产物槽里，脚本的完成判断会乱掉；
- 配方里如果用到带合成剩余物的原料（比如桶），剩余物会留在材料槽，之后会匹配不上配方，需要手动清理；
- 配方需要同一种物品占两个材料槽时（JEI 里显示两个相同图标），脚本发料时会把两份叠进同一个槽，这种情况下需要手动摆一个，或告诉我改成"按槽位分配"；
- 脚本只做"发料 → 等产物 → 收产物"，恶魔意志靠锻炉自己从灵域吸气（或你手动补意志物品）。
