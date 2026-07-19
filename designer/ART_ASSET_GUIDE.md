# Slay the Robot - 美术资源与动画系统参考文档

本文档汇总了游戏中图片/纹理/动画资源的存放位置、规格标准、引用方式以及替换操作流程。

---

## 1. 资源存放总览

所有外部美术资源统一存放在 `external/sprites/` 目录下，按类型分子目录：

```
external/sprites/
  cards/           # 卡牌纹理
  characters/      # 角色立绘、图标、能量图标
  enemies/         # 敌人纹理
  artifacts/       # 遗物纹理
  events/          # 事件背景图
  acts/            # 章节背景图
  locations/       # 地点背景图
```

---

## 2. 当前运行资产契约

所有外部美术资源统一放在 `external/sprites/`。运行图以游戏实际显示为准，不再使用早期 96x96 卡图或 96x96 事件图规格。

| 类型 | 存放路径 | 运行规格 | 格式 | 透明要求 | JSON 字段 |
| --- | --- | --- | --- | --- | --- |
| 卡牌插画 | `external/sprites/cards/` | `512 x 512` | PNG 优先 | 透明 PNG，允许无透明背景的语义图 | `card_texture_path` |
| 角色战斗立绘 | `external/sprites/characters/character_{color}/` | 当前高约 `512-600` | PNG | 真实透明 PNG，无绿底 | `character_texture_path` |
| 角色选择头像 | `external/sprites/characters/character_{color}/` | `256 x 256` | PNG | 透明 PNG | `character_icon_texture_path` |
| 角色能量图标 | `external/sprites/characters/character_{color}/` | `128 x 128` 或已验证 `16 x 16` 内嵌图 | PNG | 透明 PNG | `character_text_energy_texture_path` |
| 角色选择背景 | `external/sprites/characters/character_{color}/` | `1200 x 700` | PNG | 可不透明 | `character_background_texture_path` |
| 敌人战斗图 | `external/sprites/enemies/` | 小怪约 `64-128`，Boss 可到 `512` | PNG | 透明 PNG | `enemy_texture_path` |
| 事件插画 | `external/sprites/events/` | `768 x 768` | PNG/JPG | 可不透明 | `dialogue_state_dialogue_texture_path` |
| 战斗/章节背景 | `external/sprites/acts/`、`external/sprites/locations/` | `1200 x 700` 或 `2400 x 1400` | PNG/JPG | 不透明 | `act_background_texture_path` / `location_background_texture_path` / `event_background_texture_path` |
| 遗物图标 | `external/sprites/artifacts/` | `128 x 128` | PNG | 透明 PNG | `artifact_texture_path` |
| 消耗品图标 | `external/sprites/consumables/` | `128 x 128`，旧资源可为 `80 x 80` | PNG | 透明 PNG | `consumable_texture_path` |
| 状态图标 | `external/sprites/status_effects/` | `128 x 128`，旧资源可为 `80 x 80` | PNG | 透明 PNG | `status_effect_texture_path` |

## 3. 透明通道与绿底规则

角色、敌人、图标和卡牌插画运行图必须使用真实 alpha 通道。不得把 `#00ff00` 或其他纯色抠像底作为运行图背景提交。

验收标准：

1. 角色战斗立绘四角不能包含 chroma green RGB residue，即使这些像素的 alpha 为 `0`。
2. 角色战斗立绘中不得存在 chroma green RGB residue；清理工具必须检查所有像素的 RGB，不得只检查 opaque 像素。
3. 角色脚底、头发、武器和外轮廓必须完整可见。
4. 角色缩放到战斗显示高度约 `200px` 后仍能辨认主体。

## 4. Contact Sheet 验收

所有新增或替换的内容图必须生成 contact sheet。contact sheet 至少包含：

1. 原图预览。
2. 游戏显示尺寸预览。
3. `64px` 缩略图。
4. `32px` 缩略图。
5. 深色背景和浅色背景下的透明边检查。

Phase 0 的角色验收图输出到：

`designer/art_source/contact_sheets/phase-0-character-contract.png`

## 5. 类型化 fallback

类型化 fallback 资源统一放在 `external/sprites/fallback/`：

| 类型 | 文件 |
| --- | --- |
| 卡牌插画 fallback | `external/sprites/fallback/fallback_card.png` |
| 角色 fallback | `external/sprites/fallback/fallback_character.png` |
| 敌人 fallback | `external/sprites/fallback/fallback_enemy.png` |
| 通用图标 fallback | `external/sprites/fallback/fallback_icon.png` |
| 背景 fallback | `external/sprites/fallback/fallback_background.png` |

新增 UI 或资源加载点时，应优先使用 `FileLoader.load_texture_or_fallback(path, fallback_type)`，不要直接把缺图显示成空纹理或无语义图标。

---

## 6. 统一加载方式：FileLoader

所有外部图片由 `autoload/FileLoader.gd` 统一管理：

```gdscript
func load_texture(image_partial_path: String, is_absolute: bool = false) -> ImageTexture:
    var full_path: String = _get_modified_filepath(image_partial_path)
    if self._cached_textures.has(full_path):
        return self._cached_textures[full_path]
    if FileAccess.file_exists(full_path):
        var image := Image.load_from_file(full_path)
        var texture = ImageTexture.create_from_image(image)
        self._cached_textures[full_path] = texture
        return texture
    push_error("Image failed to load: ", full_path)
    return ImageTexture.new()
```

**特点：**
- 自动处理 `res://`（编辑器）与导出后绝对路径的切换
- 内部 `_cached_textures` 字典做缓存，避免重复 IO
- 支持 `.png`、`.jpg`、`.jpeg`、`.svg`
- 运行时若图片文件不存在，会在 Godot 输出面板打印错误并返回空纹理

---

## 7. 动画系统

### 7.1 核心特点

项目中**没有逐帧动画系统**（未使用 `AnimatedSprite` 或 `SpriteFrames`）。所有角色、敌人、卡牌均为**单张静态图片**，动画完全由 **AnimationPlayer** 驱动。

### 7.2 动画配置

动画在对应 `.tscn` 场景中通过 `AnimationPlayer` 节点定义，使用 `value` track 控制属性：

| 场景 | 动画名 | 用途 |
|------|--------|------|
| `scenes/ui/Card.tscn` | `card_hover`、`card_unhover` | 卡牌悬停位移动画 |
| `scenes/Combatant/Enemy.tscn` | `attack`、`death` | 敌人攻击位移、死亡淡出 |
| `scenes/Combatant/Player.tscn` | `attack`、`death`、`run_start` | 玩家攻击、死亡、开场入场 |
| `scenes/ui/Artifact.tscn` | `proc_anim` | 遗物触发闪烁 |
| `scenes/ui/ArtifactFade.tscn` | `fade` | 遗物飘字淡出 |
| `scenes/ui/TextFade.tscn` | `fade` | 伤害/格挡数字飘字 |

### 7.3 触发方式

代码中通过 `animation_player.play("anim_name")` 触发：

```gdscript
# 敌人攻击
animation_player.play("attack")

# 玩家死亡
animation_player.play("death")

# 遗物触发
animation_player.play("proc_anim")
```

### 7.4 修改动画

若要修改动画效果，需在 Godot 编辑器中打开对应 `.tscn` 场景，编辑 `AnimationPlayer` 的 track 关键帧（位置、透明度、缩放等）。

---

## 8. 操作指南：如何替换图片

### 8.1 替换已有卡牌的图片

**步骤：**
1. 找到目标卡牌对应的 JSON 文件，例如 `external/data/cards/card_attack_basic.json`
2. 查看其中的 `card_texture_path` 字段值，例如 `"external/sprites/cards/red/card_red.png"`
3. 直接替换该路径下的 PNG 图片文件（**保持文件名不变**）
4. 若需修改图片尺寸，需同步调整 `scenes/ui/Card.tscn` 中 `CardTexture` 节点的 `size` 和 `offset`

**示例：给 "Basic Attack" 换图**
```json
// external/data/cards/card_attack_basic.json
{
    "properties": {
        "card_texture_path": "external/sprites/cards/red/card_red.png"
    }
}
```
直接覆盖 `external/sprites/cards/red/card_red.png` 即可。

### 8.2 给不同卡牌分配不同图片

**步骤：**
1. 将新图片放入 `external/sprites/cards/` 下的对应子目录（或新建子目录）
2. 在目标卡牌的 JSON 中修改 `card_texture_path` 指向新图片路径

**示例：卡牌 A 用 red，卡牌 B 用 blue**
```json
// 卡牌 A
{ "card_texture_path": "external/sprites/cards/red/card_red.png" }

// 卡牌 B
{ "card_texture_path": "external/sprites/cards/blue/card_blue.png" }
```

### 8.3 替换角色/敌人图片

操作逻辑与卡牌相同：
1. 找到对应 JSON 中的 `*_texture_path` 字段
2. 替换路径指向的 PNG 文件

```json
// 角色
{ "character_texture_path": "external/sprites/characters/character_red/character_red.png" }

// 敌人
{ "enemy_texture_path": "external/sprites/enemies/enemy_red_large.png" }
```

### 8.4 注意事项

- **保持尺寸一致**：若新图尺寸与原有规格不同，可能导致 UI 拉伸或显示异常
- **保持透明通道**：PNG 的 Alpha 通道用于实现卡牌/敌人的透明边缘
- **无需重启 Godot**：由于 `FileLoader` 读取的是外部文件，替换 PNG 后直接在游戏中查看效果即可（Editor 模式下可能需要重新运行场景）
- **路径前缀**：JSON 中写相对路径（如 `external/sprites/...`），**不要**写 `res://`，`FileLoader` 会自动处理前缀

---

## 9. 扩展：引入逐帧动画（如需）

若未来需要将静态图改为带逐帧动画的角色/敌人，需要：
1. 将多张帧图放入一个新目录（如 `external/sprites/enemies/enemy_red_large/frame_01.png`）
2. 修改对应场景（如 `Enemy.tscn`），将 `Sprite2D` 替换为 `AnimatedSprite`
3. 调用 `FileLoader.load_animation()` 从图片序列生成 `SpriteFrames`
4. 修改 JSON 配置，新增动画帧路径字段

> 注意：`FileLoader.load_animation()` 方法已在代码中存在，但当前项目中没有任何地方调用它。
