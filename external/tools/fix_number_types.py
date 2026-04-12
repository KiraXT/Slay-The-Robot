#!/usr/bin/env python3
"""
修复JSON文件中的数值类型问题
将card_values中的浮点数转换为整数
"""

import json
import re
from pathlib import Path

# 应该为整数的字段
INT_FIELDS = {
    'damage', 'number_of_attacks', 'block', 'draw_count',
    'status_charge_amount', 'status_secondary_charge_amount',
    'money_amount', 'heal_amount', 'damage_random',
    'card_type', 'card_rarity', 'card_energy_cost',
    'card_energy_cost_variable_upper_bound',
    'card_upgrade_amount_max', 'card_first_shuffle_priority',
    'artifact_counter', 'artifact_counter_max',
    'artifact_counter_reset_on_combat_end', 'artifact_counter_reset_on_turn_start',
    'stat_enum',  # 添加 stat_enum
}


def fix_numbers_in_dict(obj, path=""):
    """递归修复字典中的数值类型"""
    if isinstance(obj, dict):
        new_dict = {}
        for key, value in obj.items():
            # 如果key是整数字段且value是浮点数，转换为整数
            if key in INT_FIELDS and isinstance(value, float):
                new_dict[key] = int(value)
                print(f"  修复: {key} {value} -> {int(value)}")
            elif key == "card_values" and isinstance(value, dict):
                # 特殊处理card_values中的数值
                new_card_values = {}
                for cv_key, cv_value in value.items():
                    if cv_key in INT_FIELDS and isinstance(cv_value, float):
                        new_card_values[cv_key] = int(cv_value)
                        print(f"  修复 card_values: {cv_key} {cv_value} -> {int(cv_value)}")
                    else:
                        new_card_values[cv_key] = cv_value
                new_dict[key] = new_card_values
            elif isinstance(value, (dict, list)):
                new_dict[key] = fix_numbers_in_dict(value, f"{path}.{key}")
            else:
                new_dict[key] = value
        return new_dict
    elif isinstance(obj, list):
        return [fix_numbers_in_dict(item, path) for item in obj]
    else:
        return obj


def fix_json_file(filepath: Path) -> bool:
    """修复单个JSON文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 修复数值类型
        fixed_data = fix_numbers_in_dict(data)

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

    # 修复卡牌
    cards_dir = project_root / "external/data/cards"
    print("=" * 60)
    print("修复卡牌JSON数值类型...")
    print("=" * 60)

    if cards_dir.exists():
        fixed_count = 0
        for json_file in cards_dir.glob("*.json"):
            print(f"\n处理: {json_file.name}")
            if fix_json_file(json_file):
                fixed_count += 1

        print(f"\n完成! 修复了 {fixed_count} 个卡牌JSON文件")

    # 修复遗物
    artifacts_dir = project_root / "external/data/artifacts"
    print("\n" + "=" * 60)
    print("修复遗物JSON数值类型...")
    print("=" * 60)

    if artifacts_dir.exists():
        fixed_count = 0
        for json_file in artifacts_dir.glob("*.json"):
            print(f"\n处理: {json_file.name}")
            if fix_json_file(json_file):
                fixed_count += 1

        print(f"\n完成! 修复了 {fixed_count} 个遗物JSON文件")


if __name__ == "__main__":
    main()
