import { useEffect, useRef, useCallback } from "react";
import seedrandom from "seedrandom";

const PLAYER_SIZE = 20;
const ENEMY_RADIUS = 10;
const HIT_STOP_DURATION = 1000;
const PLAYER_SPEED = 4;
const DASH_DELAY = 1000;
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
}

interface GameState {
  player: Point;
  enemies: Enemy[];
  particles: Particle[];
  floatingTexts: FloatingText[];
  score: number;
  isMasked: boolean;
  shatteredKills: number;
  gameOver: boolean;
  gameTime: number;
  wave: number;
  rng: seedrandom.PRNG;
  lastHitStop: number;
  keys: { [key: string]: boolean };
  dash: DashState;
}

interface GameCanvasProps {
  seed: string;
  onGameOver: (score: number) => void;
  onScoreUpdate: (score: number, isMasked: boolean, shatteredKills: number) => void;
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

export function GameCanvas({ seed, onGameOver, onScoreUpdate }: GameCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number>();
  const stateRef = useRef<GameState | null>(null);

  const initGame = useCallback(() => {
    if (!canvasRef.current) return;
    const width = canvasRef.current.width;
    const height = canvasRef.current.height;

    const rng = seedrandom(seed);

    stateRef.current = {
      player: { x: width / 2, y: height / 2 },
      enemies: [],
      particles: [],
      floatingTexts: [],
      score: 0,
      isMasked: true,
      shatteredKills: 0,
      gameOver: false,
      gameTime: 0,
      wave: 0,
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
      },
    };

    for (let i = 0; i < 3; i++) {
      spawnEnemy(width, height, true);
    }
  }, [seed]);

  const spawnEnemy = (w: number, h: number, stationary = false) => {
    if (!stateRef.current) return;
    const rng = stateRef.current.rng;

    let x, y;
    if (rng() > 0.5) {
      x = rng() > 0.5 ? -20 : w + 20;
      y = rng() * h;
    } else {
      x = rng() * w;
      y = rng() > 0.5 ? -20 : h + 20;
    }

    const angle = Math.atan2(h / 2 - y, w / 2 - x) + (rng() - 0.5) * 0.5;
    const speed = stationary ? 0 : 1 + stateRef.current.score * 0.05;

    stateRef.current.enemies.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      active: true,
    });
  };

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
        }
      }

      // Active Dash with afterimages
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
        let hitCount = 0;
        state.enemies.forEach((enemy) => {
          if (!enemy.active) return;
          if (lineIntersectCircle(prevPos, state.player, enemy, ENEMY_RADIUS + PLAYER_SIZE / 2)) {
            enemy.active = false;
            hitCount++;
            state.score++;
            spawnParticles(enemy.x, enemy.y, "#ff0000", 15);
          }
        });

        if (hitCount > 0) {
          state.lastHitStop = Date.now();
          if (!state.isMasked) {
            state.shatteredKills += hitCount;
            if (state.shatteredKills >= 3) {
              state.isMasked = true;
              state.shatteredKills = 0;
              spawnText("MASK 面具重塑", "#ffffff");
              spawnParticles(state.player.x, state.player.y, "#ffffff", 20);
            }
          }
          onScoreUpdate(state.score, state.isMasked, state.shatteredKills);
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

      // Spawner
      state.gameTime++;
      if (state.gameTime % 120 === 0) {
        spawnEnemy(width, height);
      }

      // Update Enemies
      state.enemies.forEach((enemy) => {
        if (!enemy.active) return;

        const angle = Math.atan2(state.player.y - enemy.y, state.player.x - enemy.x);
        enemy.vx = enemy.vx * 0.98 + Math.cos(angle) * 0.1;
        enemy.vy = enemy.vy * 0.98 + Math.sin(angle) * 0.1;

        enemy.x += enemy.vx;
        enemy.y += enemy.vy;

        const d = dist(state.player, enemy);
        if (d < PLAYER_SIZE / 2 + ENEMY_RADIUS) {
          if (state.isMasked) {
            state.isMasked = false;
            state.shatteredKills = 0;
            enemy.active = false;
            spawnParticles(state.player.x, state.player.y, "#ffffff", 15);
            spawnText("MASK 面具碎裂", "#ff0000");
            state.lastHitStop = Date.now();
            onScoreUpdate(state.score, state.isMasked, state.shatteredKills);
          } else {
            state.gameOver = true;
            onGameOver(state.score);
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

      // Cleanup
      if (state.gameTime % 600 === 0) {
        state.enemies = state.enemies.filter((e) => e.active);
        state.particles = state.particles.filter((p) => p.active);
        state.floatingTexts = state.floatingTexts.filter((t) => t.active);
      }

      draw(canvas, state);
      requestRef.current = requestAnimationFrame(update);
    },
    [onGameOver, onScoreUpdate]
  );

  const draw = (canvas: HTMLCanvasElement, state: GameState) => {
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const width = canvas.width;
    const height = canvas.height;

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

      // Draw line from player to target
      ctx.strokeStyle = `rgba(255, 255, 255, ${0.3 + progress * 0.5})`;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);
      ctx.beginPath();
      ctx.moveTo(state.player.x, state.player.y);
      ctx.lineTo(state.dash.pendingTarget.x, state.dash.pendingTarget.y);
      ctx.stroke();
      ctx.setLineDash([]);

      // Draw target circle
      ctx.beginPath();
      ctx.arc(state.dash.pendingTarget.x, state.dash.pendingTarget.y, 15 * progress, 0, Math.PI * 2);
      ctx.stroke();

      // Progress text
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
  };

  useEffect(() => {
    initGame();
    requestRef.current = requestAnimationFrame(update);
    return () => {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [initGame, update]);

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

  return (
    <canvas
      ref={canvasRef}
      className="block absolute top-0 left-0 w-full h-full cursor-crosshair touch-none"
      data-testid="game-canvas"
    />
  );
}
