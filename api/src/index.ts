/**
 * LifeQuest MCP API - Main Entry Point
 * 
 * Life Gamification RPG Backend
 * Transforms daily tasks into epic RPG quests
 */

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    
    // Health check endpoint
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        service: 'LifeQuest API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        environment: env.ENVIRONMENT
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Database test endpoint
    if (url.pathname === '/db-test') {
      try {
        const result = await env.DB.prepare('SELECT name FROM sqlite_master WHERE type="table"').all();
        return new Response(JSON.stringify({
          status: 'database_connected',
          tables: result.results,
          timestamp: new Date().toISOString()
        }), {
          headers: { 'Content-Type': 'application/json' }
        });
      } catch (error) {
        return new Response(JSON.stringify({
          status: 'database_error',
          error: error instanceof Error ? error.message : 'Unknown error',
          timestamp: new Date().toISOString()
        }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }
    
    // API routes will go here
    if (url.pathname.startsWith('/api/')) {
      return new Response(JSON.stringify({
        error: 'API endpoints not implemented yet',
        message: 'LifeQuest API is being built!'
      }), {
        status: 501,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Default response
    return new Response(JSON.stringify({
      message: 'Welcome to LifeQuest API! 🎮⚡',
      documentation: 'See /health for system status, /db-test for database connection'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  },
};
