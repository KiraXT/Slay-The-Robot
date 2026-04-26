# Slay the Robot - 卡牌配置指南

本指南说明如何使用 CSV/Excel 配置卡牌，并自动转换为 JSON 格式。

---

## 📁 文件结构

```
external/
├── config/
│   ├── cards.csv              # 卡牌配置源文件（编辑这个）
│   └── cards_template.csv     # 模板示例文件
├── data/
│   └── cards/                 # 自动生成的 JSON 文件
│       └── card_xxx.json      # 生成的卡牌配置
└── tools/
    ├── csv_to_json.py         # Python 转换脚本
    ├── convert.bat            # Windows 一键转换
    └── requirements.txt       # Python 依赖
```

---

## 🚀 快速开始

### 方法 1: 使用批处理文件（推荐）

1. **复制模板文件**
   ```bash
   copy external\config\cards_template.csv external\config\cards.csv
   ```

2. **编辑卡牌配置**
   - 用 Excel 或 Google Sheets 打开 `external/config/cards.csv`
   - 修改现有卡牌或添加新行

3. **运行转换**
   - 双击 `external/tools/convert.bat`
   - 或在命令行运行:
     ```bash
     python external/tools/csv_to_json.py
     ```

### 方法 2: 使用 Godot 编辑器插件

1. **启用插件**
   - 打开 Godot 编辑器
   - 进入 `项目 -> 项目设置 -> 插件`
   - 启用 "Card CSV Importer"

2. **导入卡牌**
   - 点击菜单 `项目 -> Reimport Cards from CSV`
   - 等待转换完成

---

## 📝 CSV 字段说明

### 基础信息

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `object_id` | 字符串 | 卡牌唯一标识符 | `card_strike` |
| `card_name` | 字符串 | 卡牌显示名称 | `Strike` |
| `card_description` | 字符串 | 卡牌描述（支持占位符） | `Deal [damage] damage` |
| `card_type` | 整数 | 0=ATTACK, 1=SKILL, 2=POWER, 3=STATUS, 4=CURSE | `0` |
| `card_rarity` | 整数 | 0=BASIC, 1=COMMON, 2=UNCOMMON, 3=RARE, 4=GENERATED | `1` |
| `card_color_id` | 字符串 | 颜色标识 | `color_red` |
| `card_energy_cost` | 整数 | 能量消耗 | `1` |
| `card_energy_cost_is_variable` | 布尔 | 是否为可变消耗（X费） | `FALSE` |
| `card_requires_target` | 布尔 | 是否需要选择目标 | `TRUE` |

### 标志位

| 字段 | 类型 | 说明 |
|------|------|------|
| `card_exhausts` | 布尔 | 使用后是否放逐 |
| `card_is_ethereal` | 布尔 | 是否虚无（回合结束放逐） |
| `card_is_retained` | 布尔 | 是否保留 |
| `card_appears_in_card_packs` | 布尔 | 是否出现在卡牌包中 |

### 卡牌数值 (card_values)

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `damage` | 整数 | 伤害值 | `10` |
| `number_of_attacks` | 整数 | 攻击次数 | `2` |
| `block` | 整数 | 格挡值 | `5` |
| `draw_count` | 整数 | 抽牌数 | `3` |
| `status_charge_amount` | 整数 | 状态层数 | `3` |
| `status_secondary_charge_amount` | 整数 | 次要状态层数 | `30` |
| `status_effect_object_id` | 字符串 | 状态效果ID | `status_effect_poison` |

### 动作配置

| 字段 | 类型 | 说明 | 可用值 |
|------|------|------|--------|
| `action_type` | 字符串 | 动作类型 | `ActionAttackGenerator`, `ActionBlock`, `ActionDrawGenerator`, `ActionApplyStatus` 等 |
| `action_time_delay` | 浮点数 | 动作延迟（秒） | `0.0`, `0.5` |
| `action_target_override` | 字符串 | 目标覆盖 | `BaseAction.TARGET_OVERRIDES.PARENT`, `BaseAction.TARGET_OVERRIDES.ALL_ENEMIES` |
| `action_on_lethal` | 字符串 | 击杀时触发的动作 | `ActionAddMoney` |

### 升级配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `card_upgrade_amount_max` | 整数 | 最大升级次数 |
| `first_upgrade_energy_cost` | 整数 | 首次升级后的能量消耗 |
| `upgrade_damage` | 整数 | 每次升级增加的伤害 |
| `upgrade_block` | 整数 | 每次升级增加的格挡 |
| `upgrade_number_of_attacks` | 整数 | 每次升级增加的攻击次数 |
| `upgrade_draw_count` | 整数 | 每次升级增加的抽牌数 |

---

## ✅ 验证规则

转换器会自动检查以下问题：

### 错误 (阻止生成)
- ❌ `object_id` 为空
- ❌ `card_name` 为空
- ❌ `card_type` 不是有效值 (0-4)
- ❌ `card_requires_target` 为 FALSE 但有伤害值

### 警告 (允许生成)
- ⚠️ 攻击卡牌伤害为 0
- ⚠️ 未知颜色 ID
- ⚠️ 描述中的占位符 `[xxx]` 没有对应数值
- ⚠️ Power 卡牌设置了 `card_exhausts`（冗余）
- ⚠️ 可变费用卡牌能量消耗不为 0

---

## 🆕 新增卡牌流程

1. **打开 CSV 文件**
   ```bash
   external/config/cards.csv
   ```

2. **添加新行**，填写所有必要字段
   - 复制现有卡牌行作为模板
   - 修改 `object_id` 为新值
   - 填写卡牌名称、描述、数值等

3. **运行转换**
   ```bash
   # 方法 1: 批处理
   external/tools/convert.bat

   # 方法 2: Python 脚本
   python external/tools/csv_to_json.py

   # 方法 3: Godot 菜单
   项目 -> Reimport Cards from CSV
   ```

4. **验证输出**
   - 检查 `external/data/cards/` 下是否生成了新的 JSON 文件
   - 启动游戏测试新卡牌

---

## 📝 示例卡牌配置

### 简单攻击卡牌
```csv
object_id,card_name,card_description,card_type,card_rarity,card_color_id,card_energy_cost,card_requires_target,damage,number_of_attacks,action_type,upgrade_damage,card_upgrade_amount_max
card_strike,Strike,Deal [damage] damage,0,1,color_red,1,TRUE,10,1,ActionAttackGenerator,4,1
```

### 技能卡牌（带格挡）
```csv
object_id,card_name,card_description,card_type,card_rarity,card_color_id,card_energy_cost,card_requires_target,block,action_type,action_target_override,upgrade_block,card_keyword_object_ids
card_defend,Defend,Gain [block] block,1,1,color_green,1,FALSE,8,ActionBlock,BaseAction.TARGET_OVERRIDES.PARENT,3,keyword_block
```

### 复杂卡牌（带状态效果）
```csv
object_id,card_name,card_description,card_type,card_rarity,card_color_id,card_energy_cost,card_requires_target,damage,status_charge_amount,status_effect_object_id,action_type,upgrade_damage,upgrade_status_charge_amount
card_poison,Poison Strike,Deal [damage] damage and apply [status_charge_amount] poison,0,2,color_green,2,TRUE,4,3,status_effect_poison,ActionAttackGenerator,2,2
```

---

## 🔧 故障排除

### 转换失败

**问题**: `ModuleNotFoundError: No module named 'pandas'`
- **解决**: 当前脚本使用标准库，无需 pandas

**问题**: `CSV file not found`
- **解决**: 运行 `python external/tools/csv_to_json.py --create-sample` 创建模板

**问题**: 卡牌数值不生效
- **解决**: 检查描述中的占位符 `[xxx]` 是否与字段名完全匹配

### 游戏不加载新卡牌

1. 检查 JSON 文件是否正确生成在 `external/data/cards/`
2. 检查 `object_id` 是否唯一
3. 检查是否存在验证错误

---

## 📊 迁移说明

### 从旧代码定义迁移

如果你之前有在 `Global.gd` 的 `add_test_cards()` 中定义卡牌：

1. 将所有卡牌信息转移到 CSV
2. 从 `add_test_cards()` 中删除对应代码
3. 注释掉 `add_test_cards()` 的调用或保留为备用

### 与 Mod 系统兼容

生成的 JSON 文件与 Mod 系统完全兼容：
- 可以在 `external/mods/your_mod/cards/` 中放置额外的 JSON 文件
- 可以通过 `patch_data` 覆盖基础卡牌

---

## 🎨 最佳实践

1. **命名规范**: 使用 `card_` 前缀，如 `card_fireball`
2. **描述占位符**: 使用方括号 `[damage]`，确保与字段名一致
3. **数值平衡**: 在升级列中体现成长，如 `upgrade_damage = 3-5`
4. **版本控制**: 提交 CSV 文件，忽略生成的 JSON（已配置 .gitignore）
