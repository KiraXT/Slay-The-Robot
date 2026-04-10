# Slay the Robot - Project Memory

## 🏗 System Architecture (Data-Driven)
- **Engine**: Godot (GDScript)
- **Data Pattern**: All resources are JSON-based located in `external/data/`.
- **Loader**: `FileLoader.gd` maps JSONs to `Global.gd` via `SCHEMA` array.

## 📂 Key Paths & Rules
- **Cards**: `external/data/cards/`. JSON format. Uses `card_play_actions` for logic.
- **Relics**: `external/data/artifacts/`. Pure data or `artifact_script_path`.
- **Events**: `external/data/events/` (Logic) + `external/data/dialogue/` (Text).
- **UI**: 
  - Combat: `scenes/Root.tscn` -> `scripts/ui/Combat.gd`
  - Cards: `scenes/ui/Card.tscn`
  - Hand Area: `$Hand` (Hand.gd)

## 🛠 Developer Workflow
- **Adding Content**: Create JSON in the correct sub-folder under `external/data/`. 
- **Modding**: Use `patch_data` block in JSON for overrides.
- **Actions**: Reference existing scripts in `res://scripts/actions/`.