/**
 * LifeQuest Quest Engine
 * 
 * Smart quest generation algorithm with anti-gaming features
 * Handles quest selection, completion, and progression logic
 */

export interface QuestDefinition {
  id: string;
  title: string;
  description: string;
  category: string;
  difficulty: number;
  xp_reward: number;
  cooldown_hours: number;
  duration_days: number;
  is_multi_step: boolean;
  total_steps: number;
  tags: string[];
  icon_path: string;
  is_active: boolean;
}

export interface UserStats {
  current_level: number;
  unlocked_tiers: string[];
  total_xp: number;
}

export interface QuestHistory {
  quest_id: string;
  completed_at: Date;
  category: string;
  tags: string[];
}

export interface WeightedQuest {
  quest: QuestDefinition;
  weight: number;
  reasons: string[];
}

export class QuestEngine {
  constructor(private db: D1Database) {}

  /**
   * Generate a random quest for user using smart weighted selection
   */
  async generateRandomQuest(userId: string): Promise<QuestDefinition> {
    // 1. Get user stats and recent history
    const userStats = await this.getUserStats(userId);
    const recentHistory = await this.getRecentQuestHistory(userId, 7);
    
    // 2. Get available quests (not on cooldown)
    const availableQuests = await this.getAvailableQuests(userId, userStats.unlocked_tiers);
    
    if (availableQuests.length === 0) {
      throw new Error('No quests available - all on cooldown');
    }
    
    // 3. Apply smart weighting algorithm
    const weightedQuests = this.calculateQuestWeights(availableQuests, recentHistory, userStats);
    
    // 4. Select using weighted random
    const selectedQuest = this.selectWeightedRandom(weightedQuests);
    
    // 5. Create quest instance for user
    await this.createQuestInstance(userId, selectedQuest);
    
    return selectedQuest;
  }

  /**
   * Complete a quest and award XP/achievements
   */
  async completeQuest(userId: string, questId: string): Promise<{ xp_gained: number; level_up: boolean; tier_unlocks: string[] }> {
    // Get active quest
    const questHistory = await this.db.prepare(`
      SELECT * FROM user_quest_history 
      WHERE user_id = ? AND quest_id = ? AND state = 'active'
      ORDER BY assigned_at DESC LIMIT 1
    `).bind(userId, questId).first();

    if (!questHistory) {
      throw new Error('No active quest found');
    }

    // Get quest definition for XP reward
    const questDef = await this.db.prepare(`
      SELECT * FROM quest_definitions WHERE id = ?
    `).bind(questId).first();

    if (!questDef) {
      throw new Error('Quest definition not found');
    }

    const xpGained = questDef.xp_reward;

    // Mark quest as completed
    await this.db.prepare(`
      UPDATE user_quest_history 
      SET state = 'completed', completed_at = ?, xp_earned = ?
      WHERE user_id = ? AND quest_id = ? AND state = 'active'
    `).bind(new Date().toISOString(), xpGained, userId, questId).run();

    // Update user stats
    const user = await this.db.prepare(`
      SELECT * FROM users WHERE id = ?
    `).bind(userId).first();

    if (!user) {
      throw new Error('User not found');
    }

    const newTotalXP = (user.total_xp as number) + (xpGained as number);
    const oldLevel = user.current_level as number;
    const newLevel = Math.floor(newTotalXP / 100) + 1; // 100 XP per level
    const levelUp = newLevel > oldLevel;

    // Update user XP and level
    await this.db.prepare(`
      UPDATE users 
      SET total_xp = ?, current_level = ?, last_active = ?
      WHERE id = ?
    `).bind(newTotalXP, newLevel, new Date().toISOString(), userId).run();

    // Check for tier unlocks
    const tierUnlocks = await this.checkTierUnlocks(userId);

    return { 
      xp_gained: xpGained as number, 
      level_up: levelUp,
      tier_unlocks: tierUnlocks
    };
  }

  /**
   * Get available quests not on cooldown
   */
  private async getAvailableQuests(userId: string, unlockedTiers: string[]): Promise<QuestDefinition[]> {
    // Get all active quests for unlocked tiers
    const placeholders = unlockedTiers.map(() => '?').join(',');
    const allQuests = await this.db.prepare(`
      SELECT * FROM quest_definitions 
      WHERE category IN (${placeholders}) 
      AND is_active = TRUE
    `).bind(...unlockedTiers).all();

    // Filter out quests on cooldown
    const availableQuests = [];
    
    for (const quest of allQuests.results) {
      const isAvailable = await this.isQuestAvailable(userId, quest.id as string, quest.cooldown_hours as number);
      if (isAvailable) {
        // Parse JSON fields and add proper typing
        const typedQuest = quest as any;
        typedQuest.tags = JSON.parse(typedQuest.tags || '[]');
        availableQuests.push(typedQuest as QuestDefinition);
      }
    }
    
    return availableQuests;
  }

  /**
   * Check if quest is off cooldown
   */
  private async isQuestAvailable(userId: string, questId: string, cooldownHours: number): Promise<boolean> {
    const lastCompletion = await this.db.prepare(`
      SELECT completed_at FROM user_quest_history 
      WHERE user_id = ? AND quest_id = ? AND state = 'completed'
      ORDER BY completed_at DESC LIMIT 1
    `).bind(userId, questId).first();

    if (!lastCompletion) return true; // Never completed

    const cooldownEnd = new Date(lastCompletion.completed_at as string);
    cooldownEnd.setHours(cooldownEnd.getHours() + cooldownHours);

    return new Date() >= cooldownEnd;
  }

  /**
   * Smart weighting algorithm - the anti-gaming magic!
   */
  private calculateQuestWeights(quests: QuestDefinition[], recentHistory: QuestHistory[], userStats: UserStats): WeightedQuest[] {
    return quests.map(quest => {
      let weight = 1.0;
      const reasons: string[] = [];

      // 1. CATEGORY VARIETY BONUS
      const primaryTag = quest.tags[0];
      const categoryCount = recentHistory.filter(h => {
        return h.tags && h.tags.includes(primaryTag);
      }).length;

      if (categoryCount === 0) {
        weight *= 1.5; // 50% boost for unexplored categories
        reasons.push('New category bonus');
      } else if (categoryCount >= 2) {
        weight *= 0.6; // 40% penalty for overused categories
        reasons.push('Category saturation penalty');
      }

      // 2. DIFFICULTY PROGRESSION
      const userLevel = userStats.current_level || 1;
      const optimalDifficulty = Math.floor(userLevel / 10);

      if (quest.difficulty === optimalDifficulty) {
        weight *= 1.3; // 30% boost for perfect difficulty match
        reasons.push('Perfect difficulty match');
      } else if (Math.abs(quest.difficulty - optimalDifficulty) === 1) {
        weight *= 1.1; // 10% boost for close difficulty
        reasons.push('Good difficulty range');
      }

      // 3. RECENCY PENALTY
      const daysSinceLastCompletion = this.getDaysSinceLastCompletion(quest.id, recentHistory);
      if (daysSinceLastCompletion < 2) {
        weight *= 0.5; // 50% penalty for very recent completion
        reasons.push('Recent completion penalty');
      } else if (daysSinceLastCompletion < 4) {
        weight *= 0.8; // 20% penalty for somewhat recent
        reasons.push('Mild recency penalty');
      }

      // 4. XP VALUE CONSIDERATION
      const xpMultiplier = 1 + (quest.xp_reward - 15) / 100;
      weight *= Math.max(xpMultiplier, 0.8);

      // 5. MULTI-STEP BONUS
      if (quest.is_multi_step) {
        weight *= 1.1; // Slight boost for engaging quests
        reasons.push('Multi-step engagement bonus');
      }

      return {
        quest,
        weight: Math.max(weight, 0.1), // Minimum 10% chance
        reasons
      };
    });
  }

  /**
   * Weighted random selection
   */
  private selectWeightedRandom(weightedQuests: WeightedQuest[]): QuestDefinition {
    const totalWeight = weightedQuests.reduce((sum, wq) => sum + wq.weight, 0);
    let random = Math.random() * totalWeight;

    for (const weightedQuest of weightedQuests) {
      random -= weightedQuest.weight;
      if (random <= 0) {
        console.log(`Selected: ${weightedQuest.quest.title} (weight: ${weightedQuest.weight.toFixed(2)}, reasons: ${weightedQuest.reasons.join(', ')})`);
        return weightedQuest.quest;
      }
    }

    return weightedQuests[0].quest; // Fallback
  }

  /**
   * Create quest instance for user
   */
  private async createQuestInstance(userId: string, quest: QuestDefinition): Promise<void> {
    const deadline = new Date();
    deadline.setDate(deadline.getDate() + quest.duration_days);

    await this.db.prepare(`
      INSERT INTO user_quest_history (
        user_id, quest_id, state, assigned_at, deadline, current_progress
      ) VALUES (?, ?, 'active', ?, ?, 0)
    `).bind(userId, quest.id, new Date().toISOString(), deadline.toISOString()).run();
  }

  /**
   * Get days since last completion
   */
  private getDaysSinceLastCompletion(questId: string, history: QuestHistory[]): number {
    const lastCompletion = history.find(h => h.quest_id === questId);
    if (!lastCompletion) return 999; // Never completed

    const days = (Date.now() - lastCompletion.completed_at.getTime()) / (1000 * 60 * 60 * 24);
    return Math.floor(days);
  }

  /**
   * Get user stats and progression
   */
  private async getUserStats(userId: string): Promise<UserStats> {
    const user = await this.db.prepare(`
      SELECT * FROM users WHERE id = ?
    `).bind(userId).first();

    if (!user) {
      throw new Error('User not found');
    }

    return {
      current_level: user.current_level as number,
      unlocked_tiers: JSON.parse((user.unlocked_tiers as string) || '["physiological"]'),
      total_xp: user.total_xp as number
    };
  }

  /**
   * Get recent quest completion history
   */
  private async getRecentQuestHistory(userId: string, days: number): Promise<QuestHistory[]> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const history = await this.db.prepare(`
      SELECT h.quest_id, h.completed_at, q.category, q.tags
      FROM user_quest_history h
      JOIN quest_definitions q ON h.quest_id = q.id
      WHERE h.user_id = ? AND h.state = 'completed' 
      AND h.completed_at > ?
      ORDER BY h.completed_at DESC
    `).bind(userId, cutoffDate.toISOString()).all();

    return history.results.map(row => ({
      quest_id: row.quest_id as string,
      completed_at: new Date(row.completed_at as string),
      category: row.category as string,
      tags: JSON.parse((row.tags as string) || '[]')
    }));
  }

  /**
   * Check for tier unlocks based on completion counts
   */
  private async checkTierUnlocks(userId: string): Promise<string[]> {
    // Get completion counts by tier
    const completionCounts = await this.db.prepare(`
      SELECT q.category, COUNT(*) as count
      FROM user_quest_history h
      JOIN quest_definitions q ON h.quest_id = q.id
      WHERE h.user_id = ? AND h.state = 'completed'
      GROUP BY q.category
    `).bind(userId).all();

    const counts: Record<string, number> = {};
    completionCounts.results.forEach((row: any) => {
      counts[row.category] = row.count;
    });

    // Maslow tier unlock requirements
    const tierRequirements = {
      'safety': { 'physiological': 10 },
      'security': { 'physiological': 5, 'safety': 10 },
      'love': { 'physiological': 5, 'safety': 5, 'security': 10 },
      'belonging': { 'physiological': 5, 'safety': 5, 'security': 5, 'love': 10 },
      'esteem': { 'physiological': 5, 'safety': 5, 'security': 5, 'love': 5, 'belonging': 10 },
      'self_actualization': { 'physiological': 5, 'safety': 5, 'security': 5, 'love': 5, 'belonging': 5, 'esteem': 10 }
    };

    const user = await this.db.prepare('SELECT unlocked_tiers FROM users WHERE id = ?').bind(userId).first();
    
    if (!user) {
      throw new Error('User not found');
    }
    
    const currentUnlocked = JSON.parse((user.unlocked_tiers as string) || '["physiological"]');
    const newlyUnlocked = [];

    for (const [tier, requirements] of Object.entries(tierRequirements)) {
      if (currentUnlocked.includes(tier)) continue;

      const meetsRequirements = Object.entries(requirements).every(([reqTier, reqCount]) => {
        return (counts[reqTier] || 0) >= reqCount;
      });

      if (meetsRequirements) {
        newlyUnlocked.push(tier);
        currentUnlocked.push(tier);
      }
    }

    // Update user's unlocked tiers if new ones unlocked
    if (newlyUnlocked.length > 0) {
      await this.db.prepare(`
        UPDATE users SET unlocked_tiers = ? WHERE id = ?
      `).bind(JSON.stringify(currentUnlocked), userId).run();
    }

    return newlyUnlocked;
  }

  /**
   * Get user's active quests
   */
  async getActiveQuests(userId: string): Promise<any[]> {
    const activeQuests = await this.db.prepare(`
      SELECT h.*, q.title, q.description, q.xp_reward, q.is_multi_step, q.total_steps, q.icon_path
      FROM user_quest_history h
      JOIN quest_definitions q ON h.quest_id = q.id
      WHERE h.user_id = ? AND h.state = 'active'
      ORDER BY h.assigned_at DESC
    `).bind(userId).all();
    
    return activeQuests.results;
  }

  /**
   * Get user profile with stats
   */
  async getUserProfile(userId: string): Promise<any> {
    const user = await this.db.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    if (!user) {
      throw new Error('User not found');
    }

    // Parse JSON fields
    const typedUser = user as any;
    typedUser.unlocked_tiers = JSON.parse((typedUser.unlocked_tiers as string) || '["physiological"]');
    
    return typedUser;
  }
}