# Task Plan: 验证 Godot 迁移进度与玩法一致性

## Goal
验证 Godot 版本迁移进度、与 Web 原版玩法一致性，并核查文档中 Godot Phase 4 的迁移进度。

## Current Phase
Complete

## Phases

### Phase 1: Requirements & Discovery
- [x] 明确用户需求（进度验证/玩法一致性/Phase 4 进度）
- [x] 确定需要对比的关键玩法与系统
- [x] 在 findings.md 记录初始需求
- **Status:** complete

### Phase 2: Web 版玩法基线
- [x] 提取 Web 版核心玩法与系统（敌人/得分/面具/FEVER/Combo 等）
- [x] 记录关键机制与入口
- **Status:** complete

### Phase 3: Godot 版实现核查
- [x] 核查 Godot 关键脚本与场景实现
- [x] 对照 Web 版机制逐项比对
- **Status:** complete

### Phase 4: Phase 4 迁移进度核验
- [x] 对照 SETUP_GUIDE.md Phase 4 清单
- [x] 检查对应脚本/场景是否实现
- [x] 记录缺口
- **Status:** complete

### Phase 5: 结论与交付
- [x] 汇总一致性结论与差异清单
- [x] 交付中文结论
- **Status:** complete

## Key Questions
1. Web 版核心玩法与系统有哪些？
2. Godot 版是否已实现对应系统？差异在哪？
3. 文档 Phase 4 中哪些项已实现、哪些仍缺失？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 使用 planning-with-files 分阶段对比 | 任务涉及多模块与对照分析 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| 乱码导致注释/代码合并（enum/return/var 同行） | 1 | 拆分为多行并恢复缩进 |
| 乱码裸文本出现在代码块中 | 1 | 改为注释行 |
| 脚本头部注释被拆成裸文本（Godot/ScreenEffects等） | 1 | 统一在 extends 前加 # 注释 |
| 注释与代码同一行（?func/?var 或 #... ? code）导致函数被注释/缩进错误 | 1 | 批量拆分为独立行 |
| GameManager 属性 setter 递归导致报错 | 1 | 使用 backing fields 重写属性 |
| 多处 get_viewport_rect 不可用 | 1 | 统一改为 get_viewport().get_visible_rect() |
| 多处类型推断失败 | 1 | 明确声明变量类型 |
| project.godot 在父目录导致 res://godot_ui/... 路径失效 | 1 | 在仓库根创建 project.godot 并设置 main_scene/autoload |
| GameManager.gd 解析错误 (@GlobalScope) | 1 | 改用独立 RNG 生成字符串 |
| add_child_below_node 不存在 | 1 | 改为 add_child + move_child |
| WaveManager get_viewport_rect 不可用 | 1 | 改为 get_viewport().get_visible_rect() |
| AudioManager sfx_path 类型推断失败 | 1 | 显式声明 String |
|       | 1       |            |

## Notes
- 每 2 次查看/搜索操作后更新 findings.md
- 关键结论需基于代码/文档证据
