# ShadowOfMask Godot UI

基于原 React + Canvas 项目转换的 Godot 4.x UI 场景文件。

## 文件结构

```
godot_ui/
├── Main.tscn           # 主场景，整合所有 UI
├── HUD.tscn            # 游戏进行时的 HUD
├── MenuOverlay.tscn    # 主菜单 + 游戏结束界面
├── LeaderboardItem.tscn # 排行榜条目模板（用于动态实例化）
├── Theme.tres          # 基础主题资源
└── README.md           # 本文件
```

## 场景层级说明

### Main.tscn
```
Main (Control)
├── GameBackground (ColorRect) - 黑色背景
├── GameArea (Node2D) - 游戏内容占位，未来放置玩家、敌人等
├── HUD (实例) - 游戏进行时显示
└── MenuOverlay (实例) - 菜单/结算时显示
```

### HUD.tscn
```
HUD (Control, mouse_filter=IGNORE)
├── TopBar (HBoxContainer) - 顶部信息栏
│   ├── ScoreSection - 左侧分数
│   │   ├── %ScoreValue (Label) - "0000"
│   │   └── ScoreLabel - 击杀数标签
│   ├── StageSection - 中间 Stage
│   │   └── %StageLabel (Label) - "STAGE 1"
│   └── %MaskSection - 右侧面具状态
│       ├── MaskRow
│       │   ├── %MaskStatus (Label) - "面具完整"/"面具破碎"
│       │   └── %MaskIcon (TextureRect) - 面具图标占位
│       ├── %ShatteredKills (Label) - "重塑所需: 0/3"
│       └── %FeverLabel (Label) - "FEVER"
├── %FeverBarContainer - Fever 进度条（独立定位）
│   ├── FeverBarBg
│   └── %FeverBarFill - 填充条
└── %TutorialHint - 底部教程提示
```

### MenuOverlay.tscn
```
MenuOverlay (Control)
├── OverlayBg (ColorRect) - 半透明黑色遮罩
└── CenterContent (CenterContainer)
    └── ContentVBox
        ├── TitleSection - 标题区域
        │   └── %MainTitle (Label) - "影之面具"
        ├── %MenuCard (PanelContainer) - 主菜单卡片
        │   └── MenuVBox
        │       ├── %StartButton - "开始潜行"
        │       ├── Divider
        │       ├── LeaderboardHeader
        │       └── %LeaderboardList - 排行榜列表容器
        └── %GameOverCard (PanelContainer) - 结算卡片 (visible=false)
            └── GameOverVBox
                ├── FailTitle - "任务失败"
                ├── FinalStats
                │   ├── %FinalStageValue
                │   └── %FinalKillsValue
                ├── %GameOverLeaderboardList
                ├── NameInputSection
                │   ├── %NameInput (LineEdit)
                │   └── %SaveButton
                └── ButtonRow
                    ├── %BackToMenuButton
                    └── %RetryButton
```

## 使用说明

### 1. 复制文件到 Godot 项目

将 `godot_ui/` 文件夹复制到你的 Godot 项目根目录。

### 2. 状态切换逻辑（GDScript 示例）

```gdscript
# 在 Main.gd 中
@onready var hud = %HUD
@onready var menu_overlay = %MenuOverlay
@onready var menu_card = %MenuCard
@onready var game_over_card = %GameOverCard

enum GamePhase { MENU, PLAYING, GAMEOVER }
var current_phase = GamePhase.MENU

func set_phase(phase: GamePhase):
    current_phase = phase
    match phase:
        GamePhase.MENU:
            hud.visible = false
            menu_overlay.visible = true
            menu_card.visible = true
            game_over_card.visible = false
        GamePhase.PLAYING:
            hud.visible = true
            menu_overlay.visible = false
        GamePhase.GAMEOVER:
            hud.visible = false
            menu_overlay.visible = true
            menu_card.visible = false
            game_over_card.visible = true
```

### 3. 更新 HUD 数据

```gdscript
# 更新分数
%ScoreValue.text = "%04d" % score

# 更新 Stage
%StageLabel.text = "STAGE %d" % stage

# 更新面具状态
if is_masked:
    %MaskStatus.text = "面具完整"
    %MaskStatus.modulate = Color.WHITE
    %ShatteredKills.visible = false
    %FeverLabel.visible = true
else:
    %MaskStatus.text = "面具破碎"
    %MaskStatus.modulate = Color.RED
    %ShatteredKills.visible = true
    %ShatteredKills.text = "重塑所需: %d/3" % shattered_kills
    %FeverLabel.visible = false

# 更新 Fever 条
%FeverBarContainer.visible = fever_meter > 0
%FeverBarFill.size.x = (fever_meter / 100.0) * fever_bar_max_width
```

### 4. 动态添加排行榜条目

```gdscript
const LeaderboardItemScene = preload("res://godot_ui/LeaderboardItem.tscn")

func populate_leaderboard(entries: Array):
    # 清空现有条目
    for child in %LeaderboardList.get_children():
        child.queue_free()
    
    # 添加新条目
    for i in range(entries.size()):
        var entry = entries[i]
        var item = LeaderboardItemScene.instantiate()
        %LeaderboardList.add_child(item)
        
        item.get_node("%RankBadge").text = str(i + 1)
        item.get_node("%PlayerName").text = entry.player_name
        item.get_node("%StageValue").text = "Stage %d" % entry.stage
        item.get_node("%KillsValue").text = "%d kills" % entry.kills
        
        # 设置排名徽章颜色
        var badge = item.get_node("%RankBadge")
        match i:
            0: badge.modulate = Color(1.0, 0.84, 0.0)  # 金色
            1: badge.modulate = Color(0.75, 0.75, 0.75)  # 银色
            2: badge.modulate = Color(0.8, 0.5, 0.2)  # 铜色
            _: badge.modulate = Color(0.4, 0.4, 0.4)
```

## 节点访问快捷方式

使用 `unique_name_in_owner = true` 的节点可以通过 `%NodeName` 快速访问：

| 节点路径 | 快捷访问 | 用途 |
|---------|---------|------|
| HUD/TopBar/ScoreSection/ScoreValue | `%ScoreValue` | 分数显示 |
| HUD/TopBar/StageSection/.../StageLabel | `%StageLabel` | Stage 显示 |
| HUD/TopBar/MaskSection | `%MaskSection` | 面具区域容器 |
| HUD/TopBar/MaskSection/MaskRow/MaskStatus | `%MaskStatus` | 面具状态文字 |
| HUD/TopBar/MaskSection/MaskRow/.../MaskIcon | `%MaskIcon` | 面具图标 |
| HUD/TopBar/MaskSection/ShatteredKills | `%ShatteredKills` | 重塑进度 |
| HUD/TopBar/MaskSection/FeverLabel | `%FeverLabel` | Fever 标签 |
| HUD/FeverBarContainer | `%FeverBarContainer` | Fever 条容器 |
| HUD/FeverBarContainer/FeverBarFill | `%FeverBarFill` | Fever 填充 |
| HUD/TutorialHint | `%TutorialHint` | 教程提示 |
| MenuOverlay/.../MainTitle | `%MainTitle` | 主标题 |
| MenuOverlay/.../MenuCard | `%MenuCard` | 主菜单卡片 |
| MenuOverlay/.../StartButton | `%StartButton` | 开始按钮 |
| MenuOverlay/.../LeaderboardList | `%LeaderboardList` | 排行榜列表 |
| MenuOverlay/.../GameOverCard | `%GameOverCard` | 结算卡片 |
| MenuOverlay/.../FinalStageValue | `%FinalStageValue` | 最终 Stage |
| MenuOverlay/.../FinalKillsValue | `%FinalKillsValue` | 最终击杀数 |
| MenuOverlay/.../GameOverLeaderboardList | `%GameOverLeaderboardList` | 结算排行榜 |
| MenuOverlay/.../NameInput | `%NameInput` | 玩家名输入框 |
| MenuOverlay/.../SaveButton | `%SaveButton` | 保存按钮 |
| MenuOverlay/.../BackToMenuButton | `%BackToMenuButton` | 返回按钮 |
| MenuOverlay/.../RetryButton | `%RetryButton` | 重试按钮 |

## 待实现功能

以下功能需要在 GDScript 中实现：

1. **GlitchText 效果** - 使用 Shader 或 AnimationPlayer 实现标题故障效果
2. **面具图标** - 需要导入面具贴图并设置到 `%MaskIcon`
3. **Fever 条动画** - 使用 Tween 实现填充动画和脉冲效果
4. **按钮信号连接** - 连接各按钮的 `pressed` 信号
5. **数据持久化** - 使用 `FileAccess` 或 `ConfigFile` 保存排行榜
6. **BGM 播放** - 添加 `AudioStreamPlayer` 节点

## 原项目对比

| 原组件 | Godot 实现 |
|--------|-----------|
| React State | GDScript 变量 + 信号 |
| Framer Motion | Tween / AnimationPlayer |
| localStorage | FileAccess / ConfigFile |
| Canvas 绘制 | Node2D + _draw() 或 Sprite2D |
| Tailwind CSS | Theme.tres + StyleBoxFlat |
| shadcn/ui | 自定义 Control 节点 |
