# 卡牌独立插图补全实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 50 张玩家可获得卡牌制作独立二次元插图，先完成 8 张校准样图，再按批次完成剩余 42 张，并同步卡牌配置。

**Architecture:** 以一个分阶段清单作为唯一范围源，自动检查卡牌路径、图片尺寸、透明通道和 Excel/CSV 一致性。图片使用现有四位角色与独立卡图作为身份和风格参考，通过内置图片生成、纯色底抠像、软边去色溢和 512 像素规范化进入项目；每一批完成后单独验收并提交。

**Tech Stack:** Godot 4、GDScript、Python 3 + Pillow（验证与联系表）、`@oai/artifact-tool`（Excel/CSV 同步）、内置 ImageGen、PNG RGBA。

## Global Constraints

- 设计基准：`docs/superpowers/specs/2026-07-30-card-art-individualization-design.md`。
- 只处理 50 张玩家卡；`card_debug_log` 和 `card_restart_combat` 不处理。
- 输出固定为 `512 x 512`、PNG、RGBA、透明背景、无文字、无卡框、无水印。
- 红、蓝、绿、橙卡使用对应单一主角；白色卡使用双人协作；紫色卡使用双人或三人联动。
- 每张卡只保留一个主动作和一个辅助提示，保证 96 像素预览可读。
- 仅修改目标卡的 `card_texture_path`，同步 `external/config/cards.xlsx` 与 `external/config/cards.csv`。
- 四色通用卡图保留为回退资源，不删除。
- 保留当前工作区内与本任务无关的敌人、UI、用户设置和临时文件改动。
- 用户需要直接在当前分支测试，因此实施保留在 `codex/blue-card-image-replacement`，不迁移到独立 worktree。

---

## 文件结构

### 新建

- `tools/card_art_individualization_manifest.json`
  - 定义 50 张目标卡及所属执行阶段。
- `tests/card_individual_art_regression.py`
  - 检查范围、独立路径、Excel/CSV 一致性、PNG 尺寸和透明边缘。
- `tools/render_card_art_contact_sheet.py`
  - 根据清单生成样张或完整联系表。
- `tests/card_art_contact_sheet_regression.py`
  - 检查联系表工具能够按清单稳定输出。
- `tools/process_card_art_batch.py`
  - 按阶段执行抠像、去色溢和 512 像素规范化。
- `tests/card_art_batch_processor_regression.py`
  - 使用合成纯色底样本验证批处理器的透明边缘输出。
- `tmp/card-art-individualization/update_cards.mjs`
  - 使用 `@oai/artifact-tool` 同步 Excel 与 CSV；属于执行辅助文件，不提交。
- `external/sprites/cards/white/*.png`
  - 6 张白色卡图。
- `external/sprites/cards/purple/*.png`
  - 6 张紫色卡图。

### 修改

- `external/sprites/cards/red/*.png`
  - 新增 20 张独立红色卡图。
- `external/sprites/cards/blue/*.png`
  - 新增 5 张独立蓝色卡图。
- `external/sprites/cards/green/*.png`
  - 新增 6 张独立绿色卡图。
- `external/sprites/cards/orange/*.png`
  - 新增 7 张独立橙色卡图。
- `external/config/cards.xlsx`
  - 目标卡的 `card_texture_path`。
- `external/config/cards.csv`
  - 与 Excel 相同的目标路径。
- `tools/card_art_alpha_cleanup_manifest.json`
  - 将通过边缘验收的新卡图加入后续清理检查白名单。

---

### Task 1: 建立 50 张目标卡资源契约

**Files:**
- Create: `tests/card_individual_art_regression.py`
- Create: `tools/card_art_individualization_manifest.json`

**Interfaces:**
- Consumes: `external/config/cards.csv`、`external/config/cards.xlsx`。
- Produces: `validate_manifest()`、`validate_phase(phase_name: str)`；后续资源批次使用同一个阶段清单。

- [ ] **Step 1: 写入失败的范围测试**

创建 `tests/card_individual_art_regression.py`，定义以下阶段：

```python
EXPECTED_PHASES = {
    "pilot": {
        "card_finisher",
        "card_backup_drink",
        "card_metronome",
        "card_bag_swing",
        "card_block_initial",
        "variable_cost_attack_card",
        "card_attack_block",
        "card_damage_increase",
    },
    "red": {
        "attack_lower_cost_on_discard_card",
        "attack_with_conditional_block_card",
        "attack_with_conditional_draw_card",
        "card_banish_attack",
        "card_discard_block",
        "card_draft_red_card",
        "card_duplicate_attacks",
        "card_law",
        "card_opening_strike",
        "card_play_random_from_hand",
        "card_pursuit",
        "card_requires_adjacency",
        "card_right_click_transform_mode_a",
        "card_right_click_transform_mode_b",
        "card_vulnerable_enemies",
        "cards_played_attack_card",
        "ignore_damage_increase_attack_card",
        "set_hand_energy_card",
        "transform_hand_card",
    },
    "colored": {
        "card_by_accident",
        "card_hasty_sorting",
        "card_quick_search",
        "card_something_fell_out",
        "card_distorted_note",
        "card_echo_shield",
        "card_finale_burst",
        "card_first_beat",
        "card_tuning",
        "card_last_item",
        "card_old_item_reuse",
        "card_sports_drink",
        "card_sprint_start",
        "card_travel_light",
        "card_warmup",
    },
    "team": {
        "add_health_card",
        "card_shove",
        "custom_block_card",
        "end_turn_card",
        "attack_increase_cost_on_damage_taken_card",
        "card_energy_on_discard",
        "improving_retain_block_card",
        "upgrade_entire_deck_card",
    },
}
```

测试必须：

```python
assert sum(map(len, EXPECTED_PHASES.values())) == 50
assert not set.union(*EXPECTED_PHASES.values()) & {
    "card_debug_log",
    "card_restart_combat",
}
assert MANIFEST.exists(), "missing card art individualization manifest"
```

- [ ] **Step 2: 运行测试并确认失败**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase manifest
```

Expected: FAIL，包含 `missing card art individualization manifest`。

- [ ] **Step 3: 创建最小阶段清单**

创建 `tools/card_art_individualization_manifest.json`：

```json
{
  "design": "docs/superpowers/specs/2026-07-30-card-art-individualization-design.md",
  "phases": {
    "pilot": [],
    "red": [],
    "colored": [],
    "team": []
  },
  "excluded_development_cards": [
    "card_debug_log",
    "card_restart_combat"
  ]
}
```

将 Step 1 中每个阶段的 ID 原样写入对应数组。测试从 `cards.csv` 读取 `card_color_id`，按以下规则派生独立路径：

```python
color_folder = row["card_color_id"].removeprefix("color_")
expected_path = f"external/sprites/cards/{color_folder}/{card_id}.png"
```

`validate_manifest()` 必须检查：

- 阶段名称完全等于 `pilot`、`red`、`colored`、`team`。
- 每个阶段集合与 `EXPECTED_PHASES` 完全相等。
- 50 个 ID 无重复。
- 两张开发卡只出现在排除列表。

- [ ] **Step 4: 运行范围测试并确认通过**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase manifest
```

Expected: PASS，输出 `MANIFEST_VALIDATED: 50 cards`。

- [ ] **Step 5: 提交资源契约**

```bash
git add tests/card_individual_art_regression.py tools/card_art_individualization_manifest.json
git commit -m "test: define individual card art scope"
```

---

### Task 2: 生成并接入 8 张校准样图

**Files:**
- Modify: `tests/card_individual_art_regression.py`
- Create:
  - `external/sprites/cards/red/card_finisher.png`
  - `external/sprites/cards/blue/card_backup_drink.png`
  - `external/sprites/cards/green/card_metronome.png`
  - `external/sprites/cards/orange/card_bag_swing.png`
  - `external/sprites/cards/white/card_block_initial.png`
  - `external/sprites/cards/white/variable_cost_attack_card.png`
  - `external/sprites/cards/purple/card_attack_block.png`
  - `external/sprites/cards/purple/card_damage_increase.png`
- Create: `tools/process_card_art_batch.py`
- Create: `tests/card_art_batch_processor_regression.py`
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`
- Modify: `tools/card_art_alpha_cleanup_manifest.json`

**Interfaces:**
- Consumes: Task 1 的阶段清单和设计文档第 6、7、8、9 节。
- Produces: 8 张经角色、构图和透明边缘校准的最终 PNG。

- [ ] **Step 1: 为 pilot 阶段增加失败检查**

在 `validate_phase()` 中检查：

```python
assert csv_row["card_texture_path"] == expected_path
assert xlsx_row["card_texture_path"] == expected_path
image = Image.open(ROOT / expected_path)
assert image.size == (512, 512)
assert image.mode == "RGBA"
assert image.getextrema()[3][0] == 0
assert image.getextrema()[3][1] == 255
for corner in ((0, 0), (511, 0), (0, 511), (511, 511)):
    assert image.getpixel(corner)[3] <= 16
```

再统计半透明边缘中与抠像底色过度接近的像素，单张不得达到 64 个。

- [ ] **Step 2: 运行 pilot 检查并确认失败**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase pilot
```

Expected: FAIL，第一条失败来自 `card_finisher` 仍指向通用图或目标文件不存在。

- [ ] **Step 3: 使用现有角色和卡图生成 8 张纯色底源图**

每张图使用内置 ImageGen 单独生成。统一提示词骨架：

```text
Use case: game card art
Asset type: square anime mobile-RPG card illustration
Input images: use the listed character image as the exact identity/outfit anchor;
use the listed existing card art only as rendering and effect-density reference.
Primary request: use the exact per-card art direction from section 7 of
docs/superpowers/specs/2026-07-30-card-art-individualization-design.md.
Composition: one dominant action, one supporting cue, subject contained within
the central 82 percent of a square canvas, readable at 96 px.
Style: polished 2D anime key art, crisp silhouette, clean cel-shaded rendering,
matching the current Slay-The-Robot character card illustrations.
Scene/backdrop: perfectly flat solid chroma background using the exact key
color from the following pilot table, with no
texture, gradient, shadow, horizon, or reflected color.
Constraints: exact current hairstyle, outfit and signature props; no card frame,
no UI, no text, no letters, no numbers, no logo, no watermark.
```

样图参考与抠像底色：

| 卡牌 | 身份参考 | 风格参考 | 纯色底 |
| --- | --- | --- | --- |
| `card_finisher` | `character_red.png` | `card_combo_starter.png` | `#00ff00` |
| `card_backup_drink` | `character_blue.png` | `card_draw.png` | `#ff00ff` |
| `card_metronome` | `character_green.png` | `card_bomb.png` | `#ff00ff` |
| `card_bag_swing` | `character_orange.png` | `card_attack_big.png` | `#0055ff` |
| `card_block_initial` | 红、橙角色立绘 | `card_block_basic.png`、`card_block_big.png` | `#ff00ff` |
| `variable_cost_attack_card` | 红、绿角色立绘 | `card_attack_basic.png`、`card_upgrade_card.png` | `#ff00ff` |
| `card_attack_block` | 红、绿、橙角色立绘 | `card_block_basic.png`、`card_echo_shield` 的设计方向 | `#ff00ff` |
| `card_damage_increase` | 红、绿、橙角色立绘 | `card_combo_starter.png`、`card_upgrade_card.png` | `#ff00ff` |

源图按以下表达式复制：

```python
raw_path = ROOT / "tmp" / "card-art-individualization" / "raw" / f"{card_id}.png"
```

- [ ] **Step 4: 为批处理器写入失败测试**

创建 `tests/card_art_batch_processor_regression.py`。测试生成一个 `64 x 64` 合成 PNG：纯绿色背景、中央红色矩形、矩形边缘带半透明像素。调用：

```python
process_one(
    raw_path=raw_path,
    output_path=output_path,
    key_color="#00ff00",
)
with Image.open(output_path) as image:
    assert image.size == (512, 512)
    assert image.mode == "RGBA"
    assert image.getpixel((0, 0))[3] == 0
    assert image.getpixel((256, 256))[3] == 255
```

- [ ] **Step 5: 运行批处理器测试并确认失败**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_art_batch_processor_regression.py
```

Expected: FAIL，缺少 `tools.process_card_art_batch`。

- [ ] **Step 6: 实现批处理器**

`tools/process_card_art_batch.py` 提供：

```python
import argparse
import csv
import json
from pathlib import Path

from PIL import Image

if __package__:
    from tools.card_art_chroma import remove_chroma_key
    from tools.card_art_manifest import key_color_for_card
else:
    from card_art_chroma import remove_chroma_key
    from card_art_manifest import key_color_for_card

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools" / "card_art_individualization_manifest.json"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"


def process_one(raw_path: Path, output_path: Path, key_color: str) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(raw_path) as source:
        keyed = remove_chroma_key(
            source,
            key_color,
            transparent_threshold=24,
            opaque_threshold=90,
            edge_contract=1,
            edge_feather=0.7,
            despill=True,
        )
    final = keyed.resize((512, 512), Image.Resampling.LANCZOS)
    final = _remove_key_fringe(final, key_color)
    final = _normalize_subject(final)
    final = _remove_key_fringe(final, key_color)
    final.save(output_path, format="PNG", optimize=True)


def process_phase(phase: str) -> list[Path]:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        rows = {
            row["object_id"]: row
            for row in csv.DictReader(handle)
            if row.get("object_id")
        }
    outputs = []
    for card_id in manifest["phases"][phase]:
        color_id = rows[card_id]["card_color_id"]
        color_folder = color_id.removeprefix("color_")
        raw_path = (
            ROOT / "tmp" / "card-art-individualization" / "raw"
            / f"{card_id}.png"
        )
        output_path = (
            ROOT / "external" / "sprites" / "cards" / color_folder
            / f"{card_id}.png"
        )
        key_color = key_color_for_card(manifest, card_id, color_id)
        process_one(raw_path, output_path, key_color)
        outputs.append(output_path)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--phase",
        required=True,
        choices=("pilot", "red", "colored", "team"),
    )
    args = parser.parse_args()
    outputs = process_phase(args.phase)
    print(f"CARD_ART_PROCESSED: {len(outputs)}")


if __name__ == "__main__":
    main()
```

`process_one()` 直接调用仓库内 `tools/card_art_chroma.py`，不依赖个人目录或已安装 Codex skill。固定参数为：

```text
soft matte
transparent threshold 24
opaque threshold 90
edge contract 1
edge feather 0.7
despill
```

抠像后使用 Pillow 以 `LANCZOS` 缩放为 `512 x 512 RGBA`。

阶段默认底色和单卡例外只在 `tools/card_art_individualization_manifest.json` 中定义：

```json
"key_colors": {
  "defaults": {
    "color_red": "#00ff00",
    "color_blue": "#ff00ff",
    "color_green": "#ff00ff",
    "color_orange": "#0055ff",
    "color_white": "#ff00ff",
    "color_purple": "#ff00ff"
  },
  "overrides": {
    "attack_increase_cost_on_damage_taken_card": "#00ff00",
    "card_banish_attack": "#ff00ff"
  }
}
```

`variable_cost_attack_card` 与 `custom_block_card` 使用各自颜色的默认洋红底 `#ff00ff`；`card_banish_attack` 保留显式洋红 override，`attack_increase_cost_on_damage_taken_card` 保留绿色 override。

`process_phase()` 从阶段清单和 CSV 读取卡牌颜色，输入和输出路径均由 `card_id` 与 `color_id` 的 f-string 表达式确定。

- [ ] **Step 7: 运行批处理器测试并处理 pilot**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_art_batch_processor_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/process_card_art_batch.py --phase pilot
```

Expected: 测试通过并生成 8 张 `512 x 512 RGBA` PNG。

- [ ] **Step 8: 使用 artifact-tool 同步 Excel 和 CSV**

在 `tmp/card-art-individualization/` 创建 `node_modules` 符号链接，指向：

```text
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules
```

创建 `tmp/card-art-individualization/update_cards.mjs`：

```js
import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = "/Users/xietong/Documents/GitHub/Slay-The-Robot";
const phase = process.argv[2];
const manifest = JSON.parse(await fs.readFile(
  `${root}/tools/card_art_individualization_manifest.json`, "utf8"
));
const targetIds = new Set(manifest.phases[phase]);
const pathFor = (cardId, colorId) =>
  `external/sprites/cards/${colorId.replace("color_", "")}/${cardId}.png`;

const xlsxInput = await FileBlob.load(`${root}/external/config/cards.xlsx`);
const xlsxWorkbook = await SpreadsheetFile.importXlsx(xlsxInput);
const xlsxSheet = xlsxWorkbook.worksheets.getItem("Cards");
const xlsxValues = xlsxSheet.getUsedRange(true).values;
const headers = xlsxValues[0];
const idCol = headers.indexOf("object_id");
const colorCol = headers.indexOf("card_color_id");
const textureCol = headers.indexOf("card_texture_path");
for (let row = 1; row < xlsxValues.length; row++) {
  const cardId = String(xlsxValues[row][idCol] ?? "");
  if (targetIds.has(cardId)) {
    xlsxValues[row][textureCol] = pathFor(cardId, String(xlsxValues[row][colorCol]));
  }
}
xlsxSheet.getRangeByIndexes(0, 0, xlsxValues.length, headers.length).values = xlsxValues;

const csvText = await fs.readFile(`${root}/external/config/cards.csv`, "utf8");
const csvWorkbook = await Workbook.fromCSV(csvText, { sheetName: "Cards" });
const csvSheet = csvWorkbook.worksheets.getItem("Cards");
const csvValues = csvSheet.getUsedRange(true).values;
for (let row = 1; row < csvValues.length; row++) {
  const cardId = String(csvValues[row][idCol] ?? "");
  if (targetIds.has(cardId)) {
    csvValues[row][textureCol] = pathFor(cardId, String(csvValues[row][colorCol]));
  }
}
csvSheet.getRangeByIndexes(0, 0, csvValues.length, headers.length).values = csvValues;

const escapeCsv = (value) => {
  const text = value == null ? "" : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};
const updatedCsv = csvValues.map((row) => row.map(escapeCsv).join(",")).join("\n") + "\n";

await fs.mkdir(`${root}/outputs/card-art-individualization`, { recursive: true });
const inspect = await xlsxWorkbook.inspect({
  kind: "region",
  sheetId: "Cards",
  range: "A1:P105",
  maxChars: 5000,
});
console.log(inspect.ndjson);
const preview = await xlsxWorkbook.render({
  sheetName: "Cards",
  range: "A1:P20",
  scale: 1,
  format: "png",
});
await fs.writeFile(
  `${root}/outputs/card-art-individualization/cards-preview.png`,
  new Uint8Array(await preview.arrayBuffer())
);
const output = await SpreadsheetFile.exportXlsx(xlsxWorkbook);
await output.save(`${root}/outputs/card-art-individualization/cards.xlsx`);
await fs.writeFile(`${root}/outputs/card-art-individualization/cards.csv`, updatedCsv);
```

运行：

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  tmp/card-art-individualization/update_cards.mjs pilot
```

视觉检查 `outputs/card-art-individualization/cards-preview.png`，再将验证后的 `cards.xlsx` 和 `cards.csv` 覆盖回 `external/config/`。

- [ ] **Step 9: 将 8 张图加入边缘检查白名单**

把 8 个最终路径追加到 `tools/card_art_alpha_cleanup_manifest.json` 的 `approved_paths`，保持字典序和无重复。

- [ ] **Step 10: 运行样张资源检查**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase pilot
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 两项均通过。

- [ ] **Step 11: 提交 8 张校准样图和处理工具**

```bash
git add \
  external/sprites/cards/red/card_finisher.png \
  external/sprites/cards/blue/card_backup_drink.png \
  external/sprites/cards/green/card_metronome.png \
  external/sprites/cards/orange/card_bag_swing.png \
  external/sprites/cards/white \
  external/sprites/cards/purple \
  external/config/cards.xlsx \
  external/config/cards.csv \
  tools/card_art_alpha_cleanup_manifest.json \
  tools/process_card_art_batch.py \
  tests/card_art_batch_processor_regression.py \
  tests/card_individual_art_regression.py
git commit -m "art: add card illustration calibration set"
```

---

### Task 3: 建立样张联系表并进行视觉检查点

**Files:**
- Create: `tests/card_art_contact_sheet_regression.py`
- Create: `tools/render_card_art_contact_sheet.py`
- Produce: `tmp/card-art-individualization/pilot-contact-sheet.png`

**Interfaces:**
- Consumes: 阶段清单与已完成 PNG。
- Produces: `render_contact_sheet(phase: str, output_path: Path) -> Path`。

- [ ] **Step 1: 写入失败的联系表测试**

测试调用：

```python
output = render_contact_sheet("pilot", tmp_path / "pilot.png")
assert output.exists()
with Image.open(output) as image:
    assert image.mode == "RGB"
    assert image.width == 4 * 560
    assert image.height == 2 * 620
```

- [ ] **Step 2: 运行测试并确认失败**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_art_contact_sheet_regression.py
```

Expected: FAIL，缺少 `tools.render_card_art_contact_sheet`。

- [ ] **Step 3: 实现联系表工具**

工具使用 Pillow：

- 读取清单中的阶段 ID。
- 从 CSV 获取名称、颜色和最终路径。
- 每格使用 `560 x 620`，图像区域 `512 x 512`。
- 底色为深中性灰，避免透明边缘不可见。
- 标签只显示卡名和 ID；不修改原始卡图。
- pilot 使用 4 列 2 行；all 使用 5 列 10 行。

- [ ] **Step 4: 运行测试并生成 pilot 联系表**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_art_contact_sheet_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/render_card_art_contact_sheet.py \
  --phase pilot \
  --output tmp/card-art-individualization/pilot-contact-sheet.png
```

Expected: 测试通过并生成 `2240 x 1240` 联系表。

- [ ] **Step 5: 视觉检查**

检查：

- 四位角色身份与当前立绘一致。
- 红、蓝、绿、橙单人卡风格一致。
- 白色双人图有一个明确主动作。
- 紫色三人图不拥挤。
- 96 像素缩略图仍能区分攻击、技能和能力。
- 透明边缘无底色残留。

这是方案 B 的用户检查点。通过后才执行 Task 4 至 Task 7。

- [ ] **Step 6: 提交联系表工具**

```bash
git add tests/card_art_contact_sheet_regression.py tools/render_card_art_contact_sheet.py
git commit -m "tool: add card art contact sheet renderer"
```

---

### Task 4: 完成剩余 19 张红色卡图

**Files:**
- Modify: `tests/card_individual_art_regression.py`
- Create: Task 1 `red` 集合中 19 个精确 ID 通过 `pathFor(cardId, "color_red")` 派生出的文件。
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`
- Modify: `tools/card_art_alpha_cleanup_manifest.json`

**Interfaces:**
- Consumes: 清单 `red` 阶段和设计文档第 7.1 节。
- Produces: 所有目标红色卡均使用独立插图。

- [ ] **Step 1: 运行 red 阶段检查并确认失败**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase red
```

Expected: FAIL，目标仍指向 `card_red.png`。

- [ ] **Step 2: 按设计文档逐张生成红色卡图**

统一参考：

- 身份：`external/sprites/characters/character_red/character_red.png`
- 风格：`external/sprites/cards/red/card_combo_starter.png`
- 默认抠像底：`#00ff00`

每张图的动作语义严格使用设计文档第 7.1 节，不增加第二个主要动作。

- [ ] **Step 3: 抠像、规范尺寸并同步配置**

先运行批处理器，再同步配置：

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/process_card_art_batch.py --phase red
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  tmp/card-art-individualization/update_cards.mjs red
```

将验证后的 Excel/CSV 覆盖回项目，并把 19 个路径加入 alpha 白名单。

- [ ] **Step 4: 验证红色批次**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase red
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 两项均通过。

- [ ] **Step 5: 提交红色批次**

```bash
git add external/sprites/cards/red external/config/cards.xlsx external/config/cards.csv tools/card_art_alpha_cleanup_manifest.json
git commit -m "art: add individual red card illustrations"
```

---

### Task 5: 完成剩余 15 张蓝、绿、橙卡图

**Files:**
- Create:
  - Task 1 `colored` 集合中的 4 个蓝色 ID，通过 `pathFor(cardId, "color_blue")` 派生。
  - Task 1 `colored` 集合中的 5 个绿色 ID，通过 `pathFor(cardId, "color_green")` 派生。
  - Task 1 `colored` 集合中的 6 个橙色 ID，通过 `pathFor(cardId, "color_orange")` 派生。
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`
- Modify: `tools/card_art_alpha_cleanup_manifest.json`

**Interfaces:**
- Consumes: 清单 `colored` 阶段和设计文档第 7.2 至 7.4 节。
- Produces: 所有蓝、绿、橙目标卡均使用独立插图。

- [ ] **Step 1: 运行 colored 阶段检查并确认失败**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase colored
```

Expected: FAIL，目标仍指向对应通用图。

- [ ] **Step 2: 生成蓝色批次**

- 身份：`character_blue.png`
- 风格：`card_draw.png`、`card_attack_rng.png`
- 抠像底：`#ff00ff`
- 语义：设计文档第 7.2 节。

- [ ] **Step 3: 生成绿色批次**

- 身份：`character_green.png`
- 风格：`card_bomb.png`、`card_attack_corrosion.png`
- 抠像底：`#ff00ff`
- 提示词中禁止洋红特效，语义使用设计文档第 7.3 节。

- [ ] **Step 4: 生成橙色批次**

- 身份：`character_orange.png`
- 风格：`card_pack_sorting.png`、`card_attack_big.png`
- 抠像底：`#0055ff`
- 语义：设计文档第 7.4 节。

- [ ] **Step 5: 抠像、同步配置并验证**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/process_card_art_batch.py --phase colored
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  tmp/card-art-individualization/update_cards.mjs colored
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase colored
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 三项均成功。

- [ ] **Step 6: 提交蓝、绿、橙批次**

```bash
git add external/sprites/cards/blue external/sprites/cards/green external/sprites/cards/orange external/config/cards.xlsx external/config/cards.csv tools/card_art_alpha_cleanup_manifest.json
git commit -m "art: complete colored card illustrations"
```

---

### Task 6: 完成剩余 8 张白色和紫色联动卡图

**Files:**
- Create:
  - Task 1 `team` 集合中的 4 个白色 ID，通过 `pathFor(cardId, "color_white")` 派生。
  - Task 1 `team` 集合中的 4 个紫色 ID，通过 `pathFor(cardId, "color_purple")` 派生。
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`
- Modify: `tools/card_art_alpha_cleanup_manifest.json`

**Interfaces:**
- Consumes: 清单 `team` 阶段和设计文档第 5、7.5、7.6 节。
- Produces: 12 张白/紫正式卡全部具备独立联动插图。

- [ ] **Step 1: 运行 team 阶段检查并确认失败**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase team
```

Expected: FAIL，目标 `card_texture_path` 为空。

- [ ] **Step 2: 生成 4 张白色双人卡图**

- 固定两人，不加入第三角色。
- 特效使用白、浅金、淡蓝。
- 根据每张参与角色选择不冲突的纯色底。
- 语义使用设计文档第 7.5 节。

- [ ] **Step 3: 生成 4 张紫色双人或三人卡图**

- 一位主角占主要面积，辅助角色分列后侧。
- 特效使用深紫、蓝紫和白色，不使用与抠像底相同的高饱和洋红。
- 语义使用设计文档第 7.6 节。

- [ ] **Step 4: 抠像、同步配置并验证**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/process_card_art_batch.py --phase team
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  tmp/card-art-individualization/update_cards.mjs team
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase team
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 三项均成功。

- [ ] **Step 5: 提交白紫批次**

```bash
git add external/sprites/cards/white external/sprites/cards/purple external/config/cards.xlsx external/config/cards.csv tools/card_art_alpha_cleanup_manifest.json
git commit -m "art: add team card illustrations"
```

---

### Task 7: 完整联系表与最终回归

**Files:**
- Produce: `tmp/card-art-individualization/all-contact-sheet.png`
- Verify: all task files

**Interfaces:**
- Consumes: 50 张最终 PNG 和同步后的配置。
- Produces: 可供整体视觉验收的 50 张联系表与最终测试证据。

- [ ] **Step 1: 运行 50 张完整资源检查**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_individual_art_regression.py --phase all
```

Expected: PASS，输出 `CARD_ART_VALIDATED: 50 cards`。

- [ ] **Step 2: 生成完整联系表**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/render_card_art_contact_sheet.py \
  --phase all \
  --output tmp/card-art-individualization/all-contact-sheet.png
```

检查所有颜色、卡牌类型、角色身份、透明边缘和 96 像素预览。

- [ ] **Step 3: 验证 Excel 和 CSV**

使用 artifact-tool 检查 `Cards` 表目标行的 `object_id`、`card_color_id`、`card_texture_path`；渲染表头与代表行。确认：

- Excel 与 CSV 的 50 个目标路径完全一致。
- `card_debug_log` 和 `card_restart_combat` 路径仍为空。
- 其余字段没有超出 `card_texture_path` 的修改。

- [ ] **Step 4: 运行完整回归**

```bash
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/ui_layout_bounds_regression.gd
godot --headless --path . --quit
git diff --check
```

Expected: 所有测试通过、Godot 启动退出码为 0、无空白错误。

- [ ] **Step 5: 检查提交范围**

```bash
git status --short
git diff --stat
```

只把本计划中的卡图、清单、测试、配置和联系表工具计入本任务；不提交敌人、战斗 UI、用户设置或其他已有工作区改动。
