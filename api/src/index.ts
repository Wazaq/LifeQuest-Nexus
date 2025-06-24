/**
 * LifeQuest MCP API - Main Entry Point
 * 
 * Life Gamification RPG Backend
 * Transforms daily tasks into epic RPG quests
 */

import { QuestEngine } from './engine/quest-engine';
import { createResponse, createErrorResponse, handleCORS, getTestUser, parseRequestBody } from './util/api-utils';

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const method = request.method;

    // Handle CORS preflight requests
    if (method === 'OPTIONS') {
      return handleCORS();
    }
    
    try {
      // Health check endpoint
      if (url.pathname === '/health') {
        return createResponse({
          status: 'healthy',
          service: 'LifeQuest API',
          version: '1.0.0',
          timestamp: new Date().toISOString(),
          environment: env.ENVIRONMENT
        });
      }
      
      // Database test endpoint
      if (url.pathname === '/db-test') {
        const result = await env.DB.prepare('SELECT name FROM sqlite_master WHERE type="table"').all();
        return createResponse({
          status: 'database_connected',
          tables: result.results,
          timestamp: new Date().toISOString()
        });
      }

      // Initialize Quest Engine
      const questEngine = new QuestEngine(env.DB);

      // API Routes
      if (url.pathname.startsWith('/api/')) {
        
        // Generate random quest
        if (url.pathname === '/api/quests/generate' && method === 'POST') {
          const userId = await getTestUser(env.DB);
          const quest = await questEngine.generateRandomQuest(userId);
          return createResponse(quest, 'Quest generated successfully');
        }

        // Complete quest
        if (url.pathname.startsWith('/api/quests/') && url.pathname.endsWith('/complete') && method === 'POST') {
          const questId = url.pathname.split('/')[3];
          const userId = await getTestUser(env.DB);
          const result = await questEngine.completeQuest(userId, questId);
          
          let message = `Quest completed! +${result.xp_gained} XP`;
          if (result.level_up) {
            message += ' 🎉 LEVEL UP!';
          }
          if (result.tier_unlocks.length > 0) {
            message += ` 🔓 New tiers unlocked: ${result.tier_unlocks.join(', ')}`;
          }
          
          return createResponse(result, message);
        }

        // Get user profile
        if (url.pathname === '/api/user/profile' && method === 'GET') {
          const userId = await getTestUser(env.DB);
          const profile = await questEngine.getUserProfile(userId);
          return createResponse(profile);
        }

        // Get active quests
        if (url.pathname === '/api/quests/active' && method === 'GET') {
          const userId = await getTestUser(env.DB);
          const activeQuests = await questEngine.getActiveQuests(userId);
          return createResponse(activeQuests);
        }

        // Get available quest count (for UI)
        if (url.pathname === '/api/quests/available-count' && method === 'GET') {
          const userId = await getTestUser(env.DB);
          const userStats = await questEngine.getUserProfile(userId);
          const unlockedTiers = userStats.unlocked_tiers;
          
          // Quick count of available quests
          const placeholders = unlockedTiers.map(() => '?').join(',');
          const result = await env.DB.prepare(`
            SELECT COUNT(*) as count FROM quest_definitions 
            WHERE category IN (${placeholders}) AND is_active = TRUE
          `).bind(...unlockedTiers).first();
          
          return createResponse({ 
            available_count: result ? (result.count as number) : 0,
            unlocked_tiers: unlockedTiers
          });
        }

        // API endpoint not found
        return createErrorResponse('API endpoint not found', 404);
      }
      
      // Default welcome response
      return createResponse({
        message: 'Welcome to LifeQuest API! 🎮⚡',
        documentation: 'See /health for system status, /db-test for database connection',
        endpoints: [
          'POST /api/quests/generate - Generate random quest',
          'POST /api/quests/{id}/complete - Complete quest',
          'GET /api/user/profile - Get user profile',
          'GET /api/quests/active - Get active quests',
          'GET /api/quests/available-count - Get available quest count'
        ]
      });

    } catch (error) {
      console.error('API Error:', error);
      return createErrorResponse(
        error instanceof Error ? error.message : 'Internal server error', 
        500
      );
    }
  },
};