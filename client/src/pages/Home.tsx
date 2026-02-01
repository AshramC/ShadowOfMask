import { useState, useEffect, useCallback, useRef } from "react";
import { GameCanvas } from "@/components/GameCanvas";
import { GlitchText } from "@/components/GlitchText";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { motion, AnimatePresence } from "framer-motion";
import { Sword, Trophy, Target } from "lucide-react";

type GamePhase = "MENU" | "PLAYING" | "GAMEOVER";

interface LocalScore {
  playerName: string;
  stage: number;
  score: number;
  date: string;
}

const LOCAL_STORAGE_KEY = "mask_of_shadow_leaderboard";
const DEFAULT_PLAYER_NAME = "无名刺客";

function getLocalLeaderboard(): LocalScore[] {
  try {
    const data = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (data) {
      return JSON.parse(data);
    }
  } catch (e) {
    console.error("Failed to load leaderboard", e);
  }
  return [];
}

function saveToLocalLeaderboard(entry: LocalScore) {
  const leaderboard = getLocalLeaderboard();
  leaderboard.push(entry);
  leaderboard.sort((a, b) => b.stage - a.stage || b.score - a.score);
  const top10 = leaderboard.slice(0, 10);
  localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(top10));
}

export default function Home() {
  const [phase, setPhase] = useState<GamePhase>("MENU");
  const [seed, setSeed] = useState(() => Date.now().toString());
  const [score, setScore] = useState(0);
  const [stage, setStage] = useState(1);
  const [isMasked, setIsMasked] = useState(true);
  const [shatteredKills, setShatteredKills] = useState(0);
  const [feverMeter, setFeverMeter] = useState(0);
  const [feverActive, setFeverActive] = useState(false);
  const [finalScore, setFinalScore] = useState(0);
  const [finalStage, setFinalStage] = useState(1);
  const [playerName, setPlayerName] = useState(DEFAULT_PLAYER_NAME);
  const [resultSaved, setResultSaved] = useState(false);
  const [lastResultName, setLastResultName] = useState<string | null>(null);
  const [localLeaderboard, setLocalLeaderboard] = useState<LocalScore[]>([]);
  const bgmRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    setLocalLeaderboard(getLocalLeaderboard());
  }, []);

  useEffect(() => {
    const audio = new Audio(`${import.meta.env.BASE_URL}BGM.mp3`);
    audio.loop = true;
    bgmRef.current = audio;
    return () => {
      audio.pause();
      audio.src = "";
      bgmRef.current = null;
    };
  }, []);

  useEffect(() => {
    const audio = bgmRef.current;
    if (!audio) return;
    if (phase === "PLAYING") {
      audio.currentTime = 0;
      const playPromise = audio.play();
      if (playPromise) playPromise.catch(() => {});
    } else {
      audio.pause();
      audio.currentTime = 0;
    }
  }, [phase]);

  const handleStart = () => {
    const nextSeed = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    setSeed(nextSeed);
    setScore(0);
    setStage(1);
    setIsMasked(true);
    setShatteredKills(0);
    setResultSaved(false);
    setFeverMeter(0);
    setFeverActive(false);
    setPhase("PLAYING");
  };

  const handleGameOver = useCallback((final: number, stageReached: number) => {
    setFinalScore(final);
    setFinalStage(stageReached);
    setPhase("GAMEOVER");
    setResultSaved(false);
  }, []);

  const handleScoreUpdate = useCallback(
    (
      newScore: number,
      masked: boolean,
      consecutive: number,
      currentStage: number,
      currentFever: number,
      isFeverActive: boolean
    ) => {
      setScore(newScore);
      setIsMasked(masked);
      setShatteredKills(consecutive);
      setStage(currentStage);
      setFeverMeter(currentFever);
      setFeverActive(isFeverActive);
    },
    []
  );

  const saveResult = useCallback(() => {
    if (resultSaved) return;
    const name = playerName.trim() || DEFAULT_PLAYER_NAME;
    const entry: LocalScore = {
      playerName: name,
      stage: finalStage,
      score: finalScore,
      date: new Date().toLocaleDateString(),
    };
    saveToLocalLeaderboard(entry);
    setLocalLeaderboard(getLocalLeaderboard());
    setResultSaved(true);
    setLastResultName(name);
  }, [finalScore, finalStage, playerName, resultSaved]);

  const ensureResultSaved = useCallback(() => {
    if (!resultSaved) {
      saveResult();
    }
  }, [resultSaved, saveResult]);

  const feverPercent = Math.min(feverMeter / 100, 1);

  return (
    <div className="relative w-screen h-screen bg-black overflow-hidden text-white font-sans selection:bg-red-900 selection:text-white">
      
      {phase !== "MENU" && (
        <GameCanvas 
          seed={seed || playerName} 
          playerName={playerName}
          onGameOver={handleGameOver}
          onScoreUpdate={handleScoreUpdate}
        />
      )}

      {phase === "PLAYING" && (
        <div className="absolute top-0 left-0 w-full p-6 flex justify-between items-start pointer-events-none">
          <div className="flex flex-col gap-2">
            <h2 className="text-4xl font-display font-bold tabular-nums tracking-wider">
              {score.toString().padStart(4, '0')}
            </h2>
            <div className="flex items-center gap-2 text-sm text-muted-foreground uppercase tracking-widest">
              <Sword className="w-4 h-4" /> 击杀数
            </div>
          </div>

          <div className="flex flex-col items-center">
            <div className="flex items-center gap-2 text-xl font-bold">
              <Target className="w-5 h-5" />
              <span>STAGE {stage}</span>
            </div>
          </div>

          <div className={`flex flex-col items-end transition-colors duration-300 ${!isMasked ? 'text-red-500' : 'text-white'}`}>
            <div className="flex items-center gap-3">
              <span className="text-lg font-bold tracking-widest">
                {isMasked ? "面具完整" : "面具破碎"}
              </span>
              <div className={`relative w-9 h-9 ${feverActive ? "animate-pulse drop-shadow-[0_0_12px_rgba(255,170,90,0.7)]" : ""}`}>
                <svg viewBox="0 0 100 100" className="w-full h-full">
                  <defs>
                    <clipPath id="mask-clip">
                      <path d="M20 20 Q50 5 80 20 Q90 40 75 70 L50 90 L25 70 Q10 40 20 20 Z" />
                    </clipPath>
                  </defs>
                  <path
                    d="M20 20 Q50 5 80 20 Q90 40 75 70 L50 90 L25 70 Q10 40 20 20 Z"
                    fill="none"
                    stroke={isMasked ? "rgba(240,240,240,0.9)" : "rgba(255,90,90,0.9)"}
                    strokeWidth="4"
                  />
                  <rect
                    x="0"
                    y={100 - 100 * feverPercent}
                    width="100"
                    height={100 * feverPercent}
                    clipPath="url(#mask-clip)"
                    fill={feverActive ? "rgba(255,170,90,0.95)" : "rgba(220,230,240,0.8)"}
                  />
                </svg>
              </div>
            </div>
            {!isMasked && (
              <div className="mt-1 text-sm opacity-80">
                重塑所需: {shatteredKills}/3
              </div>
            )}
            {isMasked && (
              <div className={`mt-1 text-xs tracking-widest ${feverActive ? "text-orange-300" : "text-zinc-400"}`}>
                FEVER
              </div>
            )}
          </div>
        </div>
      )}

      <AnimatePresence>
        {(phase === "MENU" || phase === "GAMEOVER") && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
          >
            <div className="w-full max-w-lg p-6">
              
              <div className="mb-12 text-center">
                <h1 className="text-6xl font-display font-bold tracking-tighter mb-2">
                  <GlitchText text="影之面具" />
                </h1>
                <p className="text-muted-foreground tracking-[0.2em] text-sm uppercase">
                  Mask of Shadow
                </p>
              </div>

              {phase === "MENU" ? (
                <Card className="bg-zinc-900/50 border-zinc-800 p-8 shadow-2xl backdrop-blur-md">
                  <div className="space-y-6">
                    <Button 
                      onClick={handleStart}
                      className="w-full h-14 text-lg font-bold bg-white text-black hover:bg-zinc-200 hover:scale-[1.02] transition-all duration-200"
                      data-testid="button-start"
                    >
                      开始潜行
                    </Button>

                    <div className="mt-8 pt-6 border-t border-white/10">
                      <h3 className="flex items-center gap-2 text-sm font-bold text-muted-foreground mb-4">
                        <Trophy className="w-4 h-4" /> 本地排行榜 (按局数排名)
                      </h3>
                      <div className="space-y-2 max-h-48 overflow-y-auto pr-2">
                        {localLeaderboard.length > 0 ? (
                          localLeaderboard.map((s, i) => (
                            <div key={i} className="flex justify-between text-sm font-mono text-zinc-400 bg-zinc-900/50 p-2 rounded">
                              <span className="flex items-center gap-2">
                                <span className={`w-6 h-6 flex items-center justify-center rounded-full text-xs font-bold ${i === 0 ? 'bg-yellow-500 text-black' : i === 1 ? 'bg-zinc-400 text-black' : i === 2 ? 'bg-amber-700 text-white' : 'bg-zinc-700 text-zinc-300'}`}>
                                  {i + 1}
                                </span>
                                <span className="text-white">{s.playerName}</span>
                              </span>
                              <span className="flex items-center gap-4">
                                <span className="text-green-400">Stage {s.stage}</span>
                                <span className="text-red-400">{s.score} kills</span>
                              </span>
                            </div>
                          ))
                        ) : (
                          <div className="text-xs text-zinc-600 italic">暂无记录</div>
                        )}
                      </div>
                    </div>
                  </div>
                </Card>
              ) : (
                <Card className="bg-red-950/20 border-red-900/50 p-8 shadow-2xl backdrop-blur-md text-center">
                  <h2 className="text-3xl font-bold text-red-500 mb-2">任务失败</h2>
                  <div className="flex justify-center gap-8 mb-6">
                    <div>
                      <div className="text-4xl font-display font-bold text-white">{finalStage}</div>
                      <div className="text-sm text-zinc-400">Stage</div>
                    </div>
                    <div>
                      <div className="text-4xl font-display font-bold text-white">{finalScore}</div>
                      <div className="text-sm text-zinc-400">Kills</div>
                    </div>
                  </div>
                  
                  <div className="mb-6 text-left">
                    <h3 className="flex items-center gap-2 text-sm font-bold text-muted-foreground mb-3">
                      <Trophy className="w-4 h-4" /> 排行榜
                    </h3>
                    <div className="space-y-2 max-h-40 overflow-y-auto pr-2">
                      {localLeaderboard.map((s, i) => (
                        <div key={i} className={`flex justify-between text-sm font-mono p-2 rounded ${s.playerName === (lastResultName || playerName) && s.stage === finalStage && s.score === finalScore ? 'bg-yellow-900/30 border border-yellow-500/50' : 'bg-zinc-900/50 text-zinc-400'}`}>
                          <span className="flex items-center gap-2">
                            <span className={`w-6 h-6 flex items-center justify-center rounded-full text-xs font-bold ${i === 0 ? 'bg-yellow-500 text-black' : i === 1 ? 'bg-zinc-400 text-black' : i === 2 ? 'bg-amber-700 text-white' : 'bg-zinc-700 text-zinc-300'}`}>
                              {i + 1}
                            </span>
                            <span className="text-white">{s.playerName}</span>
                          </span>
                          <span className="flex items-center gap-4">
                            <span className="text-green-400">Stage {s.stage}</span>
                            <span className="text-red-400">{s.score} kills</span>
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                  
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <label className="text-xs text-muted-foreground uppercase tracking-wider font-bold">
                        玩家名称
                      </label>
                      <Input
                        placeholder="输入你的名字..."
                        value={playerName}
                        onChange={(e) => setPlayerName(e.target.value)}
                        className="bg-black/50 border-zinc-700 text-white font-mono text-lg h-11 focus:border-white transition-colors"
                      />
                    </div>
                    <Button
                      onClick={saveResult}
                      disabled={resultSaved || !playerName.trim()}
                      className="w-full h-11 bg-white text-black hover:bg-zinc-200"
                    >
                      {resultSaved ? "已保存" : "保存成绩"}
                    </Button>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <Button 
                      variant="outline"
                      onClick={() => {
                        ensureResultSaved();
                        setPhase("MENU");
                      }}
                      className="h-12 border-zinc-700 text-zinc-300 hover:bg-zinc-800 hover:text-white"
                      data-testid="button-menu"
                    >
                      返回主菜单
                    </Button>
                    <Button 
                      onClick={() => {
                        ensureResultSaved();
                        handleStart();
                      }}
                      className="h-12 bg-red-600 hover:bg-red-700 text-white border-none"
                      data-testid="button-retry"
                    >
                      再次尝试
                    </Button>
                  </div>
                </Card>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {phase === "PLAYING" && score < 3 && stage === 1 && (
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="absolute bottom-12 left-0 w-full text-center pointer-events-none"
        >
          <p className="text-zinc-400 text-sm tracking-widest bg-black/50 inline-block px-4 py-2 rounded-full backdrop-blur-sm border border-white/10">
            WASD移动 · 点击鼠标蓄力冲刺 · 穿过敌人进行斩杀
          </p>
        </motion.div>
      )}
    </div>
  );
}
