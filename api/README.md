# LifeQuest API

## Development Setup

1. Install dependencies:
```bash
cd api
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Deploy to Cloudflare:
```bash
npm run deploy
```

## API Endpoints

- `GET /health` - Health check
- `POST /api/auth/register` - User registration  
- `POST /api/auth/login` - User authentication
- `GET /api/quests/generate` - Generate random quest
- `POST /api/quests/{id}/complete` - Complete quest

## Environment Variables

Set in `wrangler.toml` for each environment.
