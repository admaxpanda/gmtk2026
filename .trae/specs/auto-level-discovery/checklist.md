# Checklist

## 元数据声明
- [x] BaseLevel 暴露 6 个 @export 字段（title/subtitle/timer_mode/time_limit/order/thumbnail_path），Inspector 可见
- [x] `get_metadata()` 方法返回包含全部 6 字段的 Dictionary
- [x] 未填字段的关卡场景用 @export 默认值运行，不报错

## 关卡自动发现
- [x] `LevelManager.LEVELS` 常量已删除，改为 `var _levels` 运行时缓存
- [x] `_ready()` 调用 `_discover_levels()` 扫描 `res://scenes/levels/*.tscn`
- [x] `get_level_ids()` 返回 `["level_01_drag", "level_02_platform", "level_03_topdown"]`
- [x] 关卡按 `(order, filename)` 升序排列：level_01(order=10) < level_02(order=20) < level_03(order=30)
- [x] 空目录场景：push_error + 返回空数组（可通过临时清空目录或 mock 验证）
- [x] 非 BaseLevel 场景被跳过且 push_warning，不影响其他关卡
- [x] 元数据通过 `PackedScene.get_state()` 读取，**未实例化**场景（`_ready`/`_build_level` 未执行）

## 查询接口兼容性
- [x] `get_level_path(id)` 返回正确的 `res://scenes/levels/<id>.tscn`
- [x] `get_level_metadata(id)` 返回含 title/subtitle/timer_mode/time_limit/order/thumbnail_path 的字典
- [x] `get_level_index(id)` 返回正确序号（level_01=0, level_02=1, level_03=2）
- [x] `get_next_level_id()` 链式正确（01→02→03→""）
- [x] `is_level_unlocked(level_01)` 恒为 true（第一关）
- [x] `is_level_unlocked(level_02)` 依赖 level_01 完成状态
- [x] `get_progress()` 返回正确的 completed/total/ratio

## 加载与计时
- [x] `load_level(id)` 能正常加载 3 个关卡场景
- [x] `reload_current()` 重读 timer_mode/time_limit 并以正确模式重启 LevelTimer
- [x] level_01 以 count_up 启动，level_02 以 count_down(60s) 启动，level_03 以 count_down(45s) 启动
- [x] `complete_current_level` 正确写入存档（count_up 低者胜，count_down 高者胜）

## LevelSelect 场景
- [x] `scenes/level_select.tscn` 存在且根节点挂载 level_select.gd
- [x] 进入场景后显示 3 张关卡卡片，顺序与 LevelManager 一致
- [x] 每张卡片显示：缩略图（或占位色块）、title、subtitle、计时模式标签、最佳时间、Play 按钮
- [x] 解锁关卡点击 Play → `LevelManager.load_level(id)` 加载该关卡
- [x] 锁定关卡 Play 按钮 disabled + 灰色遮罩，点击无效果
- [x] 已通关关卡显示 "Best: MM:SS.ms"（无记录显示 "Best: —"）
- [x] "返回"按钮 + Esc 跳转回 main_menu.tscn
- [x] 监听 `SignalBus.save_written` 刷新最佳时间显示

## main_menu 接入
- [x] "开始游戏"按钮跳转到 `res://scenes/level_select.tscn`
- [x] main_menu 不再直接展示关卡列表（或已简化为纯入口菜单）
- [x] main_menu → level_select → 返回 main_menu 往返无异常

## 测试场景
- [x] `tests/test_level_select.tscn` 存在且 headless 加载无错
- [x] test_level_select 显示扫描结果（关卡数、id/path/title/order）
- [x] test_menu.gd 的 TESTS 数组包含 LevelSelect 入口
- [x] test_menu → test_level_select 往返无异常

## headless 全量验证
- [x] `Godot --headless --import` 成功注册所有类名
- [x] level_01_drag / level_02_platform / level_03_topdown 各自 headless 加载零错误
- [x] main_menu / level_select / test_level_select / test_menu 各自 headless 加载零错误
- [x] 全程无 ERROR / WARNING / SCRIPT ERROR

## 向后兼容与回归
- [x] 现有 3 个关卡的通关流程未受影响（能正常进入、完成、写存档）
- [x] HUD 显示的计时模式与关卡配置一致（level_01 正计时，level_02/03 倒计时）
- [x] 失败自动重载逻辑（fail_current_level + failed_id 快照）仍正常工作
- [x] generate-level-thumbnails spec 的 thumbnail 字段语义保持（位置迁移到 BaseLevel.thumbnail_path）
