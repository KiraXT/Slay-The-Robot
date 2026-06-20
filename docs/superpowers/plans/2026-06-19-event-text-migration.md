# Event Text Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the current event dialogue text into the event data source, keep the game reading it correctly, and update the designer-facing reference rules.

**Architecture:** EventData will gain an embedded DialogueData payload so event-specific dialogue can live inside `events` JSON instead of a separate dialogue file. The event Excel/CSV converters will build and read that embedded structure, while DialogueOverlay will prefer embedded dialogue and fall back to legacy dialogue IDs for compatibility.

**Tech Stack:** Godot 4 GDScript, pandas/openpyxl for spreadsheet conversion, existing JSON data pipeline, Markdown documentation.

---

### Task 1: Embed dialogue in EventData and use it at runtime

**Files:**
- Modify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/data/readonly/EventData.gd`
- Modify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/DialogueOverlay.gd`

- [ ] **Step 1: Add the embedded dialogue field and helper**

```gdscript
@export var event_dialogue_data: DialogueData = null

func get_dialogue_data() -> DialogueData:
	if event_dialogue_data != null:
		return event_dialogue_data
	if event_dialogue_object_id != "":
		return Global.get_dialogue_data(event_dialogue_object_id)
	return null
```

- [ ] **Step 2: Prefer embedded dialogue in the overlay**

```gdscript
var event_data: EventData = Global.get_player_event_data()
current_dialogue_data = event_data.get_dialogue_data()
if current_dialogue_data == null:
	DebugLogger.log_error("No DialogueData specified for " + str(event_data.object_id))
	end_dialogue()
	return
```

- [ ] **Step 3: Re-run the existing event/dialogue path mentally and ensure legacy `event_dialogue_object_id` still works**

### Task 2: Teach the event converters about embedded dialogue

**Files:**
- Modify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/external/tools/excel_to_json_events.py`
- Modify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/external/tools/json_to_excel.py`
- Modify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/external/tools/convert.py`

- [ ] **Step 1: Add event-dialogue columns to the event sheet schema**

```python
columns = [
    "object_id",
    "event_background_texture_path",
    "event_enemy_placement_is_automatic",
    "event_enemy_placement_positions",
    "event_weighted_enemy_object_ids",
    "location_event_pool_validator_failed_strategy",
    "event_dialogue_object_id",
    "event_dialogue_initial_dialogue_state_object_id",
    "event_dialogue_state_dialogue_texture_path",
    "event_dialogue_state_prompt_bbcode",
    "event_dialogue_option_1_object_id",
    "event_dialogue_option_1_bbcode",
    "event_dialogue_option_1_failed_validator_bbcode",
    "event_dialogue_option_1_next_dialogue_state_id",
    "event_dialogue_option_1_visible_on_failed_validation",
    "event_dialogue_option_1_actions_json",
    "event_dialogue_option_1_validators_json",
    "event_dialogue_option_2_object_id",
    "event_dialogue_option_2_bbcode",
    "event_dialogue_option_2_failed_validator_bbcode",
    "event_dialogue_option_2_next_dialogue_state_id",
    "event_dialogue_option_2_visible_on_failed_validation",
    "event_dialogue_option_2_actions_json",
    "event_dialogue_option_2_validators_json",
]
```

- [ ] **Step 2: Build `event_dialogue_data` inside the event JSON**

```python
event_dialogue_data = {
    "object_id": row.get("event_dialogue_object_id", ""),
    "dialogue_initial_dialogue_state_object_id": row.get("event_dialogue_initial_dialogue_state_object_id", ""),
    "dialogue_option_id_to_dialogue_options": {
        # option 1 and option 2 assembled from the row values
    },
    "dialogue_state_id_to_dialogue_states": {
        # initial state assembled from the row values
    },
}
```

- [ ] **Step 3: Keep reverse export working for embedded dialogue**

```python
event_dialogue = event.get("event_dialogue_data", {})
row["event_dialogue_state_prompt_bbcode"] = event_dialogue.get("dialogue_state_id_to_dialogue_states", {}).get(...).get("dialogue_state_prompt_bbcode", "")
```

- [ ] **Step 4: Add CSV fallback support to the event converter configuration**

```python
CONVERTERS["events"]["csv_file"] = PROJECT_ROOT / "external/config/events.csv"
```

- [ ] **Step 5: Let the event converter read either `.xlsx` or `.csv` and keep validation identical**

```python
if file_type == "excel":
    df = pd.read_excel(file_path, sheet_name="Events")
else:
    df = pd.read_csv(file_path)
```

### Task 3: Update designer-facing rules

**Files:**
- Create: `/Users/xietong/Documents/GitHub/Slay-The-Robot/designer/EVENT_TEXT_MAINTENANCE_GUIDE.md`

- [ ] **Step 1: Write the new source-of-truth rules**

```markdown
- Cards: edit `external/config/cards.xlsx`
- Artifacts: edit `external/config/artifacts.xlsx`
- Events: edit `external/config/events.xlsx`
- Event dialogue text no longer lives in `external/data/dialogue/` for the base game event
```

- [ ] **Step 2: Record the field mapping designers should edit**

```markdown
- `event_dialogue_state_prompt_bbcode`
- `event_dialogue_option_1_bbcode`
- `event_dialogue_option_1_failed_validator_bbcode`
- `event_dialogue_option_2_bbcode`
- `event_dialogue_option_2_failed_validator_bbcode`
```

- [ ] **Step 3: Document the compatibility rule for legacy dialogue IDs**

```markdown
- If `event_dialogue_data` is present, runtime uses it first.
- If not, runtime falls back to `event_dialogue_object_id`.
```

### Task 4: Verify the migration path

**Files:**
- Verify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/external/tools/excel_to_json_events.py`
- Verify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/scripts/ui/DialogueOverlay.gd`
- Verify: `/Users/xietong/Documents/GitHub/Slay-The-Robot/designer/EVENT_TEXT_MAINTENANCE_GUIDE.md`

- [ ] **Step 1: Run the event converter and confirm it emits the embedded dialogue fields**

```bash
python3 external/tools/excel_to_json_events.py
```

- [ ] **Step 2: Confirm the generated `event_pick_something.json` contains `event_dialogue_data`**

```bash
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("external/data/events/event_pick_something.json").read_text())
print("event_dialogue_data" in data["properties"])
PY
```

- [ ] **Step 3: Scan for stale references to the old base-game dialogue source**

```bash
rg -n "dialogue_pick_something|event_dialogue_object_id" autoload/Global.gd scripts external/tools external/data
```

