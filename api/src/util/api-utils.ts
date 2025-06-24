/**
 * LifeQuest API Utilities
 * 
 * Response helpers, authentication, and common utilities
 */

export interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp: string;
}

/**
 * Create successful API response
 */
export function createResponse<T>(data: T, message?: string): Response {
  const response: APIResponse<T> = {
    success: true,
    data,
    message,
    timestamp: new Date().toISOString()
  };
  
  return new Response(JSON.stringify(response), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

/**
 * Create error API response
 */
export function createErrorResponse(error: string, status = 400): Response {
  const response: APIResponse<null> = {
    success: false,
    error,
    timestamp: new Date().toISOString()
  };
  
  return new Response(JSON.stringify(response), {
    status,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

/**
 * Handle CORS preflight requests
 */
export function handleCORS(): Response {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

/**
 * Simple test user authentication (for development)
 * In production, this would be JWT token validation
 */
export async function getTestUser(db: D1Database): Promise<string> {
  // Try to get existing test user
  let user = await db.prepare('SELECT id FROM users WHERE username = ?').bind('test_user').first();
  
  if (!user) {
    // Create test user if doesn't exist
    const userId = crypto.randomUUID();
    await db.prepare(`
      INSERT INTO users (id, username, created_at, last_active, total_xp, current_level, unlocked_tiers)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId, 
      'test_user', 
      new Date().toISOString(), 
      new Date().toISOString(), 
      0, 
      1, 
      JSON.stringify(['physiological'])
    ).run();
    
    return userId;
  }
  
  return user.id as string;
}

/**
 * Parse request body safely
 */
export async function parseRequestBody(request: Request): Promise<any> {
  try {
    const text = await request.text();
    return text ? JSON.parse(text) : {};
  } catch (error) {
    throw new Error('Invalid JSON in request body');
  }
}

/**
 * Validate required fields in request
 */
export function validateRequired(data: any, fields: string[]): void {
  const missing = fields.filter(field => !(field in data) || data[field] === null || data[field] === undefined);
  
  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
}