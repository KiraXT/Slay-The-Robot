#!/usr/bin/env python3
"""
修复JSON文件中的target_override字段
将字符串枚举值转换为对应的整数
"""

import json
import re
from pathlib import Path

# TARGET_OVERRIDES 枚举映射
TARGET_OVERRIDES_MAP = {
    'BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS': 0,
    'BaseAction.TARGET_OVERRIDES.PARENT': 1,
    'BaseAction.TARGET_OVERRIDES.PLAYER': 2,
    'BaseAction.TARGET_OVERRIDES.ALL_COMBATANTS': 3,
    'BaseAction.TARGET_OVERRIDES.ALL_ENEMIES': 4,
    'BaseAction.TARGET_OVERRIDES.LEFTMOST_ENEMY': 5,
    'BaseAction.TARGET_OVERRIDES.ENEMY_ID': 6,
    'BaseAction.TARGET_OVERRIDES.RANDOM_ENEMY': 7,
}


def fix_target_override_in_dict(obj):
    """递归修复字典中的target_override"""
    if isinstance(obj, dict):
        new_dict = {}
        for key, value in obj.items():
            if key == "target_override":
                # 如果是字符串，转换为对应的整数
                if isinstance(value, str):
                    if value in TARGET_OVERRIDES_MAP:
                        new_dict[key] = TARGET_OVERRIDES_MAP[value]
                        print(f"  修复 target_override: '{value}' -> {TARGET_OVERRIDES_MAP[value]}")
                    else:
                        new_dict[key] = value  # 保持原样
                # 如果是浮点数，转换为整数
                elif isinstance(value, float):
                    new_dict[key] = int(value)
                    print(f"  修复 target_override: {value} -> {int(value)}")
                else:
                    new_dict[key] = value
            elif isinstance(value, (dict, list)):
                new_dict[key] = fix_target_override_in_dict(value)
            else:
                new_dict[key] = value
        return new_dict
    elif isinstance(obj, list):
        return [fix_target_override_in_dict(item) for item in obj]
    else:
        return obj


def fix_json_file(filepath: Path) -> bool:
    """修复单个JSON文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 修复target_override
        fixed_data = fix_target_override_in_dict(data)

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
    print("修复卡牌JSON target_override...")
    print("=" * 60)

    if cards_dir.exists():
        fixed_count = 0
        for json_file in cards_dir.glob("*.json"):
            print(f"\n处理: {json_file.name}")
            if fix_json_file(json_file):
                fixed_count += 1

        print(f"\n完成! 修复了 {fixed_count} 个卡牌JSON文件")


if __name__ == "__main__":
    main()
