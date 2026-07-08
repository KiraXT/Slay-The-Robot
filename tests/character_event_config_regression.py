#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENTS = ROOT / "external" / "data" / "events"
EVENT_POOLS = ROOT / "external" / "data" / "event_pools"

ACTION_ADD_HEALTH = "res://scripts/actions/ActionAddHealth.gd"
ACTION_ADD_MONEY = "res://scripts/actions/player_actions/ActionAddMoney.gd"
ACTION_ADD_CONSUMABLE = "res://scripts/actions/player_actions/ActionAddConsumable.gd"
ACTION_PICK_CARDS = "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
ACTION_PICK_UPGRADE_CARDS = "res://scripts/actions/pick_card_actions/ActionPickUpgradeCards.gd"
ACTION_ADD_CARDS_TO_DECK = "res://scripts/actions/cardset_actions/ActionAddCardsToDeck.gd"
ACTION_REMOVE_CARDS_FROM_DECK = "res://scripts/actions/cardset_actions/ActionRemoveCardsFromDeck.gd"
ACTION_TRANSFORM_CARDS = "res://scripts/actions/cardset_actions/ActionTransformCards.gd"

VALIDATOR_CHARACTER = "res://scripts/validators/ValidatorCharacter.gd"
VALIDATOR_PLAYER_HEALTH = "res://scripts/validators/ValidatorPlayerHealth.gd"
VALIDATOR_MONEY = "res://scripts/validators/ValidatorMoney.gd"
VALIDATOR_DECK_HAS_UPGRADEABLE = "res://scripts/validators/deck/ValidatorDeckHasUpgradeableCard.gd"
VALIDATOR_DECK_HAS_REMOVABLE = "res://scripts/validators/deck/ValidatorDeckHasRemovableCard.gd"
VALIDATOR_CARD_COLOR = "res://scripts/validators/card/ValidatorCardColor.gd"
VALIDATOR_CARD_DRAFTABLE = "res://scripts/validators/card/ValidatorCardDraftable.gd"
VALIDATOR_CARD_RARITY = "res://scripts/validators/card/ValidatorCardRarity.gd"
VALIDATOR_CARD_REMOVABLE = "res://scripts/validators/card/ValidatorCardRemovableFromDeck.gd"
VALIDATOR_CARD_TRANSFORMABLE = "res://scripts/validators/card/ValidatorCardTransformableFromDeck.gd"
VALIDATOR_CARD_TYPE = "res://scripts/validators/card/ValidatorCardType.gd"
VALIDATOR_CARD_UPGRADEABLE = "res://scripts/validators/card/ValidatorCardUpgradeable.gd"

FAILED_VALIDATOR_BBCODE = "[color=grey][锁定]：条件不足[/color]"
POOL_EVENTS = [
    "event_pick_something",
    "event_red_broken_boxing_ring",
    "event_red_warning_line_gate",
    "event_blue_scattered_toolbox",
    "event_blue_runaway_shuffler",
    "event_green_echo_tuning_room",
    "event_green_corrosion_tank",
    "event_orange_prep_supply_stop",
    "event_orange_hidden_backpack_pocket",
]


def health_validator(amount):
    return {VALIDATOR_PLAYER_HEALTH: {"health_amount": amount}}


def money_validator(amount):
    return {VALIDATOR_MONEY: {"money_amount": amount}}


def deck_upgradeable_validator():
    return {VALIDATOR_DECK_HAS_UPGRADEABLE: {}}


def deck_removable_validator():
    return {VALIDATOR_DECK_HAS_REMOVABLE: {}}


def add_health(amount):
    return {ACTION_ADD_HEALTH: {"health_amount": amount}}


def add_money(amount):
    return {ACTION_ADD_MONEY: {"money_amount": amount}}


def add_specific_consumable(consumable_id):
    return {ACTION_ADD_CONSUMABLE: {"consumable_object_id": consumable_id}}


def add_random_consumable():
    return {ACTION_ADD_CONSUMABLE: {"random_consumable": True, "rng_name": "rng_events"}}


def card_color_validator(color_id):
    return {VALIDATOR_CARD_COLOR: {"card_color_ids": [color_id]}}


def card_type_validator(card_type):
    return {VALIDATOR_CARD_TYPE: {"card_types": [card_type]}}


def draft_card(color_id, extra_validators=None):
    validator_data = [
        card_color_validator(color_id),
        {VALIDATOR_CARD_DRAFTABLE: {}},
    ]
    if extra_validators is None:
        validator_data.append({VALIDATOR_CARD_RARITY: {"card_rarities_exclude": [4]}})
    else:
        validator_data.extend(extra_validators)
    return {
        ACTION_PICK_CARDS: {
            "action_data": [{ACTION_ADD_CARDS_TO_DECK: {}}],
            "card_pick_text": "选择 1 张牌加入牌组",
            "card_pick_type": 8,
            "draft_from_card_pool": True,
            "draft_is_weighted": False,
            "draft_max_card_amount": 3,
            "draft_use_pity_system": False,
            "draft_use_player_draft": False,
            "force_manual_selection": True,
            "max_card_amount": 1,
            "min_card_amount": 1,
            "min_cards_are_required_for_action": True,
            "pick_draft_cards": False,
            "random_selection": False,
            "rng_name": "rng_events",
            "validator_data": validator_data,
        }
    }


def draft_attack_card(color_id):
    return draft_card(
        color_id,
        [
            {VALIDATOR_CARD_RARITY: {"card_rarities_exclude": [4]}},
            card_type_validator(0),
        ],
    )


def draft_rare_card(color_id):
    return draft_card(color_id, [{VALIDATOR_CARD_RARITY: {"card_rarities": [3]}}])


def draft_common_card(color_id):
    return draft_card(color_id, [{VALIDATOR_CARD_RARITY: {"card_rarities": [1]}}])


def upgrade_card(extra_validator):
    return {
        ACTION_PICK_UPGRADE_CARDS: {
            "card_pick_text": "选择 1 张牌升级",
            "card_pick_type": 1,
            "force_manual_selection": True,
            "max_card_amount": 1,
            "min_card_amount": 1,
            "min_cards_are_required_for_action": False,
            "validator_data": [
                {VALIDATOR_CARD_UPGRADEABLE: {}},
                extra_validator,
            ],
        }
    }


def remove_card():
    return {
        ACTION_PICK_CARDS: {
            "action_data": [{ACTION_REMOVE_CARDS_FROM_DECK: {}}],
            "card_pick_text": "选择 1 张牌移除",
            "card_pick_type": 1,
            "force_manual_selection": True,
            "max_card_amount": 1,
            "min_card_amount": 1,
            "min_cards_are_required_for_action": False,
            "validator_data": [{VALIDATOR_CARD_REMOVABLE: {}}],
        }
    }


def random_remove_card():
    return {
        ACTION_PICK_CARDS: {
            "action_data": [{ACTION_REMOVE_CARDS_FROM_DECK: {}}],
            "card_pick_type": 1,
            "max_card_amount": 1,
            "min_card_amount": 1,
            "min_cards_are_required_for_action": False,
            "random_selection": True,
            "rng_name": "rng_events",
            "validator_data": [{VALIDATOR_CARD_REMOVABLE: {}}],
        }
    }


def transform_card():
    return {
        ACTION_PICK_CARDS: {
            "action_data": [
                {
                    ACTION_TRANSFORM_CARDS: {
                        "keep_color": True,
                        "keep_rarity": False,
                        "keep_type": False,
                        "transform_parent_card": False,
                    }
                }
            ],
            "card_pick_text": "选择 1 张牌转换",
            "card_pick_type": 1,
            "force_manual_selection": True,
            "max_card_amount": 1,
            "min_card_amount": 1,
            "min_cards_are_required_for_action": False,
            "validator_data": [{VALIDATOR_CARD_TRANSFORMABLE: {}}],
        }
    }


EXPECTED_EVENTS = {
    "event_red_broken_boxing_ring": {
        "character": "character_red",
        "suffix": "red_broken_boxing_ring",
        "prompt": "废弃训练场里还有一台会反击的拳击测试机器人。它的记分屏闪烁着红色警告，只要出拳，它就会回击。",
        "options": [
            {
                "text": "重打基础: [color=red]失去6点生命[/color]，升级1张攻击牌",
                "validators": [health_validator(7), deck_upgradeable_validator()],
                "actions": [add_health(-6), upgrade_card(card_type_validator(0))],
            },
            {
                "text": "压上步伐: [color=red]失去30金币[/color]，从3张红色攻击牌中选择1张加入牌组",
                "validators": [money_validator(30)],
                "actions": [add_money(-30), draft_attack_card("color_red")],
            },
            {
                "text": "拆下护板: [color=green]获得50金币[/color]",
                "validators": [],
                "actions": [add_money(50)],
            },
        ],
    },
    "event_red_warning_line_gate": {
        "character": "character_red",
        "suffix": "red_warning_line_gate",
        "prompt": "一扇门前投射着红色警戒线。系统不断播报“只允许攻击姿态通过”，门后的奖励箱已经半开。",
        "options": [
            {
                "text": "正面突破: [color=red]失去10点生命[/color]，获得1张红色稀有牌",
                "validators": [health_validator(11)],
                "actions": [add_health(-10), draft_rare_card("color_red")],
            },
            {
                "text": "找准破绽: 从3张红色牌中选择1张加入牌组",
                "validators": [],
                "actions": [draft_card("color_red")],
            },
            {
                "text": "暂时撤退: [color=green]获得1个格挡药剂[/color]",
                "validators": [],
                "actions": [add_specific_consumable("consumable_block")],
            },
        ],
    },
    "event_blue_scattered_toolbox": {
        "character": "character_blue",
        "suffix": "blue_scattered_toolbox",
        "prompt": "一个工具箱翻倒在走廊中央，螺丝、线缆、备用电池和不明零件滚得到处都是。",
        "options": [
            {
                "text": "慌忙翻找: 从3张蓝色牌中选择1张加入牌组，并随机移除1张可移除牌",
                "validators": [deck_removable_validator()],
                "actions": [draft_card("color_blue"), random_remove_card()],
            },
            {
                "text": "留下备用品: [color=green]获得1个随机消耗品[/color]",
                "validators": [],
                "actions": [add_random_consumable()],
            },
            {
                "text": "卖掉零件: [color=green]获得60金币[/color]",
                "validators": [],
                "actions": [add_money(60)],
            },
        ],
    },
    "event_blue_runaway_shuffler": {
        "character": "character_blue",
        "suffix": "blue_runaway_shuffler",
        "prompt": "一台旧洗牌机还在工作。它吸入卡牌、吐出卡牌，偶尔还会把标签贴错。",
        "options": [
            {
                "text": "接受重排: 转换1张牌",
                "validators": [],
                "actions": [transform_card()],
            },
            {
                "text": "抓住弹出的牌: 从3张蓝色牌中选择1张加入牌组",
                "validators": [],
                "actions": [draft_card("color_blue")],
            },
            {
                "text": "关掉机器: [color=red]失去40金币[/color]，移除1张牌",
                "validators": [money_validator(40), deck_removable_validator()],
                "actions": [add_money(-40), remove_card()],
            },
        ],
    },
    "event_green_echo_tuning_room": {
        "character": "character_green",
        "suffix": "green_echo_tuning_room",
        "prompt": "破旧音响在小房间里循环播放一段节拍。每次节拍落下，墙上的仪表都会同步闪一下。",
        "options": [
            {
                "text": "跟上第一拍: 升级1张技能牌",
                "validators": [deck_upgradeable_validator()],
                "actions": [upgrade_card(card_type_validator(1))],
            },
            {
                "text": "调整频率: 从3张绿色牌中选择1张加入牌组",
                "validators": [],
                "actions": [draft_card("color_green")],
            },
            {
                "text": "过载共鸣: [color=red]失去8点生命[/color]，获得1张绿色稀有牌",
                "validators": [health_validator(9)],
                "actions": [add_health(-8), draft_rare_card("color_green")],
            },
        ],
    },
    "event_green_corrosion_tank": {
        "character": "character_green",
        "suffix": "green_corrosion_tank",
        "prompt": "玻璃槽里残留着会慢慢侵蚀金属的试剂。槽壁上写着“低剂量稳定，高剂量危险”。",
        "options": [
            {
                "text": "提取试剂: [color=green]获得1个伤害药剂和30金币[/color]",
                "validators": [],
                "actions": [add_specific_consumable("consumable_damaging"), add_money(30)],
            },
            {
                "text": "强化样本: [color=red]失去5点生命[/color]，升级1张绿色牌",
                "validators": [health_validator(6), deck_upgradeable_validator()],
                "actions": [add_health(-5), upgrade_card(card_color_validator("color_green"))],
            },
            {
                "text": "封存危险品: [color=green]获得1个治疗药剂[/color]",
                "validators": [],
                "actions": [add_specific_consumable("consumable_heal")],
            },
        ],
    },
    "event_orange_prep_supply_stop": {
        "character": "character_orange",
        "suffix": "orange_prep_supply_stop",
        "prompt": "一处自动补给站还亮着灯。货架上有饮料、旧护具和临时路线图，但每个格子都快卡住了。",
        "options": [
            {
                "text": "打包饮料: [color=green]获得1个治疗药剂[/color]，并获得1张橙色普通牌",
                "validators": [],
                "actions": [add_specific_consumable("consumable_heal"), draft_common_card("color_orange")],
            },
            {
                "text": "轻装上阵: [color=red]失去50金币[/color]，移除1张牌",
                "validators": [money_validator(50), deck_removable_validator()],
                "actions": [add_money(-50), remove_card()],
            },
            {
                "text": "多拿一点: [color=red]失去6点生命[/color]，获得2个随机消耗品",
                "validators": [health_validator(7)],
                "actions": [add_health(-6), add_random_consumable(), add_random_consumable()],
            },
        ],
    },
    "event_orange_hidden_backpack_pocket": {
        "character": "character_orange",
        "suffix": "orange_hidden_backpack_pocket",
        "prompt": "旧背包夹层里藏着票据、备用卡和一枚小徽章。很多东西已经过期，但仍然有用。",
        "options": [
            {
                "text": "夹好书签: 升级1张橙色牌",
                "validators": [deck_upgradeable_validator()],
                "actions": [upgrade_card(card_color_validator("color_orange"))],
            },
            {
                "text": "翻出旧物: 从3张橙色牌中选择1张加入牌组",
                "validators": [],
                "actions": [draft_card("color_orange")],
            },
            {
                "text": "卖掉纪念品: [color=green]获得75金币[/color]，随机移除1张可移除牌",
                "validators": [deck_removable_validator()],
                "actions": [add_money(75), random_remove_card()],
            },
        ],
    },
}


def load_properties(directory: Path, object_id: str) -> dict:
    path = directory / f"{object_id}.json"
    assert path.exists(), f"missing JSON for {object_id}: {path}"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    properties = payload["properties"]
    assert properties["object_id"] == object_id
    return properties


def walk_script_paths(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key
            yield from walk_script_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_script_paths(child)


def assert_script_paths_exist(event_id: str, event: dict) -> None:
    for script_path in walk_script_paths(event):
        local_path = ROOT / script_path.replace("res://", "")
        assert local_path.exists(), f"{event_id} references missing script {script_path}"


def assert_character_validator(event_id: str, event: dict, character_id: str) -> None:
    validators = event["event_pool_validator_data"]
    assert validators == [
        {
            VALIDATOR_CHARACTER: {
                "character_object_ids": [character_id],
            }
        }
    ], f"{event_id} should be filtered to {character_id}"


def assert_shared_event_fields(event_id: str, event: dict) -> None:
    assert event["event_background_texture_path"] == ""
    assert event["event_dialogue_object_id"] == ""
    assert event["event_enemy_placement_is_automatic"] is True
    assert event["event_enemy_placement_positions"] == []
    assert event["event_initial_combat_actions"] == []
    assert event["event_weighted_enemy_object_ids"] == []
    assert event["location_event_pool_validator_failed_strategy"] == 1


def assert_dialogue(event_id: str, event: dict, expected: dict) -> None:
    suffix = expected["suffix"]
    dialogue = event["event_dialogue_data"]
    assert dialogue is not None, f"{event_id} should embed dialogue data"
    assert dialogue["object_id"] == f"dialogue_{suffix}"

    initial_state_id = f"dialogue_state_{suffix}_initial"
    assert dialogue["dialogue_initial_dialogue_state_object_id"] == initial_state_id
    states = dialogue["dialogue_state_id_to_dialogue_states"]
    options = dialogue["dialogue_option_id_to_dialogue_options"]
    assert set(states) == {initial_state_id}

    expected_option_ids = [
        f"dialogue_option_{suffix}_{index}"
        for index in range(1, len(expected["options"]) + 1)
    ]
    assert set(options) == set(expected_option_ids)

    state = states[initial_state_id]
    assert state["object_id"] == initial_state_id
    assert state["dialogue_state_dialogue_texture_path"] == ""
    assert state["dialogue_state_prompt_bbcode"] == expected["prompt"]
    assert state["dialogue_state_dialogue_option_object_ids"] == expected_option_ids

    for option_id, expected_option in zip(expected_option_ids, expected["options"]):
        option = options[option_id]
        assert option["object_id"] == option_id
        assert option["dialogue_option_bbcode"] == expected_option["text"]
        assert option["dialogue_option_failed_validator_bbcode"] == FAILED_VALIDATOR_BBCODE
        assert option["dialogue_option_next_dialogue_state_id"] == ""
        assert option["dialogue_option_validators"] == expected_option["validators"], event_id
        assert option["dialogue_option_actions"] == expected_option["actions"], event_id
        assert option["dialogue_option_visible_on_failed_validation"] is True


def main() -> None:
    for event_id, expected in EXPECTED_EVENTS.items():
        event = load_properties(EVENTS, event_id)
        assert_shared_event_fields(event_id, event)
        assert_character_validator(event_id, event, expected["character"])
        assert_dialogue(event_id, event, expected)
        assert_script_paths_exist(event_id, event)

    pool = load_properties(EVENT_POOLS, "event_pool_act_1_dialogue")
    assert pool["event_pool_fallback_event_object_id"] == "event_pick_something"
    assert pool["event_pool_event_object_ids"] == POOL_EVENTS

    print("validated character event configuration")


if __name__ == "__main__":
    main()
