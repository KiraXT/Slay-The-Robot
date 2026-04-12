#!/usr/bin/env python3
"""
修复JSON文件中的错误action路径
将 res://scripts/actions/ActionXXX.gd 更新为正确的子目录路径
"""

import json
import re
from pathlib import Path

# Action路径映射
ACTION_PATHS = {
    # meta_actions
    'ActionAttackGenerator': 'meta_actions',
    'ActionCardPlay': 'meta_actions',
    'ActionCardPlayEnd': 'meta_actions',
    'ActionDrawGenerator': 'meta_actions',
    'ActionEmitCustomSignal': 'meta_actions',
    'ActionValidator': 'meta_actions',
    'ActionVariableCardsetModifier': 'meta_actions',
    'ActionVariableCombatStatsModifier': 'meta_actions',
    'ActionVariableCostModifier': 'meta_actions',
    # artifact_actions
    'ActionIncreaseArtifactCharge': 'artifact_actions',
    # cardset_actions
    'ActionAddCardsToDeck': 'cardset_actions',
    'ActionAddCardsToDraw': 'cardset_actions',
    'ActionAddCardsToHand': 'cardset_actions',
    'ActionAttachCardsOntoEnemy': 'cardset_actions',
    'ActionBanishCards': 'cardset_actions',
    'ActionAttachCardToSlot': 'cardset_actions',
    'ActionChangeCardEnergies': 'cardset_actions',
    'ActionChangeCardProperties': 'cardset_actions',
    'ActionDiscardCards': 'cardset_actions',
    'ActionExhaustCards': 'cardset_actions',
    'ActionImproveCardValues': 'cardset_actions',
    'ActionMoveCardsToLimbo': 'cardset_actions',
    'ActionPlayCards': 'cardset_actions',
    'ActionRandomizeCardEnergies': 'cardset_actions',
    'ActionRemoveCardsFromDeck': 'cardset_actions',
    'ActionRetainCards': 'cardset_actions',
    'ActionTransformCards': 'cardset_actions',
    'ActionUpgradeCards': 'cardset_actions',
    # custom_ui_actions
    'ActionCustomUI': 'custom_ui_actions',
    # debug_actions
    'ActionDebugLog': 'debug_actions',
    # enemy_actions
    'ActionCycleEnemyIntent': 'enemy_actions',
    # pick_card_actions
    'ActionBasePickCards': 'pick_card_actions',
    'ActionCreateCards': 'pick_card_actions',
    'ActionPickCards': 'pick_card_actions',
    'ActionPickDuplicateCards': 'pick_card_actions',
    'ActionPickUpgradeCards': 'pick_card_actions',
    # player_actions
    'ActionAddArtifact': 'player_actions',
    'ActionAddConsumable': 'player_actions',
    'ActionAddMoney': 'player_actions',
    'ActionSwapBossArtifact': 'player_actions',
    'ActionUpdateCardDrafts': 'player_actions',
    'ActionUpdateRestActions': 'player_actions',
    'ActionUseConsumable': 'player_actions',
    # status_actions
    'ActionApplyStatus': 'status_actions',
    'ActionCorrosion': 'status_actions',
    'ActionDecayStatus': 'status_actions',
    # world_interaction_actions
    'ActionOpenChest': 'world_interaction_actions',
    'ActionStartCombat': 'world_interaction_actions',
    'ActionVisitLocation': 'world_interaction_actions',
    # generated_actions
    'ActionAttack': 'generated_actions',
    'ActionDraw': 'generated_actions',
    # rewards
    'ActionClearRewards': 'rewards',
    'ActionGrantRewards': 'rewards',
    # shop_actions
    'ActionShopPopulateItems': 'shop_actions',
    'ActionShopPurchaseItems': 'shop_actions',
    # world_generation_actions
    'ActionGenerateAct': 'world_generation_actions',
}


def get_correct_path(action_type: str) -> str:
    """获取正确的action路径"""
    if not action_type.startswith("Action"):
        return f"res://scripts/actions/{action_type}.gd"

    subdir = ACTION_PATHS.get(action_type, '')
    if subdir:
        return f"res://scripts/actions/{subdir}/{action_type}.gd"
    else:
        return f"res://scripts/actions/{action_type}.gd"


def fix_paths_in_dict(obj):
    """递归修复字典中的路径"""
    if isinstance(obj, dict):
        new_dict = {}
        for key, value in obj.items():
            # 检查key是否是action路径
            if isinstance(key, str) and key.startswith("res://scripts/actions/"):
                # 提取action名称
                match = re.search(r'Action\w+\.gd', key)
                if match:
                    action_name = match.group(0).replace('.gd', '')
                    correct_path = get_correct_path(action_name)
                    if key != correct_path:
                        print(f"  修复路径: {key} -> {correct_path}")
                        key = correct_path

            # 递归处理value
            new_dict[key] = fix_paths_in_dict(value)
        return new_dict
    elif isinstance(obj, list):
        return [fix_paths_in_dict(item) for item in obj]
    else:
        return obj


def fix_json_file(filepath: Path) -> bool:
    """修复单个JSON文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 修复路径
        fixed_data = fix_paths_in_dict(data)

        # 写回文件
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(fixed_data, f, indent=4, ensure_ascii=False)

        return True
    except Exception as e:
        print(f"  错误: {e}")
        return False


def main():
    """主函数"""
    # 配置目录
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent

    # 修复卡牌
    cards_dir = project_root / "external/data/cards"
    print("=" * 60)
    print("修复卡牌JSON路径...")
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
    print("修复遗物JSON路径...")
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
