#!/usr/bin/env python3
"""
CSV to JSON Card Converter for Slay the Robot
Converts card configurations from CSV to JSON format
Requires only Python standard library (no external dependencies)
"""

import csv
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Tuple

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
CSV_FILE = PROJECT_ROOT / "external/config/cards.csv"
OUTPUT_DIR = PROJECT_ROOT / "external/data/cards"

# Valid enums for validation
VALID_CARD_TYPES = {0: "ATTACK", 1: "SKILL", 2: "POWER", 3: "STATUS", 4: "CURSE"}
VALID_RARITIES = {0: "BASIC", 1: "COMMON", 2: "UNCOMMON", 3: "RARE", 4: "GENERATED"}
VALID_COLORS = ["color_white", "color_red", "color_green", "color_blue",
                "color_purple", "color_orange", "color_yellow"]


class CardValidator:
    """Validates card configuration data"""

    def __init__(self):
        self.errors: List[Dict] = []

    def validate_card(self, card: Dict, row_num: int) -> List[Dict]:
        """Validate a single card"""
        self.errors = []
        card_id = card.get('object_id', f'ROW_{row_num}')

        # Check required fields
        required = ['object_id', 'card_name', 'card_type', 'card_description']
        for field in required:
            if not card.get(field) or str(card[field]).strip() == '':
                self.errors.append({
                    'card_id': card_id,
                    'field': field,
                    'message': f"Required field '{field}' is empty",
                    'severity': 'ERROR'
                })

        # Validate card_type
        try:
            card_type = int(card.get('card_type', -1))
            if card_type not in VALID_CARD_TYPES:
                self.errors.append({
                    'card_id': card_id,
                    'field': 'card_type',
                    'message': f"Invalid card_type '{card_type}'. Must be 0-4",
                    'severity': 'ERROR'
                })
        except (ValueError, TypeError):
            self.errors.append({
                'card_id': card_id,
                'field': 'card_type',
                'message': f"card_type must be a number",
                'severity': 'ERROR'
            })

        # Validate rarity
        try:
            rarity = int(card.get('card_rarity', 1))
            if rarity not in VALID_RARITIES:
                self.errors.append({
                    'card_id': card_id,
                    'field': 'card_rarity',
                    'message': f"Invalid rarity '{rarity}'. Must be 0-4",
                    'severity': 'WARNING'
                })
        except (ValueError, TypeError):
            pass

        # Validate color
        color = card.get('card_color_id', '')
        if color and color not in VALID_COLORS:
            self.errors.append({
                'card_id': card_id,
                'field': 'card_color_id',
                'message': f"Unknown color '{color}'",
                'severity': 'WARNING'
            })

        # Validate damage values
        damage = card.get('damage', '')
        card_type = int(card.get('card_type', 0)) if str(card.get('card_type', '')).isdigit() else 0
        if damage and str(damage).isdigit():
            damage_val = int(damage)
            if card_type == 0 and damage_val == 0:  # ATTACK with 0 damage
                self.errors.append({
                    'card_id': card_id,
                    'field': 'damage',
                    'message': "Attack card has 0 damage",
                    'severity': 'WARNING'
                })

        # Check description placeholders
        desc = card.get('card_description', '')
        import re
        placeholders = re.findall(r'\[([a-zA-Z_]+)\]', desc)
        for ph in placeholders:
            if ph in ['X', 'x']:
                continue
            if ph not in card or not card[ph] or str(card[ph]).strip() == '':
                self.errors.append({
                    'card_id': card_id,
                    'field': 'card_description',
                    'message': f"Placeholder '[{ph}]' has no value defined",
                    'severity': 'WARNING'
                })

        return self.errors


class CardConverter:
    """Converts CSV data to JSON format"""

    def __init__(self):
        self.validator = CardValidator()
        self.all_errors: List[Dict] = []

    def convert(self) -> Tuple[bool, List[Dict]]:
        """Main conversion function"""
        print("=" * 60)
        print("CSV to JSON Card Converter")
        print("=" * 60)

        # Check CSV file exists
        if not CSV_FILE.exists():
            print(f"\nERROR: CSV file not found: {CSV_FILE}")
            print("\nPlease either:")
            print(f"  1. Copy 'external/config/cards_template.csv' to 'external/config/cards.csv'")
            print(f"  2. Or create a new CSV file at that location")
            return False, []

        # Create output directory
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

        # Read CSV
        try:
            print(f"\nReading CSV: {CSV_FILE}")
            with open(CSV_FILE, 'r', encoding='gbk') as f:
                reader = csv.DictReader(f)
                cards = list(reader)
            print(f"Found {len(cards)} cards")
        except Exception as e:
            print(f"ERROR reading CSV: {e}")
            return False, []

        # Validate and convert each card
        success_count = 0
        self.all_errors = []

        for idx, card in enumerate(cards, 1):
            card_id = card.get('object_id', f'ROW_{idx}')

            # Skip empty rows or comment rows
            if not card_id or card_id.startswith('#') or card_id.strip() == '':
                continue

            print(f"\n[{idx}/{len(cards)}] Processing: {card_id}")

            # Validate
            errors = self.validator.validate_card(card, idx)
            self.all_errors.extend(errors)

            if errors:
                for err in errors:
                    prefix = "[WARN]  WARN" if err['severity'] == 'WARNING' else "[FAIL] ERROR"
                    print(f"  {prefix}: [{err['field']}] {err['message']}")

            # Skip cards with critical errors
            critical_errors = [e for e in errors if e['severity'] == 'ERROR']
            if critical_errors:
                print(f"  [SKIP]  Skipped due to {len(critical_errors)} error(s)")
                continue

            # Convert to JSON
            try:
                card_json = self._build_card_json(card)
                output_path = OUTPUT_DIR / f"{card_id}.json"

                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(card_json, f, indent=4, ensure_ascii=False)

                print(f"  [OK] Generated: {output_path}")
                success_count += 1

            except Exception as e:
                print(f"  [FAIL] Conversion failed: {e}")
                self.all_errors.append({
                    'card_id': card_id,
                    'field': 'CONVERSION',
                    'message': str(e),
                    'severity': 'ERROR'
                })

        # Summary
        print("\n" + "=" * 60)
        print(f"Conversion complete!")
        print(f"  Success: {success_count}/{len(cards)} cards")
        print(f"  Errors: {len([e for e in self.all_errors if e['severity'] == 'ERROR'])}")
        print(f"  Warnings: {len([e for e in self.all_errors if e['severity'] == 'WARNING'])}")
        print("=" * 60)

        return success_count > 0, self.all_errors

    def _build_card_json(self, card: Dict) -> Dict[str, Any]:
        """Build JSON structure from CSV row"""
        card_id = card['object_id']

        # Build card_values
        card_values = {}
        value_fields = [
            'damage', 'number_of_attacks', 'block', 'draw_count',
            'status_charge_amount', 'status_secondary_charge_amount',
            'money_amount', 'heal_amount', 'damage_random'
        ]
        for field in value_fields:
            val = card.get(field, '')
            if val and str(val).strip() != '':
                try:
                    card_values[field] = int(val)
                except ValueError:
                    if val.lower() == 'true':
                        card_values[field] = True
                    elif val.lower() == 'false':
                        card_values[field] = False
                    else:
                        card_values[field] = val

        # Special fields
        special_fields = ['status_effect_object_id', 'status_force_apply_new_effect',
                         'random_consumable', 'fill_all_slots', 'ignored_interceptor_ids']
        for field in special_fields:
            val = card.get(field, '')
            if val and str(val).strip() != '':
                if field == 'status_force_apply_new_effect' or field == 'random_consumable' or field == 'fill_all_slots':
                    card_values[field] = val.lower() == 'true'
                else:
                    card_values[field] = val

        # Build actions
        actions = self._parse_actions(card)

        # Build upgrade improvements
        upgrade_improvements = {}
        upgrade_map = {
            'upgrade_damage': 'damage',
            'upgrade_block': 'block',
            'upgrade_number_of_attacks': 'number_of_attacks',
            'upgrade_draw_count': 'draw_count',
            'upgrade_status_charge_amount': 'status_charge_amount',
            'upgrade_status_secondary_charge_amount': 'status_secondary_charge_amount',
            'upgrade_damage_random': 'damage_random',
            'upgrade_action_multiplier_offset': 'multiplier_offset'
        }
        for csv_field, json_field in upgrade_map.items():
            val = card.get(csv_field, '')
            if val and str(val).strip() != '':
                try:
                    upgrade_improvements[json_field] = int(val)
                except ValueError:
                    pass

        # Build first upgrade property changes
        first_upgrade_changes = {}
        first_upg = card.get('first_upgrade_energy_cost', '')
        if first_upg and str(first_upg).strip() != '':
            try:
                first_upgrade_changes['card_energy_cost'] = int(first_upg)
            except ValueError:
                pass

        # Parse keywords
        keywords = []
        kw_str = card.get('card_keyword_object_ids', '')
        if kw_str:
            keywords = [k.strip() for k in kw_str.split(',') if k.strip()]

        # Parse booleans
        def parse_bool(val, default=False):
            if not val or str(val).strip() == '':
                return default
            return str(val).lower() in ('true', 'yes', '1', 'TRUE')

        # Build JSON
        json_data = {
            "patch_data": {},
            "properties": {
                "object_id": card_id,
                "object_uid": "",
                "card_name": card.get('card_name', ''),
                "card_description": card.get('card_description', ''),
                "card_type": int(card.get('card_type', 0)) if str(card.get('card_type', '')).isdigit() else 0,
                "card_rarity": int(card.get('card_rarity', 1)) if str(card.get('card_rarity', '')).isdigit() else 1,
                "card_color_id": card.get('card_color_id', 'color_white'),
                "card_energy_cost": int(card.get('card_energy_cost', 1)) if str(card.get('card_energy_cost', '')).isdigit() else 1,
                "card_energy_cost_is_variable": parse_bool(card.get('card_energy_cost_is_variable')),
                "card_energy_cost_variable_upper_bound": int(card.get('card_energy_cost_variable_upper_bound', -1)) if str(card.get('card_energy_cost_variable_upper_bound', '')).lstrip('-').isdigit() else -1,
                "card_requires_target": parse_bool(card.get('card_requires_target'), True),
                "card_exhausts": parse_bool(card.get('card_exhausts')),
                "card_is_ethereal": parse_bool(card.get('card_is_ethereal')),
                "card_is_retained": parse_bool(card.get('card_is_retained')),
                "card_appears_in_card_packs": parse_bool(card.get('card_appears_in_card_packs'), True),
                "card_texture_path": card.get('card_texture_path', ''),
                "card_keyword_object_ids": keywords,
                "card_values": card_values,
                "card_play_actions": actions,
                "card_upgrade_value_improvements": upgrade_improvements,
                "card_first_upgrade_property_changes": first_upgrade_changes,
                "card_upgrade_amount": 0,
                "card_upgrade_amount_max": int(card.get('card_upgrade_amount_max', 1)) if str(card.get('card_upgrade_amount_max', '')).isdigit() else 1,
                "card_first_shuffle_priority": int(card.get('card_first_shuffle_priority', 0)) if str(card.get('card_first_shuffle_priority', '')).isdigit() else 0,
            }
        }

        return json_data

    # Action path mappings - same as excel_to_json.py
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

    def _get_action_path(self, action_type: str) -> str:
        """Get the correct path for an action type"""
        if not action_type.startswith("Action"):
            return f"res://scripts/actions/{action_type}.gd"

        subdir = self.ACTION_PATHS.get(action_type, '')
        if subdir:
            return f"res://scripts/actions/{subdir}/{action_type}.gd"
        else:
            return f"res://scripts/actions/{action_type}.gd"

    def _parse_actions(self, card: Dict) -> List[Dict]:
        """Parse action configuration"""
        actions = []

        action_type = card.get('action_type', '')
        if not action_type or action_type.strip() == '':
            return actions

        # Build action path with correct subdirectory
        action_path = self._get_action_path(action_type)
        params = {}

        # Add parameters
        time_delay = card.get('action_time_delay', '')
        if time_delay and str(time_delay).strip() != '':
            try:
                params['time_delay'] = float(time_delay)
            except ValueError:
                pass

        target_override = card.get('action_target_override', '')
        if target_override and target_override.strip() != '':
            # Handle enum string values
            if target_override.startswith('BaseAction.TARGET_OVERRIDES.'):
                # Map enum names to integer values
                target_overrides_map = {
                    'SELECTED_TARGETS': 0,
                    'PARENT': 1,
                    'PLAYER': 2,
                    'ALL_COMBATANTS': 3,
                    'ALL_ENEMIES': 4,
                    'LEFTMOST_ENEMY': 5,
                    'ENEMY_ID': 6,
                    'RANDOM_ENEMY': 7,
                }
                enum_name = target_override.replace('BaseAction.TARGET_OVERRIDES.', '')
                if enum_name in target_overrides_map:
                    params['target_override'] = target_overrides_map[enum_name]
                else:
                    params['target_override'] = target_override
            else:
                # Try to convert to int if it's a number string
                try:
                    params['target_override'] = int(target_override)
                except ValueError:
                    params['target_override'] = target_override

        # On lethal actions
        on_lethal = card.get('action_on_lethal', '')
        if on_lethal and on_lethal.strip() != '':
            lethal_action_path = self._get_action_path(on_lethal)
            params['actions_on_lethal'] = [{lethal_action_path: {}}]
        else:
            params['actions_on_lethal'] = []

        actions.append({action_path: params})

        return actions


def create_sample_csv():
    """Create a sample CSV file from template"""
    template_path = Path("external/config/cards_template.csv")
    output_path = Path("external/config/cards.csv")

    if not template_path.exists():
        print(f"ERROR: Template not found: {template_path}")
        return False

    if output_path.exists():
        print(f"WARNING: {output_path} already exists")
        response = input("Overwrite? (y/n): ")
        if response.lower() != 'y':
            return False

    import shutil
    shutil.copy(template_path, output_path)
    print(f"[OK] Created: {output_path}")
    print("\nNext steps:")
    print("  1. Open external/config/cards.csv in Excel or Google Sheets")
    print("  2. Edit/add your cards")
    print("  3. Run: python external/tools/csv_to_json.py")
    return True


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='CSV to JSON Card Converter')
    parser.add_argument('--create-sample', action='store_true',
                       help='Create cards.csv from template')

    args = parser.parse_args()

    if args.create_sample:
        create_sample_csv()
        return

    # Run conversion
    converter = CardConverter()
    success, errors = converter.convert()

    if not success and not errors:
        print("\nTo create a sample CSV file:")
        print(f"  python {sys.argv[0]} --create-sample")
        sys.exit(1)

    critical_errors = [e for e in errors if e['severity'] == 'ERROR']
    sys.exit(0 if len(critical_errors) == 0 else 1)


if __name__ == "__main__":
    main()
