extends SceneTree

const TOOLTIP_SCENE_PATH := "res://scenes/ui/general/Tooltip.tscn"
const KEYWORD_TOOLTIP_SCENE_PATH := "res://scenes/ui/general/KeywordTooltip.tscn"
const KEYWORD_THEME_PATH := "res://themes/keyword_tooltip_theme.tres"
const TITLE_THEME_PATH := "res://themes/title_screen_theme.tres"
const RUN_THEME_PATH := "res://themes/run_screen_theme.tres"
const TOOLTIP_FACTORY_PATH := "res://scripts/ui/general/TooltipFactory.gd"
const EXPECTED_TOOLTIP_BASE_WIDTH_MAX := 8.0
const EXPECTED_TOOLTIP_SHORT_WIDTH_MAX := 224.0
const EXPECTED_TOOLTIP_SHORT_HEIGHT_MAX := 120.0
const EXPECTED_TOOLTIP_LONG_WIDTH_MIN := 236.0
const EXPECTED_TOOLTIP_LONG_WIDTH_MAX := 272.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_tooltip_scene(load(TOOLTIP_SCENE_PATH).instantiate(), "Tooltip.tscn")
	_assert_tooltip_scene(load(KEYWORD_TOOLTIP_SCENE_PATH).instantiate(), "KeywordTooltip.tscn")
	_assert_tooltip_theme(load(KEYWORD_THEME_PATH), "keyword tooltip theme", true)
	_assert_tooltip_theme(load(TITLE_THEME_PATH), "title screen theme", false)
	_assert_tooltip_theme(load(RUN_THEME_PATH), "run screen theme", false)
	await _assert_tooltip_factory()
	_assert_scripted_tooltip_providers()
	await _assert_codex_entry_shells()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _assert_tooltip_scene(tooltip: Control, label: String) -> void:
	if tooltip.custom_minimum_size.x > EXPECTED_TOOLTIP_BASE_WIDTH_MAX:
		failures.append("%s base width must not force a large fixed tooltip, got %.1f" % [label, tooltip.custom_minimum_size.x])
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("%s must contain RichTextLabel" % label)
	else:
		if rich_text_label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			failures.append("%s RichTextLabel must autowrap" % label)
		if rich_text_label.scroll_active:
			failures.append("%s RichTextLabel scrolling must stay disabled" % label)
	tooltip.free()


func _assert_tooltip_theme(theme: Theme, label: String, panel_container: bool) -> void:
	var style_type := "TooltipPanel"
	if panel_container:
		style_type = "PanelContainer"
	if not theme.has_stylebox("panel", style_type):
		failures.append("%s must explicitly provide %s/panel" % [label, style_type])
		return
	var panel_style := theme.get_stylebox("panel", style_type)
	if panel_style is not StyleBoxFlat:
		failures.append("%s must provide StyleBoxFlat for %s/panel" % [label, style_type])
		return
	var flat := panel_style as StyleBoxFlat
	if flat.bg_color.r > 0.22 or flat.bg_color.g > 0.26 or flat.bg_color.b > 0.32:
		failures.append("%s tooltip background must be dark, got %s" % [label, flat.bg_color])
	if flat.content_margin_left < 8.0 or flat.content_margin_left > 14.0:
		failures.append("%s tooltip left margin must be compact, got %.1f" % [label, flat.content_margin_left])
	if flat.border_width_bottom < 1:
		failures.append("%s tooltip must keep a visible border" % label)


func _assert_tooltip_factory() -> void:
	var factory: Script = load(TOOLTIP_FACTORY_PATH)
	if factory == null:
		failures.append("TooltipFactory.gd must load")
		return
	var tooltip: Control = factory.create_text_tooltip("手牌保留\nBoss\n回合结束时手牌保留")
	if tooltip == null:
		failures.append("TooltipFactory.create_text_tooltip must return a Control")
		return
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("factory tooltip must contain RichTextLabel")
	else:
		if not rich_text_label.get_parsed_text().contains("手牌保留"):
			failures.append("factory tooltip must preserve the title text")
		if not rich_text_label.get_parsed_text().contains("回合结束时手牌保留"):
			failures.append("factory tooltip must preserve the body text")
	root.add_child(tooltip)
	await process_frame
	_assert_tooltip_size(tooltip, "short factory tooltip", EXPECTED_TOOLTIP_SHORT_WIDTH_MAX, EXPECTED_TOOLTIP_SHORT_HEIGHT_MAX)
	tooltip.queue_free()
	await process_frame

	var long_tooltip: Control = factory.create_text_tooltip("很长的说明\n选择一张攻击牌，使其显示在牌库顶端，并在下一次抽牌时优先出现。")
	root.add_child(long_tooltip)
	await process_frame
	var long_size := long_tooltip.get_combined_minimum_size()
	if long_size.x < EXPECTED_TOOLTIP_LONG_WIDTH_MIN or long_size.x > EXPECTED_TOOLTIP_LONG_WIDTH_MAX:
		failures.append("long factory tooltip width must stay near the readable max, got %.1f" % long_size.x)
	long_tooltip.queue_free()
	await process_frame


func _assert_tooltip_size(tooltip: Control, label: String, max_width: float, max_height: float) -> void:
	var size := tooltip.get_combined_minimum_size()
	if size.x > max_width:
		failures.append("%s width must fit short text, got %.1f" % [label, size.x])
	if size.y > max_height:
		failures.append("%s height must fit short text without blank space, got %.1f" % [label, size.y])


func _assert_scripted_tooltip_providers() -> void:
	var script_paths := [
		"res://scripts/ui/Artifact.gd",
		"res://scripts/ui/ConsumableButton.gd",
		"res://scripts/combatants/StatusEffect.gd",
		"res://scripts/ui/CustomRunModifierCheckbox.gd",
	]
	for path: String in script_paths:
		var script: Script = load(path)
		if script == null:
			failures.append("%s must load" % path)
			continue
		if not script.source_code.contains("func _make_custom_tooltip"):
			failures.append("%s must explicitly implement _make_custom_tooltip" % path)
			continue
		var instance: Object = script.new()
		if not instance.has_method("_make_custom_tooltip"):
			failures.append("%s must implement _make_custom_tooltip" % path)
		else:
			var tooltip: Control = instance.call("_make_custom_tooltip", "标题\n说明")
			if tooltip == null:
				failures.append("%s _make_custom_tooltip must return a Control" % path)
			else:
				tooltip.free()
		if instance is Node:
			(instance as Node).free()


func _assert_codex_entry_shells() -> void:
	var packed: PackedScene = load("res://scenes/ui/menus/TitleScreen.tscn")
	var title_screen: Control = packed.instantiate()
	root.add_child(title_screen)
	await process_frame
	var codex_menu: Control = title_screen.get_node("CodexMenu")
	if not codex_menu.has_method("populate_codex_enemy_container") or not codex_menu.has_method("populate_codex_artifact_container"):
		failures.append("CodexMenu script must load with populate methods")
		title_screen.queue_free()
		await process_frame
		return

	codex_menu.populate_codex_enemy_container()
	await process_frame
	_assert_first_codex_entry(codex_menu, "enemy codex entry")

	codex_menu.populate_codex_artifact_container()
	await process_frame
	_assert_first_codex_entry(codex_menu, "artifact codex entry")

	title_screen.queue_free()
	await process_frame


func _assert_first_codex_entry(codex_menu: Control, label: String) -> void:
	var grid: GridContainer = codex_menu.get_node("ScrollContainer/MarginContainer/CodexCardContainer")
	if grid.get_child_count() == 0:
		failures.append("%s must create at least one entry" % label)
		return
	var child := grid.get_child(0)
	if child is not PanelContainer:
		failures.append("%s must use PanelContainer, got %s" % [label, child.get_class()])
		return
	var entry := child as PanelContainer
	var script := entry.get_script() as Script
	var has_styled_tooltip := script != null and script.resource_path.ends_with("StyledTooltipPanel.gd")
	if not has_styled_tooltip:
		failures.append("%s must use StyledTooltipPanel.gd" % label)
	if not entry.has_theme_stylebox_override("panel"):
		failures.append("%s must override its panel style" % label)
	else:
		var style := entry.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			failures.append("%s panel style must be StyleBoxFlat" % label)
		elif style.bg_color.a < 0.90 or style.bg_color.r < 0.85:
			failures.append("%s panel must use a light card shell, got %s" % [label, style.bg_color])
	if not entry.has_node("MarginContainer/VBoxContainer/ImagePanel"):
		failures.append("%s must provide ImagePanel for icon staging" % label)
	if has_styled_tooltip:
		var tooltip: Control = entry.call("_make_custom_tooltip", entry.tooltip_text)
		if tooltip == null:
			failures.append("%s custom tooltip must return a Control" % label)
		else:
			tooltip.free()
