# Tasks

- [x] Task 1: BaseLevel 增加关卡元数据 @export 字段
  - [ ] 在 [feature/core/base_level.gd](feature/core/base_level.gd) 添加 `@export var title: String = "Untitled Level"`、`subtitle: String = ""`、`timer_mode: String = "count_up"`、`time_limit: float = 0.0`、`order: int = 100`、`thumbnail_path: String = ""`
  - [ ] 添加 `get_metadata() -> Dictionary` 方法返回上述字段的字典（供 LevelManager 读取，避免重复拼装）
  - [ ] 验证：编辑器中打开任一关卡场景，Inspector 出现新字段

- [x] Task 2: 迁移现有 3 个关卡场景的元数据到 @export
  - [ ] level_01_drag.tscn：title="Level 1 — Drag & Drop"、subtitle="Drag the boxes into the drop zone."、timer_mode="count_up"、time_limit=0.0、order=10
  - [ ] level_02_platform.tscn：title="Level 2 — Platformer"、subtitle="Reach the goal before the clock runs out."、timer_mode="count_down"、time_limit=60.0、order=20
  - [ ] level_03_topdown.tscn：title="Level 3 — Top-Down"、subtitle="Escape the maze before time runs out."、timer_mode="count_down"、time_limit=45.0、order=30
  - [ ] 验证：在编辑器中确认 3 个场景的 Inspector 字段已填入正确值

- [x] Task 3: LevelManager 改为运行时扫描发现关卡
  - [ ] 删除 [feature/core/autoload/level_manager.gd](feature/core/autoload/level_manager.gd) 的 `const LEVELS` 常量
  - [ ] 新增 `const LEVELS_DIR: String = "res://scenes/levels"` 和 `var _levels: Array = []`
  - [ ] 实现 `_discover_levels()`：用 `DirAccess.open(LEVELS_DIR)` 遍历 `.tscn` 文件，对每个用 `load(path)` + `get_state()` 读取根节点 @export 属性，校验根节点类型为 BaseLevel（通过 `state.get_node_type(0)` 或 `_get_base_scene_class`），构建 entry 字典 `{id, path, title, subtitle, timer_mode, time_limit, order, thumbnail_path}`
  - [ ] id 从文件名推导（去掉 `.tscn` 扩展名）
  - [ ] 按 `(order, filename)` 升序排序 `_levels`
  - [ ] 在 `_ready()` 调用 `_discover_levels()`；空结果时 push_error
  - [ ] 修改 `_find_entry` / `get_level_ids` / `get_level_path` / `get_level_metadata` / `get_level_index` / `get_next_level_id` / `is_level_unlocked` / `get_progress` 改为读 `_levels`
  - [ ] 验证：headless 运行，`LevelManager.get_level_ids()` 返回 `["level_01_drag", "level_02_platform", "level_03_topdown"]`，顺序正确

- [x] Task 4: 创建 LevelSelect 场景
  - [ ] 新建 [scenes/level_select.gd](scenes/level_select.gd) extends Control，`_ready()` 中调用 `LevelManager.get_level_ids()` 遍历构建关卡卡片
  - [ ] 每张卡片：TextureRect（缩略图或占位色块）、Label（title）、Label（subtitle）、Label（模式标签 "⏱ Count Up" / "⏳ Count Down 60s"）、Label（最佳时间 "Best: MM:SS.ms" 或 "Best: —"）、Button（"Play"，锁定时 disabled + 灰色遮罩）
  - [ ] 卡片用 GridContainer 排列（列数自适应或固定 3 列）
  - [ ] Play 按钮点击 → `LevelManager.load_level(id)`
  - [ ] "返回"按钮 + Esc → `get_tree().change_scene_to_file("res://scenes/main_menu.tscn")`
  - [ ] 监听 `SignalBus.save_written` 信号刷新最佳时间显示（玩家通关后返回选择界面能看到更新）
  - [ ] 新建 [scenes/level_select.tscn](scenes/level_select.tscn) 根节点 Control + 脚本挂载
  - [ ] 验证：编辑器中 F6 运行 level_select.tscn，显示 3 张关卡卡片，顺序正确，第 1 张解锁、其余锁定

- [x] Task 5: main_menu 接入 LevelSelect
  - [ ] 修改 [scenes/main_menu.gd](scenes/main_menu.gd) 的"开始游戏"按钮回调，从直接加载第一关改为 `get_tree().change_scene_to_file("res://scenes/level_select.tscn")`
  - [ ] 移除 main_menu 中原有的关卡列表展示逻辑（`_make_level_row` 等迁移到 LevelSelect，或简化 main_menu 为纯入口菜单）
  - [ ] 验证：从 main_menu 点"开始游戏"跳转到 level_select，level_select 点"返回"回到 main_menu

- [x] Task 6: 创建 test_level_select 测试场景
  - [ ] 新建 [tests/test_level_select.gd](tests/test_level_select.gd)：显示 LevelManager 扫描结果（关卡数、每关 id/path/title/order）、按钮跳转 level_select.tscn、按钮清理存档（用于测试锁定/解锁状态）
  - [ ] 新建 [tests/test_level_select.tscn](tests/test_level_select.tscn)
  - [ ] 在 [tests/test_menu.gd](tests/test_menu.gd) 的 TESTS 数组新增入口
  - [ ] 验证：headless 运行 test_level_select.tscn 无错误，显示 3 个关卡的信息

- [x] Task 7: headless 全量验证
  - [ ] 运行 `Godot --headless --import` 注册新类名（如有）
  - [ ] 逐个 headless 验证：level_01/02/03、main_menu、level_select、test_level_select、test_menu
  - [ ] 确认零 ERROR/WARNING/SCRIPT ERROR
  - [ ] 验证 `get_level_ids()` 顺序与预期一致

# Task Dependencies
- Task 2 依赖 Task 1（先有 @export 字段才能填值）
- Task 3 依赖 Task 1（扫描读取 BaseLevel 的 @export）
- Task 4 依赖 Task 3（LevelSelect 读 LevelManager 运行时列表）
- Task 5 依赖 Task 4（main_menu 跳转目标需存在）
- Task 6 依赖 Task 3 + Task 4（测试场景验证扫描结果 + 选择界面）
- Task 7 依赖所有前置任务
- 可并行：Task 2 与 Task 3（Task 2 改 .tscn，Task 3 改 .gd，互不冲突）
