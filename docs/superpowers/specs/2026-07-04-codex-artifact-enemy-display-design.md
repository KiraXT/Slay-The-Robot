# 目录神器和怪物展示设计

## 目标

把标题页的 `CodexMenu` 从只展示卡牌扩展为可切换展示卡牌、怪物、神器。交互方式沿用当前卡牌目录：左侧类型按钮切换，右侧同一个滚动网格展示全部条目。

## 当前状态

- `scripts/ui/menus/CodexMenu.gd` 目前只读取 `Global._id_to_card_data`，并实例化 `Scenes.CARD`。
- `scenes/Root.tscn` 已经有 `Cards / Enemies / Artifacts / Consumables` 四个按钮，但除 Cards 外都处于禁用状态。
- `Global.SCHEMA` 已经加载 `EnemyData` 和 `ArtifactData`，数据文件分别在 `external/data/enemies/` 和 `external/data/artifacts/`。

## 方案

- 保留现有目录布局和滚动网格。
- Cards 继续使用 `Scenes.CARD`，展示方式不变。
- Enemies 和 Artifacts 使用目录专用的只读条目，由 `CodexMenu.gd` 程序化生成 `Control` 节点。
- 只读条目只读取名称、图片、描述和基础数值，不实例化战斗敌人，也不实例化神器脚本。
- 暂不接入 Consumables，保留按钮禁用状态。

## 展示内容

- 怪物：图片、名称、类型、生命、格挡、小怪标记。
- 神器：图片、名称、稀有度、颜色、描述。

## 验证

新增 Godot `SceneTree` 回归测试，实例化 `Root.tscn` 后调用目录菜单：

- 默认 Cards 页能生成卡牌条目。
- Enemies 按钮启用，切换后生成与 `Global._id_to_enemy_data` 数量一致的目录条目。
- Artifacts 按钮启用，切换后生成与 `Global._id_to_artifact_data` 数量一致的目录条目。
- Consumables 按钮继续禁用。
