# Orange Character Reference Art Design

**Goal:** 基于用户提供的金发双麻花参考图，更新现有 `character_orange` 的角色立绘、头像、文本能量图标，并迭代橙色卡组卡图。

**Important decision:** 用户确认“黄色角色”是口误，本轮继续使用项目现有 `orange` 体系，不新增 `yellow` 颜色、玩家或角色数据。

## Scope

本轮处理：

- `external/sprites/characters/character_orange/character_orange.png`
- `external/sprites/characters/character_orange/character_orange_icon.png`
- `external/sprites/characters/character_orange/character_orange_text_energy.png`
- `external/sprites/cards/orange/card_orange.png`
- 所有 `card_color_id == "color_orange"` 的橙色卡牌卡图

不处理：

- 不新增 `color_yellow`
- 不新增 `character_yellow`
- 不改卡牌数值、费用、行动脚本、卡包或角色起始牌组
- 不改红/绿/蓝角色资源

## Character Anchor

参考图角色锚点：

- 金发双麻花
- 橙黄色眼睛
- 青绿色宽松外套，带白色和紫色块面
- 橙色 T 恤
- 紫色短裙
- 白色袜子
- 橙色运动鞋
- 单肩/手拎背包
- 轻快、运动系、校园日常感

视觉上应从旧齿轮脸占位升级成完整 anime 风格角色。整体色彩仍服务 `orange` 角色槽：黄色、橙色、青绿色作为主识别色。

## Asset Rules

### Character Combat Art

Path:

```text
external/sprites/characters/character_orange/character_orange.png
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
external/sprites/characters/character_orange/character_orange_icon.png
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
external/sprites/characters/character_orange/character_orange_text_energy.png
```

Spec:

```text
16x16
PNG
RGBA or indexed PNG with alpha
orange/yellow energy mark
```

### Shared Orange Card Fallback

Path:

```text
external/sprites/cards/orange/card_orange.png
```

Spec:

```text
512x512
PNG
RGBA
transparent background
generic orange character card art fallback
```

### Individual Orange Cards

New independent card images use:

```text
external/sprites/cards/orange/<card_object_id>.png
```

Each is:

```text
512x512
PNG
RGBA
transparent background
```

## Orange Card Art Mapping

Current orange cards:

- `block_if_exhaust_card` - 放逐格挡
- `card_attack_big` - 强力攻击
- `card_block_big` - 放逐格挡 / 顶置牌库
- `card_energy_on_draw` - 抽牌能量
- `card_special_discard` - 特殊弃置
- `retain_hand_card` - 保留卡牌

### `retain_hand_card`

她用发夹、书签或背包夹扣固定几张卡牌，表现“保留到下回合”。

### `card_special_discard`

她从背包里把不需要的卡甩出，卡牌触发橙色小信号，表现“弃置并触发特殊信号”。

### `card_energy_on_draw`

她抽到卡的一瞬间，运动饮料、橙黄色能量光点或运动鞋火花弹出，表现“抽到时获得能量”。

### `block_if_exhaust_card`

她用宽大外套挡住冲击，旁边有正在消散的卡牌，表现“有牌被放逐时才能格挡”。

### `card_block_big`

她把一张卡压到牌堆顶，同时外套形成黄色保护罩，部分卡牌正在消散，表现“顶置牌库 + 格挡并放逐”。

### `card_attack_big`

不做拳击或重武器。她背包甩动或运动鞋冲刺带起黄色冲击，旁边有掉落金币，表现“强力攻击，击杀获得金钱，虚无”。

## Implementation Approach

Use the built-in image generation path:

1. Generate chroma-key source images on flat `#00ff00` background.
2. Locally remove chroma-key background.
3. Normalize final PNG sizes.
4. Update orange card JSON `card_texture_path` to independent card images.
5. Keep all object IDs and data schema unchanged.

## Validation

Required checks:

1. Character combat art is `512x512` with alpha.
2. Character icon is `64x64` with alpha.
3. Text energy icon is `16x16` with alpha.
4. Shared orange fallback and individual orange card images are `512x512` with alpha.
5. Every `color_orange` card JSON points to `external/sprites/cards/orange/<object_id>.png`.
6. No non-orange card JSON is changed by this work.
7. Existing Godot SceneTree tests pass.

## Risks

- The source reference image has a checkerboard-like background, so generation should use it as identity/style reference rather than direct cutout.
- The T-shirt text in the reference should not be reproduced as readable text in final assets.
- The orange card set has overlapping exhaust/block mechanics, so card art needs distinct prop/action cues.
