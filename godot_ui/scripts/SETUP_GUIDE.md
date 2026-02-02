# ShadowOfMask Godot UI - 完整配置指南

## 📁 完整文件结构

```
godot_ui/
├── scripts/
│   ├── autoload/                    # 自动加载脚本 (全局单例)
│   │   ├── GameManager.gd           # 游戏状态管理器
│   │   ├── LeaderboardManager.gd    # 排行榜管理器
│   │   ├── AudioManager.gd          # 音频管理器 (BGM + 音效)
│   │   └── SettingsManager.gd       # 设置管理器
│   │
│   ├── game/                        # 游戏核心逻辑 (Phase 3)
│   │   ├── GameConstants.gd         # 游戏常量定义
│   │   ├── Player.gd                # 玩家控制器
│   │   ├── EnemyBase.gd             # 敌人基类
│   │   ├── WaveManager.gd           # 波次管理器
│   │   ├── ComboSystem.gd           # Combo 系统
│   │   ├── FeverSystem.gd           # Fever 系统
│   │   ├── CollisionManager.gd      # 碰撞管理器
│   │   ├── GameWorld.gd             # 游戏世界整合
│   │   │
│   │   └── enemies/                 # 敌人类型
│   │       ├── NormalEnemy.gd       # 普通敌人
│   │       ├── EliteEnemy.gd        # 精英敌人
│   │       ├── AssassinEnemy.gd     # 刺客敌人
│   │       ├── RiftEnemy.gd         # 裂隙敌人
│   │       ├── SnareEnemy.gd        # 束缚敌人
│   │       └── MinionEnemy.gd       # 小怪
│   │
│   └── ui/                          # UI 脚本
│       ├── Main.gd                  # 主场景控制
│       ├── HUD.gd                   # HUD 数据绑定
│       ├── MenuOverlay.gd           # 菜单交互
│       └── DebugPanel.gd            # 调试面板
│
├── Main.tscn                        # 主场景
├── HUD.tscn                         # HUD 场景
├── MenuOverlay.tscn                 # 菜单场景
├── DebugPanel.tscn                  # 调试面板场景
├── Theme.tres                       # 主题资源
└── assets/
    └── audio/                       # 音频资源目录
```

---

## 🔧 配置步骤

### 步骤 1: 配置 Autoload (自动加载)

**Project → Project Settings → Globals → Autoload**

按以下顺序添加脚本：

| 顺序 | 脚本路径 | 节点名称 |
|:---:|---------|---------|
| 1 | `res://godot_ui/scripts/autoload/GameManager.gd` | `GameManager` |
| 2 | `res://godot_ui/scripts/autoload/LeaderboardManager.gd` | `LeaderboardManager` |
| 3 | `res://godot_ui/scripts/autoload/SettingsManager.gd` | `SettingsManager` |
| 4 | `res://godot_ui/scripts/autoload/AudioManager.gd` | `AudioManager` |

> ⚠️ **重要**: 顺序很重要！GameManager 必须第一个加载

### 步骤 2: 设置主场景

**Project → Project Settings → Application → Run → Main Scene**
→ 设置为 `res://godot_ui/Main.tscn`

### 步骤 3: 配置输入映射 (可选)

**Project → Project Settings → Input Map**

添加以下动作：

| 动作名称 | 按键 |
|---------|------|
| `move_up` | W |
| `move_down` | S |
| `move_left` | A |
| `move_right` | D |

> 如果不配置，Player.gd 会使用内置的按键检测

---

## 📊 Phase 进度

### ✅ Phase 1: UI 框架层 - 完成
- GameManager.gd (游戏状态)
- LeaderboardManager.gd (排行榜)
- AudioManager.gd (音频)
- Main.gd, HUD.gd, MenuOverlay.gd (UI)

### ✅ Phase 2: 数据持久层 - 完成
- SettingsManager.gd (设置存储)
- AudioManager 音效增强
- DebugPanel.gd (调试工具)

### ✅ Phase 3: 游戏核心层 - 完成
- GameConstants.gd (150+ 游戏常量)
- Player.gd (移动、冲刺、碰撞)
- EnemyBase.gd (敌人基类)
- 6 种敌人类型脚本
- WaveManager.gd (波次生成)
- ComboSystem.gd (连击系统)
- FeverSystem.gd (狂热系统)
- CollisionManager.gd (碰撞检测)
- GameWorld.gd (系统整合)

### ✅ Phase 4: 视觉效果层 - 已实现
- [x] 粒子效果
- [x] 屏幕震动
- [x] 闪光效果
- [x] 击杀文字
- [x] 敌人渲染
- [x] 裂隙门场景

---

## 📋 API 速查

### GameConstants - 游戏常量

```gdscript
# 玩家
GameConstants.PLAYER_SIZE          # 20.0
GameConstants.PLAYER_SPEED         # 4.0
GameConstants.DASH_DURATION        # 200ms

# 敌人
GameConstants.ENEMY_RADIUS         # 10.0
GameConstants.ELITE_ENEMY_RADIUS   # 18.0
GameConstants.ASSASSIN_RADIUS      # 8.0

# Combo
GameConstants.COMBO_WINDOW_MS      # 2000ms
GameConstants.COMBO_THRESHOLDS     # [1, 2, 3, 4, 6, 8]

# Fever
GameConstants.FEVER_METER_MAX      # 100.0
GameConstants.FEVER_DURATION_MS    # 6500ms
GameConstants.FEVER_SPEED_MULT     # 1.6

# 辅助函数
GameConstants.get_combo_level(combo_count)  # 0-5
GameConstants.get_enemy_base_speed(stage)   # 基础速度
```

### Player - 玩家控制

```gdscript
# 状态查询
player.is_dashing()           # 是否正在冲刺
player.is_pending_dash()      # 是否正在蓄力
player.is_invulnerable()      # 是否无敌
player.is_snared()            # 是否被减速

# 状态修改
player.set_invulnerable(1000) # 设置 1 秒无敌
player.apply_snare(800)       # 应用 0.8 秒减速
player.knockback(dir, 40)     # 击退 40 像素

# 信号
player.dash_started           # (start_pos, end_pos)
player.dash_ended             # (kills_this_dash)
player.enemy_killed           # (enemy, kills_this_dash)
player.player_hit             # (by_enemy)
```

### WaveManager - 波次管理

```gdscript
# 方法
wave_manager.start_wave()                # 开始新波次
wave_manager.spawn_minion(position)      # 生成小怪
wave_manager.get_alive_enemy_count()     # 存活敌人数

# 信号
wave_manager.wave_started                # (wave_id, enemy_count)
wave_manager.wave_completed              # (wave_id)
wave_manager.enemy_spawned               # (enemy)
wave_manager.penalty_enemies_spawned     # (count)
```

### ComboSystem - Combo 系统

```gdscript
# 方法
combo_system.add_kills(count, pos, kills_this_dash)
combo_system.trigger_hit_stop(combo_level)
combo_system.get_combo_level()           # 0-5
combo_system.get_combo_count()           # 当前连击数
combo_system.get_mark_intensity()        # 0.0-1.0

# 信号
combo_system.combo_updated               # (count, level)
combo_system.screen_shake_requested      # (magnitude, duration)
combo_system.kill_text_requested         # (position, kills, level)
```

### FeverSystem - Fever 系统

```gdscript
# 方法
fever_system.add_fever(amount, combo_level)
fever_system.is_fever_active()
fever_system.get_fever_percent()         # 0-100
fever_system.get_fever_remaining_ratio() # 0.0-1.0
fever_system.on_mask_broken()            # 面具破碎时调用

# 信号
fever_system.fever_activated
fever_system.fever_deactivated
fever_system.fever_flash_requested       # ("in" 或 "out")
```

### EnemyBase - 敌人基类

```gdscript
# 属性
enemy.enemy_type                 # EnemyType 枚举
enemy.radius                     # 碰撞半径
enemy.hp / enemy.max_hp          # 生命值
enemy.is_active                  # 是否激活
enemy.is_spawned                 # 是否已生成

# 方法
enemy.take_damage(1, dash_id)    # 受到伤害，返回是否死亡
enemy.die()                      # 立即死亡
enemy.get_fever_value()          # Fever 能量值

# 信号
enemy.hit                        # (damage, by_player)
enemy.died                       # (enemy)
```

---

## 🎮 快速测试

1. 运行项目
2. 按 **F12** 打开调试面板
3. 使用调试面板测试：
   - **F1**: +Score
   - **F2**: +Stage
   - **F3**: 破碎面具
   - **F4**: +重塑击杀
   - **F5**: +Fever
   - **F6**: 游戏结束

---

## 🗂️ 敌人类型说明

| 类型 | 首次出现 | 特点 |
|------|---------|------|
| Normal | Stage 1 | 基础追踪，周期性突进 |
| Elite | Stage 3 | 高血量(3)，击退玩家，有接触冷却 |
| Assassin | Stage 4 | 隐身接近，蓄力突进，可传送 |
| Rift | Stage 6 | 召唤裂隙门生成小怪 |
| Snare | Stage 8 | 释放锁链减速玩家 |
| Minion | Stage 6+ | 由裂隙门召唤，快速追踪 |

---

## 📝 下一步 (Phase 4)

- [x] 创建敌人场景 (.tscn)
- [x] 实现粒子效果系统
- [x] 实现屏幕震动
- [x] 实现闪光效果
- [x] 实现击杀文字
- [x] 敌人视觉渲染
- [x] 裂隙门场景
- [x] 阶段提示（Stage Toast）
- [x] Mark 背景效果接入
- [x] Seed 随机性对齐
- [ ] 完整游戏测试
