# 修复：回收站功能失效 + 第二关虚计时器无法拖动

## 问题 1：回收站功能无法使用（影响 Level 2/3/4）
**根因**：三个可拖拽节点（`VirtualTimer`、`PaperBlock`、`NegativeSign`）在松手时通过 `get_overlapping_areas()` 判断是否落入 `TrashBin`。但三者创建时都是 `monitoring = false`、`collision_mask = 0`，而 `TrashBin` 是 `monitorable = false`。Godot 要求**拖拽方自身**处于 `monitoring` 且 mask 覆盖掉落区层、且回收站 `monitorable = true`，`get_overlapping_areas()` 才会返回回收站。结果检测永远为空 → 物体总是弹回，回收站逻辑从不触发（高亮因为 `TrashBin` 自身 `monitoring=true` 检测 draggable 而正常，所以"看起来有反应"）。

**修复**：
- `trash_bin.gd`：`monitorable = is_functional`（装饰性回收站仍不作为掉落目标）。
- `virtual_timer.gd` / `paper_block.gd` / `negative_sign.gd`：`collision_mask = 1 << 4`（掉落区层），`monitoring = true`，保留 `monitorable = true`。

## 问题 2：第二关虚计时器无法拖动
**根因**：`VirtualTimer` 用 `PanelContainer` + `Label`（Control 子树）绘制外观，默认 `mouse_filter = STOP` 拦截了鼠标输入，使 `Area2D.input_event` 拖拽回调永远不触发。`PaperBlock`/`NegativeSign` 使用 `Polygon2D`/`Line2D`（无 Control），因此只有虚计时器拖不动。这与项目 README 已记录的"背景 Control 需 `mouse_filter = IGNORE`"陷阱一致。

**修复**：`virtual_timer.gd` 的 `_build_ui()` 中给 `_panel` 和 `_label` 设置 `mouse_filter = Control.MOUSE_FILTER_IGNORE`，让拾取命中底层 `Area2D`。

## 涉及文件
- `feature/core/ui/trash_bin.gd`
- `feature/core/ui/virtual_timer.gd`
- `feature/core/ui/paper_block.gd`
- `feature/core/ui/negative_sign.gd`

## 验证要点
- `LevelTimer.truncate_to_units()` 与 `truncated_to_units` 信号均存在，虚计时器入箱后会正确截断时间。
- 建议在编辑器中 F6 单独运行 `level_02_digit_drop`、`level_03_clear_path`、`level_04_negative_sign` 验证拖入回收站生效。
- 已知设计行为（非 bug）：L2 在 units digit 为 0 时丢弃会立即归零失败。
