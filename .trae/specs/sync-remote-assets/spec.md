# Sync Remote Assets and Merge Code Fixes Spec

## Why
远程仓库有新的美术资源、音效和 UI 场景，本地有代码审查修复。两者分叉需要合并以避免工作丢失。

## What Changes
- 合并远程的资源文件（字体、图片、音效、场景）
- 解决代码冲突（pulley_objective.gd, pulley_platform.gd, sliding_panel.gd）
- 保留本地的代码修复（绳索动态更新、安全检查）
- 同步 .uid 文件

## Impact
- Affected specs: 无
- Affected code: 
  - feature/core/objective/pulley_objective.gd
  - feature/core/ui/pulley_platform.gd
  - feature/core/ui/sliding_panel.gd

## ADDED Requirements
### Requirement: 合并远程资源
系统应将远程仓库的美术资源、音效和 UI 场景合并到本地。

#### Scenario: 成功合并
- **WHEN** 执行 git pull
- **THEN** 资源文件正确下载到本地

### Requirement: 解决代码冲突
系统应在合并过程中解决代码冲突，保留本地修复。

#### Scenario: 冲突解决
- **WHEN** 检测到代码冲突
- **THEN** 手动解决冲突，保留本地修复的关键代码：
  - 绳索动态更新逻辑
  - 平台传感器安全检查

## MODIFIED Requirements
无

## REMOVED Requirements
无