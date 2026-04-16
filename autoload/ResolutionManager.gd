## 分辨率管理器
## 负责在运行时应用用户设置的分辨率，并提供当前缩放比例查询。
## 核心策略：保持内部基准分辨率 1200x700 不变，通过 Godot Stretch 自动映射到任意窗口尺寸。
extends Node

const BASE_RESOLUTION: Vector2 = Vector2(1200, 700)

## 预设分辨率列表（标签: Vector2）
const RESOLUTION_PRESETS: Dictionary = {
	"1280 x 720 (720P)": Vector2(1280, 720),
	"1920 x 1080 (1080P)": Vector2(1920, 1080),
	"2560 x 1440 (2K)": Vector2(2560, 1440),
	"3840 x 2160 (4K)": Vector2(3840, 2160),
}

func _ready() -> void:
	apply_saved_resolution()
	get_tree().root.size_changed.connect(_on_window_resized)

## 根据 UserSettingsData 中保存的尺寸应用分辨率
func apply_saved_resolution() -> void:
	var size: Vector2 = Global.user_settings_data.settings_window_size
	if size.x > 0 and size.y > 0:
		apply_resolution(int(size.x), int(size.y))

## 设置窗口尺寸并居中。注意：实际 2D 缩放由 project.godot 的 stretch 配置处理。
func apply_resolution(width: int, height: int) -> void:
	var new_size := Vector2i(width, height)

	# 如果窗口处于最大化或全屏模式，set_size 会无效，先切回窗口模式
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED or current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	DisplayServer.window_set_size(new_size)

	# 窗口居中（保持在当前所在的屏幕上）
	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(current_screen)
	var screen_pos := DisplayServer.screen_get_position(current_screen)
	var window_position := Vector2i(
		screen_pos.x + clampi((screen_size.x - width) / 2, 0, maxi(screen_size.x - width, 0)),
		screen_pos.y + clampi((screen_size.y - height) / 2, 0, maxi(screen_size.y - height, 0))
	)
	DisplayServer.window_set_position(window_position)

	# 同步保存设置
	Global.user_settings_data.settings_window_size = Vector2(width, height)
	FileLoader.save_user_settings()

## 获取当前窗口相对基准分辨率的缩放比例
## 用于需要手动适配分辨率的动态元素（如绝对坐标动画、自定义绘制等）
func get_scale() -> Vector2:
	var window_size := DisplayServer.window_get_size()
	return Vector2(window_size) / BASE_RESOLUTION

## 获取统一的缩放因子（取宽高中较小值，保持比例无拉伸）
func get_uniform_scale() -> float:
	var s := get_scale()
	return min(s.x, s.y)

func _on_window_resized() -> void:
	# 当用户手动调整窗口大小时，可选择性更新保存的尺寸
	# 若不需要记录手动拖拽，可注释掉下面两行
	# Global.user_settings_data.settings_window_size = Vector2(DisplayServer.window_get_size())
	# FileLoader.save_user_settings()
	pass
