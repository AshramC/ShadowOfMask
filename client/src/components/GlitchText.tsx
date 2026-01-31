import { motion } from "framer-motion";

export function GlitchText({ text, className = "" }: { text: string; className?: string }) {
  return (
    <div className={`relative inline-block ${className}`}>
      <motion.span
        className="relative z-10"
        animate={{ x: [0, -1, 1, 0], opacity: [1, 0.9, 1] }}
        transition={{ repeat: Infinity, duration: 2, repeatDelay: 3 }}
      >
        {text}
      </motion.span>
      <span className="absolute top-0 left-0 -ml-[2px] text-red-500 opacity-70 animate-pulse z-0 pointer-events-none mix-blend-screen">
        {text}
      </span>
      <span className="absolute top-0 left-0 ml-[2px] text-blue-500 opacity-70 animate-pulse z-0 pointer-events-none mix-blend-screen delay-75">
        {text}
      </span>
    </div>
  );
}
