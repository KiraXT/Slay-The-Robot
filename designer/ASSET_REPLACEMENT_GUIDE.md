# 图片资源替换清单

本文档整理当前项目中已经接通、可直接替换的图片资源入口，供后续批量出图与资源替换使用。

## 总览

| 资源类型 | 主要用途 | 配置字段 | 当前基准尺寸 | 建议交付格式 | 透明要求 |
| --- | --- | --- | --- | --- | --- |
| 战斗主背景 | 战斗场景整屏背景 | `act_background_texture_path` / `location_background_texture_path` / `event_background_texture_path` | `1200 x 700` 显示区 | `PNG` | 不透明 |
| 事件插图 | 事件面板左侧大图 | `dialogue_state_dialogue_texture_path` | `768 x 768` | `PNG` | 可不透明 |
| 玩家战斗立绘 | 玩家角色战斗显示 | `character_texture_path` | `512 x 512` | `PNG` | 透明底 |
| 角色选择头像 | 新开局角色按钮图 | `character_icon_texture_path` | `256 x 256` | `PNG` | 透明底 |
| 角色能量小图标 | 卡牌文本内嵌图标 | `character_text_energy_texture_path` | `128 x 128` | `PNG` | 透明底 |
| 敌人战斗立绘 | 敌人战斗显示 | `enemy_texture_path` | 小 `64` / 中 `96` / Boss `512` | `PNG` | 透明底 |
| 卡牌插图 | 卡牌中央插图 | `card_texture_path` | `512 x 512` | `PNG` | 透明底 |
| 遗物图标 | HUD / 商店 / 奖励遗物图标 | `artifact_texture_path` | `128 x 128` 建议统一 | `PNG` | 透明底 |
| 消耗品图标 | 消耗品按钮 / 商店图标 | `consumable_texture_path` | `128 x 128` | `PNG` | 透明底 |
| 状态效果图标 | 战斗状态图标 | `status_effect_texture_path` | `128 x 128` | `PNG` | 透明底 |

## 详细清单

### 战斗主背景

| 项目 | 内容 |
| --- | --- |
| 用途 | 战斗场景整屏背景 |
| 逻辑入口 | [scripts/ui/Combat.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/Combat.gd#L105) |
| 配置字段 | `act_background_texture_path` / `location_background_texture_path` / `event_background_texture_path` |
| 显示区域 | [scenes/Root.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/Root.tscn#L696) |
| 项目基准分辨率 | [project.godot](/Users/xietong/Documents/GitHub/Slay-The-Robot/project.godot#L43) |
| 当前示例资源 | [external/sprites/acts/act_1_background.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/acts/act_1_background.png) |
| 当前示例尺寸 | `1642 x 958` |
| 直接可用尺寸 | `1200 x 700` |
| 长线母图建议 | `2400 x 1400` |
| 格式 | `PNG` |
| 透明要求 | 不透明 |
| 制作建议 | 画面中央和下方尽量留干净，避免角色、血条、手牌被高对比细节干扰 |

### 事件插图 / 对话左侧大图

| 项目 | 内容 |
| --- | --- |
| 用途 | 事件面板左侧大图 |
| 数据入口 | [external/data/dialogue/dialogue_pick_something.json](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/data/dialogue/dialogue_pick_something.json#L92) |
| 配置字段 | `dialogue_state_dialogue_texture_path` |
| 显示区域 | [scenes/Root.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/Root.tscn#L1268) |
| 当前示例资源 | [external/sprites/events/event_pick_something.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/events/event_pick_something.png) |
| 当前示例尺寸 | `768 x 768` |
| 建议尺寸 | `768 x 768` |
| 格式 | `PNG` |
| 透明要求 | 可不透明 |
| 制作建议 | 实际显示框约 `528 x 528`，推荐正方图，主体四周保留安全边 |

### 玩家战斗立绘

| 项目 | 内容 |
| --- | --- |
| 用途 | 玩家角色战斗立绘 |
| 数据入口 | [external/data/characters/character_red.json](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/data/characters/character_red.json#L41) |
| 配置字段 | `character_texture_path` |
| 逻辑入口 | [scripts/combatants/Player.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/combatants/Player.gd#L131) |
| 当前示例资源 | [external/sprites/characters/character_red/character_red.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/characters/character_red/character_red.png) |
| 当前示例尺寸 | `512 x 512` |
| 建议尺寸 | `512 x 512` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 主体占画布高度约 `70% - 85%`，脚底完整可见，避免透明边过大 |

### 角色选择头像

| 项目 | 内容 |
| --- | --- |
| 用途 | 新开局角色选择按钮图标 |
| 配置字段 | `character_icon_texture_path` |
| 数据入口 | [external/data/characters/character_red.json](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/data/characters/character_red.json#L7) |
| 显示节点 | [scenes/ui/CharacterSelectionButton.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/ui/CharacterSelectionButton.tscn#L8) |
| 当前示例资源 | [external/sprites/characters/character_red/character_red_icon.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/characters/character_red/character_red_icon.png) |
| 当前示例尺寸 | `256 x 256` |
| 建议尺寸 | `256 x 256` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | UI 实际占位是 `64 x 64`，需要高辨识度、强轮廓 |

### 角色能量小图标

| 项目 | 内容 |
| --- | --- |
| 用途 | 卡牌文本中嵌入的能量图标 |
| 配置字段 | `character_text_energy_texture_path` |
| 逻辑入口 | [scripts/ui/Card.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/Card.gd#L183) |
| 当前示例资源 | [external/sprites/characters/character_red/character_red_text_energy.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/characters/character_red/character_red_text_energy.png) |
| 当前示例尺寸 | `128 x 128` |
| 建议尺寸 | `128 x 128` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 最终显示很小，优先保证符号轮廓和对比，不要堆细节 |

### 敌人战斗立绘

| 项目 | 内容 |
| --- | --- |
| 用途 | 敌人战斗立绘 |
| 配置字段 | `enemy_texture_path` |
| 逻辑入口 | [scripts/combatants/Enemy.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/combatants/Enemy.gd#L21) |
| 小体型示例 | [external/sprites/enemies/enemy_green_small.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/enemies/enemy_green_small.png) `64 x 64` |
| 中体型示例 | [external/sprites/enemies/enemy_red_medium.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/enemies/enemy_red_medium.png) `96 x 96` |
| Boss 示例 | [external/sprites/enemies/enemy_act_1_boss_1.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/enemies/enemy_act_1_boss_1.png) `512 x 512` |
| 建议尺寸 | 小怪 `64 x 64` / 中怪 `96 x 96` / Boss `512 x 512` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 按体型分档，不建议目前统一到一个尺寸 |

### 卡牌插图

| 项目 | 内容 |
| --- | --- |
| 用途 | 卡牌中央插图区域 |
| 配置字段 | `card_texture_path` |
| 逻辑入口 | [scripts/ui/Card.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/Card.gd#L86) |
| 显示节点 | [scenes/ui/Card.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/ui/Card.tscn#L152) |
| 当前示例资源 | [external/sprites/cards/card_attack_basic.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/cards/card_attack_basic.png) |
| 当前示例尺寸 | `512 x 512` |
| 建议尺寸 | `512 x 512` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 实际显示区约 `96 x 96`，主体要大而集中，不适合复杂背景 |

### 遗物图标

| 项目 | 内容 |
| --- | --- |
| 用途 | HUD / 商店 / 奖励 / 初始遗物展示 |
| 配置字段 | `artifact_texture_path` |
| 逻辑入口 | [scripts/ui/Artifact.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/Artifact.gd#L19)、[scripts/ui/shop/ArtifactShopButton.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/shop/ArtifactShopButton.gd#L15)、[scripts/ui/rewards/ArtifactRewardButton.gd](/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/rewards/ArtifactRewardButton.gd#L10) |
| 当前示例资源 | [external/sprites/artifacts/artifact_red.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/artifacts/artifact_red.png) `64 x 64`、[external/sprites/artifacts/artifact_add_money.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/artifacts/artifact_add_money.png) `128 x 128` |
| HUD 显示占位 | [scenes/ui/Artifact.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/ui/Artifact.tscn#L24) `40 x 40` |
| 建议尺寸 | 建议统一按 `128 x 128` 制作 |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 实际显示尺寸很小，图标要图形化，不要依赖细碎纹理 |

### 消耗品图标

| 项目 | 内容 |
| --- | --- |
| 用途 | 消耗品按钮 / 商店消耗品图标 |
| 配置字段 | `consumable_texture_path` |
| 数据入口示例 | [external/data/consumables/consumable_damaging.json](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/data/consumables/consumable_damaging.json#L17) |
| 当前示例资源 | [external/sprites/consumables/consumable_damaging.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/consumables/consumable_damaging.png) |
| 当前示例尺寸 | `128 x 128` |
| 按钮占位 | [scenes/ui/ConsumableButton.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/ui/ConsumableButton.tscn#L6) `32 x 32` |
| 建议尺寸 | `128 x 128` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 需要一眼可识别，尽量少文字、少复杂边框 |

### 状态效果图标

| 项目 | 内容 |
| --- | --- |
| 用途 | 战斗状态效果图标 |
| 配置字段 | `status_effect_texture_path` |
| 数据入口示例 | [external/data/status_effects/status_effect_vulnerable.json](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/data/status_effects/status_effect_vulnerable.json#L26) |
| 当前示例资源 | [external/sprites/status_effects/status_effect_vulnerable.png](/Users/xietong/Documents/GitHub/Slay-The-Robot/external/sprites/status_effects/status_effect_vulnerable.png) |
| 当前示例尺寸 | `128 x 128` |
| 显示占位 | [scenes/combatants/StatusEffect.tscn](/Users/xietong/Documents/GitHub/Slay-The-Robot/scenes/combatants/StatusEffect.tscn#L11) `24 x 24` |
| 建议尺寸 | `128 x 128` |
| 格式 | `PNG` |
| 透明要求 | 透明底 |
| 制作建议 | 最终显示极小，图标外轮廓与主符号优先，避免渐变太轻 |

## 预留但当前未完全启用的入口

| 字段 | 所在数据 | 当前状态 | 备注 |
| --- | --- | --- | --- |
| `character_background_texture_path` | `external/data/characters/*.json` | 未看到实际显示链路 | 可以保留作为后续角色背景扩展位 |
| `rest_action_texture_path` | `external/data/rest_actions/*.json` | 当前大多为空，未看到 UI 使用链路 | 适合作为休息点选项图标扩展位 |
| `event_background_texture_path` | `external/data/events/*.json` | 逻辑已支持，现有数据大多为空 | 一旦填写，会覆盖 Act 默认战斗背景 |

## AI 出图提示词模板

### 通用模板

```text
为 2D 卡牌战斗游戏生成一张游戏资源图。

要求：
- 资源类型：【替换为具体类型，例如战斗背景 / 角色立绘 / 图标 / 卡牌插图】
- 画布尺寸：【填写尺寸，例如 512x512 / 128x128 / 1200x700】
- 输出格式：PNG
- 背景要求：【透明背景 / 非透明背景】
- 风格：手绘感、游戏插画风、轮廓清晰、适合深色 UI 或卡牌界面
- 不要文字、不要边框、不要水印、不要 UI 元素
- 保证主体清晰，缩小后仍然有较高辨识度

额外要求：
- 【填写具体构图要求】
- 【填写颜色 / 情绪 / 世界观要求】
- 【填写是否需要留白】

最终输出必须适合作为游戏内可直接替换的图片资源。
```

### 战斗背景模板

```text
为 2D 卡牌战斗游戏生成战斗背景图。

要求：
- 画布 1200x700
- PNG
- 非透明背景
- 画面用于战斗场景底图
- 中央与下方保持相对干净，避免遮挡角色、血条、手牌
- 风格统一、细节中等、不要文字、不要 UI 元素
- 整体适合作为游戏背景，而不是单张宣传海报

风格补充：
- 【填写主题，例如机械废土 / 空中圣城 / 科幻遗迹 / 森林祭坛】
- 【填写明暗倾向，例如偏暗 / 明亮但低干扰】

最终输出必须适合作为游戏战斗背景直接替换使用。
```

### 角色战斗立绘模板

```text
为 2D 卡牌战斗游戏生成角色战斗立绘。

要求：
- 单个角色
- 全身或接近全身
- 透明背景 PNG
- 画布 512x512
- 角色主体居中，脚底完整可见
- 主体占画布高度约 70% 到 85%
- 轮廓清晰，缩小后仍然容易辨认
- 不要背景、不要地面平台、不要文字、不要边框

风格补充：
- 手绘感
- 游戏插画风
- 造型清晰
- 适合战斗站位显示

最终输出必须适合作为游戏内战斗立绘资源直接替换使用。
```

### 图标模板

```text
为 2D 卡牌战斗游戏生成一个图标资源。

要求：
- 透明背景 PNG
- 画布尺寸：【128x128 / 256x256】
- 主体图形化、简洁、清晰
- 不要文字、不要复杂背景、不要边框
- 缩小到 24px - 64px 时仍然可辨认

风格补充：
- 颜色集中
- 对比明确
- 适合 UI 小尺寸显示

最终输出必须适合作为游戏图标直接替换使用。
```

## 交付自检清单

| 检查项 | 要求 |
| --- | --- |
| 文件格式 | `PNG` |
| 尺寸 | 与本表建议尺寸一致 |
| 透明通道 | 需要透明底的资源必须真的包含 alpha，不允许棋盘格烘进像素 |
| 背景 | 背景图可不透明，角色 / 图标 / 卡图一般要求透明底 |
| 构图 | 主体不要贴边，不要被裁切 |
| 可读性 | 缩小后仍然能辨认主体 |
| 风格统一 | 尽量与当前项目 UI、卡牌、角色方向一致 |
| 命名 | 使用明确的英文文件名，便于后续替换 |

## 推荐命名规则

| 类型 | 命名示例 |
| --- | --- |
| 战斗背景 | `act_2_background.png` |
| 事件插图 | `event_pick_something.png` |
| 角色立绘 | `character_blue.png` |
| 角色头像 | `character_blue_icon.png` |
| 能量图标 | `character_blue_text_energy.png` |
| 敌人立绘 | `enemy_act_2_boss_1.png` |
| 卡牌插图 | `card_attack_basic.png` |
| 遗物图标 | `artifact_add_money.png` |
| 消耗品图标 | `consumable_heal.png` |
| 状态图标 | `status_effect_weaken.png` |

## 使用建议

1. 每次出图时先明确属于哪一类资源，再按对应尺寸生产。
2. 对透明底资源，交付前先确认文件本身包含 alpha 通道。
3. 对战斗背景和事件插图，优先保证构图与 UI 不冲突。
4. 如果有新图片入口需要接入，先补配置字段，再加入本清单。
