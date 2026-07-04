# 选关地图图标更新设计

## 背景

当前选关地图位于 `RunScreen/Map`，场景结构写在 `scenes/Root.tscn`，显示逻辑在 `scripts/ui/Map.gd` 和 `scripts/ui/MapLocation.gd`。地图节点由 `scenes/ui/MapLocation.tscn` 实例化，目前使用统一 `icon_map.png` 贴图，并在节点下方显示 `LocationData.LOCATION_TYPES` 的英文枚举名。用户提供了一张 2x3 的地图图标素材图，希望裁剪、抠图后用于地图节点表现，并调整 UI 布局避免遮挡。

已确认采用 C 方案：地图节点只显示图标，右侧固定图例栏显示类型说明。

## 目标

1. 从用户提供的素材图裁出并抠出 6 个透明 PNG 图标：
   - 基础战斗：第一排左，映射 `COMBAT`。
   - 神秘事件：第一排中，映射 `EVENT`。
   - 商店：第一排右，映射 `SHOP`。
   - 小型 BOSS：第二排左，映射 `MINIBOSS`。
   - 大型 BOSS：第二排中，映射 `BOSS`。
   - 篝火：第二排右，映射 `REST_SITE`。
2. 生成一张同风格宝箱浮岛图标，映射 `TREASURE`。
3. `MapLocation` 根据 `LocationData.LOCATION_TYPES` 显示对应图标。
4. 节点本身不再显示类型文字，减少地图内遮挡。
5. 在地图右侧增加固定图例栏，展示 7 类节点的图标和中文名称。
6. 调整地图滚动区域，为右侧图例栏留出空间，避免图例、返回按钮和地图节点互相遮挡。

## 非目标

1. 不修改世界地图生成规则、节点连接规则或随机事件概率。
2. 不改变 `LocationData` 的数据结构。
3. 不修改战斗、商店、事件、营火、宝箱的进入逻辑。
4. 不新增可交互的筛选、缩放或地图路线重绘功能。
5. 不把图例栏做成可配置数据系统；本次只服务当前固定 7 类节点。

## 素材处理

素材源图为本地 PNG，尺寸为 1448x1086，背景为高饱和绿色。处理流程：

1. 按 2 行 3 列区域切分源图。
2. 对每个区域使用绿色背景抠图生成透明 PNG。
3. 自动裁掉透明外边距，并保留少量安全边距，防止 Godot 缩放后边缘被截断。
4. 统一导出到 `external/sprites/ui/map_locations/`。
5. 宝箱图标使用图像生成得到同风格浮岛素材，再通过同样的透明背景流程落盘。

建议文件名：

| 节点类型 | 文件 |
| --- | --- |
| COMBAT | `map_location_combat.png` |
| EVENT | `map_location_event.png` |
| SHOP | `map_location_shop.png` |
| MINIBOSS | `map_location_miniboss.png` |
| BOSS | `map_location_boss.png` |
| REST_SITE | `map_location_rest_site.png` |
| TREASURE | `map_location_treasure.png` |
| 未知/混淆 | `map_location_unknown.png` |

未知/混淆图标使用独立的 `map_location_unknown.png`。该文件由现有 `sprites/ui/flipper/icon_map.png` 复制或重采样得到，不从真实节点类型派生。实现时必须保证未访问且混淆的节点不通过图标暴露真实类型。

## 地图节点表现

`MapLocation.tscn` 根节点继续保持 `TextureButton`，以保留按钮行为、焦点和现有闪烁动画。节点视觉调整为：

1. 根节点目标尺寸约 80x80。
2. `texture_normal` 由脚本按类型设置，不再固定为 `icon_map.png`。
3. 删除 `MapLabel` 节点及脚本引用，不再在节点下方显示英文枚举。
4. 闪烁动画继续作用在根节点 `self_modulate` 上，让可前往节点整体闪烁。
5. `location_obfuscated and not location_visited` 时显示未知图标。

当前地图生成使用 100px 格距，因此单个节点视觉区域需控制在 80px 内，避免同层或相邻层节点互相覆盖。

## 图例栏布局

地图整体仍是 `RunScreen/Map` 下的覆盖层。布局调整：

1. `BackButton` 固定在顶部左侧，避开地图滚动区和右侧图例栏。
2. `ScrollContainer` 向左收窄，主要用于地图节点滚动。
3. 新增右侧 `LegendPanel`，固定在 `RunScreen/Map` 内，不随地图滚动。
4. 图例栏纵向显示 7 项，每项包含小图标和中文名称。
5. 图例栏尺寸以 1200x700 当前画布为基准，宽度约 150-180px；地图滚动区右边界相应左移。

右侧图例栏不需要可点击行为，只提供识别说明。

## 数据流

`Map.gd.populate_locations()` 的节点生成流程保持不变：

1. 读取 `Global.get_all_act_locations()`。
2. 跳过 `STARTING`。
3. 实例化 `Scenes.MAP_LOCATION`。
4. 调用 `map_location.init(location_data)`。
5. 根据可前往状态播放闪烁动画。

变化集中在 `MapLocation.gd.init()`：

1. 保存 `location_data`。
2. 设置节点位置。
3. 根据可见性与 `location_type` 选择贴图路径。
4. 加载贴图并赋给 `texture_normal`。

新增或调整的 helper 只放在 `MapLocation.gd`，例如：

- `_get_location_texture_path(location_data: LocationData) -> String`
- `_is_location_type_hidden(location_data: LocationData) -> bool`

图例栏在 `Root.tscn` 中静态配置，减少运行时节点生成复杂度。

## 错误处理与兼容

1. 找不到某类贴图时，先回退到 `map_location_unknown.png`；若未知图标也缺失，再回退到现有 `icon_map.png`，避免节点空白。
2. 未知 `LOCATION_TYPES` 值回退到未知图标。
3. 混淆节点无论真实类型是什么，都显示未知图标。
4. 如果宝箱生成图标与其他图标风格有明显偏差，重新生成宝箱图标；未通过视觉检查前不接入最终地图图例。
5. 新增资源不影响旧存档，因为节点类型仍来自已有 `LocationData`。

## 验证

实现完成后需要验证：

1. Godot headless 能加载项目，`Root.tscn` 和 `MapLocation.tscn` 无资源错误。
2. 单元/回归测试覆盖 7 类 `LOCATION_TYPES` 到贴图路径的映射。
3. 测试混淆未访问节点显示未知图标，不显示真实类型图标。
4. UI 布局测试覆盖地图滚动区、返回按钮、右侧图例栏均在 1200x700 画布内。
5. 手动或截图检查地图节点与图例栏没有明显重叠，节点在 100px 格距下不互相遮挡。
6. 图例栏中文名称与图标映射一致。

## 实施顺序建议

1. 处理源素材，导出 6 个透明地图图标。
2. 生成宝箱图标并抠透明背景。
3. 新增或调整地图节点贴图映射测试，先确认会失败。
4. 修改 `MapLocation.gd` 和 `MapLocation.tscn`，让节点按类型显示图标。
5. 修改 `Root.tscn` 的地图布局，加入右侧图例栏并收窄滚动区域。
6. 扩展 UI 布局回归测试。
7. 运行 Godot headless 与相关测试，最后做视觉截图检查。
