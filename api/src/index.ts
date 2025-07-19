/**
 * LifeQuest MCP API - Main Entry Point
 * 
 * Life Gamification RPG Backend
 * Transforms daily tasks into epic RPG quests
 */

import { QuestEngine } from './engine/quest-engine';
import { 
  createResponse, 
  createErrorResponse, 
  handleCORS, 
  getTestUser, 
  getUserFromRequest, 
  parseRequestBody,
  getUserFromAuthRequest,
  exchangeGoogleCode,
  createOrLinkGoogleUser,
  generateJWT,
  storeSession,
  revokeSession,
  verifyJWT
} from './util/api-utils';

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
  GOOGLE_CLIENT_ID: string;
  GOOGLE_CLIENT_SECRET: string;
  JWT_SECRET: string;
  OAUTH_REDIRECT_DEV: string;
  OAUTH_REDIRECT_PROD: string;
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

      // OAuth Authentication Routes
      if (url.pathname.startsWith('/auth/')) {
        
        // Initiate Google OAuth flow
        if (url.pathname === '/auth/google/login' && method === 'GET') {
          const state = crypto.randomUUID();
          const redirectUri = env.ENVIRONMENT === 'development' ? env.OAUTH_REDIRECT_DEV : env.OAUTH_REDIRECT_PROD;
          
          const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
          authUrl.searchParams.set('client_id', env.GOOGLE_CLIENT_ID);
          authUrl.searchParams.set('redirect_uri', redirectUri);
          authUrl.searchParams.set('response_type', 'code');
          authUrl.searchParams.set('scope', 'openid email profile');
          authUrl.searchParams.set('state', state);
          
          return createResponse({
            auth_url: authUrl.toString(),
            state
          }, 'OAuth flow initiated');
        }
        
        // Handle Google OAuth callback
        if (url.pathname === '/auth/google/callback' && method === 'GET') {
          const code = url.searchParams.get('code');
          const state = url.searchParams.get('state');
          
          if (!code) {
            return createErrorResponse('Missing authorization code', 400);
          }
          
          try {
            const redirectUri = env.ENVIRONMENT === 'development' ? env.OAUTH_REDIRECT_DEV : env.OAUTH_REDIRECT_PROD;
            const googleData = await exchangeGoogleCode(code, env.GOOGLE_CLIENT_ID, env.GOOGLE_CLIENT_SECRET, redirectUri);
            
            // Check for existing user to link (via X-User-ID header)
            let existingUserId: string | undefined;
            try {
              existingUserId = await getUserFromRequest(request, env.DB);
            } catch {
              // No existing user, will create new one
            }
            
            const userId = await createOrLinkGoogleUser(env.DB, googleData, existingUserId);
            const token = await generateJWT(userId, googleData, env.JWT_SECRET);
            
            // Store session
            const userAgent = request.headers.get('user-agent') || undefined;
            const ipAddress = request.headers.get('cf-connecting-ip') || undefined;
            await storeSession(env.DB, userId, token, userAgent, ipAddress);
            
            return createResponse({
              token,
              user: {
                id: userId,
                email: googleData.email,
                name: googleData.name,
                avatar: googleData.picture
              }
            }, 'Authentication successful');
            
          } catch (error) {
            console.error('OAuth callback error:', error);
            return createErrorResponse('Authentication failed', 400);
          }
        }
        
        // Verify JWT token
        if (url.pathname === '/auth/verify' && method === 'POST') {
          try {
            const { token } = await parseRequestBody(request);
            if (!token) {
              return createErrorResponse('Missing token', 400);
            }
            
            const sessionData = await verifyJWT(token, env.JWT_SECRET);
            if (!sessionData) {
              return createErrorResponse('Invalid or expired token', 401);
            }
            
            return createResponse({
              valid: true,
              user_id: sessionData.userId,
              email: sessionData.email,
              display_name: sessionData.displayName
            }, 'Token is valid');
            
          } catch (error) {
            return createErrorResponse('Token verification failed', 401);
          }
        }
        
        // Logout and revoke session
        if (url.pathname === '/auth/logout' && method === 'POST') {
          try {
            const authHeader = request.headers.get('Authorization');
            if (authHeader && authHeader.startsWith('Bearer ')) {
              const token = authHeader.substring(7);
              await revokeSession(env.DB, token);
            }
            
            return createResponse({ logged_out: true }, 'Session terminated');
            
          } catch (error) {
            return createErrorResponse('Logout failed', 400);
          }
        }
        
        // Auth endpoint not found
        return createErrorResponse('Auth endpoint not found', 404);
      }

      // API Routes
      if (url.pathname.startsWith('/api/')) {
        
        // Generate random quest
        if (url.pathname === '/api/quests/generate' && method === 'POST') {
          const userId = await getUserFromAuthRequest(request, env.DB, env.JWT_SECRET);
          const quest = await questEngine.generateRandomQuest(userId);
          return createResponse(quest, 'Quest generated successfully');
        }

        // Complete quest
        if (url.pathname.startsWith('/api/quests/') && url.pathname.endsWith('/complete') && method === 'POST') {
          const questId = url.pathname.split('/')[3];
          const userId = await getUserFromAuthRequest(request, env.DB, env.JWT_SECRET);
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
          const userId = await getUserFromAuthRequest(request, env.DB, env.JWT_SECRET);
          const profile = await questEngine.getUserProfile(userId);
          return createResponse(profile);
        }

        // Get active quests
        if (url.pathname === '/api/quests/active' && method === 'GET') {
          const userId = await getUserFromAuthRequest(request, env.DB, env.JWT_SECRET);
          const activeQuests = await questEngine.getActiveQuests(userId);
          return createResponse(activeQuests);
        }

        // Get available quest count (for UI)
        if (url.pathname === '/api/quests/available-count' && method === 'GET') {
          const userId = await getUserFromAuthRequest(request, env.DB, env.JWT_SECRET);
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
