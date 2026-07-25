# 关卡缩略图运行时生成 Spec

## Why
主菜单的关卡选择界面需要视觉预览。通过在运行时使用 SubViewport 加载关卡场景并截图，无需预生成 PNG 文件，缩略图始终与关卡最新状态同步。

## What Changes
- 修改 `level_select.gd` 的 `_make_thumbnail` 方法，改为通过 SubViewport 实时加载关卡场景截图
- 移除 `thumbnail_path` 属性（BaseLevel 和 LevelManager 中不再需要）
- 移除 `ThumbnailGenerator` 编辑器工具和 `assets/thumbnails/` 目录（运行时生成替代）
- 添加缩略图缓存机制（`_thumbnail_cache`），避免重复渲染

## Impact
- Affected code: `level_select.gd`（核心变更）、`base_level.gd`（移除 thumbnail_path）、`level_manager.gd`（移除 thumbnail_path 相关）
- Removed code: `thumbnail_generator.gd`、`assets/thumbnails/`

## ADDED Requirements

### Requirement: 运行时缩略图生成
系统 SHALL 在关卡选择界面打开时，通过 SubViewport 实时渲染每个关卡场景的首帧截图作为缩略图。

#### Scenario: 首次加载
- **WHEN** 玩家打开关卡选择界面
- **THEN** 系统逐个加载关卡 PackedScene 到 1280x720 SubViewport，等待 2 帧后截图，缩放至 320x180 保存为 ImageTexture 并缓存

#### Scenario: 缓存命中
- **WHEN** 缩略图已在 `_thumbnail_cache` 中存在（如 save_written 触发刷新）
- **THEN** 直接从缓存返回 ImageTexture，不重新渲染

#### Scenario: 场景加载失败
- **WHEN** 关卡场景路径无效或加载失败
- **THEN** 显示占位图（ColorRect，颜色根据解锁状态区分）

### Requirement: 未解锁关卡缩略图灰度化
- **WHEN** 关卡处于锁定状态
- **THEN** 缩略图 TextureRect 的 modulate 设为 `Color(0.5, 0.5, 0.5)`

## REMOVED Requirements

### Requirement: 预生成缩略图 PNG
**Reason**: 改为运行时生成，无需预生成步骤
**Migration**: 删除 ThumbnailGenerator 脚本和 assets/thumbnails/ 目录

### Requirement: thumbnail_path 属性
**Reason**: 不再需要手动指定缩略图路径，运行时从场景路径自动生成
**Migration**: 从 BaseLevel @export 和 LevelManager 注册表中移除
