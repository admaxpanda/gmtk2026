# 关卡自动发现与选择场景 Spec

## Why
当前 [level_manager.gd](feature/core/autoload/level_manager.gd) 的 `LEVELS` 是硬编码常量数组，每新增一个关卡都要修改 autoload 源码、重排索引、补全元数据。这种中心化注册方式与"按场景即关卡"的直觉相悖，且容易遗漏字段。需要改为**运行时扫描 `scenes/levels/` 目录自动发现关卡**，让新增关卡只需"放一个 `.tscn` + 填好 @export 元数据"即可，无需触碰 LevelManager。

## What Changes
- **BaseLevel 增加元数据 @export 字段**：`title` / `subtitle` / `timer_mode` / `time_limit` / `order` / `thumbnail_path`，由关卡场景在 Inspector 中填写
- **LevelManager 改为运行时扫描**：启动时用 `DirAccess` 扫描 `res://scenes/levels/*.tscn`，用 `PackedScene.get_state()` **不实例化**读取根节点 @export 属性，构建运行时关卡列表（替代硬编码 `LEVELS` 常量）
- **新增 `LevelSelect` 场景**：独立的关卡选择界面（`scenes/level_select.tscn`），根据扫描结果动态生成关卡卡片网格，显示缩略图/标题/状态/最佳时间，支持锁定/解锁
- **main_menu 接入**："开始游戏"按钮跳转到 LevelSelect，LevelSelect 保留"返回主菜单"入口
- **迁移现有 3 个关卡**：把硬编码的元数据搬到各关卡场景的 @export
- **兼容 `generate-level-thumbnails` spec**：thumbnail 字段从"LEVELS 数组字段"演变为"BaseLevel @export 字段"，语义不变

## Impact
- Affected specs: `generate-level-thumbnails`（thumbnail 字段位置从 LEVELS 迁移到 BaseLevel @export，语义兼容）
- Affected code:
  - [feature/core/base_level.gd](feature/core/base_level.gd) — 新增元数据 @export 字段
  - [feature/core/autoload/level_manager.gd](feature/core/autoload/level_manager.gd) — 删除 `LEVELS` 常量，改为运行时扫描 + 缓存
  - [scenes/main_menu.gd](scenes/main_menu.gd) — "开始游戏"跳转目标改为 level_select
  - [scenes/levels/level_01_drag.tscn](scenes/levels/level_01_drag.tscn) / `level_02_platform.tscn` / `level_03_topdown.tscn` — 在 Inspector 填入元数据
- New code:
  - `scenes/level_select.gd` + `scenes/level_select.tscn` — 关卡选择场景
  - `tests/test_level_select.gd` + `tests/test_level_select.tscn` — 验证场景
- New constant: `LevelManager.LEVELS_DIR = "res://scenes/levels"`

## ADDED Requirements

### Requirement: 关卡元数据声明
BaseLevel SHALL 通过 `@export` 暴露以下关卡元数据字段，供关卡设计者在 Inspector 中填写：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | String | "Untitled Level" | 关卡显示名 |
| `subtitle` | String | "" | 副标题/提示 |
| `timer_mode` | String | "count_up" | "count_up" 或 "count_down" |
| `time_limit` | float | 0.0 | 倒计时时限（秒），仅 count_down 有效 |
| `order` | int | 100 | 排序权重，升序；同 order 按文件名字典序 |
| `thumbnail_path` | String | "" | 缩略图资源路径，空则用占位图 |

#### Scenario: 关卡填齐元数据
- **WHEN** 开发者在某关卡场景的 Inspector 中填写 title="Level 1 — Drag"、order=10、timer_mode="count_up"
- **THEN** LevelManager 扫描后该关卡以 title="Level 1 — Drag"、order=10 出现在列表第 1 位，LevelTimer 以 count_up 模式启动

#### Scenario: 关卡未填元数据
- **WHEN** 开发者新建关卡场景但未在 Inspector 填写任何元数据字段
- **THEN** LevelManager 用 @export 默认值填充（title="Untitled Level"、order=100、count_up），关卡仍可被发现和加载，push_warning 提示 title 为默认值

### Requirement: 关卡自动发现
LevelManager SHALL 在 `_ready()` 时扫描 `res://scenes/levels/` 目录下所有 `.tscn` 文件，构建运行时关卡注册表，替代原有的硬编码 `LEVELS` 常量。

#### Scenario: 正常扫描
- **WHEN** LevelManager 启动且 `res://scenes/levels/` 下存在 level_01_drag.tscn、level_02_platform.tscn、level_03_topdown.tscn
- **THEN** `get_level_ids()` 返回 3 个 id，按 order 升序排列（order 相同则按文件名字典序）

#### Scenario: 空目录
- **WHEN** `res://scenes/levels/` 下无 `.tscn` 文件
- **THEN** LevelManager push_error("No levels discovered")，`get_level_ids()` 返回空数组，`get_progress()` 返回 `{completed:0, total:0, ratio:0.0}`

#### Scenario: 非 BaseLevel 场景被跳过
- **WHEN** `res://scenes/levels/` 下存在一个根节点非 BaseLevel 的 `.tscn`（如误放的测试场景）
- **THEN** LevelManager push_warning("Skipping <path>: root is not BaseLevel")，不加入注册表，不影响其他关卡的发现

#### Scenario: 新增关卡无需改源码
- **WHEN** 开发者在 `res://scenes/levels/` 新建 level_04_puzzle.tscn（extends BaseLevel，填好元数据）
- **THEN** 无需修改 level_manager.gd，重启后 `get_level_ids()` 自动包含 "level_04_puzzle"

### Requirement: 元数据无实例化读取
LevelManager SHALL 使用 `PackedScene.get_state()` 读取关卡场景根节点的 @export 属性，**不实例化场景**，避免 `_ready` 副作用和性能开销。

#### Scenario: 读取 title
- **WHEN** LevelManager 扫描 level_02_platform.tscn
- **THEN** 通过 `load(path).get_state()` 读取根节点 "title" 属性值为 "Level 2 — Platformer"，场景的 `_ready`/`_build_level` 未被执行

#### Scenario: 属性缺失回退
- **WHEN** 某关卡场景的 .tscn 未保存某 @export 字段（Inspector 未修改，使用脚本默认值）
- **THEN** LevelManager 回退到 BaseLevel 脚本声明的默认值（如 title="Untitled Level"），不报错

### Requirement: LevelSelect 场景
系统 SHALL 提供独立的关卡选择场景 `scenes/level_select.tscn`，根据 LevelManager 的运行时注册表动态生成关卡卡片。

#### Scenario: 显示关卡列表
- **WHEN** 玩家从主菜单点击"开始游戏"进入 LevelSelect
- **THEN** 场景以网格布局显示所有已发现关卡卡片，每张卡片包含：缩略图（或占位图）、标题、副标题、计时模式标签、最佳时间（如有）、锁定/解锁状态

#### Scenario: 解锁关卡可进入
- **WHEN** 玩家点击已解锁关卡的卡片
- **THEN** 调用 `LevelManager.load_level(id)` 加载该关卡

#### Scenario: 锁定关卡不可进入
- **WHEN** 玩家点击锁定关卡的卡片
- **THEN** 卡片显示锁定遮罩，点击无效果（可选：播放禁用音效/抖动反馈）

#### Scenario: 显示最佳时间
- **WHEN** 某关卡有历史最佳时间记录
- **THEN** 卡片显示 "Best: MM:SS.ms"（count_up）或 "Best: MM:SS.ms remaining"（count_down），无记录则显示 "Best: —"

#### Scenario: 返回主菜单
- **WHEN** 玩家点击"返回"按钮或按 Esc
- **THEN** 跳转回 main_menu.tscn

### Requirement: 排序策略
LevelManager SHALL 按 `order` 字段升序排列关卡，相同 order 时按文件名（不含扩展名）字典序作为稳定 tiebreaker。

#### Scenario: order 不同
- **WHEN** level_03 的 order=30，level_01 的 order=10，level_02 的 order=20
- **THEN** 列表顺序为 [level_01, level_02, level_03]

#### Scenario: order 相同
- **WHEN** level_a 和 level_b 都设 order=100
- **THEN** 按 "level_a" < "level_b" 字典序排列

## MODIFIED Requirements

### Requirement: LevelManager 关卡注册表
LevelManager 不再持有硬编码 `LEVELS` 常量。改为：
- `const LEVELS_DIR: String = "res://scenes/levels"`
- `var _levels: Array` 运行时缓存，由 `_ready()` 中的 `_discover_levels()` 填充
- 所有现有查询方法（`get_level_ids` / `get_level_path` / `get_level_metadata` / `get_level_index` / `get_next_level_id` / `is_level_unlocked` / `get_progress`）改为读取 `_levels`，对外接口签名**不变**
- `load_level` / `reload_current` 从 `_levels` 中查 entry，timer_mode/time_limit 读取逻辑不变

### Requirement: main_menu 入口
main_menu 的"开始游戏"按钮 SHALL 跳转到 `res://scenes/level_select.tscn` 而非直接进入第一关。原有的关卡列表展示逻辑从 main_menu 移除（由 LevelSelect 承担）。

### Requirement: BaseLevel 元数据
BaseLevel SHALL 作为关卡元数据的唯一声明源。所有 extends BaseLevel 的关卡场景通过 Inspector 填写元数据，不再依赖外部注册表。

### Requirement: generate-level-thumbnails 兼容
原 `generate-level-thumbnails` spec 中的 thumbnail 字段位置从 `LevelManager.LEVELS` 数组迁移到 `BaseLevel.thumbnail_path` @export。ThumbnailGenerator 工具改为遍历 LevelManager 的运行时注册表（而非硬编码 LEVELS），其余行为不变。

## REMOVED Requirements

### Requirement: 硬编码 LEVELS 常量
**Reason**: 中心化注册与自动发现目标冲突，每次新增关卡需修改 autoload 源码。
**Migration**: 现有 3 个关卡的元数据（id/path/title/subtitle/timer_mode/time_limit）迁移到各自场景的 BaseLevel @export。id 从文件名推导（`level_01_drag.tscn` → `level_01_drag`），path 从扫描结果得到。
