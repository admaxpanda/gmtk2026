# GMTK 2026 — Countdown

基于 **Godot 4.6.3 (Mono)** 构建的 2D 游戏框架，围绕"倒计时"主题设计。包含三种核心玩法、关卡管理、双模式计时器与方向感知的存档系统。

## 核心功能

### 三种 2D 玩法组件

| 组件 | 文件 | 说明 |
|------|------|------|
| **拖拽** | [feature/drag/draggable.gd](feature/drag/draggable.gd) | Area2D 点击拖拽，悬停/拖拽视觉反馈，`_process` 帧率跟随 |
| **平台跳跃** | [feature/platformer/player_platformer.gd](feature/platformer/player_platformer.gd) | Coyote Time + Jump Buffering + 可变跳跃高度，专业手感 |
| **俯视角移动** | [feature/topdown/player_topdown.gd](feature/topdown/player_topdown.gd) | 八方向移动，对角线归一化 |

### 关卡系统

- **关卡管理** [feature/core/autoload/level_manager.gd](feature/core/autoload/level_manager.gd) — 关卡注册、解锁、进度追踪、失败后 1.2s 自动重载（带失败 ID 快照防误重载）
- **关卡基类** [feature/core/base_level.gd](feature/core/base_level.gd) — 自动发现 `LevelObjective` 子节点并桥接信号，超时默认触发失败
- **目标系统** [feature/core/objective/](feature/core/objective/)
  - `LevelObjective` 抽象基类（completed/failed/progress 信号，幂等触发）
  - `ReachGoalObjective` — 玩家进入目标区域即通关
  - `DragAllToZoneObjective` — N 个拖拽物全部放入 DropZone 即通关
  - `StopClockObjective` — 倒计时归零瞬间点击红色按钮即通关，按钮上方实时显示 2 位小数倒计时

关卡元数据集中定义在 [scenes/levels/levels.json](scenes/levels/levels.json)（id / title / subtitle / timer_mode / time_limit / order / record_time），新增关卡只需追加一条记录：

## 关卡设计

### Level 1 — Stop the Clock（停表）

| 属性 | 值 |
|------|-----|
| **机制** | 倒计时归零瞬间点击按钮 |
| **计时模式** | 10 秒倒计时 |
| **记录时间** | 否 |

**玩法描述**：
- 屏幕中央有一个红色圆形按钮，上方显示 2 位小数倒计时
- 玩家需在倒计时归零（0.00）时点击按钮通关
- 点击过早或超时未点击则失败
- 右下角有装饰性回收站（非功能性）

**技术要点**：
- 按钮使用 `Area2D.input_event` 处理点击
- 倒计时标签实时监听 `LevelTimer.tick` 信号
- F6 单独运行支持（`LevelManager.begin_dev_test`）

---

### Level 2 — Digit Drop（数字丢弃）

| 属性 | 值 |
|------|-----|
| **机制** | 拖动虚计时器截断时间 |
| **计时模式** | 11110 秒倒计时 |
| **记录时间** | 否 |

**玩法描述**：
- 左上角显示两个计时器：
  - **虚计时器**：显示高位数字（如 `1111`）
  - **主计时器**：显示个位数（如 `0`）
- 实际时间 = 虚计时器值 × 10 + 主计时器值
- 玩家可拖动虚计时器到右下角回收站
- 丢弃后，时间截断为个位数继续倒数
- 在显示 `0.00` 时点击按钮通关

**技术要点**：
- `VirtualTimer` 类继承 `Area2D`，可拖动
- `LevelTimer.get_high_digits()` / `get_units_digit()` 分离数字
- `LevelTimer.truncate_to_units()` 截断时间
- 拖动到非回收站位置会弹回原位

---

### Level 3 — Clear Path（清路）

| 属性 | 值 |
|------|-----|
| **机制** | 拖动方块移除遮挡，倒计时归零瞬间点击按钮通关 |
| **计时模式** | 45 秒倒计时 |
| **记录时间** | 否 |

**玩法描述**：
- 屏幕中央有一个蓝色纸质方块，完全遮挡红色按钮
- 玩家需将方块拖入右下角回收站
- 方块消失后，按钮露出
- 在倒计时归零（0.00）时点击按钮通关（参照 Level 1 的停表机制）；过早点击或超时未点击则失败

**技术要点**：
- `PaperBlock` 类继承 `Area2D`，可拖动
- `TrashBin` 类继承 `Area2D`，作为 DropZone
- 检测 `get_overlapping_areas()` 判断是否拖入回收站

---

### Level 4 — Negative Sign（负号）

| 属性 | 值 |
|------|-----|
| **机制** | 拖动负号切换显示模式 |
| **计时模式** | 10 秒倒计时 |
| **记录时间** | 否 |

**玩法描述**：
- 按钮上方显示倒计时，但前面有一个蓝色负号
- **有负号时**：计时器显示负数增加（`0 → -1 → -2...`）
- **无负号时**：计时器显示正常倒数（`10 → 9 → 8...`）
- 玩家可拖动负号到回收站，移除后显示真实时间
- 在显示 `0.00` 时点击按钮通关

**技术要点**：
- `NegativeSign` 类继承 `Area2D`，可拖动
- 通过 `_elapsed_time` 计算实际经过时间
- `_is_negative_mode` 控制显示模式
- 移除负号后立即切换显示逻辑

---

### Level 5 — Pulley（滑轮）

| 属性 | 值 |
|------|-----|
| **机制** | 平台跳跃 + 滑轮物理 |
| **计时模式** | 30 秒倒计时 |
| **记录时间** | 否 |

**玩法描述**：
- 玩家控制一个平台跳跃角色（青色方块）
- 屏幕右侧有一个滑动面板，遮挡住红色按钮
- 滑轮系统连接平台和面板：
  - 玩家跳上平台 → 平台下沉
  - 平台下沉 → 面板上升（滑轮原理）
- 当面板完全上升后，按钮露出
- 玩家从平台跳到按钮上触发通关

**技术要点**：
- `PulleyPlatform` 继承 `AnimatableBody2D`，检测玩家站立后下沉
- `SlidingPanel` 继承 `AnimatableBody2D`，监听平台移动信号反向上升
- 绳索视觉动态更新（`Line2D.set_point_position`）
- 平台传感器安全检查（防止玩家死亡后状态不同步）
- 使用 `PlayerPlatformer` 类实现专业手感（Coyote Time + Jump Buffering）

---

### 关卡机制总结

| 关卡 | 核心交互 | UI 元素 | 物理系统 |
|------|---------|---------|---------|
| Level 1 | 点击 | 按钮、倒计时标签 | 无 |
| Level 2 | 拖拽 | 虚计时器、回收站 | 无 |
| Level 3 | 拖拽 | 纸质方块、回收站 | 无 |
| Level 4 | 拖拽 | 负号、回收站 | 无 |
| Level 5 | 平台跳跃 | 滑轮、绳索、面板 | CharacterBody2D + AnimatableBody2D |

---

### 可复用组件

| 组件类 | 文件 | 用途 |
|--------|------|------|
| `VirtualTimer` | [feature/core/ui/virtual_timer.gd](feature/core/ui/virtual_timer.gd) | 可拖动的计时器显示 |
| `TrashBin` | [feature/core/ui/trash_bin.gd](feature/core/ui/trash_bin.gd) | 回收站区域 |
| `PaperBlock` | [feature/core/ui/paper_block.gd](feature/core/ui/paper_block.gd) | 可拖动的遮挡物 |
| `NegativeSign` | [feature/core/ui/negative_sign.gd](feature/core/ui/negative_sign.gd) | 可拖动的负号 |
| `PulleyPlatform` | [feature/core/ui/pulley_platform.gd](feature/core/ui/pulley_platform.gd) | 滑轮平台（下沉检测） |
| `SlidingPanel` | [feature/core/ui/sliding_panel.gd](feature/core/ui/sliding_panel.gd) | 滑动面板（联动上升） |

### 双模式计时器

[feature/core/autoload/level_timer.gd](feature/core/autoload/level_timer.gd)

- **正计时**（COUNT_UP）— 速通模式，用时越短越好
- **倒计时**（COUNT_DOWN）— 限时模式，剩余时间越多越好
- 单调时钟实现（`Time.get_ticks_msec()`），跨暂停/恢复准确
- `tick` 信号每帧驱动 HUD，`timed_out` 信号驱动 BaseLevel 失败逻辑

### 方向感知存档

[feature/core/autoload/save_manager.gd](feature/core/autoload/save_manager.gd)

- `ConfigFile` 持久化到 `user://save_data.cfg`
- 关卡完成状态 + 最佳时间
- `set_best_time(time, lower_is_better)` — 正计时取最小值，倒计时取最大值（剩余时间）
- `.get(key, default)` 兼容字段扩展，旧存档不损坏

## 架构

### 信号向上、调用向下

```
┌──────────────────────────────────────┐
│  PRESENTATION  (HUD / Label)         │  ← 监听信号，不持有数据
├──────────────────────────────────────┤
│  LOGIC         (LevelManager)        │  ← 编排转换，查询数据
├──────────────────────────────────────┤
│  DATA          (SaveManager / .cfg)  │  ← 单一数据源，可序列化
├──────────────────────────────────────┤
│  INFRASTRUCTURE (Autoloads)          │  ← SignalBus / Timer / Manager
└──────────────────────────────────────┘
```

### 五个 Autoload 单例

| 单例 | 职责 |
|------|------|
| `SignalBus` | 全局生命周期信号（level_started/completed/failed、timer_tick、objective_progress、save_written） |
| `SaveManager` | 存档读写、方向感知最佳时间 |
| `LevelTimer` | 双模式计时、暂停/恢复、超时信号 |
| `LevelManager` | 关卡注册/加载/解锁、失败自动重载 |
| `HUD` | 模式感知 HUD、暂停/完成菜单（PROCESS_MODE_ALWAYS 保证暂停时可交互） |

### 物理层分配

| 层 | 用途 |
|----|------|
| 0 | Player |
| 1 | Solid（平台/墙壁） |
| 2 | Goal Zone |
| 3 | Draggable |
| 4 | Drop Zone |

## 目录结构

```
GMTK_COUNTDOWN/
├── project.godot              # 5 autoload + input map + 5 物理层
├── feature/
│   ├── core/
│   │   ├── autoload/          # SignalBus, SaveManager, LevelTimer, LevelManager
│   │   ├── objective/         # LevelObjective + ReachGoal + DragAllToZone + TemplateObjective
│   │   ├── base_level.gd      # 关卡基类
│   │   └── scene_helpers.gd   # 测试场景共享工具
│   ├── drag/draggable.gd
│   ├── platformer/player_platformer.gd
│   └── topdown/player_topdown.gd
├── scenes/
│   ├── main_menu.gd/.tscn     # 主菜单（入口，跳转到关卡选择）
│   └── levels/
│       ├── levels.json                # 关卡元数据（id/title/timer_mode/time_limit/order/record_time）
│       ├── level_template.gd          # 关卡脚本模板（创建新关卡时复制）
│       └── level_07_stop_the_clock.gd # StopClock + 10s 倒计时（点击精度挑战）
├── tests/                     # 7 个独立测试场景 + 测试菜单
└── ui/hud.gd/.tscn            # 持久化 HUD + 暂停/完成面板
```

## 运行

### 环境要求

- **Godot 4.6.3 (Mono)** — 虽用 GDScript，但开发环境为 Mono 版本

### 启动

1. 用 Godot 4.6.3 打开项目（首次会自动导入并注册全局类名）
2. **正式游戏**：运行 [scenes/main_menu.tscn](scenes/main_menu.tscn)
3. **测试场景**：运行 [tests/test_menu.tscn](tests/test_menu.tscn)，或按 F6 单独运行任一测试

### 控制方式

| 场景 | 操作 |
|------|------|
| 通用 | `Esc` 暂停 / `R` 重置当前关卡 |
| 平台跳跃 | `A`/`D` 或 `←`/`→` 移动，`Space` 跳跃 |
| 俯视角 | `W`/`A`/`S`/`D` 或方向键移动 |
| 拖拽 | 鼠标左键点击拖动，松手放下 |

## 测试场景

| 场景 | 验证内容 |
|------|---------|
| [test_draggable](tests/test_draggable.tscn) | 拖拽、悬停反馈、释放、重置 |
| [test_platformer](tests/test_platformer.tscn) | 移动/跳跃，实时显示 velocity/floor/coyote/buffer |
| [test_topdown](tests/test_topdown.tscn) | 八方向移动 + 墙壁碰撞 |
| [test_timer](tests/test_timer.tscn) | 正/倒计时、暂停/恢复、重置、tick/timed_out 信号 |
| [test_save](tests/test_save.tscn) | 方向感知最佳时间（正计时低者胜，倒计时高者胜） |
| [test_objective](tests/test_objective.tscn) | DragAllToZone + ReachGoal 双目标、幂等性 |
| [test_ninepatch](tests/test_ninepatch.tscn) | NinePatchRect 9-slice 切分演示，实时调整 patch margin + 尺寸 + 拉伸模式 |
| [test_menu](tests/test_menu.tscn) | 测试入口菜单，导航到上述 7 个场景 |

## 创建新关卡

项目提供了完整的关卡模板，可以快速创建新关卡。

### 快速开始

1. **复制关卡模板**：
   - 复制 `scenes/levels/level_template.gd` 为 `level_XX_name.gd`
   - 复制 `feature/core/objective/template_objective.gd` 为 `xx_objective.gd`

2. **修改关卡脚本**：
   ```gdscript
   # level_08_click_the_button.gd
   class_name Level08  # 改为你的关卡名
   extends BaseLevel

   func _build_level() -> void:
	   var objective := ClickButtonObjective.new()
	   add_child(objective)
   ```

3. **注册关卡元数据**（在 `scenes/levels/levels.json`）：
   ```json
   {
	   "id": "level_08_click_the_button",
	   "title": "Level 8 — Click the Button",
	   "subtitle": "Click the button to win.",
	   "timer_mode": "count_up",
	   "order": 80,
	   "record_time": true
   }
   ```

### 关卡模板文件

| 文件 | 用途 |
|------|------|
| [level_template.gd](scenes/levels/level_template.gd) | 关卡脚本模板，包含详细的创建步骤注释 |
| [template_objective.gd](feature/core/objective/template_objective.gd) | 目标类模板，展示如何实现胜利/失败条件 |

### 现有关卡目标类型

| 目标类 | 触发条件 | 适用场景 |
|--------|---------|---------|
| `ReachGoalObjective` | 玩家进入目标区域 | 平台跳跃、俯视角关卡 |
| `DragAllToZoneObjective` | N 个拖拽物全部放入 DropZone | 拖拽关卡 |
| `StopClockObjective` | 倒计时归零瞬间点击按钮（±0.25s 容差） | 精度挑战关卡 |

### 自定义目标类

继承 `LevelObjective` 并实现：
- `_ready()` — 初始化关卡元素（按钮、区域、物体等）
- 胜利条件检测 — 调用 `_complete()`
- 失败条件检测 — 调用 `_fail(reason)`
- （可选）`get_progress_ratio()` / `get_progress_text()` — 进度显示

### 关卡元数据字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✓ | 关卡唯一标识（对应脚本文件名） |
| `title` | string | ✓ | 关卡标题（如 "Level 1 — Stop the Clock"） |
| `subtitle` | string | | 关卡描述 |
| `timer_mode` | string | | `"count_up"` 或 `"count_down"`，默认正计时 |
| `time_limit` | float | | 倒计时限制（仅 `count_down` 有效） |
| `order` | int | ✓ | 关卡顺序（10, 20, 30...） |
| `record_time` | bool | | 是否记录通关时间，默认 `true` |

## 关键技术决策

- **单调时钟计时** — `Time.get_ticks_msec()` 而非累计 delta，跨暂停/恢复保持准确
- **Coyote Time + Jump Buffering** — 平台跳跃的专业手感标准
- **失败自动重载** — 1.2s 延迟让玩家看清失败原因，带 `failed_id` 快照防止切换关卡后误重载
- **HUD PROCESS_MODE_ALWAYS** — 暂停时菜单仍可交互
- **背景 Control `mouse_filter = IGNORE`** — 防止全屏 ColorRect/CenterContainer 拦截 Area2D 的 `input_event`
- **`_visual.scale` 而非 `scale`** — 拖拽视觉反馈只缩放 Polygon2D，不影响 CollisionShape2D，避免 DropZone 计数抖动
- **倒计时归零点击（Stop the Clock）** — `Area2D.input_event` 在 `LevelTimer._process` 之前处理，同帧点击归零先 `_complete()`，`timed_out` 因 `is_completed()` 为真而空转，零额外竞态处理

## 许可证

见 [LICENSE](LICENSE)。
