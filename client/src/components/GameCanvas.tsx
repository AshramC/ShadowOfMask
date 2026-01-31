import { useEffect, useRef, useState, useCallback } from "react";
import seedrandom from "seedrandom";

// --- Game Constants & Types ---
const PLAYER_SIZE = 20;
const ENEMY_RADIUS = 10;
const HIT_STOP_DURATION = 100; // ms

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
  life: number; // 0-1
  color: string;
}

interface FloatingText extends Entity {
  text: string;
  color: string;
  life: number;
  vy: number;
}

interface GameState {
  player: Point;
  enemies: Enemy[];
  particles: Particle[];
  floatingTexts: FloatingText[];
  score: number;
  isMasked: boolean; // true = shield, false = shattered
  shatteredKills: number; // consecutive kills in shattered mode
  gameOver: boolean;
  gameTime: number;
  wave: number;
  rng: seedrandom.PRNG;
  lastHitStop: number;
}

interface GameCanvasProps {
  seed: string;
  onGameOver: (score: number) => void;
  onScoreUpdate: (score: number, isMasked: boolean, shatteredKills: number) => void;
}

// --- Helper Math ---
function dist(p1: Point, p2: Point): number {
  return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
}

// Line segment intersection with circle
function lineIntersectCircle(
  A: Point, 
  B: Point, 
  C: Point, 
  radius: number
): boolean {
  const dx = B.x - A.x;
  const dy = B.y - A.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) return dist(A, C) <= radius;

  // Project point C onto line segment AB, clamp t to [0,1]
  let t = ((C.x - A.x) * dx + (C.y - A.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const closestX = A.x + t * dx;
  const closestY = A.y + t * dy;

  const d = dist({ x: closestX, y: closestY }, C);
  return d <= radius;
}

export function GameCanvas({ seed, onGameOver, onScoreUpdate }: GameCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number>();
  const stateRef = useRef<GameState | null>(null);

  // --- Initialization ---
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
    };

    // Initial Tutorial Enemies
    for (let i = 0; i < 3; i++) {
      spawnEnemy(width, height, true); // true = stationary
    }
  }, [seed]);

  const spawnEnemy = (w: number, h: number, stationary = false) => {
    if (!stateRef.current) return;
    const rng = stateRef.current.rng;
    
    // Spawn at edges
    let x, y;
    if (rng() > 0.5) {
      x = rng() > 0.5 ? -20 : w + 20;
      y = rng() * h;
    } else {
      x = rng() * w;
      y = rng() > 0.5 ? -20 : h + 20;
    }

    // Move towards center generally
    const angle = Math.atan2(h/2 - y, w/2 - x) + (rng() - 0.5) * 0.5;
    const speed = stationary ? 0 : 1 + (stateRef.current.score * 0.05);

    stateRef.current.enemies.push({
      x, y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      active: true
    });
  };

  const spawnParticles = (x: number, y: number, color: string, count: number) => {
    if (!stateRef.current) return;
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 3 + 1;
      stateRef.current.particles.push({
        x, y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 1.0,
        color,
        active: true
      });
    }
  };

  const spawnText = (text: string, color: string) => {
    if (!stateRef.current) return;
    stateRef.current.floatingTexts.push({
      x: stateRef.current.player.x,
      y: stateRef.current.player.y - 20,
      text,
      color,
      life: 1.0,
      vy: -1,
      active: true
    });
  };

  // --- Input Handling ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const handleClick = (e: MouseEvent) => {
      const state = stateRef.current;
      if (!state || state.gameOver) return;

      const rect = canvas.getBoundingClientRect();
      const targetX = e.clientX - rect.left;
      const targetY = e.clientY - rect.top;

      // TELEPORT SLASH LOGIC
      const startPos = { ...state.player };
      const endPos = { x: targetX, y: targetY };
      
      // Update position immediately
      state.player = endPos;

      // Check hits
      let hitCount = 0;
      state.enemies.forEach(enemy => {
        if (!enemy.active) return;
        if (lineIntersectCircle(startPos, endPos, enemy, ENEMY_RADIUS)) {
          // Kill Enemy
          enemy.active = false;
          hitCount++;
          state.score++;
          spawnParticles(enemy.x, enemy.y, "#ff0000", 10);
        }
      });

      if (hitCount > 0) {
        state.lastHitStop = Date.now();
        // Shattered Mode Logic
        if (!state.isMasked) {
          state.shatteredKills += hitCount;
          if (state.shatteredKills >= 3) {
            state.isMasked = true;
            state.shatteredKills = 0;
            spawnText("面具重塑", "#ffffff");
            spawnParticles(state.player.x, state.player.y, "#ffffff", 20);
          }
        }
      }

      // Trail Effect (visual only, handled in draw)
      // We'll leave a trail line that fades
      state.particles.push({
        x: startPos.x, y: startPos.y, // Not moving particle, just a marker
        vx: 0, vy: 0,
        life: 0.5,
        color: "trail", // special type
        active: true
      });
      // Store the trail endpoint too for drawing a line segment
      // (Simplified: just particles for now)
      
      // Propagate state update to React UI
      onScoreUpdate(state.score, state.isMasked, state.shatteredKills);
    };

    canvas.addEventListener('mousedown', handleClick);
    return () => canvas.removeEventListener('mousedown', handleClick);
  }, [onScoreUpdate]);

  // --- Game Loop ---
  const update = useCallback((timestamp: number) => {
    const state = stateRef.current;
    const canvas = canvasRef.current;
    
    if (!state || !canvas) return;

    // HITSTOP
    if (Date.now() - state.lastHitStop < HIT_STOP_DURATION) {
      requestRef.current = requestAnimationFrame(update);
      return; 
    }

    if (state.gameOver) {
      // Just draw one last time or stop
      return; 
    }

    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const width = canvas.width;
    const height = canvas.height;

    // --- LOGIC ---
    
    // Spawner
    state.gameTime++;
    if (state.gameTime % 120 === 0) { // Every ~2 seconds
      spawnEnemy(width, height);
    }

    // Update Enemies
    state.enemies.forEach(enemy => {
      if (!enemy.active) return;
      
      // Move towards player
      const angle = Math.atan2(state.player.y - enemy.y, state.player.x - enemy.x);
      // Slight homing
      enemy.vx = enemy.vx * 0.98 + Math.cos(angle) * 0.1;
      enemy.vy = enemy.vy * 0.98 + Math.sin(angle) * 0.1;
      
      enemy.x += enemy.vx;
      enemy.y += enemy.vy;

      // Collision with Player
      const d = dist(state.player, enemy);
      if (d < PLAYER_SIZE/2 + ENEMY_RADIUS) {
        if (state.isMasked) {
          // Break Shield
          state.isMasked = false;
          state.shatteredKills = 0;
          enemy.active = false; // Enemy dies on impact? Or just bounces? Usually dies in these games to be fair.
          spawnParticles(state.player.x, state.player.y, "#ffffff", 15);
          spawnText("面具碎裂", "#ff0000");
          state.lastHitStop = Date.now();
          onScoreUpdate(state.score, state.isMasked, state.shatteredKills);
        } else {
          // DIE
          state.gameOver = true;
          onGameOver(state.score);
        }
      }
    });

    // Update Particles
    state.particles.forEach(p => {
      if (!p.active) return;
      if (p.color === "trail") {
        p.life -= 0.05;
      } else {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.02;
      }
      if (p.life <= 0) p.active = false;
    });

    // Update Text
    state.floatingTexts.forEach(t => {
      if (!t.active) return;
      t.y += t.vy;
      t.life -= 0.01;
      if (t.life <= 0) t.active = false;
    });

    // Cleanup arrays occasionally
    if (state.gameTime % 600 === 0) {
      state.enemies = state.enemies.filter(e => e.active);
      state.particles = state.particles.filter(p => p.active);
      state.floatingTexts = state.floatingTexts.filter(t => t.active);
    }

    // --- RENDER ---
    
    // Background
    if (state.isMasked) {
      ctx.fillStyle = "#000000";
    } else {
      // Red tint for danger
      ctx.fillStyle = "#220000";
    }
    ctx.fillRect(0, 0, width, height);

    // Particles
    state.particles.forEach(p => {
      if (!p.active) return;
      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.color === "trail" ? "#ffffff" : p.color;
      
      if (p.color === "trail") {
         ctx.fillRect(p.x - 10, p.y - 10, 20, 20); // Ghost squares
      } else {
         ctx.fillRect(p.x, p.y, 2, 2);
      }
      ctx.globalAlpha = 1.0;
    });

    // Enemies
    ctx.fillStyle = "#ff0000";
    state.enemies.forEach(e => {
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

    // Floating Text
    ctx.font = "20px 'Noto Sans SC'";
    ctx.textAlign = "center";
    state.floatingTexts.forEach(t => {
      if (!t.active) return;
      ctx.globalAlpha = t.life;
      ctx.fillStyle = t.color;
      ctx.fillText(t.text, t.x, t.y);
      ctx.globalAlpha = 1.0;
    });

    requestRef.current = requestAnimationFrame(update);
  }, [onGameOver, onScoreUpdate]);

  useEffect(() => {
    initGame();
    requestRef.current = requestAnimationFrame(update);
    return () => {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [initGame, update]);

  // Resize handler
  useEffect(() => {
    const handleResize = () => {
      if (canvasRef.current) {
        canvasRef.current.width = window.innerWidth;
        canvasRef.current.height = window.innerHeight;
      }
    };
    window.addEventListener('resize', handleResize);
    handleResize(); // Initial size
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return (
    <canvas 
      ref={canvasRef} 
      className="block absolute top-0 left-0 w-full h-full cursor-crosshair touch-none"
    />
  );
}
