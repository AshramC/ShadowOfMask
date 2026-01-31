import { useEffect, useRef, useCallback } from "react";
import seedrandom from "seedrandom";

const PLAYER_SIZE = 20;
const ENEMY_RADIUS = 10;
const HIT_STOP_DURATION = 80;
const SCREEN_SHAKE_DURATION = 120;
const SCREEN_SHAKE_MAGNITUDE = 6;
const PLAYER_SPEED = 4;
const DASH_DELAY = 1000;
const DASH_DURATION = 200;
const MAX_KILLS_PER_DASH = 5;

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
  killsThisDash: number;
  hitStopUsed: boolean;
}

interface Announcement {
  text: string;
  life: number;
}

interface GameState {
  player: Point;
  playerName: string;
  enemies: Enemy[];
  particles: Particle[];
  floatingTexts: FloatingText[];
  killTexts: KillText[];
  announcement: Announcement | null;
  score: number;
  stage: number;
  enemiesInWave: number;
  enemiesKilledInWave: number;
  waveComplete: boolean;
  isMasked: boolean;
  shatteredKills: number;
  gameOver: boolean;
  gameTime: number;
  shakeUntil: number;
  shakeMagnitude: number;
  rng: seedrandom.PRNG;
  lastHitStop: number;
  keys: { [key: string]: boolean };
  dash: DashState;
}

interface GameCanvasProps {
  seed: string;
  playerName: string;
  onGameOver: (score: number, stage: number) => void;
  onScoreUpdate: (score: number, isMasked: boolean, shatteredKills: number, stage: number) => void;
}

const KILL_ANNOUNCEMENTS = [
  "First Blood",
  "Double Kill",
  "Triple Kill",
  "Quadra Kill",
  "Penta Kill",
];

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

export function GameCanvas({ seed, playerName, onGameOver, onScoreUpdate }: GameCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number>();
  const stateRef = useRef<GameState | null>(null);

  const spawnWave = useCallback((state: GameState, w: number, h: number) => {
    const enemyCount = 3 + state.stage * 2;
    state.enemiesInWave = enemyCount;
    state.enemiesKilledInWave = 0;
    state.waveComplete = false;

    for (let i = 0; i < enemyCount; i++) {
      const rng = state.rng;
      let x, y;
      if (rng() > 0.5) {
        x = rng() > 0.5 ? -20 : w + 20;
        y = rng() * h;
      } else {
        x = rng() * w;
        y = rng() > 0.5 ? -20 : h + 20;
      }

      const angle = Math.atan2(h / 2 - y, w / 2 - x) + (rng() - 0.5) * 0.5;
      const speed = state.stage === 1 ? 0 : 0.5 + state.stage * 0.3;

      state.enemies.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        active: true,
      });
    }
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
      particles: [],
      floatingTexts: [],
      killTexts: [],
      announcement: null,
      score: 0,
      stage: 1,
      enemiesInWave: 0,
      enemiesKilledInWave: 0,
      waveComplete: false,
      isMasked: true,
      shatteredKills: 0,
      gameOver: false,
      gameTime: 0,
      shakeUntil: 0,
      shakeMagnitude: 0,
      rng,
      lastHitStop: 0,
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
        killsThisDash: 0,
        hitStopUsed: false,
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

  const spawnText = (text: string, color: string) => {
    if (!stateRef.current) return;
    stateRef.current.floatingTexts.push({
      x: stateRef.current.player.x,
      y: stateRef.current.player.y - 40,
      text,
      color,
      life: 1.0,
      vy: -2,
      size: 48,
      active: true,
    });
  };

  const spawnKillText = (x: number, y: number, killNumber: number) => {
    if (!stateRef.current) return;
    const text = killNumber === 1 ? "1 kill" : `${killNumber} kills`;
    stateRef.current.killTexts.push({
      x,
      y,
      text,
      life: 1.0,
      active: true,
    });
  };

  const showAnnouncement = (killCount: number) => {
    if (!stateRef.current) return;
    if (killCount >= 1 && killCount <= 5) {
      stateRef.current.announcement = {
        text: `${KILL_ANNOUNCEMENTS[killCount - 1]} (${stateRef.current.playerName})`,
        life: 1.0,
      };
    }
  };

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

      state.dash.pending = true;
      state.dash.pendingStart = Date.now();
      state.dash.pendingTarget = { x: targetX, y: targetY };
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

      if (Date.now() - state.lastHitStop < HIT_STOP_DURATION) {
        draw(canvas, state);
        requestRef.current = requestAnimationFrame(update);
        return;
      }

      if (state.gameOver) {
        draw(canvas, state);
        return;
      }

      const width = canvas.width;
      const height = canvas.height;

      // Check wave complete
      if (!state.waveComplete) {
        const allEnemiesOnScreen = state.enemies.every(
          (e) => !e.active || (e.x >= 0 && e.x <= width && e.y >= 0 && e.y <= height)
        );
        const allEnemiesDead = state.enemies.every((e) => !e.active);

        if (allEnemiesOnScreen && allEnemiesDead && state.enemiesInWave > 0) {
          state.waveComplete = true;
          state.stage++;
          spawnText(`STAGE ${state.stage}`, "#00ff00");

          setTimeout(() => {
            if (stateRef.current && !stateRef.current.gameOver) {
              spawnWave(stateRef.current, width, height);
            }
          }, 2000);

          onScoreUpdate(state.score, state.isMasked, state.shatteredKills, state.stage);
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
        moveX = (moveX / len) * PLAYER_SPEED;
        moveY = (moveY / len) * PLAYER_SPEED;
        state.player.x = Math.max(PLAYER_SIZE / 2, Math.min(width - PLAYER_SIZE / 2, state.player.x + moveX));
        state.player.y = Math.max(PLAYER_SIZE / 2, Math.min(height - PLAYER_SIZE / 2, state.player.y + moveY));
      }

      // Pending Dash (1 second delay)
      if (state.dash.pending && !state.dash.active) {
        const elapsed = Date.now() - state.dash.pendingStart;
        if (elapsed >= DASH_DELAY) {
          state.dash.active = true;
          state.dash.pending = false;
          state.dash.startTime = Date.now();
          state.dash.startPos = { ...state.player };
          state.dash.endPos = { ...state.dash.pendingTarget };
          state.dash.trail = [];
          state.dash.killsThisDash = 0;
          state.dash.hitStopUsed = false;
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

        // Check collision during dash movement (max 5 kills)
        let hitCount = 0;
        state.enemies.forEach((enemy) => {
          if (!enemy.active) return;
          if (state.dash.killsThisDash >= MAX_KILLS_PER_DASH) return;

          if (lineIntersectCircle(prevPos, state.player, enemy, ENEMY_RADIUS + PLAYER_SIZE / 2)) {
            enemy.active = false;
            state.dash.killsThisDash++;
            hitCount++;
            state.score++;
            state.enemiesKilledInWave++;
            spawnParticles(enemy.x, enemy.y, "#ff0000", 15);
            spawnKillText(enemy.x, enemy.y, state.dash.killsThisDash);
          }
        });

        if (hitCount > 0) {
          skipCollisionThisFrame = true;
          if (!state.dash.hitStopUsed) {
            state.lastHitStop = Date.now();
            state.dash.hitStopUsed = true;
            state.shakeUntil = Date.now() + SCREEN_SHAKE_DURATION;
            state.shakeMagnitude = SCREEN_SHAKE_MAGNITUDE;
          }
          showAnnouncement(state.dash.killsThisDash);

          if (!state.isMasked) {
            state.shatteredKills += hitCount;
            if (state.shatteredKills >= 3) {
              state.isMasked = true;
              state.shatteredKills = 0;
              spawnText("MASK 面具重塑", "#ffffff");
              spawnParticles(state.player.x, state.player.y, "#ffffff", 20);
            }
          }
          onScoreUpdate(state.score, state.isMasked, state.shatteredKills, state.stage);
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

      // Update Enemies
      const disablePlayerCollision = state.dash.active || skipCollisionThisFrame;
      state.enemies.forEach((enemy) => {
        if (!enemy.active) return;

        const angle = Math.atan2(state.player.y - enemy.y, state.player.x - enemy.x);
        enemy.vx = enemy.vx * 0.98 + Math.cos(angle) * 0.1;
        enemy.vy = enemy.vy * 0.98 + Math.sin(angle) * 0.1;

        enemy.x += enemy.vx;
        enemy.y += enemy.vy;

        if (disablePlayerCollision) return;
        const d = dist(state.player, enemy);
        if (d < PLAYER_SIZE / 2 + ENEMY_RADIUS) {
          if (state.isMasked) {
            state.isMasked = false;
            state.shatteredKills = 0;
            enemy.active = false;
            spawnParticles(state.player.x, state.player.y, "#ffffff", 15);
            spawnText("MASK 面具碎裂", "#ff0000");
            state.lastHitStop = Date.now();
            onScoreUpdate(state.score, state.isMasked, state.shatteredKills, state.stage);
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
        t.y -= 1;
        t.life -= 0.02;
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
        state.enemies = state.enemies.filter((e) => e.active);
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
      const progress = Math.min(elapsed / DASH_DELAY, 1);

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
      ctx.fillText(`${((1 - progress) * 1).toFixed(1)}s`, state.dash.pendingTarget.x, state.dash.pendingTarget.y - 25);
    }

    // Particles
    state.particles.forEach((p) => {
      if (!p.active) return;
      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - 2, p.y - 2, 4, 4);
    });
    ctx.globalAlpha = 1.0;

    // Enemies
    ctx.fillStyle = "#ff0000";
    state.enemies.forEach((e) => {
      if (!e.active) return;
      ctx.beginPath();
      ctx.arc(e.x, e.y, ENEMY_RADIUS, 0, Math.PI * 2);
      ctx.fill();
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

    // Kill Texts on enemies
    ctx.font = "bold 16px 'Noto Sans SC', sans-serif";
    ctx.textAlign = "center";
    state.killTexts.forEach((t) => {
      if (!t.active) return;
      ctx.globalAlpha = t.life;
      ctx.fillStyle = "#ffff00";
      ctx.strokeStyle = "#000000";
      ctx.lineWidth = 3;
      ctx.strokeText(t.text, t.x, t.y);
      ctx.fillText(t.text, t.x, t.y);
    });
    ctx.globalAlpha = 1.0;

    // Announcement at top center
    if (state.announcement && state.announcement.life > 0) {
      ctx.globalAlpha = state.announcement.life;
      ctx.font = "bold 36px 'Noto Sans SC', sans-serif";
      ctx.textAlign = "center";
      ctx.fillStyle = "#ff4444";
      ctx.strokeStyle = "#000000";
      ctx.lineWidth = 4;
      ctx.strokeText(state.announcement.text, width / 2, 80);
      ctx.fillText(state.announcement.text, width / 2, 80);
      ctx.globalAlpha = 1.0;
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
