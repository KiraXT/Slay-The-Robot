# Event Text Maintenance Guide

## Source Of Truth

- Cards: edit `external/config/cards.xlsx`
- Artifacts: edit `external/config/artifacts.xlsx`
- Events: edit `external/config/events.xlsx`
- Event dialogue text now lives inside the Events sheet, not in a separate base-game dialogue file

## Event Fields

Use these columns when editing event text:

- `event_dialogue_object_id`
- `event_dialogue_initial_dialogue_state_object_id`
- `event_dialogue_state_dialogue_texture_path`
- `event_dialogue_state_prompt_bbcode`
- `event_dialogue_option_1_bbcode`
- `event_dialogue_option_1_failed_validator_bbcode`
- `event_dialogue_option_2_bbcode`
- `event_dialogue_option_2_failed_validator_bbcode`

Use these columns when editing embedded event dialogue behavior:

- `event_dialogue_option_1_actions_json`
- `event_dialogue_option_1_validators_json`
- `event_dialogue_option_2_actions_json`
- `event_dialogue_option_2_validators_json`

## Rules

- If `event_dialogue_data` exists in the generated event JSON, runtime uses it first.
- If `event_dialogue_data` is missing, runtime falls back to `event_dialogue_object_id`.
- The legacy `external/data/dialogue/` folder is compatibility-only for the current base-game event and should not be treated as the primary editing location.
- Use the event converter to rebuild JSON after spreadsheet edits.

## Conversion Notes

- `external/tools/excel_to_json_events.py` reads `external/config/events.xlsx`
- The same converter accepts `external/config/events.csv` as a fallback source
- `external/tools/json_to_excel.py` can regenerate the spreadsheet from the JSON output

## Practical Editing Rule

- If you are changing the text a player sees during an event, edit `external/config/events.xlsx`
- If you are changing a card tooltip, use `external/config/cards.xlsx`
- If you are changing an artifact description, use `external/config/artifacts.xlsx`
