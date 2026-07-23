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

- **关卡管理** [feature/core/autoload/level_manager.gd](feature/core/autoload/level_manager.gd) — 关卡注册、解锁、进度追踪、失败后 0.6s 自动重载（带失败 ID 快照防误重载）
- **关卡基类** [feature/core/base_level.gd](feature/core/base_level.gd) — 自动发现 `LevelObjective` 子节点并桥接信号，超时默认触发失败
- **目标系统** [feature/core/objective/](feature/core/objective/)
  - `LevelObjective` 抽象基类（completed/failed/progress 信号，幂等触发）
  - `ReachGoalObjective` — 玩家进入目标区域即通关
  - `DragAllToZoneObjective` — N 个拖拽物全部放入 DropZone 即通关

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
│   │   ├── objective/         # LevelObjective + ReachGoal + DragAllToZone
│   │   ├── base_level.gd      # 关卡基类
│   │   └── scene_helpers.gd   # 测试场景共享工具
│   ├── drag/draggable.gd
│   ├── platformer/player_platformer.gd
│   └── topdown/player_topdown.gd
├── scenes/
│   ├── main_menu.gd/.tscn     # 关卡选择菜单（锁定/解锁、进度统计）
│   └── levels/
│       ├── level_01_drag.gd    # DragAllToZone + 正计时
│       ├── level_02_platform.gd # ReachGoal + 60s 倒计时
│       └── level_03_topdown.gd # ReachGoal + 45s 倒计时
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

## 关键技术决策

- **单调时钟计时** — `Time.get_ticks_msec()` 而非累计 delta，跨暂停/恢复保持准确
- **Coyote Time + Jump Buffering** — 平台跳跃的专业手感标准
- **失败自动重载** — 0.6s 延迟让玩家看清失败原因，带 `failed_id` 快照防止切换关卡后误重载
- **HUD PROCESS_MODE_ALWAYS** — 暂停时菜单仍可交互
- **背景 Control `mouse_filter = IGNORE`** — 防止全屏 ColorRect/CenterContainer 拦截 Area2D 的 `input_event`
- **`_visual.scale` 而非 `scale`** — 拖拽视觉反馈只缩放 Polygon2D，不影响 CollisionShape2D，避免 DropZone 计数抖动

## 许可证

见 [LICENSE](LICENSE)。
