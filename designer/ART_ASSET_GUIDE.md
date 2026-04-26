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

## 2. 卡牌图片

### 2.1 存放位置

`external/sprites/cards/{color}/`

按颜色分类存放：
```
external/sprites/cards/
  blue/card_blue.png
  green/card_green.png
  orange/card_orange.png
  red/card_red.png
```

### 2.2 图片规格

| 项目 | 标准 |
|------|------|
| **尺寸** | **96 x 96** 像素 |
| **格式** | PNG（8-bit RGBA，带透明通道） |
| **命名** | `card_{color}.png` |

### 2.3 引用方式

**配置层（JSON）：**
在 `external/data/cards/*.json` 中，通过 `card_texture_path` 字段指定图片路径：

```json
{
    "properties": {
        "card_texture_path": "external/sprites/cards/red/card_red.png"
    }
}
```

**代码层：**
运行时由 `scripts/ui/Card.gd` 调用 `FileLoader.load_texture()` 加载：

```gdscript
if card_data.card_texture_path != "":
    card_texture.texture = FileLoader.load_texture(card_data.card_texture_path)
```

### 2.4 UI 适配

- 卡牌场景：`scenes/ui/Card.tscn`
- 卡牌控件总尺寸：**144 x 184**
- 纹理显示区域（TextureRect）：**96 x 96**，在控件内居中偏上
- 背景色通过 `ColorRect` 根据 `card_color_id` 动态渲染，**不依赖背景纹理**

---

## 3. 角色图片

### 3.1 存放位置

`external/sprites/characters/character_{color}/`

```
external/sprites/characters/
  character_red/character_red.png                  # 角色立绘
  character_red/character_red_icon.png             # 角色选择图标
  character_red/character_red_text_energy.png      # 能量图标
```

### 3.2 图片规格

| 用途 | 尺寸 | 格式 |
|------|------|------|
| 角色立绘 (`character_{color}.png`) | **96 x 96** | PNG RGBA |
| 角色图标 (`character_{color}_icon.png`) | 约 **64 x 64** | PNG RGBA |
| 能量图标 (`character_{color}_text_energy.png`) | 待确认 | PNG RGBA |

### 3.3 引用方式

**配置层（JSON）：**
在 `external/data/characters/*.json` 中：

```json
{
    "properties": {
        "character_texture_path": "external/sprites/characters/character_red/character_red.png",
        "character_icon_texture_path": "external/sprites/characters/character_red/character_red_icon.png",
        "character_text_energy_texture_path": "external/sprites/characters/character_red/character_red_text_energy.png"
    }
}
```

**代码层：**
- `Player.gd`：`sprite.texture = FileLoader.load_texture(character_data.character_texture_path)`
- `CharacterSelectionButton.gd`：`texture_normal = FileLoader.load_texture(character_data.character_icon_texture_path)`

---

## 4. 敌人图片

### 4.1 存放位置

`external/sprites/enemies/`

命名规则：`enemy_{color}_{size}.png`

```
external/sprites/enemies/
  enemy_red_large.png
  enemy_red_medium.png
  enemy_red_small.png
  enemy_blue_large.png
  ...
```

### 4.2 图片规格

| 项目 | 标准 |
|------|------|
| **尺寸** | **128 x 128** 像素 |
| **格式** | PNG（RGBA） |
| **命名** | `enemy_{color}_{size}.png`（size: small, medium, large） |

### 4.3 引用方式

**配置层（JSON）：**
在 `external/data/enemies/*.json` 中：

```json
{
    "properties": {
        "enemy_texture_path": "external/sprites/enemies/enemy_red_large.png"
    }
}
```

**代码层：**
`Enemy.gd`：`sprite.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)`

---

## 5. 遗物 / 事件 / 其他图片

| 类型 | 存放路径 | 规格 | JSON 引用字段 |
|------|---------|------|--------------|
| 遗物 | `external/sprites/artifacts/artifact_{color}.png` | **64 x 64** PNG | `artifact_texture_path` |
| 事件背景 | `external/sprites/events/event_{id}.png` | **96 x 96** PNG | `event_background_texture_path` |
| Act 背景 | `external/sprites/acts/...` | 视场景而定 | `act_background_texture_path` |
| 地点背景 | `external/sprites/locations/...` | 视场景而定 | `location_background_texture_path` |

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
