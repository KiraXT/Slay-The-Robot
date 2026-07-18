# 卡牌出牌反馈维护说明

## 目标

卡牌出牌反馈现在由数据字段驱动，代码只负责解析、兜底和播放。新增或调整卡牌时，应优先改 `external/data/cards/*.json` 中的表现字段，而不是在战斗反馈代码里写卡牌特例。

## 卡牌表现字段

每张卡的 `properties` 需要显式配置以下字段：

- `card_visual_profile`：卡牌表现类别，可选 `attack`、`skill`、`power`、`curse`。
- `card_play_sfx`：打出音效 ID，例如 `card_attack`、`card_skill_draw`、`card_power`。
- `card_impact_vfx`：命中特效 ID，例如 `impact_slash`、`guard_burst`、`power_aura`。
- `card_screen_shake`：屏幕震动强度，可选空字符串、`small`、`medium`、`large`、`heavy`、`none`。
- `card_hit_pause`：命中停顿时长，单位为秒；`0` 表示不启用。

允许值由 `scripts/ui/CardPresentationResolver.gd` 统一登记，新增 ID 时需要同步补充 resolver 和相关测试。

## 播放链路

- `scripts/ui/Hand.gd` 发出卡牌开始打出、消耗能量、移动牌堆等信号。
- `scripts/ui/CombatFeedbackPresenter.gd` 监听战斗反馈信号，并根据当前卡牌配置播放闪烁、震动、hit pause、VFX 和 SFX。
- `scripts/ui/CombatFeedbackSfxLibrary.gd` 负责把默认 SFX ID 注册到 `AudioStreamPlayer`。
- `scripts/ui/CardPresentationResolver.gd` 负责把卡牌数据解析成最终表现配置，并为缺省字段提供类型兜底。
- `scenes/ui/vfx/CardImpactVFX.tscn` 和 `scripts/ui/vfx/CardImpactVFX.gd` 提供可复用的程序化命中特效。

当前 SFX 已提供一批程序化占位 wav，路径为 `external/audio/sfx/*.wav`。真实音频资源接入时可以直接替换同名 wav，或通过 `CombatFeedbackPresenter.register_sfx_stream(sound_id, stream)` 注册自定义音频流。

## 音效资源

默认音效文件由以下脚本生成：

```bash
node tools/generate_combat_sfx_assets.js
```

默认覆盖的 SFX ID 包括卡牌打出音效、伤害/格挡/状态反馈、能量变化和牌堆移动反馈。由于这些 wav 位于 `external/` 目录，运行时由 `CombatFeedbackSfxLibrary.gd` 读取 wav 字节并构造 `AudioStreamWAV`，不依赖 Godot 编辑器导入流程。

## 预览入口

开发调试时可以打开 `scenes/dev/CombatFeedbackPreview.tscn`。该场景会列出当前登记的 VFX 和 SFX ID，点击按钮即可在中心播放程序化命中特效或播放占位音效。

这个场景不接入正式游戏流程，只用于快速调手感。新增 VFX/SFX ID 时，应同步更新 `scripts/dev/CombatFeedbackPreview.gd` 和 `tests/combat_feedback_preview_regression.gd`。

## 生成器

使用以下命令检查卡牌表现字段是否和推断规则一致：

```bash
node tools/generate_card_presentation_config.js --check
```

需要批量写回 JSON 时执行：

```bash
node tools/generate_card_presentation_config.js --write
```

生成器会保留少量明确的手感覆盖项，例如 `card_bomb`、`card_duplicate_attacks`、`card_energy_on_draw`、`card_energy_on_discard`。新增特殊卡牌时，如果通用动作规则无法表达预期手感，应在生成器的 `MANUAL_PRESENTATION_OVERRIDES` 中登记。

## 验证

相关回归测试：

```bash
godot --headless --path . --script tests/card_presentation_data_regression.gd
godot --headless --path . --script tests/combat_feedback_presenter_regression.gd
```

完整检查仍应包含手牌拖拽、卡牌效果、UI 布局和 Godot 启动检查，避免反馈改动影响主战斗流程。
