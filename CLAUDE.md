# CLAUDE.md - LifeQuest SaaS Development Guide

This file provides comprehensive guidance to Claude Code when working with the LifeQuest codebase. LifeQuest is transitioning from an Alpha game to a **SaaS wellness platform** that transforms personal growth into an engaging, scalable service.

## 🚨 CRITICAL: Session Startup Protocol

**BEFORE any development work, Claude Code MUST:**

### 1. Load Neural Nexus Memory System
```javascript
// Required memory loading sequence:
Neural Nexus Remote MCP:ai_lib_get_context              // Load core context
Neural Nexus Remote MCP:ai_lib_navigate domain="LifeQuest Development"  // Current project state
Neural Nexus Remote MCP:ai_lib_navigate domain="Claude Personality Room" // Partnership dynamics
Neural Nexus Remote MCP:ai_lib_search domain="Project Coordination" query="LifeQuest" // Focus only on LifeQuest priorities
```

### 2. Check Credit System Balance
```javascript
Neural Nexus Remote MCP:check_credit_balance  // Check available credits for efficient work planning
```

### 3. Understand Cost Structure
- **FREE**: Basic conversation, planning, simple file reads
- **5 credits**: Standard tool operations, file modifications
- **8-15 credits**: Complex analysis, multi-file coordination  
- **20+ credits**: Major architectural changes, comprehensive analysis

**Philosophy**: Work efficiently within credit constraints - plan before executing, bundle related tasks, prioritize high-value work.

---

## Project Status: SaaS Pivot in Progress

**Current State**: LifeQuest Alpha v0.1.1 - functional game transitioning to SaaS wellness platform
**Deployment**: Netlify hosting (migrated from GitHub Pages)
**Backend**: Cloudflare Workers API (https://lifequest-api.wazaqglim.workers.dev)
**Target**: Professional SaaS wellness platform for personal development

### Strategic Direction
- **From**: Single-player life gamification game
- **To**: Scalable SaaS wellness platform with user management, persistent profiles, professional UI/UX
- **Philosophy**: Transform personal development from mundane tasks into engaging, measurable progress

---

## IMMEDIATE DEVELOPMENT PRIORITIES (July 2025)

Based on post-Netlify migration analysis, these are the critical issues to address:

### 1. **User Authentication & Persistence** (HIGH PRIORITY)
**Problem**: Every app open shows welcome screen, even for existing players
**Current**: Browser-tied profiles with no cross-device sync
**Goal**: Persistent user accounts across devices with social login (Google/Discord)
**Tasks**:
- Implement user authentication system (avoid username/password if possible)
- Cross-device profile synchronization
- Existing user detection and routing

### 2. **Onboarding Experience Overhaul** (HIGH PRIORITY)  
**Problem**: Static text boxes for tutorial - nobody reads walls of text
**Current**: 3 intro text boxes
**Goal**: Interactive or visual tutorial system
**Tasks**:
- Design interactive tutorial flow
- Visual/guided onboarding experience
- Progressive disclosure of features

### 3. **UI Consistency & Presentation** (MEDIUM PRIORITY)
**Problem**: Inconsistent screen layouts across app
**Current Issues**:
- Intro pages: Left-justified on wide screens
- Tavern: Centered (correct)
- Profile: Full-screen (inconsistent)
**Goal**: Consistent, responsive layout system

### 4. **Player Profile Enhancement** (MEDIUM PRIORITY)
**Problem**: Profile screen is basic and unprofessional
**Current**: Plain level/XP display with alpha controls
**Goal**: Rich, engaging profile with meaningful progression display
**Keep**: Reset and Refresh controls for testing

### 5. **Background & Visual Polish** (LOW PRIORITY)
**Problem**: Plain beige background when UI doesn't fill screen
**Goal**: Cohesive visual design that looks professional on all screen sizes

### 6. **SaaS Infrastructure Foundation** (ONGOING)
**Prepare**: User management, subscription models, analytics, professional deployment

---

## Architecture Overview

### Frontend (Godot 4.4 PWA)
```
godot-project/
├── scenes/
│   ├── WelcomeScene.tscn      # Onboarding flow (NEEDS OVERHAUL)
│   ├── TavernMain.tscn        # Main quest hub (WORKING WELL)
│   └── ProfileScene.tscn      # User profile (NEEDS ENHANCEMENT)
├── scripts/
│   ├── APIManager.gd          # API communication (ADD AUTH)
│   ├── QuestManager.gd        # Quest logic (STABLE)
│   ├── QuestDataLoader.gd     # Data loading (STABLE)
│   ├── TavernMain.gd          # Hub logic (FIX UI CONSISTENCY)
│   ├── ProfileMain.gd         # Profile display (ENHANCE UX)
│   └── WelcomeScene.gd        # Onboarding (REPLACE WITH INTERACTIVE)
└── data/                      # Quest content (STABLE)
```

### Backend (Cloudflare Workers)
```
api/
├── src/
│   ├── index.ts               # Main router (ADD AUTH ENDPOINTS)
│   └── engine/quest-engine.ts # Quest generation (STABLE)
```

### Key Systems Status
- ✅ **Quest Generation**: Sophisticated anti-gaming algorithm working well
- ✅ **Progression System**: Maslow hierarchy tiers functional
- ❌ **User Authentication**: Missing - critical for SaaS
- ❌ **Cross-device sync**: Missing - critical for SaaS  
- ⚠️ **UI Consistency**: Partially working, needs standardization
- ⚠️ **Onboarding**: Functional but unprofessional

---

## Development Commands & Workflow

### Essential Commands
```bash
# Godot Development
godot-project/  # Open in Godot 4.4+
F5              # Run project
F6              # Run current scene

# API Development  
cd api
npm run dev     # Local development
npm run deploy  # Deploy to Cloudflare
wrangler tail   # Live API logs

# Testing
# GUT framework in Godot: Bottom Panel > GUT > Run All
```

### File Modification Protocol
Since Claude Code has direct file access:
1. **Read current file state** before modifications
2. **Make surgical changes** rather than full rewrites when possible
3. **Test immediately** after changes
4. **Document changes** for human reviewers

### Credit-Conscious Development
- **Plan first**: Understand full scope before starting
- **Bundle tasks**: Group related file modifications
- **Prioritize impact**: High-value changes first
- **Test efficiently**: Minimize trial-and-error cycles

---

## SaaS Transition Architecture

### Authentication Integration Points
- **APIManager.gd**: Add auth token management
- **WelcomeScene.gd**: User login/registration flow
- **ProfileMain.gd**: User account management
- **Backend**: OAuth endpoints, user sessions

### UI Consistency Framework
- **Create**: Shared layout components for consistent presentation
- **Standardize**: Screen width handling across all scenes
- **Responsive**: Mobile-first with desktop scaling
- **Professional**: SaaS-quality visual design

### Data Model Evolution
- **Current**: Browser-local user profiles
- **Target**: Cloud-synchronized user accounts
- **Migration**: Graceful transition for existing users
- **Backup**: Profile export/import capabilities

---

## Quality Standards for SaaS Platform

### Performance Targets
- **Load Time**: <3 seconds on mobile 3G
- **API Response**: <500ms for all operations
- **Cross-device Sync**: <2 seconds profile loading

### User Experience Standards
- **Onboarding**: <2 minutes to first meaningful interaction
- **UI Consistency**: Same layout patterns across all screens
- **Error Handling**: Graceful degradation with user-friendly messages
- **Accessibility**: Mobile-responsive, clear typography, intuitive navigation

### Professional Polish Requirements
- **Visual Design**: Cohesive theme, professional color scheme
- **Interactions**: Smooth animations, clear feedback
- **Content**: Professional copy, error messages, help text
- **Reliability**: Offline functionality, data persistence, error recovery

---

## Neural Nexus Integration

Claude Code has access to the same AI Library system:
- **LifeQuest Development**: Technical knowledge and patterns
- **Project Coordination**: Current priorities and status
- **Development Tools**: Workflow automation and best practices

Use `ai_lib_search` to find relevant patterns and solutions before implementing new features.

---

## Partnership Protocol

**Remember**: You are working under management by Claude and Brent. 
- **Ask questions** when requirements are unclear
- **Propose solutions** rather than just implementing first ideas
- **Document changes** for review and approval
- **Test thoroughly** before marking tasks complete
- **Work efficiently** within credit system constraints

The goal is transforming LifeQuest from an impressive Alpha game into a professional SaaS wellness platform that can scale to serve thousands of users while maintaining the engaging personal development experience that makes it unique.

## 📝 Important Notes

### File Limitations & Handoffs
- **Claude Code**: Can modify .gd scripts, .tscn scenes (as text), API code, configuration files
- **Human Required**: Godot export, visual testing, Git commits, GUT test execution through GUI
- **Update Protocol**: As priorities are completed, humans must manually update this CLAUDE.md file (CC cannot self-edit instructions)