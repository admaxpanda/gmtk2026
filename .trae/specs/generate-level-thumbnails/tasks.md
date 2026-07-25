# Tasks

- [x] Task 1: 修改 level_select.gd 实现运行时缩略图生成
  - [x] 1.1: 添加 `_thumbnail_cache` 字典
  - [x] 1.2: 将 `_make_thumbnail` 改为 async，使用 SubViewport 加载场景、等待 2 帧、截图、缩放至 320x180
  - [x] 1.3: 截图后立即释放 SubViewport 和场景实例
  - [x] 1.4: 将 `_populate_cards` 和 `_make_card` 改为 async（支持 await）
  - [x] 1.5: 提取 `_make_thumb_rect` 辅助方法
  - [x] 1.6: 未解锁关卡灰度化 modulate

- [x] Task 2: 清理不再需要的预生成缩略图代码
  - [x] 2.1: 从 base_level.gd 移除 `thumbnail_path` @export 和 get_metadata() 中的字段
  - [x] 2.2: 从 level_manager.gd 移除 `get_level_thumbnail` 方法和 `_discover_levels` 中的 thumbnail_path 读取
  - [x] 2.3: 删除 `thumbnail_generator.gd` 及其 .uid 文件
  - [x] 2.4: 删除 `assets/thumbnails/` 目录

# Task Dependencies
- Task 2 与 Task 1 无依赖，可并行执行
