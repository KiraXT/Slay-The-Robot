extends SceneTree

const TOOLTIP_SCENE_PATH := "res://scenes/ui/general/Tooltip.tscn"
const KEYWORD_TOOLTIP_SCENE_PATH := "res://scenes/ui/general/KeywordTooltip.tscn"
const KEYWORD_THEME_PATH := "res://themes/keyword_tooltip_theme.tres"
const TITLE_THEME_PATH := "res://themes/title_screen_theme.tres"
const RUN_THEME_PATH := "res://themes/run_screen_theme.tres"
const TOOLTIP_FACTORY_PATH := "res://scripts/ui/general/TooltipFactory.gd"
const EXPECTED_TOOLTIP_WIDTH_MIN := 248.0
const EXPECTED_TOOLTIP_WIDTH_MAX := 272.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_tooltip_scene(load(TOOLTIP_SCENE_PATH).instantiate(), "Tooltip.tscn")
	_assert_tooltip_scene(load(KEYWORD_TOOLTIP_SCENE_PATH).instantiate(), "KeywordTooltip.tscn")
	_assert_tooltip_theme(load(KEYWORD_THEME_PATH), "keyword tooltip theme", true)
	_assert_tooltip_theme(load(TITLE_THEME_PATH), "title screen theme", false)
	_assert_tooltip_theme(load(RUN_THEME_PATH), "run screen theme", false)
	_assert_tooltip_factory()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _assert_tooltip_scene(tooltip: Control, label: String) -> void:
	if tooltip.custom_minimum_size.x < EXPECTED_TOOLTIP_WIDTH_MIN or tooltip.custom_minimum_size.x > EXPECTED_TOOLTIP_WIDTH_MAX:
		failures.append("%s width must stay near 260px, got %.1f" % [label, tooltip.custom_minimum_size.x])
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("%s must contain RichTextLabel" % label)
	else:
		if rich_text_label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			failures.append("%s RichTextLabel must autowrap" % label)
		if rich_text_label.scroll_active:
			failures.append("%s RichTextLabel scrolling must stay disabled" % label)
	tooltip.queue_free()


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
	var tooltip: Control = factory.create_text_tooltip("攻击格挡\n每进行3次攻击获得5点格挡")
	if tooltip == null:
		failures.append("TooltipFactory.create_text_tooltip must return a Control")
		return
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("factory tooltip must contain RichTextLabel")
	else:
		if not rich_text_label.get_parsed_text().contains("攻击格挡"):
			failures.append("factory tooltip must preserve the title text")
		if not rich_text_label.get_parsed_text().contains("每进行3次攻击获得5点格挡"):
			failures.append("factory tooltip must preserve the body text")
	tooltip.queue_free()
