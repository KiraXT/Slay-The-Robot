#!/usr/bin/env python3
"""Create a properly formatted cards.csv file"""

import csv

# Define all fields
FIELDS = [
    'object_id', 'card_name', 'card_description', 'card_type', 'card_rarity',
    'card_color_id', 'card_energy_cost', 'card_energy_cost_is_variable',
    'card_energy_cost_variable_upper_bound', 'card_requires_target',
    'card_exhausts', 'card_is_ethereal', 'card_is_retained',
    'card_appears_in_card_packs', 'card_texture_path', 'card_keyword_object_ids',
    'damage', 'number_of_attacks', 'block', 'draw_count',
    'status_charge_amount', 'status_secondary_charge_amount',
    'money_amount', 'heal_amount', 'damage_random',
    'status_effect_object_id', 'status_force_apply_new_effect',
    'random_consumable', 'fill_all_slots', 'ignored_interceptor_ids',
    'action_multiplier_offset', 'action_type', 'action_time_delay',
    'action_target_override', 'action_on_lethal', 'validator_type',
    'card_upgrade_amount_max', 'first_upgrade_energy_cost',
    'upgrade_damage', 'upgrade_block', 'upgrade_number_of_attacks',
    'upgrade_draw_count', 'upgrade_status_charge_amount',
    'upgrade_status_secondary_charge_amount', 'upgrade_damage_random',
    'upgrade_action_multiplier_offset', 'card_first_shuffle_priority'
]

# Sample cards data
SAMPLE_CARDS = [
    {
        'object_id': 'card_attack_basic',
        'card_name': 'Basic Attack',
        'card_description': 'Attack for [damage] damage [number_of_attacks] times',
        'card_type': 0,
        'card_rarity': 0,
        'card_color_id': 'color_white',
        'card_energy_cost': 1,
        'card_requires_target': 'TRUE',
        'damage': 25,
        'number_of_attacks': 1,
        'action_type': 'ActionAttackGenerator',
        'action_time_delay': 0,
        'upgrade_damage': 1,
        'upgrade_number_of_attacks': 1,
        'card_upgrade_amount_max': 1,
    },
    {
        'object_id': 'card_block_basic',
        'card_name': 'Basic Block',
        'card_description': 'Add [block] block',
        'card_type': 1,
        'card_rarity': 0,
        'card_color_id': 'color_white',
        'card_energy_cost': 1,
        'card_requires_target': 'FALSE',
        'card_keyword_object_ids': 'keyword_block',
        'block': 5,
        'action_type': 'ActionBlock',
        'action_time_delay': 0.5,
        'action_target_override': 'BaseAction.TARGET_OVERRIDES.PARENT',
        'upgrade_block': 3,
        'card_upgrade_amount_max': 1,
    },
    {
        'object_id': 'card_draw',
        'card_name': 'Draw',
        'card_description': 'Draw [draw_count] cards',
        'card_type': 1,
        'card_rarity': 1,
        'card_color_id': 'color_blue',
        'card_texture_path': 'external/sprites/cards/blue/card_blue.png',
        'card_energy_cost': 1,
        'card_requires_target': 'FALSE',
        'draw_count': 3,
        'action_type': 'ActionDrawGenerator',
        'upgrade_draw_count': 1,
        'card_upgrade_amount_max': 1,
    },
    {
        'object_id': 'card_attack_rng',
        'card_name': 'RNG Attack',
        'card_description': 'Attack for [damage] + [damage_random] damage',
        'card_type': 0,
        'card_rarity': 1,
        'card_color_id': 'color_blue',
        'card_texture_path': 'external/sprites/cards/blue/card_blue.png',
        'card_energy_cost': 1,
        'damage': 10,
        'number_of_attacks': 1,
        'damage_random': 5,
        'action_type': 'ActionAttackGenerator',
        'action_time_delay': 0,
        'upgrade_damage_random': 5,
        'card_upgrade_amount_max': 1,
    },
    {
        'object_id': 'card_attack_corrosion',
        'card_name': 'Corrosion',
        'card_description': 'Do [damage] damage and apply [status_charge_amount] corrosion',
        'card_type': 0,
        'card_rarity': 1,
        'card_color_id': 'color_green',
        'card_texture_path': 'external/sprites/cards/green/card_green.png',
        'card_keyword_object_ids': 'keyword_corrosion',
        'card_energy_cost': 1,
        'damage': 5,
        'number_of_attacks': 1,
        'status_charge_amount': 5,
        'status_effect_object_id': 'status_effect_corrosion',
        'action_type': 'ActionApplyStatus',
        'action_time_delay': 0.5,
        'upgrade_status_charge_amount': 3,
        'card_upgrade_amount_max': 1,
    },
    {
        'object_id': 'card_bomb',
        'card_name': 'Bomb',
        'card_description': 'In [status_charge_amount] turns do [status_secondary_charge_amount] damage to all enemies',
        'card_type': 1,
        'card_rarity': 1,
        'card_color_id': 'color_green',
        'card_texture_path': 'external/sprites/cards/green/card_green.png',
        'card_keyword_object_ids': 'keyword_bomb',
        'card_requires_target': 'FALSE',
        'card_energy_cost': 1,
        'status_charge_amount': 3,
        'status_secondary_charge_amount': 30,
        'status_effect_object_id': 'status_effect_bomb',
        'status_force_apply_new_effect': 'TRUE',
        'action_type': 'ActionApplyStatus',
        'action_time_delay': 0.5,
        'action_target_override': 'BaseAction.TARGET_OVERRIDES.PARENT',
        'upgrade_status_secondary_charge_amount': 20,
        'card_upgrade_amount_max': 1,
    },
]

def create_csv():
    output_path = 'external/config/cards.csv'

    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()

        for card in SAMPLE_CARDS:
            # Fill in missing fields with empty string
            row = {field: card.get(field, '') for field in FIELDS}
            writer.writerow(row)

    print(f'Created: {output_path}')
    print(f'Total cards: {len(SAMPLE_CARDS)}')

if __name__ == '__main__':
    create_csv()
