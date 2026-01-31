import { useState } from "react";
import { GameCanvas } from "@/components/GameCanvas";
import { GlitchText } from "@/components/GlitchText";
import { useScores, useSubmitScore } from "@/hooks/use-scores";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { motion, AnimatePresence } from "framer-motion";
import { Sword, Shield, Skull, Trophy } from "lucide-react";

type GamePhase = "MENU" | "PLAYING" | "GAMEOVER";

export default function Home() {
  const [phase, setPhase] = useState<GamePhase>("MENU");
  const [seed, setSeed] = useState("");
  const [score, setScore] = useState(0);
  const [isMasked, setIsMasked] = useState(true);
  const [shatteredKills, setShatteredKills] = useState(0);
  const [finalScore, setFinalScore] = useState(0);

  const { data: scores } = useScores();
  const submitScore = useSubmitScore();

  const handleStart = () => {
    if (!seed.trim()) return;
    setScore(0);
    setIsMasked(true);
    setShatteredKills(0);
    setPhase("PLAYING");
  };

  const handleGameOver = (final: number) => {
    setFinalScore(final);
    setPhase("GAMEOVER");
    submitScore.mutate({ seed, score: final });
  };

  const handleScoreUpdate = (newScore: number, masked: boolean, consecutive: number) => {
    setScore(newScore);
    setIsMasked(masked);
    setShatteredKills(consecutive);
  };

  return (
    <div className="relative w-screen h-screen bg-black overflow-hidden text-white font-sans selection:bg-red-900 selection:text-white">
      
      {/* GAME LAYER */}
      {phase !== "MENU" && (
        <GameCanvas 
          seed={seed} 
          onGameOver={handleGameOver}
          onScoreUpdate={handleScoreUpdate}
        />
      )}

      {/* HUD LAYER */}
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

          <div className={`flex flex-col items-end transition-colors duration-300 ${!isMasked ? 'text-red-500' : 'text-white'}`}>
            <div className="flex items-center gap-3">
              <span className="text-lg font-bold tracking-widest">
                {isMasked ? "面具完整" : "面具破碎"}
              </span>
              {isMasked ? (
                <Shield className="w-6 h-6 animate-pulse" />
              ) : (
                <Skull className="w-6 h-6 animate-bounce" />
              )}
            </div>
            {!isMasked && (
              <div className="mt-1 text-sm opacity-80">
                重塑所需: {shatteredKills}/3
              </div>
            )}
          </div>
        </div>
      )}

      {/* MENU / UI OVERLAY */}
      <AnimatePresence>
        {(phase === "MENU" || phase === "GAMEOVER") && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
          >
            <div className="w-full max-w-md p-6">
              
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
                    <div className="space-y-2">
                      <label className="text-xs text-muted-foreground uppercase tracking-wider font-bold">
                        潜行代号 (SEED)
                      </label>
                      <Input 
                        autoFocus
                        placeholder="输入任意字符..." 
                        value={seed}
                        onChange={(e) => setSeed(e.target.value)}
                        className="bg-black/50 border-zinc-700 text-white font-mono text-lg h-12 focus:border-white transition-colors"
                        onKeyDown={(e) => e.key === "Enter" && handleStart()}
                      />
                    </div>

                    <Button 
                      onClick={handleStart}
                      disabled={!seed}
                      className="w-full h-14 text-lg font-bold bg-white text-black hover:bg-zinc-200 hover:scale-[1.02] transition-all duration-200"
                    >
                      开始潜行
                    </Button>

                    <div className="mt-8 pt-6 border-t border-white/10">
                      <h3 className="flex items-center gap-2 text-sm font-bold text-muted-foreground mb-4">
                        <Trophy className="w-4 h-4" /> 最近记录
                      </h3>
                      <div className="space-y-2 max-h-40 overflow-y-auto pr-2 custom-scrollbar">
                        {scores?.map((s, i) => (
                          <div key={i} className="flex justify-between text-sm font-mono text-zinc-400">
                            <span>#{s.seed}</span>
                            <span className="text-white">{s.score}</span>
                          </div>
                        ))}
                        {(!scores || scores.length === 0) && (
                          <div className="text-xs text-zinc-600 italic">暂无记录</div>
                        )}
                      </div>
                    </div>
                  </div>
                </Card>
              ) : (
                <Card className="bg-red-950/20 border-red-900/50 p-8 shadow-2xl backdrop-blur-md text-center">
                  <h2 className="text-3xl font-bold text-red-500 mb-2">任务失败</h2>
                  <div className="text-6xl font-display font-bold text-white mb-8">
                    {finalScore}
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <Button 
                      variant="outline"
                      onClick={() => setPhase("MENU")}
                      className="h-12 border-zinc-700 text-zinc-300 hover:bg-zinc-800 hover:text-white"
                    >
                      返回主菜单
                    </Button>
                    <Button 
                      onClick={handleStart}
                      className="h-12 bg-red-600 hover:bg-red-700 text-white border-none"
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

      {/* Tutorial Hint (Only Level 1/Initial) */}
      {phase === "PLAYING" && score < 3 && (
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="absolute bottom-12 left-0 w-full text-center pointer-events-none"
        >
          <p className="text-zinc-400 text-sm tracking-widest bg-black/50 inline-block px-4 py-2 rounded-full backdrop-blur-sm border border-white/10">
            点击鼠标瞬移 · 穿过敌人进行斩杀
          </p>
        </motion.div>
      )}
    </div>
  );
}
