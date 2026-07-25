## ============================================================================
## OBJECTIVE TEMPLATE
## ============================================================================
## 复制此文件作为新关卡目标的起点：
## 1. 将此文件复制为 xx_objective.gd（如 click_objective.gd）
## 2. 修改 class_name 为 XxObjective（如 ClickObjective）
## 3. 实现关卡的胜利/失败条件检测逻辑
## 4. 在关卡脚本中实例化并添加为子节点
##
## 目标类职责：
## - 定义关卡的胜利条件（何时调用 _complete()）
## - 定义关卡的失败条件（何时调用 _fail()）
## - （可选）提供进度信息（get_progress_ratio / get_progress_text）
## ============================================================================


class_name TemplateObjective
extends LevelObjective
## 关卡目标模板类。继承 LevelObjective，实现具体的胜利/失败条件检测。
##
## 使用方式：
## 1. 在 _ready() 中初始化关卡内容（按钮、区域、物体等）
## 2. 监听游戏事件（点击、碰撞、时间等）
## 3. 当条件满足时调用 _complete() 或 _fail()
## 4. （可选）重写 get_progress_ratio() / get_progress_text() 提供进度信息


## ============================================================================
## 导出变量 — 在编辑器或关卡脚本中配置
## ============================================================================

## 示例：目标位置
@export var target_position: Vector2 = Vector2(960, 540)

## 示例：容差范围
@export var tolerance: float = 0.25

## 示例：颜色配置
@export var primary_color: Color = Color(0.80, 0.18, 0.18)


## ============================================================================
## 内部状态
## ============================================================================

## 示例：UI 元素引用
var _button: Area2D
var _label: Label

## 示例：游戏状态追踪
var _click_count: int = 0
var _is_interactable: bool = true


## ============================================================================
## 生命周期
## ============================================================================

func _ready() -> void:
	## ========================================
	## 步骤 1: 创建 UI/交互元素
	## ========================================
	## 根据关卡需求创建按钮、区域、物体等。
	##
	## 示例 — 创建可点击的按钮：
	# _create_button()
	##
	## 示例 — 创建碰撞区域：
	# _create_goal_zone()
	##
	## 示例 — 创建拖拽物体：
	# _create_draggables()

	## ========================================
	## 步骤 2: 连接信号
	## ========================================
	## 监听游戏事件，如点击、碰撞、时间等。
	##
	## 示例 — 监听计时器：
	# LevelTimer.tick.connect(_on_timer_tick)
	##
	## 示例 — 监听输入：
	# 如果需要全局输入，使用 _input() 或 _unhandled_input()

	## ========================================
	## 步骤 3: F6 开发支持（如需要）
	## ========================================
	## 如果关卡需要 LevelManager 上下文（F6 单独运行），
	## 调用 LevelManager.begin_dev_test(level_id)。
	##
	# if LevelManager.get_current_level_id() == "":
	#     var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
	#     LevelManager.begin_dev_test(level_id)

	## ========================================
	## 步骤 4: 初始化显示
	## ========================================
	## 设置初始 UI 状态。
	_emit_progress()

	pass


## ============================================================================
## 信号处理 — 根据关卡需求选择使用
## ============================================================================

## 方式 1: Area2D.input_event — 处理点击/碰撞
## 用于可点击物体、碰撞区域等。
##
# func _on_area_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
#     if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
#         if event.pressed:
#             _handle_click()

## 方式 2: body_entered / area_entered — 处理碰撞进入
## 用于目标区域、触发器等。
##
# func _on_body_entered(body: Node2D) -> void:
#     if body is PlayerPlatformer or body is PlayerTopdown:
#         _complete()

## 方式 3: LevelTimer.tick — 处理时间相关逻辑
## 用于倒计时显示、时间限制等。
##
# func _on_timer_tick(display_time: float) -> void:
#     _label.text = "%.2f" % display_time
#     _emit_progress()

## 方式 4: _input() / _unhandled_input() — 处理全局输入
## 用于键盘、全局鼠标事件等。
##
# func _unhandled_input(event: InputEvent) -> void:
#     if event.is_action_pressed("ui_accept"):
#         _handle_action()


## ============================================================================
## 游戏逻辑 — 实现胜利/失败条件检测
## ============================================================================

## 示例：处理点击事件
func _handle_click() -> void:
	# 防止重复触发
	if _is_completed or _is_failed:
		return

	# 示例：检查游戏状态
	# var remaining: float = LevelTimer.get_remaining()
	# if abs(remaining - target_time) <= tolerance:
	#     _complete()  # 条件满足，通关
	# else:
	#     _fail("Not quite!")  # 条件不满足，失败

	pass


## ============================================================================
## 进度报告 — 可选，用于 HUD 显示
## ============================================================================

## 重写 get_progress_ratio() 以返回 0..1 的进度值。
## 默认：未完成时返回 0.0，完成时返回 1.0。
##
# func get_progress_ratio() -> float:
#     if _is_completed:
#         return 1.0
#     # 示例：基于剩余时间
#     var elapsed: float = LevelTimer.get_elapsed()
#     return min(elapsed / 10.0, 1.0)  # 10秒内渐变到100%

## 重写 get_progress_text() 以返回人类可读的进度文本。
## 默认：返回空字符串。
##
# func get_progress_text() -> String:
#     if _is_completed:
#         return "Complete!"
#     # 示例：显示点击次数
#     return "%d clicks" % _click_count


## ============================================================================
## 辅助方法 — 创建关卡元素
## ============================================================================

## 示例：创建可点击的圆形按钮
func _create_button() -> void:
	_button = Area2D.new()
	_button.position = target_position
	_button.input_pickable = true
	_button.collision_layer = 1 << 3  # clickable layer
	_button.collision_mask = 0

	# 视觉元素
	var circle := Polygon2D.new()
	circle.polygon = _make_circle(50.0, 32)
	circle.color = primary_color
	_button.add_child(circle)

	# 碰撞体
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	_button.add_child(col)

	# 连接输入信号
	_button.input_event.connect(_on_area_input)
	add_child(_button)


## 示例：创建目标区域
func _create_goal_zone() -> void:
	var zone := Area2D.new()
	zone.position = target_position
	zone.collision_layer = 1 << 2  # goal layer
	zone.collision_mask = 1 << 0   # player layer
	zone.monitoring = true

	# 碰撞体
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	col.shape = shape
	zone.add_child(col)

	# 连接进入信号
	zone.body_entered.connect(_on_body_entered)
	add_child(zone)


## 示例：创建圆形多边形
func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts