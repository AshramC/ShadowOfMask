import { useEffect, useRef, useCallback } from "react";
import seedrandom from "seedrandom";
import maskBgUrl from "../BG.png";
import maskBrokenUrl from "../BG_BROKEN.png";

const PLAYER_SIZE = 20;
const ENEMY_RADIUS = 10;
const ELITE_ENEMY_RADIUS = 18;
const ASSASSIN_RADIUS = 8;
const MINION_RADIUS = 7;
const RIFT_RADIUS = 14;
const SNARE_RADIUS = 12;
const ELITE_MAX_HP = 3;
const RIFT_MAX_HP = 2;
const SNARE_MAX_HP = 2;
const ELITE_SPEED_MULT = 0.7;
const ASSASSIN_SPEED_MULT = 1.0;
const MINION_SPEED_MULT = 0.9;
const RIFT_SPEED_MULT = 0.6;
const SNARE_SPEED_MULT = 0.8;
const ASSASSIN_DASH_SPEED_MULT = 4.2;
const ASSASSIN_WINDUP_MS = 160;
const ASSASSIN_DASH_MS = 320;
const ASSASSIN_RECOVER_MS = 360;
const ASSASSIN_COOLDOWN_MS = 1100;
const ASSASSIN_TRIGGER_RANGE = 320;
const ASSASSIN_TELEPORT_COOLDOWN_MS = 2400;
const ASSASSIN_TELEPORT_TRIGGER_DISTANCE = 420;
const ASSASSIN_TELEPORT_MIN_RADIUS = 120;
const ASSASSIN_TELEPORT_MAX_RADIUS = 200;
const RIFT_CAST_COOLDOWN_MS = 2800;
const RIFT_WARNING_MS = 420;
const RIFT_DURATION_MS = 4200;
const RIFT_SPAWN_INTERVAL_MS = 1000;
const RIFT_SPAWN_MIN_RADIUS = 140;
const RIFT_SPAWN_MAX_RADIUS = 240;
const RIFT_MINION_BONUS_SPEED = 1.15;
const SNARE_RANGE = 280;
const SNARE_WINDUP_MS = 300;
const SNARE_FIRE_MS = 140;
const SNARE_RECOVER_MS = 700;
const SNARE_COOLDOWN_MS = 1900;
const SNARE_SLOW_MS = 800;
const SNARE_SLOW_MULT = 0.6;
const SNARE_DASH_DELAY_MULT = 1.35;
const SNARE_CHAIN_WIDTH = 18;
const ASSASSIN_ALPHA_STEALTH = 0.65;
const ASSASSIN_ALPHA_ACTIVE = 1.0;
const ASSASSIN_COLOR = "#c252ff";
const ASSASSIN_GLOW = "rgba(194, 82, 255, 0.9)";
const ASSASSIN_OUTLINE = "rgba(30, 10, 60, 0.75)";
const RIFT_COLOR = "#4cc9ff";
const RIFT_GLOW = "rgba(76, 201, 255, 0.8)";
const SNARE_COLOR = "#28d4b5";
const SNARE_GLOW = "rgba(40, 212, 181, 0.85)";
const BASE_ENEMY_SPEED = 0.9;
const SPEED_PER_STAGE = 0.07;
const BURST_WAVE_DELAY = 600;
const BURST_SPEED_MULT = 1.6;
const BURST_DURATION = 260;
const BURST_COOLDOWN_BASE = 2200;
const BURST_COOLDOWN_VARIANCE = 1400;
const COMBO_WINDOW_MS = 2000;
const COMBO_THRESHOLDS = [1, 2, 3, 4, 6, 8];
const COMBO_HIT_STOP_MS = [50, 65, 80, 95, 110, 130];
const COMBO_SHAKE_MAGNITUDE = [2, 3, 4, 5, 6, 7];
const COMBO_BADGE_SCALE = [1, 1.15, 1.3, 1.45, 1.65, 1.85];
const COMBO_BADGE_COLOR = [
  "#cfd3d6",
  "#f0f2f4",
  "#ffffff",
  "#ffe08a",
  "#ffb347",
  "#ff6b4a",
];
const MARK_MAX = 6;
const MARK_BG_ALPHA_MIN = 0.08;
const MARK_BG_ALPHA_MAX = 0.28;
const MARK_BG_TINT = "140, 20, 20";
const MARK_BG_LINE_ALPHA = 0.12;
const KILL_TEXT_SIZES = [14, 16, 18, 21, 24, 28];
const KILL_TEXT_COLORS = [
  "#d1d5db",
  "#f3f4f6",
  "#fff3bf",
  "#ffd166",
  "#ff9f1c",
  "#ff5c5c",
];
const KILL_TEXT_POP_SCALE = [1.05, 1.08, 1.12, 1.18, 1.25, 1.32];
const KILL_TEXT_RISE = [0.9, 1.0, 1.1, 1.2, 1.35, 1.5];
const KILL_IMPACT_FLASH_DURATION = 160;
const KILL_IMPACT_FLASH_ALPHA = 0.22;
const BASE_HIT_STOP_MS = 80;
const SCREEN_SHAKE_DURATION = 120;
const MASK_FLASH_DURATION = 220;
const MASK_FLASH_ALPHA = 0.55;
const MASK_EMBLEM_BREAK_DURATION = 260;
const MASK_EMBLEM_RESTORE_DURATION = 320;
const MASK_EMBLEM_SIZE_RATIO = 0.7;
const MASK_EMBLEM_ALPHA_BREAK = 0.75;
const MASK_EMBLEM_ALPHA_RESTORE = 0.65;
const MASK_RING_DURATION = 320;
const MASK_RING_MAX_RADIUS_RATIO = 0.6;
const MASK_RING_ALPHA = 0.55;
const ELITE_CONTACT_COOLDOWN = 650;
const ELITE_KNOCKBACK_DISTANCE = 40;
const PLAYER_INVULN_MS = 1000;
const NO_KILL_LIMIT_BASE = 4000;
const NO_KILL_LIMIT_MIN = 2200;
const NO_KILL_LIMIT_DECAY = 120;
const NO_KILL_EXTRA_SPAWN_COUNT = 4;
const NO_KILL_ESCALATE_THRESHOLD = 2;
const FEVER_METER_MAX = 100;
const FEVER_DURATION_MS = 6500;
const FEVER_SPEED_MULT = 1.6;
const FEVER_DASH_DELAY_MULT = 0.35;
const FEVER_GAIN_NORMAL = 6;
const FEVER_GAIN_ELITE = 12;
const FEVER_GAIN_COMBO_BONUS = 0.2;
const FEVER_TINT_ALPHA = 0.18;
const FEVER_FLASH_DURATION = 280;
const FEVER_FLASH_ALPHA = 0.45;
const WAVE_TRANSITION_DELAY = 900;
const STAGE_TOAST_FADE_IN = 150;
const STAGE_TOAST_HOLD = 350;
const STAGE_TOAST_FADE_OUT = 300;
const PLAYER_SPEED = 4;
const MIN_DASH_DELAY = 100;
const MAX_DASH_DELAY = 1100;
const DASH_DURATION = 200;

interface Point {
  x: number;
  y: number;
}

interface Entity extends Point {
  active: boolean;
}

interface Enemy extends Entity {
  vx: number;
  vy: number;
  radius: number;
  hp: number;
  maxHp: number;
  type: "normal" | "elite" | "assassin" | "minion" | "rift" | "snare";
  spawned: boolean;
  spawnAt: number;
  flankSign: number;
  speed: number;
  nextBurstAt: number;
  burstUntil: number;
  nextTeleportAt: number;
  nextRiftAt: number;
  lastAssassinAttackAt: number;
  lastHitDashId: number;
  contactCooldownUntil: number;
  waveId: number;
  assassinState: "approach" | "windup" | "dash" | "recover";
  stateUntil: number;
  dashDx: number;
  dashDy: number;
  snareState: "seek" | "windup" | "fire" | "recover";
  snareUntil: number;
  snareDirX: number;
  snareDirY: number;
}

interface Particle extends Entity {
  vx: number;
  vy: number;
  life: number;
  color: string;
}

interface FloatingText extends Entity {
  text: string;
  color: string;
  life: number;
  vy: number;
  size: number;
}

interface KillText extends Entity {
  text: string;
  life: number;
  size: number;
  color: string;
  popLife: number;
  popScale: number;
  rise: number;
}

interface TrailSegment {
  x: number;
  y: number;
  life: number;
}

interface DashState {
  active: boolean;
  startTime: number;
  startPos: Point;
  endPos: Point;
  trail: TrailSegment[];
  pending: boolean;
  pendingStart: number;
  pendingTarget: Point;
  pendingDelay: number;
  killsThisDash: number;
  hitStopUsed: boolean;
  id: number;
}

interface Announcement {
  text: string;
  life: number;
  scale: number;
  color: string;
}

interface StageToast {
  text: string;
  startedAt: number;
}

interface MaskEffect {
  type: "break" | "restore";
  startedAt: number;
  origin: Point;
}

interface GameState {
  player: Point;
  playerName: string;
  enemies: Enemy[];
  rifts: Rift[];
  particles: Particle[];
  floatingTexts: FloatingText[];
  killTexts: KillText[];
  announcement: Announcement | null;
  stageToast: StageToast | null;
  score: number;
  stage: number;
  enemiesInWave: number;
  enemiesKilledInWave: number;
  waveComplete: boolean;
  waveStartAt: number;
  currentWaveId: number;
  lastKillAt: number;
  noKillStrikes: number;
  isMasked: boolean;
  shatteredKills: number;
  gameOver: boolean;
  gameTime: number;
  shakeUntil: number;
  shakeMagnitude: number;
  maskFlashUntil: number;
  maskFlashColor: string;
  impactFlashUntil: number;
  impactFlashColor: string;
  maskEffect: MaskEffect | null;
  rng: seedrandom.PRNG;
  hitStopUntil: number;
  comboCount: number;
  comboUntil: number;
  playerInvulnUntil: number;
  snareUntil: number;
  markCount: number;
  markIntensity: number;
  feverMeter: number;
  feverActive: boolean;
  feverUntil: number;
  feverFlashUntil: number;
  feverFlashType: "in" | "out" | null;
  keys: { [key: string]: boolean };
  dash: DashState;
}

interface Rift extends Entity {
  openAt: number;
  endAt: number;
  nextSpawnAt: number;
}

interface GameCanvasProps {
  seed: string;
  playerName: string;
  onGameOver: (score: number, stage: number) => void;
  onScoreUpdate: (
    score: number,
    isMasked: boolean,
    shatteredKills: number,
    stage: number,
    feverMeter: number,
    feverActive: boolean
  ) => void;
}

function dist(p1: Point, p2: Point): number {
  return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
}

function lineIntersectCircle(A: Point, B: Point, C: Point, radius: number): boolean {
  const dx = B.x - A.x;
  const dy = B.y - A.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) return dist(A, C) <= radius;

  let t = ((C.x - A.x) * dx + (C.y - A.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const closestX = A.x + t * dx;
  const closestY = A.y + t * dy;

  return dist({ x: closestX, y: closestY }, C) <= radius;
}

function distancePointToSegment(A: Point, B: Point, P: Point): number {
  const dx = B.x - A.x;
  const dy = B.y - A.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) return dist(A, P);

  let t = ((P.x - A.x) * dx + (P.y - A.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const closestX = A.x + t * dx;
  const closestY = A.y + t * dy;
  return dist({ x: closestX, y: closestY }, P);
}

function getComboLevel(comboCount: number): number {
  let level = 0;
  for (let i = 0; i < COMBO_THRESHOLDS.length; i++) {
    if (comboCount >= COMBO_THRESHOLDS[i]) {
      level = i;
    } else {
      break;
    }
  }
  return level;
}

function drawRoundedRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number
) {
  const r = Math.min(radius, width / 2, height / 2);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + width, y, x + width, y + height, r);
  ctx.arcTo(x + width, y + height, x, y + height, r);
  ctx.arcTo(x, y + height, x, y, r);
  ctx.arcTo(x, y, x + width, y, r);
  ctx.closePath();
}

function drawMaskEmblem(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  size: number,
  type: "break" | "restore",
  alpha: number,
  image?: HTMLImageElement | null,
  brokenImage?: HTMLImageElement | null
) {
  const half = size / 2;
  const top = -half * 0.9;
  const bottom = half * 0.95;
  ctx.save();
  ctx.translate(cx, cy);

  if (type === "break") {
    const jitter = (1 - alpha / MASK_EMBLEM_ALPHA_BREAK) * 8;
    ctx.translate((Math.random() - 0.5) * jitter, (Math.random() - 0.5) * jitter);
  }

  const stroke = type === "break" ? "rgba(255, 120, 90, 0.9)" : "rgba(230, 235, 240, 0.9)";
  ctx.globalAlpha = alpha;
  if (type === "break" && brokenImage && brokenImage.complete) {
    ctx.drawImage(brokenImage, -half, -half, size, size);
  } else if (image && image.complete) {
    ctx.drawImage(image, -half, -half, size, size);
  } else {
    ctx.strokeStyle = stroke;
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(-half * 0.6, top);
    ctx.quadraticCurveTo(0, top - half * 0.2, half * 0.6, top);
    ctx.quadraticCurveTo(half * 0.85, 0, half * 0.55, bottom * 0.6);
    ctx.lineTo(0, bottom);
    ctx.lineTo(-half * 0.55, bottom * 0.6);
    ctx.quadraticCurveTo(-half * 0.85, 0, -half * 0.6, top);
    ctx.closePath();
    ctx.stroke();
  }

  ctx.restore();
  ctx.globalAlpha = 1.0;
}

export function GameCanvas({ seed, playerName, onGameOver, onScoreUpdate }: GameCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number>();
  const stateRef = useRef<GameState | null>(null);
  const bgImageRef = useRef<HTMLImageElement | null>(null);
  const bgBrokenRef = useRef<HTMLImageElement | null>(null);

  const spawnWave = useCallback((state: GameState, w: number, h: number) => {
    const rng = state.rng;
    const now = Date.now();
    const waveIndex = (state.stage - 1) % 5;
    const waveId = state.stage;
    const baseCount = Math.round(4 + state.stage * 1.2);
    let normalCount = baseCount;
    let eliteCount = 0;
    let assassinCount = 0;
    let riftCount = 0;
    let snareCount = 0;

    if (waveIndex === 2) {
      eliteCount = 1;
    } else if (waveIndex === 3) {
      normalCount = Math.round(baseCount * 1.4);
    } else if (waveIndex === 4) {
      eliteCount = Math.min(3, 1 + Math.floor(state.stage / 5));
      normalCount = Math.max(2, Math.round(baseCount * 0.6));
    }

    if (state.stage >= 4) {
      assassinCount = Math.min(3, 1 + Math.floor((state.stage - 4) / 5));
      if (waveIndex === 3 && assassinCount > 1) {
        assassinCount = 1;
      }
    }

    if (state.stage >= 6) {
      riftCount = Math.min(2, 1 + Math.floor((state.stage - 6) / 5));
    }

    if (state.stage >= 8) {
      snareCount = Math.min(2, 1 + Math.floor((state.stage - 8) / 5));
    }

    const totalCount = normalCount + eliteCount + assassinCount + riftCount + snareCount;
    state.enemiesInWave = totalCount;
    state.enemiesKilledInWave = 0;
    state.waveComplete = false;

    const baseSpeed = BASE_ENEMY_SPEED + state.stage * SPEED_PER_STAGE;

    const spawnEnemy = (
      type: "normal" | "elite" | "assassin" | "minion" | "rift" | "snare",
      delayMs: number
    ) => {
      let x, y;
      if (rng() > 0.5) {
        x = rng() > 0.5 ? -20 : w + 20;
        y = rng() * h;
      } else {
        x = rng() * w;
        y = rng() > 0.5 ? -20 : h + 20;
      }

      const angle = Math.atan2(h / 2 - y, w / 2 - x) + (rng() - 0.5) * 0.5;
      const speed =
        type === "elite"
          ? baseSpeed * ELITE_SPEED_MULT
          : type === "assassin"
            ? baseSpeed * ASSASSIN_SPEED_MULT
            : type === "minion"
              ? baseSpeed * MINION_SPEED_MULT
              : type === "rift"
                ? baseSpeed * RIFT_SPEED_MULT
                : type === "snare"
                  ? baseSpeed * SNARE_SPEED_MULT
            : baseSpeed;
      const radius =
        type === "elite"
          ? ELITE_ENEMY_RADIUS
          : type === "assassin"
            ? ASSASSIN_RADIUS
            : type === "minion"
              ? MINION_RADIUS
              : type === "rift"
                ? RIFT_RADIUS
                : type === "snare"
                  ? SNARE_RADIUS
            : ENEMY_RADIUS;
      const maxHp =
        type === "elite"
          ? ELITE_MAX_HP
          : type === "rift"
            ? RIFT_MAX_HP
            : type === "snare"
              ? SNARE_MAX_HP
            : 1;
      const spawned = delayMs === 0;
      const nextBurstBase = Math.max(900, BURST_COOLDOWN_BASE - state.stage * 60);
      const nextBurstAt = now + nextBurstBase + rng() * BURST_COOLDOWN_VARIANCE;
      const nextTeleportAt =
        now +
        ASSASSIN_TELEPORT_COOLDOWN_MS *
          (0.7 + rng() * 0.6);
      const nextRiftAt =
        now +
        RIFT_CAST_COOLDOWN_MS *
          (0.7 + rng() * 0.6);

      state.enemies.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        active: spawned,
        radius,
        hp: maxHp,
        maxHp,
        type,
        spawned,
        spawnAt: now + delayMs,
        flankSign: rng() > 0.5 ? 1 : -1,
        speed,
        nextBurstAt,
        burstUntil: 0,
        nextTeleportAt,
        nextRiftAt,
        lastAssassinAttackAt: 0,
        lastHitDashId: -1,
        contactCooldownUntil: 0,
        waveId,
        assassinState: "approach",
        stateUntil: now + rng() * 400,
        dashDx: 0,
        dashDy: 0,
        snareState: "seek",
        snareUntil: now + rng() * 500,
        snareDirX: 0,
        snareDirY: 0,
      });
    };

    const burstSplit = waveIndex === 3 ? Math.floor(normalCount / 2) : normalCount;
    for (let i = 0; i < normalCount; i++) {
      const delay = waveIndex === 3 && i >= burstSplit ? BURST_WAVE_DELAY : 0;
      spawnEnemy("normal", delay);
    }
    for (let i = 0; i < eliteCount; i++) {
      spawnEnemy("elite", 0);
    }
    for (let i = 0; i < assassinCount; i++) {
      spawnEnemy("assassin", 0);
    }
    for (let i = 0; i < riftCount; i++) {
      spawnEnemy("rift", 0);
    }
    for (let i = 0; i < snareCount; i++) {
      spawnEnemy("snare", 0);
    }

    state.waveStartAt = now;
    state.currentWaveId = waveId;
  }, []);

  const initGame = useCallback(() => {
    if (!canvasRef.current) return;
    const width = canvasRef.current.width;
    const height = canvasRef.current.height;

    const rng = seedrandom(seed);

    const state: GameState = {
      player: { x: width / 2, y: height / 2 },
      playerName: playerName || "Player",
      enemies: [],
      rifts: [],
      particles: [],
      floatingTexts: [],
      killTexts: [],
      announcement: null,
      stageToast: null,
      score: 0,
      stage: 1,
      enemiesInWave: 0,
      enemiesKilledInWave: 0,
      waveComplete: false,
      waveStartAt: Date.now(),
      currentWaveId: 1,
      lastKillAt: Date.now(),
      noKillStrikes: 0,
      isMasked: true,
      shatteredKills: 0,
      gameOver: false,
      gameTime: 0,
      shakeUntil: 0,
      shakeMagnitude: 0,
      maskFlashUntil: 0,
      maskFlashColor: "255, 255, 255",
      impactFlashUntil: 0,
      impactFlashColor: "255, 200, 140",
      maskEffect: null,
      rng,
      hitStopUntil: 0,
      comboCount: 0,
      comboUntil: 0,
      playerInvulnUntil: 0,
      snareUntil: 0,
      markCount: 0,
      markIntensity: 0,
      feverMeter: 0,
      feverActive: false,
      feverUntil: 0,
      feverFlashUntil: 0,
      feverFlashType: null,
      keys: {},
      dash: {
        active: false,
        startTime: 0,
        startPos: { x: 0, y: 0 },
        endPos: { x: 0, y: 0 },
        trail: [],
        pending: false,
        pendingStart: 0,
        pendingTarget: { x: 0, y: 0 },
        pendingDelay: MIN_DASH_DELAY,
        killsThisDash: 0,
        hitStopUsed: false,
        id: 0,
      },
    };

    stateRef.current = state;
    spawnWave(state, width, height);
  }, [seed, playerName, spawnWave]);

  const spawnParticles = (x: number, y: number, color: string, count: number) => {
    if (!stateRef.current) return;
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 3 + 1;
      stateRef.current.particles.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 1.0,
        color,
        active: true,
      });
    }
  };

  const spawnMinion = (state: GameState, x: number, y: number) => {
    const now = Date.now();
    const baseSpeed = BASE_ENEMY_SPEED + state.stage * SPEED_PER_STAGE;
    const speed = baseSpeed * MINION_SPEED_MULT * RIFT_MINION_BONUS_SPEED;
    const angle =
      Math.atan2(state.player.y - y, state.player.x - x) + (state.rng() - 0.5) * 0.5;
    const nextBurstBase = Math.max(900, BURST_COOLDOWN_BASE - state.stage * 60);
    const nextBurstAt = now + nextBurstBase + state.rng() * BURST_COOLDOWN_VARIANCE;

    state.enemies.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      active: true,
      radius: MINION_RADIUS,
      hp: 1,
      maxHp: 1,
      type: "minion",
      spawned: true,
      spawnAt: now,
      flankSign: state.rng() > 0.5 ? 1 : -1,
      speed,
      nextBurstAt,
      burstUntil: 0,
      nextTeleportAt: now + ASSASSIN_TELEPORT_COOLDOWN_MS,
      nextRiftAt: now + RIFT_CAST_COOLDOWN_MS,
      lastAssassinAttackAt: 0,
      lastHitDashId: -1,
      contactCooldownUntil: 0,
      waveId: state.currentWaveId,
      assassinState: "approach",
      stateUntil: now + state.rng() * 400,
      dashDx: 0,
      dashDy: 0,
      snareState: "seek",
      snareUntil: now + state.rng() * 500,
      snareDirX: 0,
      snareDirY: 0,
    });
    state.enemiesInWave += 1;
  };

  const spawnRift = (state: GameState, w: number, h: number) => {
    const now = Date.now();
    const angle = state.rng() * Math.PI * 2;
    const radius =
      RIFT_SPAWN_MIN_RADIUS +
      state.rng() * (RIFT_SPAWN_MAX_RADIUS - RIFT_SPAWN_MIN_RADIUS);
    const targetX = state.player.x + Math.cos(angle) * radius;
    const targetY = state.player.y + Math.sin(angle) * radius;
    const x = Math.max(RIFT_RADIUS, Math.min(w - RIFT_RADIUS, targetX));
    const y = Math.max(RIFT_RADIUS, Math.min(h - RIFT_RADIUS, targetY));

    state.rifts.push({
      x,
      y,
      active: true,
      openAt: now + RIFT_WARNING_MS,
      endAt: now + RIFT_WARNING_MS + RIFT_DURATION_MS,
      nextSpawnAt: now + RIFT_WARNING_MS,
    });
  };

  const spawnPenaltyEnemies = (
    state: GameState,
    w: number,
    h: number,
    count: number
  ) => {
    const rng = state.rng;
    const now = Date.now();
    const baseSpeed = BASE_ENEMY_SPEED + state.stage * SPEED_PER_STAGE;
    for (let i = 0; i < count; i++) {
      let x, y;
      if (rng() > 0.5) {
        x = rng() > 0.5 ? -20 : w + 20;
        y = rng() * h;
      } else {
        x = rng() * w;
        y = rng() > 0.5 ? -20 : h + 20;
      }

      const angle = Math.atan2(h / 2 - y, w / 2 - x) + (rng() - 0.5) * 0.5;
      const speed = baseSpeed;
      const nextBurstBase = Math.max(900, BURST_COOLDOWN_BASE - state.stage * 60);
      const nextBurstAt = now + nextBurstBase + rng() * BURST_COOLDOWN_VARIANCE;

      state.enemies.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        active: true,
        radius: ENEMY_RADIUS,
        hp: 1,
        maxHp: 1,
        type: "normal",
        spawned: true,
        spawnAt: now,
        flankSign: rng() > 0.5 ? 1 : -1,
        speed,
        nextBurstAt,
        burstUntil: 0,
        nextTeleportAt: now + ASSASSIN_TELEPORT_COOLDOWN_MS,
        nextRiftAt: now + RIFT_CAST_COOLDOWN_MS,
        lastAssassinAttackAt: 0,
        lastHitDashId: -1,
        contactCooldownUntil: 0,
        waveId: state.currentWaveId,
        assassinState: "approach",
        stateUntil: now + rng() * 400,
        dashDx: 0,
        dashDy: 0,
        snareState: "seek",
        snareUntil: now + rng() * 500,
        snareDirX: 0,
        snareDirY: 0,
      });
    }
    state.enemiesInWave += count;
  };

  const spawnKillText = (x: number, y: number, killNumber: number, comboLevel: number) => {
    if (!stateRef.current) return;
    const text = killNumber === 1 ? "1 kill" : `${killNumber} kills`;
    stateRef.current.killTexts.push({
      x,
      y,
      text,
      life: 1.0,
      size: KILL_TEXT_SIZES[comboLevel],
      color: KILL_TEXT_COLORS[comboLevel],
      popLife: 1.0,
      popScale: KILL_TEXT_POP_SCALE[comboLevel],
      rise: KILL_TEXT_RISE[comboLevel],
      active: true,
    });
  };

  const showAnnouncement = (comboCount: number, comboLevel: number, markCount: number) => {
    if (!stateRef.current) return;
    const comboText = comboCount >= 8 ? "COMBO x8+" : `COMBO x${comboCount}`;
    const markText =
      markCount >= MARK_MAX ? "MARK MAX" : markCount > 0 ? `MARK ${markCount}` : "";
    const display = markText ? `${comboText} | ${markText}` : comboText;
    stateRef.current.announcement = {
      text: display,
      life: 1.0,
      scale: COMBO_BADGE_SCALE[comboLevel],
      color: COMBO_BADGE_COLOR[comboLevel],
    };
  };

  useEffect(() => {
    const img = new Image();
    img.src = maskBgUrl;
    bgImageRef.current = img;

    const broken = new Image();
    broken.src = maskBrokenUrl;
    bgBrokenRef.current = broken;
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const handleClick = (e: MouseEvent) => {
      const state = stateRef.current;
      if (!state || state.gameOver) return;
      if (state.dash.active || state.dash.pending) return;

      const rect = canvas.getBoundingClientRect();
      const targetX = e.clientX - rect.left;
      const targetY = e.clientY - rect.top;
      const dx = targetX - state.player.x;
      const dy = targetY - state.player.y;
      const distance = Math.hypot(dx, dy);
      const maxDistance = Math.max(1, Math.hypot(canvas.width, canvas.height));
      const ratio = Math.min(distance / maxDistance, 1);
      const baseDelay = MIN_DASH_DELAY + (MAX_DASH_DELAY - MIN_DASH_DELAY) * ratio;
      const snareMult = Date.now() < state.snareUntil ? SNARE_DASH_DELAY_MULT : 1;
      const pendingDelay =
        baseDelay * (state.feverActive ? FEVER_DASH_DELAY_MULT : 1) * snareMult;

      state.dash.pending = true;
      state.dash.pendingStart = Date.now();
      state.dash.pendingTarget = { x: targetX, y: targetY };
      state.dash.pendingDelay = pendingDelay;
      state.dash.killsThisDash = 0;
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      const state = stateRef.current;
      if (!state) return;
      state.keys[e.key.toLowerCase()] = true;
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      const state = stateRef.current;
      if (!state) return;
      state.keys[e.key.toLowerCase()] = false;
    };

    canvas.addEventListener("mousedown", handleClick);
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("keyup", handleKeyUp);
    return () => {
      canvas.removeEventListener("mousedown", handleClick);
      window.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("keyup", handleKeyUp);
    };
  }, [onScoreUpdate]);

  const update = useCallback(
    (timestamp: number) => {
      const state = stateRef.current;
      const canvas = canvasRef.current;

      if (!state || !canvas) return;

      const now = Date.now();
      if (now < state.hitStopUntil) {
        draw(canvas, state);
        requestRef.current = requestAnimationFrame(update);
        return;
      }

      if (state.feverActive && now > state.feverUntil) {
        state.feverActive = false;
        state.feverMeter = 0;
        state.feverUntil = 0;
        state.feverFlashUntil = now + FEVER_FLASH_DURATION;
        state.feverFlashType = "out";
        onScoreUpdate(
          state.score,
          state.isMasked,
          state.shatteredKills,
          state.stage,
          state.feverMeter,
          state.feverActive
        );
      }

      if (state.gameOver) {
        draw(canvas, state);
        requestRef.current = requestAnimationFrame(update);
        return;
      }

      const width = canvas.width;
      const height = canvas.height;

      if (now > state.comboUntil) {
        state.comboCount = 0;
        state.markCount = 0;
      }
      const markTarget = Math.min(state.markCount / MARK_MAX, 1);
      const markLerp = markTarget > state.markIntensity ? 0.12 : 0.2;
      state.markIntensity += (markTarget - state.markIntensity) * markLerp;
      if (state.markIntensity < 0.002) state.markIntensity = 0;

      state.enemies.forEach((enemy) => {
        if (!enemy.spawned && now >= enemy.spawnAt) {
          enemy.spawned = true;
          enemy.active = true;
        }
      });

      // Check wave complete / no-kill pressure
      if (!state.waveComplete) {
        const currentWaveEnemies = state.enemies.filter(
          (e) => e.waveId === state.currentWaveId
        );
        const allEnemiesOnScreen = currentWaveEnemies.every(
          (e) =>
            !e.spawned ||
            !e.active ||
            (e.x >= 0 && e.x <= width && e.y >= 0 && e.y <= height)
        );
        const allEnemiesDead = currentWaveEnemies.every(
          (e) => !e.active && e.spawned
        );
        const spawnedWaveReady =
          currentWaveEnemies.length > 0 &&
          currentWaveEnemies.every((e) => e.spawned);
        const noKillLimit = Math.max(
          NO_KILL_LIMIT_MIN,
          NO_KILL_LIMIT_BASE - state.stage * NO_KILL_LIMIT_DECAY
        );
        const noKillTimedOut =
          spawnedWaveReady && now - state.lastKillAt >= noKillLimit;

        if (allEnemiesOnScreen && allEnemiesDead && currentWaveEnemies.length > 0) {
          state.waveComplete = true;
          state.stage++;
          state.noKillStrikes = 0;
          state.stageToast = {
            text: `STAGE ${state.stage}`,
            startedAt: now,
          };

          setTimeout(() => {
            if (stateRef.current && !stateRef.current.gameOver) {
              spawnWave(stateRef.current, width, height);
            }
          }, WAVE_TRANSITION_DELAY);

          onScoreUpdate(
            state.score,
            state.isMasked,
            state.shatteredKills,
            state.stage,
            state.feverMeter,
            state.feverActive
          );
        } else if (noKillTimedOut) {
          if (state.noKillStrikes + 1 < NO_KILL_ESCALATE_THRESHOLD) {
            state.noKillStrikes += 1;
            spawnPenaltyEnemies(state, width, height, NO_KILL_EXTRA_SPAWN_COUNT);
            state.lastKillAt = now;
          } else {
            state.waveComplete = true;
            state.stage++;
            state.noKillStrikes = 0;
            state.stageToast = {
              text: `STAGE ${state.stage}`,
              startedAt: now,
            };
            state.lastKillAt = now;

            setTimeout(() => {
              if (stateRef.current && !stateRef.current.gameOver) {
                spawnWave(stateRef.current, width, height);
              }
            }, WAVE_TRANSITION_DELAY);

            onScoreUpdate(
              state.score,
              state.isMasked,
              state.shatteredKills,
              state.stage,
              state.feverMeter,
              state.feverActive
            );
          }
        }
      }

      if (state.stageToast) {
        const total =
          STAGE_TOAST_FADE_IN + STAGE_TOAST_HOLD + STAGE_TOAST_FADE_OUT;
        if (now - state.stageToast.startedAt > total) {
          state.stageToast = null;
        }
      }

      if (state.maskEffect) {
        const duration =
          state.maskEffect.type === "break"
            ? MASK_EMBLEM_BREAK_DURATION
            : MASK_EMBLEM_RESTORE_DURATION;
        if (now - state.maskEffect.startedAt > duration) {
          state.maskEffect = null;
        }
      }

      // WASD Movement
      let moveX = 0;
      let moveY = 0;
      if (state.keys["w"]) moveY -= 1;
      if (state.keys["s"]) moveY += 1;
      if (state.keys["a"]) moveX -= 1;
      if (state.keys["d"]) moveX += 1;

      if (moveX !== 0 || moveY !== 0) {
        const len = Math.sqrt(moveX * moveX + moveY * moveY);
        const snareMult = now < state.snareUntil ? SNARE_SLOW_MULT : 1;
        const speed =
          PLAYER_SPEED * (state.feverActive ? FEVER_SPEED_MULT : 1) * snareMult;
        moveX = (moveX / len) * speed;
        moveY = (moveY / len) * speed;
        state.player.x = Math.max(PLAYER_SIZE / 2, Math.min(width - PLAYER_SIZE / 2, state.player.x + moveX));
        state.player.y = Math.max(PLAYER_SIZE / 2, Math.min(height - PLAYER_SIZE / 2, state.player.y + moveY));
      }

      // Pending Dash (delay scales with distance)
      if (state.dash.pending && !state.dash.active) {
        const elapsed = Date.now() - state.dash.pendingStart;
        if (elapsed >= state.dash.pendingDelay) {
          state.dash.active = true;
          state.dash.pending = false;
          state.dash.startTime = Date.now();
          state.dash.startPos = { ...state.player };
          state.dash.endPos = { ...state.dash.pendingTarget };
          state.dash.trail = [];
          state.dash.killsThisDash = 0;
          state.dash.hitStopUsed = false;
          state.dash.id += 1;
        }
      }

      // Active Dash with afterimages
      let skipCollisionThisFrame = false;
      if (state.dash.active) {
        const elapsed = Date.now() - state.dash.startTime;
        const progress = Math.min(elapsed / DASH_DURATION, 1);

        const prevPos = { ...state.player };
        state.player.x = state.dash.startPos.x + (state.dash.endPos.x - state.dash.startPos.x) * progress;
        state.player.y = state.dash.startPos.y + (state.dash.endPos.y - state.dash.startPos.y) * progress;

        state.dash.trail.push({
          x: state.player.x,
          y: state.player.y,
          life: 1.0,
        });

        // Check collision during dash movement
        let killCount = 0;
        let feverGain = 0;
        state.enemies.forEach((enemy) => {
          if (!enemy.active) return;
          if (lineIntersectCircle(prevPos, state.player, enemy, enemy.radius + PLAYER_SIZE / 2)) {
            if (enemy.lastHitDashId === state.dash.id) return;
            enemy.lastHitDashId = state.dash.id;
            enemy.hp -= 1;

            const hitColor =
              enemy.type === "elite"
                ? "#ff9933"
                : enemy.type === "assassin"
                  ? ASSASSIN_COLOR
                  : enemy.type === "rift"
                    ? RIFT_COLOR
                    : enemy.type === "snare"
                      ? SNARE_COLOR
                      : enemy.type === "minion"
                        ? "#ff5c5c"
                        : "#ff0000";
            spawnParticles(enemy.x, enemy.y, hitColor, 10);

            if (enemy.hp <= 0) {
              enemy.active = false;
              state.dash.killsThisDash++;
              killCount++;
              state.score++;
              state.enemiesKilledInWave++;
              state.lastKillAt = now;
              state.noKillStrikes = 0;
              feverGain += enemy.type === "elite" ? FEVER_GAIN_ELITE : FEVER_GAIN_NORMAL;
              spawnParticles(enemy.x, enemy.y, "#ff0000", 15);
              const projectedCombo = Math.max(
                state.comboCount + 1,
                state.dash.killsThisDash
              );
              const textComboLevel = getComboLevel(projectedCombo);
              spawnKillText(
                enemy.x,
                enemy.y,
                state.dash.killsThisDash,
                textComboLevel
              );
            }
          }
        });

        if (killCount > 0) {
          skipCollisionThisFrame = true;
          if (now > state.comboUntil) {
            state.comboCount = killCount;
          } else {
            state.comboCount += killCount;
          }
          state.comboUntil = now + COMBO_WINDOW_MS;
          state.markCount = Math.min(MARK_MAX, state.markCount + killCount);

          const comboLevel = getComboLevel(state.comboCount);
          state.shakeUntil = now + SCREEN_SHAKE_DURATION;
          state.shakeMagnitude = COMBO_SHAKE_MAGNITUDE[comboLevel];

          if (state.isMasked && !state.feverActive) {
            const comboBonus = 1 + comboLevel * FEVER_GAIN_COMBO_BONUS;
            state.feverMeter = Math.min(
              FEVER_METER_MAX,
              state.feverMeter + feverGain * comboBonus
            );
            if (state.feverMeter >= FEVER_METER_MAX) {
              state.feverActive = true;
              state.feverUntil = now + FEVER_DURATION_MS;
              state.feverMeter = FEVER_METER_MAX;
              state.feverFlashUntil = now + FEVER_FLASH_DURATION;
              state.feverFlashType = "in";
            }
          }

          if (comboLevel >= 3) {
            state.impactFlashUntil = now + KILL_IMPACT_FLASH_DURATION;
            state.impactFlashColor =
              comboLevel >= 5 ? "255, 120, 90" : "255, 200, 140";
            const extraCount = 6 + comboLevel * 4 + killCount * 2;
            spawnParticles(
              state.player.x,
              state.player.y,
              comboLevel >= 5 ? "#ff6b4a" : "#ffd166",
              extraCount
            );
          }

          if (!state.dash.hitStopUsed) {
            state.hitStopUntil = Math.max(
              state.hitStopUntil,
              now + COMBO_HIT_STOP_MS[comboLevel]
            );
            state.dash.hitStopUsed = true;
          }

          showAnnouncement(state.comboCount, comboLevel, state.markCount);

          if (!state.isMasked) {
            state.shatteredKills += killCount;
            if (state.shatteredKills >= 3) {
              state.isMasked = true;
              state.shatteredKills = 0;
              state.maskFlashUntil = Date.now() + MASK_FLASH_DURATION;
              state.maskFlashColor = "255, 255, 255";
              state.maskEffect = {
                type: "restore",
                startedAt: now,
                origin: { ...state.player },
              };
              spawnParticles(state.player.x, state.player.y, "#ffffff", 20);
            }
          }
          onScoreUpdate(
            state.score,
            state.isMasked,
            state.shatteredKills,
            state.stage,
            state.feverMeter,
            state.feverActive
          );
        }

        if (progress >= 1) {
          state.dash.active = false;
        }
      }

      // Update trail fade
      state.dash.trail.forEach((t) => {
        t.life -= 0.03;
      });
      state.dash.trail = state.dash.trail.filter((t) => t.life > 0);

      // Update Rifts
      state.rifts.forEach((rift) => {
        if (!rift.active) return;
        if (now >= rift.endAt) {
          rift.active = false;
          return;
        }
        if (now >= rift.openAt && now >= rift.nextSpawnAt) {
          spawnMinion(state, rift.x, rift.y);
          rift.nextSpawnAt = now + RIFT_SPAWN_INTERVAL_MS;
        }
      });
      state.rifts = state.rifts.filter((r) => r.active);

      // Update Enemies
      const disablePlayerCollision =
        state.dash.active || skipCollisionThisFrame || now < state.playerInvulnUntil;
      state.enemies.forEach((enemy) => {
        if (!enemy.spawned || !enemy.active) return;

        if (enemy.type === "assassin") {
          const toPlayerX = state.player.x - enemy.x;
          const toPlayerY = state.player.y - enemy.y;
          const distance = Math.hypot(toPlayerX, toPlayerY);
          const baseAngle = Math.atan2(toPlayerY, toPlayerX);
          const chaseStrength = 0.08;
          const lateralStrength = 0.04 * enemy.flankSign;
          const shouldTeleport =
            enemy.assassinState === "recover" &&
            now >= enemy.stateUntil &&
            enemy.lastAssassinAttackAt > 0 &&
            now >= enemy.nextTeleportAt &&
            distance > ASSASSIN_TELEPORT_TRIGGER_DISTANCE;

          if (enemy.assassinState === "approach") {
            const targetSpeed = enemy.speed;
            const targetVx =
              Math.cos(baseAngle) * targetSpeed +
              Math.cos(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;
            const targetVy =
              Math.sin(baseAngle) * targetSpeed +
              Math.sin(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;
            enemy.vx = enemy.vx * (1 - chaseStrength) + targetVx * chaseStrength;
            enemy.vy = enemy.vy * (1 - chaseStrength) + targetVy * chaseStrength;

            if (distance < ASSASSIN_TRIGGER_RANGE && now >= enemy.stateUntil) {
              enemy.assassinState = "windup";
              enemy.stateUntil = now + ASSASSIN_WINDUP_MS;
              const len = distance || 1;
              enemy.dashDx = toPlayerX / len;
              enemy.dashDy = toPlayerY / len;
            }
          } else if (enemy.assassinState === "windup") {
            enemy.vx *= 0.5;
            enemy.vy *= 0.5;
            if (now >= enemy.stateUntil) {
              const len = distance || 1;
              enemy.dashDx = toPlayerX / len;
              enemy.dashDy = toPlayerY / len;
              enemy.assassinState = "dash";
              enemy.stateUntil = now + ASSASSIN_DASH_MS;
            }
          } else if (enemy.assassinState === "dash") {
            enemy.vx = enemy.dashDx * enemy.speed * ASSASSIN_DASH_SPEED_MULT;
            enemy.vy = enemy.dashDy * enemy.speed * ASSASSIN_DASH_SPEED_MULT;
            if (now >= enemy.stateUntil) {
              enemy.assassinState = "recover";
              enemy.stateUntil = now + ASSASSIN_RECOVER_MS;
              enemy.lastAssassinAttackAt = now;
            }
          } else {
            enemy.vx *= 0.85;
            enemy.vy *= 0.85;
            if (now >= enemy.stateUntil) {
              if (shouldTeleport) {
                const teleportAngle = state.rng() * Math.PI * 2;
                const teleportRadius =
                  ASSASSIN_TELEPORT_MIN_RADIUS +
                  state.rng() * (ASSASSIN_TELEPORT_MAX_RADIUS - ASSASSIN_TELEPORT_MIN_RADIUS);
                const targetX =
                  state.player.x + Math.cos(teleportAngle) * teleportRadius;
                const targetY =
                  state.player.y + Math.sin(teleportAngle) * teleportRadius;
                enemy.x = Math.max(enemy.radius, Math.min(width - enemy.radius, targetX));
                enemy.y = Math.max(enemy.radius, Math.min(height - enemy.radius, targetY));
                enemy.vx = 0;
                enemy.vy = 0;
                const dx = state.player.x - enemy.x;
                const dy = state.player.y - enemy.y;
                const len = Math.hypot(dx, dy) || 1;
                enemy.dashDx = dx / len;
                enemy.dashDy = dy / len;
                enemy.assassinState = "windup";
                enemy.stateUntil = now + ASSASSIN_WINDUP_MS;
                enemy.nextTeleportAt = now + ASSASSIN_TELEPORT_COOLDOWN_MS;
              } else {
                enemy.assassinState = "approach";
                enemy.stateUntil = now + ASSASSIN_COOLDOWN_MS;
              }
            }
          }
        } else if (enemy.type === "snare") {
          const toPlayerX = state.player.x - enemy.x;
          const toPlayerY = state.player.y - enemy.y;
          const distance = Math.hypot(toPlayerX, toPlayerY);
          const baseAngle = Math.atan2(toPlayerY, toPlayerX);
          const chaseStrength = 0.07;
          const lateralStrength = 0.03 * enemy.flankSign;

          if (enemy.snareState === "seek") {
            const targetSpeed = enemy.speed;
            const targetVx =
              Math.cos(baseAngle) * targetSpeed +
              Math.cos(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;
            const targetVy =
              Math.sin(baseAngle) * targetSpeed +
              Math.sin(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;
            enemy.vx = enemy.vx * (1 - chaseStrength) + targetVx * chaseStrength;
            enemy.vy = enemy.vy * (1 - chaseStrength) + targetVy * chaseStrength;

            if (distance < SNARE_RANGE && now >= enemy.snareUntil) {
              enemy.snareState = "windup";
              enemy.snareUntil = now + SNARE_WINDUP_MS;
              const len = distance || 1;
              enemy.snareDirX = toPlayerX / len;
              enemy.snareDirY = toPlayerY / len;
            }
          } else if (enemy.snareState === "windup") {
            enemy.vx *= 0.5;
            enemy.vy *= 0.5;
            if (now >= enemy.snareUntil) {
              const chainEnd = {
                x: enemy.x + enemy.snareDirX * SNARE_RANGE,
                y: enemy.y + enemy.snareDirY * SNARE_RANGE,
              };
              const dot =
                (state.player.x - enemy.x) * enemy.snareDirX +
                (state.player.y - enemy.y) * enemy.snareDirY;
              const inRange = dot >= 0 && dot <= SNARE_RANGE;
              const lineDistance = distancePointToSegment(enemy, chainEnd, state.player);

              if (
                !state.dash.active &&
                inRange &&
                lineDistance <= SNARE_CHAIN_WIDTH + PLAYER_SIZE / 2
              ) {
                state.snareUntil = Math.max(state.snareUntil, now + SNARE_SLOW_MS);
                spawnParticles(state.player.x, state.player.y, SNARE_COLOR, 12);
              }

              enemy.snareState = "fire";
              enemy.snareUntil = now + SNARE_FIRE_MS;
            }
          } else if (enemy.snareState === "fire") {
            enemy.vx *= 0.7;
            enemy.vy *= 0.7;
            if (now >= enemy.snareUntil) {
              enemy.snareState = "recover";
              enemy.snareUntil = now + SNARE_RECOVER_MS;
            }
          } else {
            enemy.vx *= 0.85;
            enemy.vy *= 0.85;
            if (now >= enemy.snareUntil) {
              enemy.snareState = "seek";
              enemy.snareUntil = now + SNARE_COOLDOWN_MS;
            }
          }
        } else if (enemy.type === "rift") {
          const toPlayerX = state.player.x - enemy.x;
          const toPlayerY = state.player.y - enemy.y;
          const baseAngle = Math.atan2(toPlayerY, toPlayerX);
          const chaseStrength = 0.05;
          const lateralStrength = 0.02 * enemy.flankSign;
          const targetSpeed = enemy.speed;
          const targetVx =
            Math.cos(baseAngle) * targetSpeed +
            Math.cos(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;
          const targetVy =
            Math.sin(baseAngle) * targetSpeed +
            Math.sin(baseAngle + Math.PI / 2) * targetSpeed * lateralStrength;

          enemy.vx = enemy.vx * (1 - chaseStrength) + targetVx * chaseStrength;
          enemy.vy = enemy.vy * (1 - chaseStrength) + targetVy * chaseStrength;

          if (now >= enemy.nextRiftAt) {
            spawnRift(state, width, height);
            enemy.nextRiftAt = now + RIFT_CAST_COOLDOWN_MS;
          }
        } else {
          if (enemy.type !== "minion" && now >= enemy.nextBurstAt) {
            enemy.burstUntil = now + BURST_DURATION;
            const nextBurstBase = Math.max(800, BURST_COOLDOWN_BASE - state.stage * 50);
            enemy.nextBurstAt = now + nextBurstBase + state.rng() * BURST_COOLDOWN_VARIANCE;
          }

          const isMinion = enemy.type === "minion";
          const chaseStrength = isMinion
            ? 0.1
            : Math.min(0.06 + state.stage * 0.008, 0.22);
          const lateralStrength =
            (isMinion ? 0.015 : Math.min(0.02 + state.stage * 0.004, 0.08)) *
            enemy.flankSign;
          const burstMultiplier = !isMinion && now < enemy.burstUntil ? BURST_SPEED_MULT : 1;
          const angle = Math.atan2(state.player.y - enemy.y, state.player.x - enemy.x);
          const targetSpeed = enemy.speed * burstMultiplier;
          const targetVx =
            Math.cos(angle) * targetSpeed +
            Math.cos(angle + Math.PI / 2) * targetSpeed * lateralStrength;
          const targetVy =
            Math.sin(angle) * targetSpeed +
            Math.sin(angle + Math.PI / 2) * targetSpeed * lateralStrength;

          enemy.vx = enemy.vx * (1 - chaseStrength) + targetVx * chaseStrength;
          enemy.vy = enemy.vy * (1 - chaseStrength) + targetVy * chaseStrength;
        }

        enemy.x += enemy.vx;
        enemy.y += enemy.vy;

        if (disablePlayerCollision) return;
        const d = dist(state.player, enemy);
        if (d < PLAYER_SIZE / 2 + enemy.radius) {
          if (enemy.type === "elite" && now < enemy.contactCooldownUntil) return;
          if (state.isMasked) {
            state.isMasked = false;
            state.shatteredKills = 0;
            state.playerInvulnUntil = now + PLAYER_INVULN_MS;
            state.maskFlashUntil = Date.now() + MASK_FLASH_DURATION;
            state.maskFlashColor = "255, 80, 80";
            if (state.feverActive || state.feverMeter > 0) {
              state.feverActive = false;
              state.feverMeter = 0;
              state.feverUntil = 0;
              state.feverFlashUntil = now + FEVER_FLASH_DURATION;
              state.feverFlashType = "out";
            }
            state.maskEffect = {
              type: "break",
              startedAt: now,
              origin: { ...state.player },
            };
            if (enemy.type === "elite") {
              enemy.contactCooldownUntil = now + ELITE_CONTACT_COOLDOWN;
              const dx = state.player.x - enemy.x;
              const dy = state.player.y - enemy.y;
              const len = Math.hypot(dx, dy) || 1;
              const pushX = (dx / len) * ELITE_KNOCKBACK_DISTANCE;
              const pushY = (dy / len) * ELITE_KNOCKBACK_DISTANCE;
              state.player.x = Math.max(
                PLAYER_SIZE / 2,
                Math.min(width - PLAYER_SIZE / 2, state.player.x + pushX)
              );
              state.player.y = Math.max(
                PLAYER_SIZE / 2,
                Math.min(height - PLAYER_SIZE / 2, state.player.y + pushY)
              );
            }
            if (enemy.hp > 1) {
              enemy.hp -= 1;
              spawnParticles(enemy.x, enemy.y, "#ff9933", 10);
            } else {
              enemy.active = false;
              state.enemiesKilledInWave++;
              state.score++;
              state.lastKillAt = now;
              state.noKillStrikes = 0;
              spawnParticles(enemy.x, enemy.y, "#ff0000", 12);
            }
            spawnParticles(state.player.x, state.player.y, "#ffffff", 15);
            state.hitStopUntil = Math.max(state.hitStopUntil, now + BASE_HIT_STOP_MS);
            onScoreUpdate(
              state.score,
              state.isMasked,
              state.shatteredKills,
              state.stage,
              state.feverMeter,
              state.feverActive
            );
          } else {
            state.gameOver = true;
            onGameOver(state.score, state.stage);
          }
        }
      });

      // Update Particles
      state.particles.forEach((p) => {
        if (!p.active) return;
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.02;
        if (p.life <= 0) p.active = false;
      });

      // Update Text
      state.floatingTexts.forEach((t) => {
        if (!t.active) return;
        t.y += t.vy;
        t.life -= 0.008;
        if (t.life <= 0) t.active = false;
      });

      // Update Kill Texts
      state.killTexts.forEach((t) => {
        if (!t.active) return;
        t.y -= t.rise;
        t.life -= 0.02;
        t.popLife = Math.max(0, t.popLife - 0.08);
        if (t.life <= 0) t.active = false;
      });

      // Update Announcement
      if (state.announcement) {
        state.announcement.life -= 0.01;
        if (state.announcement.life <= 0) {
          state.announcement = null;
        }
      }

      // Cleanup
      state.gameTime++;
      if (state.gameTime % 600 === 0) {
        state.enemies = state.enemies.filter((e) => e.active || !e.spawned);
        state.particles = state.particles.filter((p) => p.active);
        state.floatingTexts = state.floatingTexts.filter((t) => t.active);
        state.killTexts = state.killTexts.filter((t) => t.active);
      }

      draw(canvas, state);
      requestRef.current = requestAnimationFrame(update);
    },
    [onGameOver, onScoreUpdate, spawnWave]
  );

  const draw = (canvas: HTMLCanvasElement, state: GameState) => {
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const width = canvas.width;
    const height = canvas.height;

    const now = Date.now();
    if (state.shakeUntil > now) {
      const progress = (state.shakeUntil - now) / SCREEN_SHAKE_DURATION;
      const magnitude = state.shakeMagnitude * Math.max(progress, 0.1);
      const offsetX = (Math.random() * 2 - 1) * magnitude;
      const offsetY = (Math.random() * 2 - 1) * magnitude;
      ctx.save();
      ctx.translate(offsetX, offsetY);
    }

    // Background
    if (state.isMasked) {
      ctx.fillStyle = "#000000";
    } else {
      ctx.fillStyle = "#330000";
    }
    ctx.fillRect(0, 0, width, height);

    if (state.markIntensity > 0) {
      const ratio = state.markIntensity;
      const alpha = MARK_BG_ALPHA_MIN + (MARK_BG_ALPHA_MAX - MARK_BG_ALPHA_MIN) * ratio;
      const gradient = ctx.createRadialGradient(
        width / 2,
        height / 2,
        Math.min(width, height) * 0.15,
        width / 2,
        height / 2,
        Math.max(width, height) * 0.65
      );
      gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(1, `rgba(${MARK_BG_TINT}, ${alpha})`);

      ctx.save();
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);

      ctx.globalAlpha = MARK_BG_LINE_ALPHA * ratio;
      ctx.strokeStyle = "rgba(120, 15, 15, 0.9)";
      ctx.lineWidth = 1;
      for (let y = -height; y < height * 2; y += 26) {
        ctx.beginPath();
        ctx.moveTo(-width, y);
        ctx.lineTo(width * 2, y + 40);
        ctx.stroke();
      }
      ctx.restore();

      const bgImage = bgImageRef.current;
      if (bgImage && bgImage.complete) {
        const size = Math.min(width, height) * 0.72;
        const x = width / 2 - size / 2;
        const y = height / 2 - size / 2;
        ctx.save();
        ctx.globalAlpha = alpha * 0.7;
        ctx.drawImage(bgImage, x, y, size, size);
        ctx.restore();
      }
    }

    // Dash trail (afterimages)
    state.dash.trail.forEach((t) => {
      ctx.globalAlpha = t.life * 0.5;
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = 2;
      const halfSize = PLAYER_SIZE / 2;
      ctx.strokeRect(t.x - halfSize, t.y - halfSize, PLAYER_SIZE, PLAYER_SIZE);
    });
    ctx.globalAlpha = 1.0;

    // Pending dash indicator
    if (state.dash.pending) {
      const elapsed = Date.now() - state.dash.pendingStart;
      const delay = Math.max(1, state.dash.pendingDelay);
      const progress = Math.min(elapsed / delay, 1);

      ctx.strokeStyle = `rgba(255, 255, 255, ${0.3 + progress * 0.5})`;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);
      ctx.beginPath();
      ctx.moveTo(state.player.x, state.player.y);
      ctx.lineTo(state.dash.pendingTarget.x, state.dash.pendingTarget.y);
      ctx.stroke();
      ctx.setLineDash([]);

      ctx.beginPath();
      ctx.arc(state.dash.pendingTarget.x, state.dash.pendingTarget.y, 15 * progress, 0, Math.PI * 2);
      ctx.stroke();

      ctx.font = "14px 'Noto Sans SC', sans-serif";
      ctx.fillStyle = "#ffffff";
      ctx.textAlign = "center";
      const remain = Math.max(delay - elapsed, 0) / 1000;
      ctx.fillText(`${remain.toFixed(1)}s`, state.dash.pendingTarget.x, state.dash.pendingTarget.y - 25);
    }

    // Particles
    state.particles.forEach((p) => {
      if (!p.active) return;
      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - 2, p.y - 2, 4, 4);
    });
    ctx.globalAlpha = 1.0;

    // Rifts
    state.rifts.forEach((rift) => {
      if (!rift.active) return;
      const isOpen = now >= rift.openAt;
      const warningT = isOpen
        ? 1
        : 1 - Math.max(0, (rift.openAt - now) / RIFT_WARNING_MS);
      const pulse = 0.6 + Math.sin(now / 140) * 0.4;
      const radius = RIFT_RADIUS + 6 * pulse;

      ctx.save();
      ctx.translate(rift.x, rift.y);
      ctx.globalAlpha = isOpen ? 0.75 : 0.45 * warningT;
      ctx.shadowBlur = 16;
      ctx.shadowColor = RIFT_GLOW;
      ctx.strokeStyle = RIFT_COLOR;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(0, 0, radius, 0, Math.PI * 2);
      ctx.stroke();
      if (isOpen) {
        ctx.globalAlpha = 0.25;
        ctx.fillStyle = RIFT_COLOR;
        ctx.beginPath();
        ctx.arc(0, 0, radius * 0.6, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    });

    // Enemies
    state.enemies.forEach((e) => {
      if (!e.active) return;
      if (e.type === "assassin") {
        const alpha =
          e.assassinState === "approach"
            ? ASSASSIN_ALPHA_STEALTH
            : e.assassinState === "recover"
              ? 0.7
              : ASSASSIN_ALPHA_ACTIVE;
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.shadowBlur = 14;
        ctx.shadowColor = ASSASSIN_GLOW;
        ctx.translate(e.x, e.y);
        ctx.fillStyle = ASSASSIN_COLOR;
        ctx.strokeStyle = ASSASSIN_OUTLINE;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(0, -e.radius);
        ctx.lineTo(e.radius, 0);
        ctx.lineTo(0, e.radius);
        ctx.lineTo(-e.radius, 0);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        if (e.assassinState === "windup") {
          ctx.globalAlpha = 0.7;
          ctx.strokeStyle = "rgba(210, 160, 255, 0.95)";
          ctx.lineWidth = 3;
          ctx.beginPath();
          ctx.arc(0, 0, e.radius + 6, 0, Math.PI * 2);
          ctx.stroke();
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(e.dashDx * (e.radius + 16), e.dashDy * (e.radius + 16));
          ctx.stroke();
        } else if (e.assassinState === "dash") {
          ctx.globalAlpha = 0.6;
          ctx.strokeStyle = "rgba(180, 110, 255, 0.95)";
          ctx.lineWidth = 4;
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(-e.dashDx * (e.radius + 20), -e.dashDy * (e.radius + 20));
          ctx.stroke();
        }
        ctx.restore();
      } else if (e.type === "rift") {
        ctx.save();
        ctx.globalAlpha = 0.9;
        ctx.shadowBlur = 12;
        ctx.shadowColor = RIFT_GLOW;
        ctx.fillStyle = RIFT_COLOR;
        ctx.beginPath();
        ctx.arc(e.x, e.y, e.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = "rgba(10, 40, 70, 0.7)";
        ctx.lineWidth = 3;
        ctx.stroke();
        ctx.restore();
      } else if (e.type === "snare") {
        if (e.snareState === "windup" || e.snareState === "fire") {
          const chainEndX = e.x + e.snareDirX * SNARE_RANGE;
          const chainEndY = e.y + e.snareDirY * SNARE_RANGE;
          ctx.save();
          ctx.globalAlpha = e.snareState === "fire" ? 0.8 : 0.55;
          ctx.strokeStyle = "rgba(40, 212, 181, 0.95)";
          ctx.lineWidth = e.snareState === "fire" ? 4 : 2;
          ctx.beginPath();
          ctx.moveTo(e.x, e.y);
          ctx.lineTo(chainEndX, chainEndY);
          ctx.stroke();
          ctx.restore();
        }
        ctx.save();
        ctx.shadowBlur = 10;
        ctx.shadowColor = SNARE_GLOW;
        ctx.fillStyle = SNARE_COLOR;
        ctx.beginPath();
        ctx.arc(e.x, e.y, e.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = "rgba(0, 30, 25, 0.7)";
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.restore();
      } else {
        ctx.fillStyle =
          e.type === "elite"
            ? "#ff7a18"
            : e.type === "minion"
              ? "#ff5c5c"
              : "#ff0000";
        ctx.beginPath();
        ctx.arc(e.x, e.y, e.radius, 0, Math.PI * 2);
        ctx.fill();
        if (e.type === "elite") {
          ctx.strokeStyle = "#000000";
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }
    });

    // Player
    ctx.strokeStyle = "#ffffff";
    ctx.fillStyle = "#ffffff";
    const halfSize = PLAYER_SIZE / 2;

    if (state.isMasked) {
      ctx.fillRect(state.player.x - halfSize, state.player.y - halfSize, PLAYER_SIZE, PLAYER_SIZE);
    } else {
      ctx.lineWidth = 2;
      ctx.strokeRect(state.player.x - halfSize, state.player.y - halfSize, PLAYER_SIZE, PLAYER_SIZE);
    }

    // Mask break/restore effects (emblem + ring)
    if (state.maskEffect) {
      const elapsed = now - state.maskEffect.startedAt;
      const isBreak = state.maskEffect.type === "break";
      const emblemDuration = isBreak
        ? MASK_EMBLEM_BREAK_DURATION
        : MASK_EMBLEM_RESTORE_DURATION;
      const emblemT = Math.min(elapsed / emblemDuration, 1);
      const emblemAlpha = (isBreak ? MASK_EMBLEM_ALPHA_BREAK : MASK_EMBLEM_ALPHA_RESTORE) * (1 - emblemT);
      const baseSize = Math.min(width, height) * MASK_EMBLEM_SIZE_RATIO;
      const scale = isBreak ? 1.2 - 0.2 * emblemT : 0.9 + 0.12 * emblemT;
      drawMaskEmblem(
        ctx,
        width / 2,
        height / 2,
        baseSize * scale,
        state.maskEffect.type,
        emblemAlpha,
        bgImageRef.current,
        bgBrokenRef.current
      );

      const ringT = Math.min(elapsed / MASK_RING_DURATION, 1);
      const ringRadius = Math.min(width, height) * MASK_RING_MAX_RADIUS_RATIO * ringT;
      const ringAlpha = MASK_RING_ALPHA * (1 - ringT);
      if (ringAlpha > 0.01) {
        ctx.save();
        ctx.globalAlpha = ringAlpha;
        ctx.strokeStyle = isBreak ? "rgba(255, 90, 70, 0.9)" : "rgba(230, 235, 240, 0.9)";
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.arc(state.maskEffect.origin.x, state.maskEffect.origin.y, ringRadius, 0, Math.PI * 2);
        ctx.stroke();
        ctx.globalAlpha = ringAlpha * 0.6;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(
          state.maskEffect.origin.x,
          state.maskEffect.origin.y,
          ringRadius * 0.55,
          0,
          Math.PI * 2
        );
        ctx.stroke();
        ctx.restore();
      }
    }

    // Kill Texts on enemies
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    state.killTexts.forEach((t) => {
      if (!t.active) return;
      const scale = 1 + t.popLife * (t.popScale - 1);
      ctx.save();
      ctx.translate(t.x, t.y);
      ctx.scale(scale, scale);
      ctx.globalAlpha = t.life;
      ctx.font = `700 ${t.size}px 'Noto Sans SC', sans-serif`;
      ctx.fillStyle = t.color;
      ctx.strokeStyle = "rgba(0, 0, 0, 0.6)";
      ctx.lineWidth = 2;
      ctx.strokeText(t.text, 0, 0);
      ctx.fillText(t.text, 0, 0);
      ctx.restore();
    });
    ctx.globalAlpha = 1.0;

    // Kill impact flash
    if (state.impactFlashUntil > now) {
      const remaining = Math.max(state.impactFlashUntil - now, 0);
      const t = remaining / KILL_IMPACT_FLASH_DURATION;
      const alpha = KILL_IMPACT_FLASH_ALPHA * t;
      const gradient = ctx.createRadialGradient(
        width / 2,
        height / 2,
        Math.min(width, height) * 0.15,
        width / 2,
        height / 2,
        Math.max(width, height) * 0.6
      );
      gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(1, `rgba(${state.impactFlashColor}, 1)`);
      ctx.globalAlpha = alpha;
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
      ctx.globalAlpha = 1.0;
    }

    // Fever tint
    if (state.feverActive) {
      ctx.globalAlpha = FEVER_TINT_ALPHA;
      ctx.fillStyle = "rgba(255, 180, 90, 0.35)";
      ctx.fillRect(0, 0, width, height);
      ctx.globalAlpha = 1.0;
    }

    // Fever flash on enter/exit
    if (state.feverFlashUntil > now && state.feverFlashType) {
      const remaining = Math.max(state.feverFlashUntil - now, 0);
      const t = remaining / FEVER_FLASH_DURATION;
      const alpha = FEVER_FLASH_ALPHA * t;
      const gradient = ctx.createRadialGradient(
        width / 2,
        height / 2,
        Math.min(width, height) * 0.15,
        width / 2,
        height / 2,
        Math.max(width, height) * 0.8
      );
      const color =
        state.feverFlashType === "in"
          ? "rgba(255, 200, 120, 1)"
          : "rgba(120, 140, 160, 1)";
      gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(1, color);
      ctx.globalAlpha = alpha;
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
      ctx.globalAlpha = 1.0;
    }

    // Mask flash vignette
    if (state.maskFlashUntil > now) {
      const remaining = Math.max(state.maskFlashUntil - now, 0);
      const t = remaining / MASK_FLASH_DURATION;
      const alpha = MASK_FLASH_ALPHA * t;
      const gradient = ctx.createRadialGradient(
        width / 2,
        height / 2,
        Math.min(width, height) * 0.2,
        width / 2,
        height / 2,
        Math.max(width, height) * 0.7
      );
      gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(1, `rgba(${state.maskFlashColor}, 1)`);
      ctx.globalAlpha = alpha;
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
      ctx.globalAlpha = 1.0;
    }

    // Kill announcement badge
    if (state.announcement && state.announcement.life > 0) {
      const life = Math.min(state.announcement.life, 1);
      const progress = Math.min(1 - life, 1);
      const enter = Math.min(progress * 4, 1);
      const easeOut = 1 - Math.pow(1 - Math.min(progress, 1), 2);
      const alpha = life * enter;
      const text = state.announcement.text.toUpperCase();
      const margin = 22;
      const scale = state.announcement.scale;
      const paddingX = 10 * scale;
      const badgeHeight = 24 * scale;
      const rise = easeOut * 8;
      const slide = (1 - enter) * 12;

      ctx.font = `600 ${14 * scale}px 'Noto Sans SC', sans-serif`;
      ctx.textAlign = "left";
      ctx.textBaseline = "middle";
      const textWidth = ctx.measureText(text).width;
      const badgeWidth = textWidth + paddingX * 2;
      const x = width - margin - badgeWidth + slide;
      const y = margin + rise;

      ctx.globalAlpha = alpha;
      ctx.fillStyle = "rgba(0, 0, 0, 0.55)";
      ctx.strokeStyle = "rgba(255, 255, 255, 0.18)";
      ctx.lineWidth = 1;
      drawRoundedRect(ctx, x, y, badgeWidth, badgeHeight, 8);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = state.announcement.color;
      ctx.fillText(text, x + paddingX, y + badgeHeight / 2);
      ctx.globalAlpha = 1.0;
    }

    // Stage toast (subtle center stamp)
    if (state.stageToast) {
      const elapsed = now - state.stageToast.startedAt;
      const total =
        STAGE_TOAST_FADE_IN + STAGE_TOAST_HOLD + STAGE_TOAST_FADE_OUT;
      if (elapsed <= total) {
        let alpha = 1;
        if (elapsed < STAGE_TOAST_FADE_IN) {
          alpha = elapsed / STAGE_TOAST_FADE_IN;
        } else if (elapsed > STAGE_TOAST_FADE_IN + STAGE_TOAST_HOLD) {
          alpha =
            1 -
            (elapsed - STAGE_TOAST_FADE_IN - STAGE_TOAST_HOLD) /
              STAGE_TOAST_FADE_OUT;
        }
        const rise = Math.min(elapsed / total, 1) * 6;
        ctx.globalAlpha = Math.max(alpha, 0);
        ctx.font = "600 26px 'Noto Sans SC', sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillStyle = "rgba(230, 235, 240, 0.9)";
        ctx.strokeStyle = "rgba(10, 10, 10, 0.35)";
        ctx.lineWidth = 2;
        ctx.strokeText(
          state.stageToast.text,
          width / 2,
          height / 2 - rise
        );
        ctx.fillText(
          state.stageToast.text,
          width / 2,
          height / 2 - rise
        );
        ctx.globalAlpha = 1.0;
      }
    }

    // Floating Text (larger, more visible)
    state.floatingTexts.forEach((t) => {
      if (!t.active) return;
      ctx.globalAlpha = t.life;
      ctx.font = `bold ${t.size}px 'Noto Sans SC', sans-serif`;
      ctx.textAlign = "center";
      ctx.strokeStyle = "#000000";
      ctx.lineWidth = 4;
      ctx.strokeText(t.text, t.x, t.y);
      ctx.fillStyle = t.color;
      ctx.fillText(t.text, t.x, t.y);
    });
    ctx.globalAlpha = 1.0;

    if (state.shakeUntil > now) {
      ctx.restore();
    }
  };

  useEffect(() => {
    const handleResize = () => {
      if (canvasRef.current) {
        canvasRef.current.width = window.innerWidth;
        canvasRef.current.height = window.innerHeight;
      }
    };
    window.addEventListener("resize", handleResize);
    handleResize();
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  useEffect(() => {
    initGame();
  }, [initGame]);

  useEffect(() => {
    requestRef.current = requestAnimationFrame(update);
    return () => {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [update]);

  return (
    <canvas
      ref={canvasRef}
      className="block absolute top-0 left-0 w-full h-full cursor-crosshair touch-none"
      data-testid="game-canvas"
    />
  );
}
