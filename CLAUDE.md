# CrypCop

Real-time Solana token scanner and rug-pull detector. AI-powered risk analysis for crypto traders.

## Tech Stack
- Rails 8.0.4 / Ruby 3.4.3 / PostgreSQL
- Hotwire (Turbo Streams + Stimulus) / Tailwind CSS v4
- Solid Queue, Solid Cache, Solid Cable
- Claude API (Sonnet) for AI analysis
- Devise (auth), Stripe (billing)

## Commands
```bash
bin/rails server              # Start dev server
bin/dev                       # Start with Procfile.dev (server + esbuild + tailwind)
bin/rails test                # Run all tests
bin/rails test:system         # Run system tests
bin/rails db:migrate          # Run migrations
bin/rails db:seed             # Seed database
bundle exec brakeman          # Security scan
bundle exec rubocop           # Lint
```

## Architecture
- **Models:** User, Token, Scan, WatchlistItem, Alert, TrustVote, Subscription
- **Services:** All business logic in `app/services/` (Solana API clients, AI analysis, billing)
- **Jobs:** Background processing via Solid Queue in `app/jobs/`
- **Channels:** Action Cable channels in `app/channels/` for real-time Turbo Streams

## Conventions
- Dark theme UI with neon green (#00FF88) and cyan (#00D4FF) accents
- Service objects for all external API calls and complex business logic
- WebMock + VCR for stubbing external APIs in tests
- FactoryBot for test fixtures
- No co-author lines in git commits
- Conventional commit messages (e.g., "feat: add token scanner", "fix: rate limit check")

## Key Environment Variables
- `HELIUS_API_KEY` - Solana RPC and token data
- `ANTHROPIC_API_KEY` - Claude API for AI analysis
- `STRIPE_SECRET_KEY` / `STRIPE_PUBLISHABLE_KEY` - Billing
- `STRIPE_WEBHOOK_SECRET` - Stripe webhook verification
- `STRIPE_PRICE_ID_PRO` - Pro tier price ID
