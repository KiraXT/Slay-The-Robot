# Green Miku Reference Art Design

**Goal:** 基于用户提供的初音未来参考图，更新现有 `character_green` 的角色立绘、头像、文本能量图标，并迭代绿色卡组卡图。

**Important decision:** 本轮继续使用项目现有 `green` 体系，不新增角色、颜色或玩家数据。

## Scope

本轮处理：

- `external/sprites/characters/character_green/character_green.png`
- `external/sprites/characters/character_green/character_green_icon.png`
- `external/sprites/characters/character_green/character_green_text_energy.png`
- `external/sprites/cards/green/card_green.png`
- 所有 `card_color_id == "color_green"` 的绿色卡牌卡图

不处理：

- 不新增 `color_miku` 或新角色
- 不改卡牌数值、费用、行为脚本、卡包或角色起始牌组
- 不改红/橙/蓝角色资源

## Character Anchor

参考图角色锚点：

- 青绿色超长双马尾
- 耳机与小麦克风
- 灰白上衣与青绿色领带
- 黑色长袖套
- 黑色短裙与青绿色细节
- 黑色长靴
- 电子歌姬、节奏、音符、数字信号感

最终素材应服务 `green` 角色槽：以青绿、薄荷绿、电子蓝绿为主，避免变成蓝色角色视觉。

## Asset Rules

### Character Combat Art

Path:

```text
external/sprites/characters/character_green/character_green.png
```

Spec:

```text
512x512
PNG
RGBA
transparent background
full-body or near full-body character
```

### Character Icon

Path:

```text
external/sprites/characters/character_green/character_green_icon.png
```

Spec:

```text
64x64
PNG
RGBA
transparent background
head-and-shoulders crop
```

### Text Energy Icon

Path:

```text
external/sprites/characters/character_green/character_green_text_energy.png
```

Spec:

```text
16x16
PNG
RGBA or indexed PNG with alpha
green/cyan musical-energy mark
```

### Shared Green Card Fallback

Path:

```text
external/sprites/cards/green/card_green.png
```

Spec:

```text
512x512
PNG
RGBA
transparent background
generic green character card art fallback
```

### Individual Green Cards

New independent card images use:

```text
external/sprites/cards/green/<card_object_id>.png
```

Each is:

```text
512x512
PNG
RGBA
transparent background
```

## Green Card Art Mapping

Current green cards:

- `card_attack_corrosion` - 腐蚀攻击
- `card_attack_in_center` - 居中攻击
- `card_block_without_attacks` - 手牌无攻击时格挡
- `card_bomb` - 延迟炸弹
- `card_cycle_enemy_intent` - 切换敌人意图
- `card_draft_random_attack` - 抽取攻击牌
- `card_duplicate_plays` - 重复出牌
- `card_generate_shoves` - 生成推搡
- `card_improving_block` - 进化格挡
- `card_preserve_block` - 保留格挡
- `card_upgrade_card` - 升级卡牌

### `card_attack_corrosion`

电子歌姬挥出绿色声波，音符像腐蚀数据流一样包裹敌人。

### `card_attack_in_center`

角色站在三张手牌中间，中央卡牌发光，表现“只能在手牌中间打出”。

### `card_block_without_attacks`

她用音波护盾保护自己，旁边没有攻击卡，表现“无攻击牌时可格挡”。

### `card_bomb`

节拍器/数字倒计时音符形成绿色能量炸弹，表现延迟爆发。

### `card_cycle_enemy_intent`

她调节耳机/混音面板，让敌人意图图标切换，表现强制换意图。

### `card_draft_random_attack`

她从浮动全息攻击卡中选择一张，表现从 3 张攻击牌中选 1 张。

### `card_duplicate_plays`

舞台回声复制第一张打出的卡，表现每回合复制第一次出牌。

### `card_generate_shoves`

音波节拍把多个“推搡”卡片推入手牌，表现生成推搡。

### `card_improving_block`

她把卡放到牌堆顶，同时声波护盾层层增强，表现本场战斗中格挡成长。

### `card_preserve_block`

绿色声波护盾被锁定成持续屏障，表现格挡不在回合结束时重置。

### `card_upgrade_card`

她用音频调校/数字调音台升级一张卡，卡牌出现绿色上升光效。

## Implementation Approach

Use the built-in image generation path:

1. Generate chroma-key source images on flat `#00ff00` background.
2. Locally remove chroma-key background.
3. Normalize final PNG sizes.
4. Update green card JSON `card_texture_path` to independent card images.
5. Keep all object IDs and data schema unchanged.

## Validation

Required checks:

1. Character combat art is `512x512` with alpha.
2. Character icon is `64x64` with alpha.
3. Text energy icon is `16x16` with alpha.
4. Shared green fallback and individual green card images are `512x512` with alpha.
5. Every `color_green` card JSON points to `external/sprites/cards/green/<object_id>.png`.
6. No non-green card JSON is changed by this work.
7. Existing Godot SceneTree tests pass.

## Risks

- The reference image is recognizable as an existing virtual singer, so final game assets should use it as an in-project green character reference and avoid readable logos or exact text marks.
- Green chroma-key removal can conflict with teal hair and cyan effects; if needed, use magenta chroma-key for generated sources.
- Many green cards are abstract state/control effects, so card art needs clear card/intent/shield/digital music cues.
