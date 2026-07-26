# 关卡设计文档

本文档详细描述了 GMTK 2026 — Countdown 游戏中的所有关卡设计，包括机制、玩法、技术实现和可复用组件。

---

## 关卡概览

| 关卡 | 名称 | 核心机制 | 计时模式 | 时间限制 |
|------|------|---------|---------|---------|
| Level 1 | Stop the Clock | 点击按钮 | 倒计时 | 10s |
| Level 2 | Digit Drop | 拖动虚计时器 | 倒计时 | 11110s |
| Level 3 | Clear Path | 拖动方块 | 倒计时 | 45s |
| Level 4 | Negative Sign | 拖动负号 | 倒计时 | 10s |
| Level 5 | Pulley | 平台跳跃 | 倒计时 | 30s |

---

## Level 1 — Stop the Clock（停表）

### 基本信息

| 属性 | 值 |
|------|-----|
| **关卡 ID** | `level_07_stop_the_clock` |
| **机制** | 倒计时归零瞬间点击按钮 |
| **计时模式** | 10 秒倒计时 |
| **记录时间** | 否 |

### 玩法描述

- 屏幕中央有一个红色圆形按钮，上方显示 2 位小数倒计时
- 玩家需在倒计时归零（0.00）时点击按钮通关
- 点击过早或超时未点击则失败
- 右下角有装饰性回收站（非功能性）

### 交互流程

```
开始
  │
  ▼
倒计时开始（10.00 → 9.87 → ...）
  │
  ├── 点击过早 ──→ 失败（"Too early!"）
  │
  ├── 倒计时归零时点击 ──→ 成功
  │
  └── 超时未点击 ──→ 失败
```

### 技术实现

- **文件**: [feature/core/objective/stop_clock_objective.gd](feature/core/objective/stop_clock_objective.gd)
- **按钮**: `Area2D` + `CollisionShape2D`（圆形）+ `Polygon2D`（视觉）
- **倒计时显示**: `Label` 监听 `LevelTimer.tick` 信号
- **点击检测**: `Area2D.input_event` 信号处理
- **F6 支持**: 在 `_ready()` 中调用 `LevelManager.begin_dev_test()`

### 视觉元素

- 红色圆形按钮（半径 50px）
- 白色倒计时标签（2 位小数）
- 按钮悬停效果（缩放 1.05x）

---

## Level 2 — Digit Drop（数字丢弃）

### 基本信息

| 属性 | 值 |
|------|-----|
| **关卡 ID** | `level_02_digit_drop` |
| **机制** | 拖动虚计时器截断时间 |
| **计时模式** | 11110 秒倒计时 |
| **记录时间** | 否 |

### 玩法描述

- 左上角显示两个计时器：
  - **虚计时器**：显示高位数字（如 `1111`），可拖动
  - **主计时器**：显示个位数（如 `0`），固定
- 实际时间 = 虚计时器值 × 10 + 主计时器值
- 玩家可拖动虚计时器到右下角回收站
- 丢弃后，时间瞬间截断为个位数继续倒数
- 在显示 `0.00` 时点击按钮通关

### 交互流程

```
开始
  │
  ▼
双计时器显示（11110 秒）
  │
  ├── 等待完整倒计时（约 3 小时） ──→ 点击按钮通关
  │
  └── 拖动虚计时器到回收站
        │
        ▼
      时间截断为个位数（如 9 → 8 → ...）
        │
        └── 在 0.00 时点击按钮通关
```

### 技术实现

- **文件**: [feature/core/objective/digit_drop_objective.gd](feature/core/objective/digit_drop_objective.gd)
- **虚计时器**: `VirtualTimer` 类继承 `Area2D`，可拖动
- **回收站**: `TrashBin` 类继承 `Area2D`，检测拖入
- **时间分离**: `LevelTimer.get_high_digits()` 和 `get_units_digit()`
- **时间截断**: `LevelTimer.truncate_to_units()`
- **弹回逻辑**: 拖动到非回收站位置时，Tween 回到原位

### 视觉元素

- 虚计时器：深灰色背景，白色数字
- 主计时器：与 HUD 计时器样式一致
- 回收站：垃圾桶图标（🗑️）

---

## Level 3 — Clear Path（清路）

### 基本信息

| 属性 | 值 |
|------|-----|
| **关卡 ID** | `level_03_clear_path` |
| **机制** | 拖动方块移除遮挡，倒计时归零瞬间点击按钮通关 |
| **计时模式** | 45 秒倒计时 |
| **记录时间** | 否 |

### 玩法描述

- 屏幕中央有一个蓝色纸质方块，完全遮挡红色按钮
- 玩家需将方块拖入右下角回收站
- 方块消失后，按钮露出
- 在倒计时归零（0.00）时点击按钮通关（参照 Level 1 的停表机制）；过早点击或超时未点击则失败

### 交互流程

```
开始
  │
  ▼
按钮被蓝色方块遮挡，倒计时开始（45.00 → 44.xx → ...）
  │
  └── 拖动方块到回收站
        │
        ▼
      方块消失，按钮露出
        │
        ├── 倒计时归零时点击 ──→ 成功
        │
        ├── 过早点击（剩余时间偏离 0.00 超过 0.25s） ──→ 失败（"Too early!"）
        │
        └── 超时未点击 ──→ 失败
```

### 技术实现

- **文件**: [feature/core/objective/clear_path_objective.gd](feature/core/objective/clear_path_objective.gd)
- **纸质方块**: `PaperBlock` 类继承 `Area2D`，可拖动
- **回收站**: `TrashBin` 类（与 Level 2 共享）
- **遮挡逻辑**: 方块 `z_index` 高于按钮
- **消失动画**: 方块拖入回收站后 `queue_free()`

### 视觉元素

- 蓝色纸质方块（140×280 px）
- 红色按钮（被遮挡）
- 回收站（功能性）

---

## Level 4 — Negative Sign（负号）

### 基本信息

| 属性 | 值 |
|------|-----|
| **关卡 ID** | `level_04_negative_sign` |
| **机制** | 拖动负号切换显示模式 |
| **计时模式** | 10 秒倒计时 |
| **记录时间** | 否 |

### 玩法描述

- 按钮上方显示倒计时，前面有一个可拖动的蓝色负号（但数字本身不带符号）
- **有负号时**：计时器作为"骗局"正数递增（`1.00 → 2.23 → 3.45...`，从 1 开始）—— 数字正向变大
- **无负号时**：计时器恢复正常倒数（`10.00 → 8.77 → 6.55... → 0.00`），方向与有负号时相反
- 玩家可拖动负号到回收站，移除后数字**仅反转变化方向**（不重置为完整 10.00）
- 必须先移除负号，再在显示 `0.00` 时点击按钮通关

### 交互流程

```
开始
  │
  ▼
负号存在：数字正向递增（0 → 1 → 2...）
  │
  ├── 保持负号 ──→ 数字一直涨到 10.00，此时无法以"0.00"方式通关（必须移除负号）
  │
  └── 拖动负号到回收站
        │
        ▼
      负号消失：数字反向倒数（10 → 9 → 8... → 0），仅反转方向，不重置
        │
        └── 在 0.00 时点击按钮通关
```

### 技术实现

- **文件**: [feature/core/objective/negative_sign_objective.gd](feature/core/objective/negative_sign_objective.gd)
- **负号**: `NegativeSign` 类继承 `Area2D`，可拖动
- **显示模式**: `_is_negative_mode` 布尔值控制
- **时间计算**: `_elapsed_time` 累加经过时间
- **显示切换**: 移除负号后立即切换显示逻辑

### 视觉元素

- 蓝色负号（`−` 符号，大小 40px，可拖动对象，不在数字上加符号）
- 倒计时标签（纯数字，无符号）
- 回收站

---

## Level 5 — Pulley（滑轮）

### 基本信息

| 属性 | 值 |
|------|-----|
| **关卡 ID** | `level_05_pulley` |
| **机制** | 平台跳跃 + 滑轮物理 |
| **计时模式** | 30 秒倒计时 |
| **记录时间** | 否 |

### 玩法描述

- 玩家控制一个平台跳跃角色（青色方块）
- 屏幕右侧有一个滑动面板，遮挡住红色按钮
- 滑轮系统连接平台和面板：
  - 玩家跳上平台 → 平台下沉
  - 平台下沉 → 面板上升（滑轮原理）
- 当面板完全上升后，按钮露出
- 玩家从平台跳到按钮上触发通关

### 交互流程

```
开始
  │
  ▼
按钮被面板遮挡
  │
  └── 跳上滑轮平台
        │
        ▼
      平台下沉，面板上升
        │
        └── 按钮露出
              │
              └── 跳到按钮上通关
```

### 技术实现

- **文件**: [feature/core/objective/pulley_objective.gd](feature/core/objective/pulley_objective.gd)
- **平台**: `PulleyPlatform` 继承 `AnimatableBody2D`
  - 检测玩家站立（`Area2D` 传感器）
  - 玩家站上时下沉 200px
  - 发射 `moved(delta_y)` 信号
- **面板**: `SlidingPanel` 继承 `AnimatableBody2D`
  - 监听平台 `moved` 信号
  - 平台下沉 N 像素 → 面板上升 N 像素
- **绳索**: `Line2D` 动态更新端点
- **玩家**: `PlayerPlatformer` 类（Coyote Time + Jump Buffering）

### 视觉元素

- 滑轮（圆形，半径 20px）
- 绳索（棕色线条，宽度 3px）
- 平台（灰色矩形）
- 面板（深灰色矩形）
- 按钮（红色圆形）

### 关卡布局

```
┌──────────────────────────────────────────────┐
│         [滑轮]                                │
│         /     \                                │
│        /       \                               │
│       绳         绳                            │
│       │         │                              │
│       │      [面板]                            │
│       │      ┌──┐ ← 挡住按钮                   │
│       │      │  │                              │
│  [玩家]  [平台]  [按钮] (被面板挡住)            │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (地面)    │
└──────────────────────────────────────────────┘
```

---

## 可复用组件

### UI 组件

| 组件类 | 文件 | 用途 | 继承 |
|--------|------|------|------|
| `VirtualTimer` | [feature/core/ui/virtual_timer.gd](feature/core/ui/virtual_timer.gd) | 可拖动的计时器显示 | `Area2D` |
| `TrashBin` | [feature/core/ui/trash_bin.gd](feature/core/ui/trash_bin.gd) | 回收站区域 | `Area2D` |
| `PaperBlock` | [feature/core/ui/paper_block.gd](feature/core/ui/paper_block.gd) | 可拖动的遮挡物 | `Area2D` |
| `NegativeSign` | [feature/core/ui/negative_sign.gd](feature/core/ui/negative_sign.gd) | 可拖动的负号 | `Area2D` |
| `PulleyPlatform` | [feature/core/ui/pulley_platform.gd](feature/core/ui/pulley_platform.gd) | 滑轮平台 | `AnimatableBody2D` |
| `SlidingPanel` | [feature/core/ui/sliding_panel.gd](feature/core/ui/sliding_panel.gd) | 滑动面板 | `AnimatableBody2D` |

### 组件特性

#### VirtualTimer
- 显示高位数字
- 可拖动，拖到非回收站位置弹回
- 拖入回收站触发 `LevelTimer.truncate_to_units()`

#### TrashBin
- 支持 `is_functional` 开关
  - `true`：接收虚计时器/负号/方块
  - `false`：仅装饰（Level 1）
- 可自定义图标

#### PulleyPlatform
- 玩家站上时自动下沉
- 离开时回升
- 发射 `moved(delta_y)` 信号供面板联动
- 安全检查：防止玩家死亡后状态不同步

#### SlidingPanel
- 监听平台 `moved` 信号
- 反向移动（滑轮原理）
- 可配置最大上升距离

---

## 关卡机制总结

### 交互类型分布

| 关卡 | 核心交互 | UI 元素 | 物理系统 |
|------|---------|---------|---------|
| Level 1 | 点击 | 按钮、倒计时标签 | 无 |
| Level 2 | 拖拽 | 虚计时器、回收站 | 无 |
| Level 3 | 拖拽 | 纸质方块、回收站 | 无 |
| Level 4 | 拖拽 | 负号、回收站 | 无 |
| Level 5 | 平台跳跃 | 滑轮、绳索、面板 | CharacterBody2D + AnimatableBody2D |

### 难度曲线

```
难度
  ▲
  │                        Level 5 (★★★)
  │                      ↗
  │                 Level 4 (★★)
  │               ↗
  │          Level 3 (★)
  │        ↗
  │   Level 2 (★)
  │ ↗
  └─Level 1 (★)────────────────────────────▶ 关卡顺序
```

### 设计理念

1. **Level 1**：引入核心概念（点击按钮、倒计时）
2. **Level 2**：引入拖拽机制、时间操控
3. **Level 3**：引入遮挡移除、拖拽应用
4. **Level 4**：引入显示欺骗、时间认知
5. **Level 5**：引入物理交互、平台跳跃

---

## 扩展建议

### 新关卡方向

1. **多重遮挡**：需要按顺序移除多个方块
2. **时间加法**：多个负号，拖入不同组合产生不同效果
3. **移动平台**：滑轮平台可以水平移动
4. **合作机制**：两个玩家同时操作不同元素

### 可复用性

所有 UI 组件设计为独立类，可在新关卡中直接实例化：

```gdscript
# 快速创建回收站
var trash := TrashBin.new()
trash.position = Vector2(1800, 980)
add_child(trash)

# 快速创建可拖动方块
var block := PaperBlock.new()
block.position = Vector2(960, 540)
add_child(block)
```

---

## 技术决策记录

### 为什么使用 `AnimatableBody2D`？

- `AnimatableBody2D` 可以通过脚本移动，不受物理引擎影响
- 适合平台、门、电梯等"可移动但非玩家控制"的物体
- 与 `CharacterBody2D` 正确交互（玩家可以站在移动平台上）

### 为什么绳索动态更新？

- 绳索是视觉装饰，应反映物理状态
- 提升游戏真实感
- 成本低（每帧只更新 2 个端点）

### 为什么 Level 2 使用 11110 秒？

- 约等于 3 小时，足够玩家尝试拖拽机制
- 数字 `1111` 视觉上清晰易读
- 丢弃后瞬间变为个位数，对比强烈

---

**文档版本**: 2026-07-25  
**作者**: AI Assistant  
**项目**: GMTK 2026 — Countdown