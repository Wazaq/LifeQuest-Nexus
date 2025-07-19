/**
 * LifeQuest API Utilities
 * 
 * Response helpers, authentication, OAuth, and common utilities
 */

import jwt from '@tsndr/cloudflare-worker-jwt';

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
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-User-ID',
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
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-User-ID',
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
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-User-ID',
    },
  });
}

/**
 * Get or create user based on X-User-ID header
 * Falls back to test user if no header provided
 */
export async function getUserFromRequest(request: Request, db: D1Database): Promise<string> {
  // Get user ID from header
  const headerUserId = request.headers.get('X-User-ID');
  
  if (headerUserId) {
    // Use provided user ID - create user if doesn't exist
    return await getOrCreateUser(db, headerUserId);
  } else {
    // Fallback to test user for backwards compatibility
    return await getTestUser(db);
  }
}

/**
 * Get or create user by ID
 */
export async function getOrCreateUser(db: D1Database, clientUserId: string): Promise<string> {
  // Check if user exists by matching the client user ID as username
  let user = await db.prepare('SELECT id FROM users WHERE username = ?').bind(clientUserId).first();
  
  if (!user) {
    // Create new user with client ID as username
    const userId = crypto.randomUUID();
    await db.prepare(`
      INSERT INTO users (id, username, created_at, last_active, total_xp, current_level, unlocked_tiers)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId, 
      clientUserId,  // Use client ID as username for tracking
      new Date().toISOString(), 
      new Date().toISOString(), 
      0, 
      1, 
      JSON.stringify(['physiological'])
    ).run();
    
    console.log(`🆕 Created new user: ${clientUserId} -> ${userId}`);
    return userId;
  }
  
  // Update last active time
  await db.prepare('UPDATE users SET last_active = ? WHERE id = ?')
    .bind(new Date().toISOString(), user.id as string).run();
  
  return user.id as string;
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

// OAuth and JWT Utilities

interface GoogleUserInfo {
  id: string;
  email: string;
  name: string;
  picture?: string;
}

interface SessionData {
  userId: string;
  googleId?: string;
  email?: string;
  displayName?: string;
  exp: number;
}

/**
 * Generate JWT token for authenticated user
 */
export async function generateJWT(userId: string, googleData: GoogleUserInfo | null, jwtSecret: string): Promise<string> {
  const payload: SessionData = {
    userId,
    exp: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60), // 30 days
  };
  
  if (googleData) {
    payload.googleId = googleData.id;
    payload.email = googleData.email;
    payload.displayName = googleData.name;
  }
  
  return await jwt.sign(payload, jwtSecret);
}

/**
 * Verify and decode JWT token
 */
export async function verifyJWT(token: string, jwtSecret: string): Promise<SessionData | null> {
  try {
    const isValid = await jwt.verify(token, jwtSecret);
    if (!isValid) return null;
    
    const payload = jwt.decode(token);
    return payload.payload as SessionData;
  } catch (error) {
    console.error('JWT verification error:', error);
    return null;
  }
}

/**
 * Get user from Authorization header (JWT) or fallback to X-User-ID
 */
export async function getUserFromAuthRequest(request: Request, db: D1Database, jwtSecret: string): Promise<string> {
  // Try JWT authentication first
  const authHeader = request.headers.get('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    const sessionData = await verifyJWT(token, jwtSecret);
    
    if (sessionData) {
      // Update last_used in session table
      await updateSessionLastUsed(db, token);
      return sessionData.userId;
    }
  }
  
  // Fallback to existing X-User-ID system
  return await getUserFromRequest(request, db);
}

/**
 * Create or link user account with Google OAuth data
 */
export async function createOrLinkGoogleUser(db: D1Database, googleData: GoogleUserInfo, existingUserId?: string): Promise<string> {
  // Check if Google account already exists
  let user = await db.prepare('SELECT id FROM users WHERE google_id = ?').bind(googleData.id).first();
  
  if (user) {
    // Update existing Google user
    await db.prepare(`
      UPDATE users SET 
        email = ?, 
        display_name = ?, 
        avatar_url = ?, 
        last_login = ?
      WHERE google_id = ?
    `).bind(
      googleData.email,
      googleData.name,
      googleData.picture || null,
      new Date().toISOString(),
      googleData.id
    ).run();
    
    return user.id as string;
  }
  
  if (existingUserId) {
    // Link Google account to existing user
    await db.prepare(`
      UPDATE users SET 
        google_id = ?, 
        email = ?, 
        display_name = ?, 
        avatar_url = ?, 
        last_login = ?
      WHERE id = ?
    `).bind(
      googleData.id,
      googleData.email,
      googleData.name,
      googleData.picture || null,
      new Date().toISOString(),
      existingUserId
    ).run();
    
    return existingUserId;
  }
  
  // Create new user with Google data
  const userId = crypto.randomUUID();
  await db.prepare(`
    INSERT INTO users (
      id, username, google_id, email, display_name, avatar_url,
      created_at, last_active, last_login, total_xp, current_level, unlocked_tiers
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    userId,
    googleData.name, // Use Google name as username
    googleData.id,
    googleData.email,
    googleData.name,
    googleData.picture || null,
    new Date().toISOString(),
    new Date().toISOString(),
    new Date().toISOString(),
    0,
    1,
    JSON.stringify(['physiological'])
  ).run();
  
  console.log(`🆕 Created new Google user: ${googleData.email} -> ${userId}`);
  return userId;
}

/**
 * Store JWT session in database
 */
export async function storeSession(db: D1Database, userId: string, token: string, userAgent?: string, ipAddress?: string): Promise<void> {
  const sessionId = crypto.randomUUID();
  const tokenHash = await hashToken(token);
  const expiresAt = new Date(Date.now() + (30 * 24 * 60 * 60 * 1000)).toISOString(); // 30 days
  
  await db.prepare(`
    INSERT INTO user_sessions (id, user_id, token_hash, expires_at, user_agent, ip_address)
    VALUES (?, ?, ?, ?, ?, ?)
  `).bind(
    sessionId,
    userId,
    tokenHash,
    expiresAt,
    userAgent || null,
    ipAddress || null
  ).run();
}

/**
 * Update session last_used timestamp
 */
export async function updateSessionLastUsed(db: D1Database, token: string): Promise<void> {
  const tokenHash = await hashToken(token);
  await db.prepare(`
    UPDATE user_sessions 
    SET last_used = CURRENT_TIMESTAMP 
    WHERE token_hash = ? AND expires_at > datetime('now')
  `).bind(tokenHash).run();
}

/**
 * Revoke user session
 */
export async function revokeSession(db: D1Database, token: string): Promise<void> {
  const tokenHash = await hashToken(token);
  await db.prepare('DELETE FROM user_sessions WHERE token_hash = ?').bind(tokenHash).run();
}

/**
 * Hash token for secure storage
 */
async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Exchange Google OAuth code for user info
 */
export async function exchangeGoogleCode(code: string, clientId: string, clientSecret: string, redirectUri: string): Promise<GoogleUserInfo> {
  // Exchange authorization code for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    }),
  });
  
  if (!tokenResponse.ok) {
    throw new Error('Failed to exchange authorization code');
  }
  
  const tokenData = await tokenResponse.json() as any;
  
  // Get user info using access token
  const userResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
    headers: {
      'Authorization': `Bearer ${tokenData.access_token}`,
    },
  });
  
  if (!userResponse.ok) {
    throw new Error('Failed to fetch user info');
  }
  
  return await userResponse.json() as GoogleUserInfo;
}