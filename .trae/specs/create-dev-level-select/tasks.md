# Tasks

- [x] Task 1: 创建开发者关卡选择脚本
  - [x] SubTask 1.1: 创建 `tests/test_level_select_all_unlocked.gd` 脚本
  - [x] SubTask 1.2: 复用 level_select.gd 的 UI 构建逻辑（标题、进度标签、网格、返回按钮）
  - [x] SubTask 1.3: 修改卡片生成逻辑，强制所有关卡为解锁状态
  - [x] SubTask 1.4: 修改关卡加载逻辑，绕过 `is_level_unlocked` 检查

- [x] Task 2: 创建开发者关卡选择场景文件
  - [x] SubTask 2.1: 创建 `tests/test_level_select_all_unlocked.tscn` 场景
  - [x] SubTask 2.2: 场景根节点挂载对应脚本

# Task Dependencies
- [Task 2] 依赖 [Task 1] 完成