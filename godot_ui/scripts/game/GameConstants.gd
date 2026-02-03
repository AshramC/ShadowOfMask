

class_name GameConstants
extends RefCounted

const PLAYER_SIZE := 20.0
const PLAYER_SPEED := 4.0
const PLAYER_INVULN_MS := 1000

const MIN_DASH_DELAY := 100
const MAX_DASH_DELAY := 1100
const DASH_DURATION := 200

const ENEMY_RADIUS := 10.0
const ELITE_ENEMY_RADIUS := 18.0
const ASSASSIN_RADIUS := 8.0
const MINION_RADIUS := 7.0
const RIFT_RADIUS := 14.0
const SNARE_RADIUS := 12.0

const ELITE_MAX_HP := 3
const RIFT_MAX_HP := 2
const SNARE_MAX_HP := 2

const BASE_ENEMY_SPEED := 0.9
const SPEED_PER_STAGE := 0.07
const ELITE_SPEED_MULT := 0.7
const ASSASSIN_SPEED_MULT := 1.0
const MINION_SPEED_MULT := 0.9
const RIFT_SPEED_MULT := 0.6
const SNARE_SPEED_MULT := 0.8

const ASSASSIN_DASH_SPEED_MULT := 4.2
const ASSASSIN_WINDUP_MS := 160
const ASSASSIN_DASH_MS := 320
const ASSASSIN_RECOVER_MS := 360
const ASSASSIN_COOLDOWN_MS := 1100
const ASSASSIN_TRIGGER_RANGE := 320.0
const ASSASSIN_TELEPORT_COOLDOWN_MS := 2400
const ASSASSIN_TELEPORT_TRIGGER_DISTANCE := 420.0
const ASSASSIN_TELEPORT_MIN_RADIUS := 120.0
const ASSASSIN_TELEPORT_MAX_RADIUS := 200.0
const ASSASSIN_ALPHA_STEALTH := 0.65
const ASSASSIN_ALPHA_ACTIVE := 1.0
const ASSASSIN_COLOR := Color("#c252ff")
const ASSASSIN_GLOW := Color(0.76, 0.32, 1.0, 0.9)
const ASSASSIN_OUTLINE := Color(0.12, 0.04, 0.24, 0.75)

const RIFT_CAST_COOLDOWN_MS := 2800
const RIFT_WARNING_MS := 420
const RIFT_DURATION_MS := 4200
const RIFT_SPAWN_INTERVAL_MS := 1000
const RIFT_SPAWN_MIN_RADIUS := 140.0
const RIFT_SPAWN_MAX_RADIUS := 240.0
const RIFT_MINION_BONUS_SPEED := 1.15
const RIFT_COLOR := Color("#4cc9ff")
const RIFT_GLOW := Color(0.3, 0.79, 1.0, 0.8)

const SNARE_RANGE := 280.0
const SNARE_WINDUP_MS := 300
const SNARE_FIRE_MS := 140
const SNARE_RECOVER_MS := 700
const SNARE_COOLDOWN_MS := 1900
const SNARE_SLOW_MS := 800
const SNARE_SLOW_MULT := 0.6
const SNARE_DASH_DELAY_MULT := 1.35
const SNARE_CHAIN_WIDTH := 18.0
const SNARE_COLOR := Color("#28d4b5")
const SNARE_GLOW := Color(0.16, 0.83, 0.71, 0.85)

const BURST_WAVE_DELAY := 600
const BURST_SPEED_MULT := 1.6
const BURST_DURATION := 260
const BURST_COOLDOWN_BASE := 2200
const BURST_COOLDOWN_VARIANCE := 1400

const ELITE_CONTACT_COOLDOWN := 650
const ELITE_KNOCKBACK_DISTANCE := 40.0

const COMBO_WINDOW_MS := 2000
const COMBO_THRESHOLDS := [1, 2, 3, 4, 6, 8]
const COMBO_HIT_STOP_MS := [50, 65, 80, 95, 110, 130]
const COMBO_SHAKE_MAGNITUDE := [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
const COMBO_BADGE_SCALE := [1.0, 1.15, 1.3, 1.45, 1.65, 1.85]
const COMBO_BADGE_COLOR := [
	Color("#cfd3d6"),
	Color("#f0f2f4"),
	Color("#ffffff"),
	Color("#ffe08a"),
	Color("#ffb347"),
	Color("#ff6b4a"),
]

const MARK_MAX := 6
const MARK_BG_ALPHA_MIN := 0.08
const MARK_BG_ALPHA_MAX := 0.28
const MARK_BG_TINT := Color(0.55, 0.08, 0.08)
const MARK_BG_LINE_ALPHA := 0.12

const KILL_TEXT_SIZES := [14, 16, 18, 21, 24, 28]
const KILL_TEXT_COLORS := [
	Color("#d1d5db"),
	Color("#f3f4f6"),
	Color("#fff3bf"),
	Color("#ffd166"),
	Color("#ff9f1c"),
	Color("#ff5c5c"),
]
const KILL_TEXT_POP_SCALE := [1.05, 1.08, 1.12, 1.18, 1.25, 1.32]
const KILL_TEXT_RISE := [0.9, 1.0, 1.1, 1.2, 1.35, 1.5]
const KILL_IMPACT_FLASH_DURATION := 160
const KILL_IMPACT_FLASH_ALPHA := 0.22

const BASE_HIT_STOP_MS := 80
const SCREEN_SHAKE_DURATION := 120

const MASK_FLASH_DURATION := 220
const MASK_FLASH_ALPHA := 0.55
const MASK_EMBLEM_BREAK_DURATION := 260
const MASK_EMBLEM_RESTORE_DURATION := 320
const MASK_EMBLEM_SIZE_RATIO := 0.7
const MASK_EMBLEM_ALPHA_BREAK := 0.75
const MASK_EMBLEM_ALPHA_RESTORE := 0.65
const MASK_RING_DURATION := 320
const MASK_RING_MAX_RADIUS_RATIO := 0.6
const MASK_RING_ALPHA := 0.55

const NO_KILL_LIMIT_BASE := 4000
const NO_KILL_LIMIT_MIN := 2200
const NO_KILL_LIMIT_DECAY := 120
const NO_KILL_EXTRA_SPAWN_COUNT := 4
const NO_KILL_ESCALATE_THRESHOLD := 2

const FEVER_METER_MAX := 100.0
const FEVER_DURATION_MS := 6500
const FEVER_SPEED_MULT := 1.6
const FEVER_DASH_DELAY_MULT := 0.35
const FEVER_GAIN_NORMAL := 6.0
const FEVER_GAIN_ELITE := 12.0
const FEVER_GAIN_COMBO_BONUS := 0.2
const FEVER_TINT_ALPHA := 0.18
const FEVER_FLASH_DURATION := 280
const FEVER_FLASH_ALPHA := 0.45

const WAVE_TRANSITION_DELAY := 900
const STAGE_TOAST_FADE_IN := 150
const STAGE_TOAST_HOLD := 350
const STAGE_TOAST_FADE_OUT := 300

const COLOR_NORMAL_ENEMY := Color("#ff0000")
const COLOR_ELITE_ENEMY := Color("#ff7a18")
const COLOR_MINION_ENEMY := Color("#ff5c5c")
const COLOR_PLAYER := Color("#ffffff")
const COLOR_TRAIL := Color(1.0, 1.0, 1.0, 0.5)

static func get_combo_level(combo_count: int) -> int:
	var level := 0
	for i in range(COMBO_THRESHOLDS.size()):
		if combo_count >= COMBO_THRESHOLDS[i]:
			level = i
		else:
			break
	return level

static func get_enemy_base_speed(stage: int) -> float:
	return BASE_ENEMY_SPEED + stage * SPEED_PER_STAGE

static func get_no_kill_limit(stage: int) -> int:
	return maxi(NO_KILL_LIMIT_MIN, NO_KILL_LIMIT_BASE - stage * NO_KILL_LIMIT_DECAY)

static func get_burst_cooldown_base(stage: int) -> int:
	return maxi(800, BURST_COOLDOWN_BASE - stage * 50)
