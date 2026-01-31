import { db } from "./db";
import { scores, type InsertScore, type Score } from "@shared/schema";
import { desc } from "drizzle-orm";

export interface IStorage {
  createScore(score: InsertScore): Promise<Score>;
  getTopScores(limit?: number): Promise<Score[]>;
}

export class DatabaseStorage implements IStorage {
  async createScore(insertScore: InsertScore): Promise<Score> {
    const [score] = await db.insert(scores).values(insertScore).returning();
    return score;
  }

  async getTopScores(limit = 10): Promise<Score[]> {
    return await db.select()
      .from(scores)
      .orderBy(desc(scores.score))
      .limit(limit);
  }
}

export const storage = new DatabaseStorage();
