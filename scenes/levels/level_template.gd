## ============================================================================
## LEVEL TEMPLATE
## ============================================================================
## 复制此文件作为新关卡的起点：
## 1. 将此文件复制为 level_XX_name.gd（XX 为关卡编号）
## 2. 修改 class_name 为 LevelXX（如 Level02）
## 3. 创建对应的 Objective 类（复制 template_objective.gd）
## 4. 在 levels.json 中添加关卡元数据
## 5. 删除此模板文件（或在 .gitignore 中排除）
##
## 关卡元数据示例 (添加到 levels.json):
## {
##     "id": "level_XX_name",
##     "title": "Level X — 关卡名称",
##     "subtitle": "关卡描述",
##     "timer_mode": "count_up",    # 或 "count_down"
##     "time_limit": 60.0,           # 仅用于 count_down
##     "order": XX0,                 # 关卡顺序（10, 20, 30...）
##     "record_time": true           # 是否记录通关时间
## }
## ============================================================================


class_name LevelTemplate
extends BaseLevel
## 关卡模板类。继承 BaseLevel，实现 _build_level() 方法来构建关卡内容。
## 关卡元数据在 levels.json 中定义，不在脚本中。


## ============================================================================
## 导出变量 — 在编辑器中配置
## ============================================================================

## 关卡背景颜色（BaseLevel 默认深蓝色）
## 如需自定义，取消注释并修改：
# @export var bg_color: Color = Color(0.10, 0.12, 0.18)

## 关卡背景尺寸（默认 1280x720，填满视口则设为 1920x1080）
## 如需填满 1920x1080 视口，取消注释并修改：
# @export var bg_size: Vector2 = Vector2(1920, 1080)


## ============================================================================
## 生命周期
## ============================================================================

func _ready() -> void:
	# 如果需要填满 1920x1080 视口，设置 bg_size：
	# bg_size = Vector2(1920, 1080)

	# 调用父类 _ready()（会调用 _build_level() 并连接目标信号）
	super._ready()


## ============================================================================
## 关卡构建 — 必须重写此方法
## ============================================================================

func _build_level() -> void:
	## ========================================
	## 步骤 1: 创建关卡目标（LevelObjective 子类）
	## ========================================
	## 每个关卡必须有且仅有一个 LevelObjective 子类实例。
	## 目标类定义关卡的胜利/失败条件。
	##
	## 示例 1 — 使用现有目标类型：
	# var objective := ReachGoalObjective.new()
	# objective.goal_position = Vector2(1500, 500)
	# objective.goal_size = Vector2(80, 80)
	# add_child(objective)
	##
	## 示例 2 — 使用自定义目标类型：
	# var objective := TemplateObjective.new()
	# add_child(objective)
	##
	## 示例 3 — 使用 Stop the Clock 目标：
	# var objective := StopClockObjective.new()
	# objective.button_position = Vector2(960, 540)
	# add_child(objective)

	## ========================================
	## 步骤 2: 构建关卡几何（地板、墙壁、平台）
	## ========================================
	## 使用 build_solid() 创建静态碰撞体。
	##
	## build_solid(position, size, color):
	##   - position: StaticBody2D 的中心位置（世界坐标）
	##   - size: 碰撞体尺寸
	##   - color: 渲染颜色（ColorRect）
	##
	## 示例 — 地板：
	# build_solid(Vector2(960, 1000), Vector2(1920, 200), Color(0.2, 0.25, 0.3))
	##
	## 示例 — 墙壁：
	# build_solid(Vector2(0, 540), Vector2(40, 1080), Color(0.15, 0.18, 0.22))
	##
	## 示例 — 平台：
	# build_solid(Vector2(960, 700), Vector2(400, 30), Color(0.25, 0.28, 0.35))

	## ========================================
	## 步骤 3: 创建玩家实体（如需要）
	## ========================================
	## 如果关卡需要玩家控制的角色，创建并添加 Player 节点。
	##
	## 平台跳跃玩家：
	# var player := PlayerPlatformer.new()
	# player.position = Vector2(200, 800)
	# add_child(player)
	##
	## 俯视角玩家：
	# var player := PlayerTopdown.new()
	# player.position = Vector2(200, 800)
	# add_child(player)

	## ========================================
	## 步骤 4: 创建可交互物体（如需要）
	## ========================================
	## 拖拽物体：
	# var draggable := Draggable.new()
	# draggable.position = Vector2(400, 500)
	# draggable.size = Vector2(60, 60)
	# add_child(draggable)
	##
	## 放置区域（DropZone）：
	# var drop_zone := DropZone.new()
	# drop_zone.position = Vector2(800, 500)
	# drop_zone.size = Vector2(120, 120)
	# add_child(drop_zone)

	## ========================================
	## 步骤 5: 添加关卡特定逻辑
	## ========================================
	## 如果关卡需要额外的游戏逻辑（如敌人、陷阱、触发器），
	## 可以在这里创建。复杂的逻辑应该封装在单独的类中。

	pass


## ============================================================================
## 可选：重写超时行为
## ============================================================================

## 默认行为：倒计时归零时失败（除非目标已完成）。
## 如果需要"存活到时间结束"的胜利条件，取消注释并重写此方法：
##
# func _on_timer_timed_out() -> void:
#     if _objective != null and _objective.is_completed():
#         return  # 已经通关，不处理超时
#     _objective._complete()  # 超时即胜利