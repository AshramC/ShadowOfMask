# Findings & Decisions

## Requirements
- 验证 Godot 版本迁移进度。
- 判断 Godot 版与 Web 原版玩法是否一致。
- 检查文档中 Godot Phase 4 的迁移进度。

## Research Findings
- 已修复：面具破碎接触击杀补齐计分（与 Web 版一致）。
- 修复：`GameManager.gd`/`AssassinEnemy.gd` 的 enum 行拆分为多行，避免注释导致枚举项被吞。
- 修复：`LeaderboardManager.gd` 中排行榜结构体字段/排名比较函数被合并在同一行的问题。
- 修复：多处被拆行导致的“裸文本”行（Combo/Hit Stop 等）已改为注释，避免解析错误。
- 处理：`GameManager.gd` 内含大量乱码注释，已统一替换为英文占位注释（避免编码干扰）。
- 修复：脚本头部注释被拆行导致的裸文本（如 Godot/ScreenEffects 等）已统一改为注释，消除 Unexpected identifier/Unexpected ( 解析错误。
- 修复：批量拆分 `?func/?var` 与 `# ...? code` 形成的同一行注释/代码混写，避免函数与语句被注释导致解析错误。
- 修复：`GameManager.gd` 使用 backing fields（_score/_stage 等）实现属性 setter，解决 Properties can only have one setter。
- 修复：`AudioManager.gd` 中多处 `?func` 行导致作用域错乱，拆分后解决 stream 已声明错误。
- 修复：补齐多处 `get_viewport_rect()` 为 `get_viewport().get_visible_rect()`。
- 修复：为 `AssassinEnemy/RiftEnemy/SnareEnemy/PlayerRenderer/HUD/DebugPanel/CollisionManager` 等添加显式类型，消除类型推断错误。
- 修复：在 D:\Godot\shadow-of-mask\ShadowOfMask 新建 project.godot 并写入主场景与 Autoload 配置（GameManager/AudioManager/SettingsManager/LeaderboardManager）。
- 修复：复制 icon.svg 到项目根，确保 
es://icon.svg 可用。
- 修复：GameManager.gd 的 _generate_random_string 使用独立 RNG，去除 @GlobalScope 语法导致的解析错误。
- 修复：ScreenEffects.gd 用 dd_child + move_child 替代 dd_child_below_node。
- 修复：WaveManager.gd 使用 get_viewport().get_visible_rect() 取视口尺寸。
- 修复：AudioManager.gd 中 sfx_path 显式类型，避免类型推断失败。
- 已修复：基于 seed 的 RNG 已接入（GameManager RNG），并替换玩法相关随机调用；保证可复现随机。
- Godot 场景中已挂载渲染脚本：`Player.tscn` 包含 `PlayerRenderer` 与 `DashTrailRenderer`，`NormalEnemy.tscn` 包含 `EnemyRenderer`，说明视觉层已接入场景。
- 已补齐：Stage Toast（阶段提示弹出）在 HUD 中实现。
- 已补齐：Mark 强度已接入 `ScreenEffects` 背景效果。
- 已更新文档：SETUP_GUIDE.md 的 Phase 4 状态与清单已同步为“已实现”，保留“完整游戏测试”为待完成。
- 实际代码中已实现多项 Phase 4 视觉效果（粒子、震动、闪光、击杀文字、敌人渲染、裂隙门等），且存在敌人场景文件 `godot_ui/scenes/enemies/*.tscn`。
- Godot `RiftPortal.gd` 已实现 Rift 门生成/生命周期/小怪生成请求，符合 Phase 4 中“裂隙门场景”的实现项。
- Godot `PlayerRenderer.gd` 实现玩家渲染、无敌闪烁、Fever/面具状态与 Dash 视觉效果。
- Godot `DashIndicator.gd` 与 `FeverBarUI.gd` 已实现冲刺蓄力提示与 Fever UI 进度条，属于 Phase 4 视觉/UI 项。
- Godot `KillText.gd` 与 `ComboAnnouncement.gd` 已实现击杀文本与 Combo 公告显示，符合 Phase 4 视觉效果项。
- Godot `EnemyRenderer.gd` 实现各敌人类型的绘制与效果（精英血条、刺客蓄力/突进指示、Rift/ Snare 特效等），说明“敌人渲染”已实现。
- Godot `DashTrailRenderer.gd` 实现冲刺残影效果。
- Godot `ParticleEmitter.gd` 实现击杀/命中/面具破碎/Combo 等粒子效果；`ScreenEffects.gd` 实现屏幕震动、闪光、Fever 色调与闪烁，说明 Phase 4 中部分视觉效果已实现。
- Godot `HUD.gd` 通过 GameManager 信号更新分数/Stage/面具/FEVER，并包含教程提示与 Fever 脉冲动画，UI 功能与 Web 版一致。
- Godot `MenuOverlay.gd` 负责菜单与结算 UI、排行榜保存与高亮，逻辑与 Web 版菜单/结算流程一致；文件中存在中文乱码与字符串疑似截断（可能由编码问题导致）。
- Godot `MinionEnemy.gd` 定义为 Rift 召唤的高速小怪，追踪更积极、无 Burst，与 Web 版设定一致。
- Godot `LeaderboardManager.gd` 将排行榜持久化到 `user://leaderboard.json`，并按 Stage/Score 排序，与 Web 版 localStorage 排行榜逻辑一致。
- Godot `RiftEnemy.gd` 实现定期召唤 Rift（按冷却与随机半径生成），追踪行为与 Web 版一致。
- Godot `SnareEnemy.gd` 实现 SEEK/WINDUP/FIRE/RECOVER 状态与链条减速逻辑（含范围、蓄力、冷却），与 Web 版机制匹配。
- Godot `NormalEnemy.gd` 与 `EliteEnemy.gd` 仅定义基础参数（尺寸/血量/速度），精英有更低追踪/侧向强度，符合 Web 版“更慢但高血量/击退”的设定。
- Godot `EnemyBase.gd` 实现基础追踪/突进（burst）、血量、接触冷却、Fever 值等通用逻辑，与 Web 版的敌人通用行为对齐。
- Godot `AssassinEnemy.gd` 实现接近/蓄力/突进/恢复状态机与远距传送，参数与 Web 版一致（风格/触发阈值/冷却）。
- Godot `FeverSystem.gd` 实现 Fever 充能/激活/结束、面具破碎清空、延长时长等逻辑，并同步 GameManager 与音效，整体与 Web 版一致。
- Godot `CollisionManager.gd` 实现 Dash 线段-圆碰撞与非 Dash 接触判定，命中/击杀通过 Player 信号上报，接触使用 `enemy.can_contact_player()` 过滤。
- Godot `WaveManager.gd` 的波次逻辑与 Web 版一致：waveIndex 调整 normal/elite 数量与延迟刷怪；assassin 从 Stage 4、rift 从 Stage 6、snare 从 Stage 8；并包含 no-kill 惩罚机制与额外刷怪。
- Godot `ComboSystem.gd` 实现 Combo 计数、Mark 强度、屏幕震动、KillText、Impact Flash 与 Combo 公告，并提供 HitStop 触发接口，与 Web 版机制对齐。
- Godot `GameConstants.gd` 基本复刻 Web `GameCanvas.tsx` 的参数常量（敌人尺寸/速度/FEVER/Combo/波次/特效等），显示出对数值体系的迁移。
- Godot `Player.gd` 实现 WASD 移动、鼠标点按蓄力冲刺、Dash 轨迹、Snare 与 Fever 的速度/延迟倍率影响，并发出信号供系统联动。
- Web 版 Dash 触发击杀、Combo、HitStop、Fever 充能、面具破碎/恢复与特效触发逻辑在 `GameCanvas.tsx` 中集中处理。
- Web 版与敌人碰撞：若面具完整则破碎并进入无敌、清空 Fever；若已破碎再次碰撞则直接 GameOver；精英敌人可触发击退与接触冷却。
- Web 版 KillText/Announcement/Particles 等特效均在 Canvas 层实现（有独立更新/清理逻辑）。
- Web 版 `GameCanvas.tsx` 明确包含多种敌人类型（normal/elite/assassin/rift/snare/minion），并基于关卡阶段控制生成：assassin 从 Stage 4，rift 从 Stage 6，snare 从 Stage 8。
- Web 版波次生成使用 `spawnWave`，按 waveIndex 调整精英数量/普通数量与延迟刷怪，并以 `BASE_ENEMY_SPEED + stage * SPEED_PER_STAGE` 作为基础速度。
- Web 版核心状态包含：score/stage、combo、fever、mask 状态、dash 状态、no-kill 处罚机制等（见 `GameCanvas.tsx` 状态结构）。
- 新发现：当前 Godot 项目 `project.godot` 位于 `D:\Godot\shadow-of-mask\project.godot`，而代码与文档使用 `res://godot_ui/...`，要求项目根目录是 `D:\Godot\shadow-of-mask\ShadowOfMask`（否则路径需带 `res://ShadowOfMask/...`），因此会出现场景 preload 不存在的报错。
- 新发现：`project.godot` 未配置 Autoload（GameManager/AudioManager/SettingsManager/LeaderboardManager），导致大量 `Identifier "GameManager" not declared` 类报错级联。
- 新发现：`godot_ui/scripts/autoload/GameManager.gd` 第 319 行存在 `CHARS[@GlobalScope.randi() % CHARS.length()]`，`@GlobalScope` 在表达式中会触发语法解析错误（Expected expression after "["）。
- 新发现：`ScreenEffects.gd` 使用 `add_child_below_node()`，在 Godot 4.5.1 上提示方法不存在（需要替换为 `add_child` + `move_child` 或 `add_sibling`）。
- 新发现：`WaveManager.gd` 中 `get_viewport_rect()` 在当前基类上不可用（需改为 `get_viewport().get_visible_rect()` 或绑定到 CanvasItem/Node2D）。
- 新发现：`AudioManager.gd` 中 `var sfx_path := ...` 触发类型推断失败，需显式类型或改为 `var sfx_path = ...`。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 使用分阶段对照分析（Web vs Godot） | 便于系统性验证一致性与进度 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
|       |            |

## Resources
- task_plan.md
- findings.md
- progress.md
- client/src/components/GameCanvas.tsx
- godot_ui/scripts/SETUP_GUIDE.md
- godot_ui/scenes/Player.tscn
- godot_ui/scenes/enemies/NormalEnemy.tscn
- godot_ui/scenes/enemies/*.tscn
- godot_ui/scripts/game/GameConstants.gd
- godot_ui/scripts/game/GameWorld.gd
- godot_ui/scripts/game/Player.gd
- godot_ui/scripts/game/WaveManager.gd
- godot_ui/scripts/game/ComboSystem.gd
- godot_ui/scripts/game/FeverSystem.gd
- godot_ui/scripts/game/CollisionManager.gd
- godot_ui/scripts/game/EnemyBase.gd
- godot_ui/scripts/game/enemies/AssassinEnemy.gd
- godot_ui/scripts/game/enemies/NormalEnemy.gd
- godot_ui/scripts/game/enemies/EliteEnemy.gd
- godot_ui/scripts/game/enemies/RiftEnemy.gd
- godot_ui/scripts/game/enemies/SnareEnemy.gd
- godot_ui/scripts/game/enemies/MinionEnemy.gd
- godot_ui/scripts/autoload/GameManager.gd
- godot_ui/scripts/autoload/LeaderboardManager.gd
- godot_ui/scripts/ui/HUD.gd
- godot_ui/scripts/ui/MenuOverlay.gd
- godot_ui/scripts/effects/ParticleEmitter.gd
- godot_ui/scripts/effects/ScreenEffects.gd
- godot_ui/scripts/effects/EnemyRenderer.gd
- godot_ui/scripts/effects/DashTrailRenderer.gd
- godot_ui/scripts/effects/KillText.gd
- godot_ui/scripts/effects/ComboAnnouncement.gd
- godot_ui/scripts/effects/DashIndicator.gd
- godot_ui/scripts/effects/FeverBarUI.gd
- godot_ui/scripts/effects/RiftPortal.gd
- godot_ui/scripts/effects/PlayerRenderer.gd

## Visual/Browser Findings
- N/A
