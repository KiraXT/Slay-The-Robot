# Blue Individual Card Art Design

**Goal:** 将蓝色角色卡组从共用 `card_blue.png` 改为每张卡独立卡图。每张图优先表达卡牌效果含义，同时保留八柰见的冒失感、学生气和日常小混乱。

**Chosen direction:** 方案 B：人物 + 道具/效果主导。

## Scope

本轮处理所有 `card_color_id == "color_blue"` 的卡牌：

- `add_to_draw_from_discard_card`
- `card_add_consumable`
- `card_attack_heal_unblocked_damage`
- `card_attack_rng`
- `card_discard_attacks_from_draw`
- `card_discard_hand`
- `card_draw`
- `card_improving_attack`
- `card_pick_from_discard`
- `card_play_from_discard`
- `card_reshuffle_draw`
- `randomize_hand_card`
- `self_attaching_attack_card`

本轮不改卡牌数值、费用、行为脚本、卡包配置、角色立绘、头像或能量图标。

## Asset Rules

每张新卡图使用独立文件：

```text
external/sprites/cards/blue/<card_object_id>.png
```

每张图片规格：

```text
512x512
PNG
RGBA with alpha
transparent background
```

每张蓝色卡 JSON 的 `card_texture_path` 改为对应独立文件路径。保留 `external/sprites/cards/blue/card_blue.png` 作为共用/回退资源，不再作为所有蓝色卡的唯一图片。

## Visual Direction

### Character Anchor

八柰见的识别锚点：

- 蓝色短发
- 白色学生衬衫
- 蓝色裙子
- 黄色领结
- 青春、日常、轻喜剧气质

她不需要每张全身出镜。允许使用手部、书包、便当、饮料、卡牌、作业纸等特写，但整体必须仍然像“八柰见世界观里的卡图”，而不是通用图标。

### Tone

统一基调：

- 冒失
- 手忙脚乱
- 临场补救
- 被卷入战斗但没有正经战斗职业感

避免：

- 红色角色式拳击、爆裂、重击
- 正统魔法少女大招感
- 黑暗严肃战斗氛围
- 纯 UI 图标化，导致角色感丢失

## Per-Card Art Mapping

### `card_draw` - 抽牌

八柰见慌忙翻书包，扑出来一叠卡牌和作业纸。重点是“抽出资源”。

### `card_discard_hand` - 弃掉手牌，抽牌

手里的卡牌失手撒飞，八柰见一边慌张一边试图补救。重点是“先清空，再重新抓牌”。

### `card_reshuffle_draw` - 重新洗牌并抽牌

散乱卡牌被她塞回书包或抽牌堆，形成小漩涡。重点是“弃牌堆回流到抽牌堆”。

### `card_pick_from_discard` - 从弃牌堆选择

八柰见蹲在地上，从散落纸张和卡牌里翻找指定卡。重点是“挑选”。

### `add_to_draw_from_discard_card` - 从弃牌堆抽取并置入抽牌堆

她把捡回来的卡塞到抽牌堆顶，像临时整理错乱笔记。重点是“回收并放回牌库”。

### `card_play_from_discard` - 从弃牌堆打出

她从地上一把捞起卡牌临时打出，同时用书包或便当袋做笨拙防御。重点是“废堆临场再利用”。

### `card_discard_attacks_from_draw` - 从抽牌堆弃置攻击牌

她从牌堆顶慌张抽走危险的红色攻击卡并丢开。重点是“过滤攻击牌”。

### `randomize_hand_card` - 随机化费用

能量标记、硬币、便当贴纸和卡牌数字乱飞，八柰见被变化吓到。重点是“费用被搅乱”。

### `card_add_consumable` - 添加消耗品

她从便当袋里意外掏出饮料、药膏、小道具，自己也很惊讶。重点是“随机消耗品生成”。

### `card_attack_rng` - 随机攻击

她闭眼乱丢面包、饮料或书本文具，轨迹夸张但不重击。重点是“伤害随机”。

### `card_improving_attack` - 进化攻击

从笨拙防御姿态变成“好像有点会了”的成长瞬间，有轻微蓝色效果和小盾牌感。重点是“击杀后成长”。

### `card_attack_heal_unblocked_damage` - 治疗攻击

饮料或便当汤汁泼出去造成伤害，溅回来的光点像回复效果。重点是“攻击和回复绑定”。

### `self_attaching_attack_card` - 自我附着攻击

便签或卡牌贴到敌人影子上，八柰见在旁边慌张指着。重点是“战斗开始自动附着到目标”。

## Implementation Approach

采用生成式位图流程：

1. 为每张卡生成一张平面纯色抠像背景源图。
2. 本地去底生成透明 PNG。
3. 统一规范为 `512x512 RGBA PNG`。
4. 将对应蓝色卡 JSON 的 `card_texture_path` 指向独立图。

## Validation

每张卡图需要满足：

1. 文件存在于 `external/sprites/cards/blue/`。
2. 图片为 `512x512 PNG`。
3. 图片有 alpha 通道，四角透明。
4. 蓝色卡 JSON 的 `card_texture_path` 指向对应文件。
5. 缩小后能看出卡牌效果差异。
6. 至少能通过角色、道具或画面气质看出八柰见的冒失感。

## Risks

- 13 张图如果都画全身八柰见，容易重复。
- 如果特写太符号化，会丢失角色感。
- 如果道具太多，小尺寸卡面会变乱。
- 如果生成图背景去除不干净，会出现绿色边缘。

## Out of Scope

- 不新增卡牌。
- 不调整战斗逻辑。
- 不改角色、头像、能量图标。
- 不替换红色、绿色、橙色卡组图。
