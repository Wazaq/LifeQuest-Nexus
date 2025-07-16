# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Godot Development
- **Run Project**: Open `godot-project/` in Godot 4.4+ and press F5
- **Export to Web**: Project > Export > HTML5 preset (already configured)
- **Run Tests**: In Godot editor, go to Bottom Panel > GUT > Run All

### API Development
```bash
cd api
npm install          # First time setup
npm run dev          # Start local dev server (uses wrangler)
npm run deploy       # Deploy to Cloudflare Workers
npm run type-check   # TypeScript validation
```

## Architecture Overview

LifeQuest is a hybrid web game with two main components:

### Frontend (Godot 4.4)
- **Entry Point**: `godot-project/scenes/WelcomeScene.tscn`
- **Core Singletons**: 
  - `APIManager.gd` - Handles all API communication
  - `QuestManager.gd` - Quest logic and progression system
- **Scene Flow**: WelcomeScene → TavernMain → ProfileScene
- **Quest Data**: JSON files in `godot-project/data/` (categories from Maslow's hierarchy)

### Backend (Cloudflare Workers)
- **Entry**: `api/src/index.ts` - Main request router
- **Quest Engine**: `api/src/engine/quest-engine.ts` - Core quest generation logic
- **Database**: Cloudflare D1 (SQLite) bound as `DB` in wrangler.toml
- **API Base URL**: `https://lifequest-api.wazaqglim.workers.dev`

## Key Development Patterns

### API Integration in Godot
- All API calls go through `APIManager` singleton
- Headers must include `X-User-Id` for user identification
- CORS is configured for GitHub Pages and localhost

### Quest System
- Quests are categorized by Maslow's hierarchy (physiological, safety, love_belonging, esteem, self_actualization)
- Random quest generation with anti-cherry-picking cooldowns
- XP scaling based on difficulty and player level

### Testing
- Unit tests use GUT framework (Godot Unit Testing)
- Test files in `godot-project/Tests/unit/` and `godot-project/Tests/integration/`
- Run specific test: Select test file in GUT panel

### PWA/Web Build
- Export preset already configured for HTML5
- Service worker at `godot-project/builds/web/index.service.worker.js`
- Deployment via GitHub Pages from `builds/web/` directory

## Database Schema

Users table:
- id, username, level, experience_points, tier_unlocked, created_at

Quests table:
- id, title, description, category, difficulty, xp_reward, completion_time_minutes

UserQuests table:
- id, user_id, quest_id, status, completed_at

## Common Development Tasks

### Adding New Quests
1. Add quest data to appropriate JSON file in `godot-project/data/`
2. Run API deploy to sync with database
3. Test quest generation in game

### Debugging API Issues
1. Check browser console for CORS errors
2. Verify `X-User-Id` header is being sent
3. Use `wrangler tail` to see live API logs

### Mobile Testing
1. Export to HTML5
2. Serve locally: `python -m http.server 8000` in `builds/web/`
3. Access from mobile device on same network