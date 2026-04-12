#!/usr/bin/env python3
"""
修复JSON文件中的浮点数类型字段
将 target_override, stat_enum 等应该是整数的字段从浮点数转换为整数
"""

import json
from pathlib import Path

# 应该为整数的字段
INT_FIELDS = {
    'target_override', 'stat_enum', 'card_type', 'card_rarity', 'card_energy_cost',
    'card_energy_cost_variable_upper_bound', 'card_first_shuffle_priority',
    'card_upgrade_amount', 'card_upgrade_amount_max', 'artifact_counter',
    'artifact_counter_max', 'artifact_counter_reset_on_combat_end',
    'artifact_counter_reset_on_turn_start', 'enemy_intent',
    'enemy_intent_stat_enum'
}


def fix_floats_in_dict(obj):
    """递归修复字典中的浮点数字段"""
    if isinstance(obj, dict):
        new_dict = {}
        for key, value in obj.items():
            if key in INT_FIELDS and isinstance(value, float):
                new_dict[key] = int(value)
                print(f"  修复 {key}: {value} -> {int(value)}")
            elif isinstance(value, (dict, list)):
                new_dict[key] = fix_floats_in_dict(value)
            else:
                new_dict[key] = value
        return new_dict
    elif isinstance(obj, list):
        return [fix_floats_in_dict(item) for item in obj]
    else:
        return obj


def fix_json_file(filepath: Path) -> bool:
    """修复单个JSON文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 修复浮点数
        fixed_data = fix_floats_in_dict(data)

        # 写回文件
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(fixed_data, f, indent=4, ensure_ascii=False)

        return True
    except Exception as e:
        print(f"  错误: {e}")
        return False


def main():
    """主函数"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent

    print("=" * 60)
    print("修复JSON浮点数类型问题...")
    print("=" * 60)

    # 需要修复的目录
    dirs_to_fix = [
        project_root / "external/data/cards",
        project_root / "external/data/artifacts",
        project_root / "external/data/events",
        project_root / "external/data/enemies",
        project_root / "external/data/consumables",
        project_root / "external/data/status_effects",
    ]

    total_fixed = 0
    for dir_path in dirs_to_fix:
        if not dir_path.exists():
            continue

        print(f"\n处理目录: {dir_path.name}")
        for json_file in dir_path.glob("*.json"):
            if fix_json_file(json_file):
                total_fixed += 1

    print(f"\n完成! 处理了 {total_fixed} 个JSON文件")


if __name__ == "__main__":
    main()
