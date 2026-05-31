# Muscle Money

Muscle Money is a production-oriented fintech and AI learning platform for students and young adults. The product direction is "Duolingo for Finance": adaptive lessons, gamified progress, simulated investing, auto-save habits, analytics, and safe AI explanations.

This repository is a Turborepo monorepo with a NestJS API, FastAPI AI service, Flutter mobile app, shared TypeScript packages, and local infrastructure.

## Architecture

```text
apps/
  api/          NestJS API, Prisma, PostgreSQL, Redis, BullMQ
  ai-service/   FastAPI service for structured educational AI outputs
  mobile/       Flutter app using Riverpod, GoRouter, Dio, Hive, secure storage
packages/
  shared-types/ API contracts shared across TypeScript services
  eslint-config/
  tsconfig/
  ui-tokens/
infrastructure/
  docker/
  nginx/
  scripts/
```

## Fintech Safety Rules

Balances are derived from immutable ledger rows. Application code must never directly mutate wallet or simulator balances. Wallet savings, simulated deposits, and simulator cash movement are represented as ledger transactions with idempotency keys.

Market data must flow through backend fetchers, Redis cache, and PostgreSQL snapshots before reaching mobile clients. The frontend never calls external market providers directly.

AI is limited to educational explanations, recommendations, summaries, and adaptive learning support. It must not execute transactions, control balances, or provide personalized investment advice.

## Local Prerequisites

- Node.js 22
- npm 11
- Docker Desktop
- Flutter stable SDK
- Python 3.11

## Environment

Copy the example env file and replace secrets before running services:

```powershell
Copy-Item .env.example .env
```

Use secrets with at least 32 characters for `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET`.

## Setup

```powershell
npm.cmd install
docker compose up -d postgres redis
npm.cmd run api:prisma:generate
npm.cmd run api:prisma:migrate
npm.cmd --workspace @muscle-money/api run prisma:seed
npm.cmd run dev
```

Flutter:

```powershell
Set-Location apps/mobile
flutter pub get
flutter analyze
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:3000/api/v1
```

Use `http://10.0.2.2:3000/api/v1` for the Android emulator. Use your computer's LAN IP address for a physical Android phone on the same Wi-Fi network.

AI service:

```powershell
Set-Location apps/ai-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install fastapi "uvicorn[standard]" pydantic-settings google-generativeai
uvicorn app.main:app --reload --port 8000
```

## Phase 1 Status

- Turborepo workspace created.
- NestJS API bootstrap added with config validation, security middleware, global validation, response wrapping, exception filtering, request logging, rate limiting, Prisma, Redis, BullMQ, and authentication architecture.
- Prisma schema added for users, profiles, wallet ledger, savings rules, learning, simulator ledger, market assets, notifications, streaks, badges, and audit logs.
- Flutter app bootstrap added with feature-first folders, dark theme, GoRouter, Riverpod, Dio, secure token storage, and first auth screen.
- FastAPI AI service boundary added with structured response models and explicit finance safety boundaries.
- Docker Compose added for PostgreSQL and Redis.
- Dockerfiles, nginx config, CI workflow, env examples, shared packages, linting, formatting, and TypeScript configs added.

## Phase 2 Status

- Authentication now uses persisted `auth_sessions` with hashed refresh tokens, expiry, revocation, and rotation.
- Refresh tokens are submitted directly to `/auth/refresh`; access tokens are not accepted for refresh rotation.
- Email verification uses single-use hashed tokens with expiry through `/auth/verify-email`.
- Logout supports current-session and all-session revocation.
- `/auth/me` returns the authenticated user from a validated access token.
- Auth actions write audit log records for registration, login, refresh rotation, refresh-token reuse detection, email verification, and logout.
- Flutter sign-in is wired to the real API contract, persists tokens with secure storage, and exposes loading/error states through Riverpod.
- Backend unit tests cover registration, session creation, refresh rotation, refresh-token reuse revocation, and email verification.
- Flutter widget tests cover sign-in form rendering and validation.

## Next Engineering Phases

1. Add production email delivery and push notification providers.
2. Add external market ingestion jobs that write Redis cache and PostgreSQL snapshots.
3. Expand mobile dashboard into dedicated wallet, learning, simulator, and analytics screens.
4. Add database-backed integration tests and AI JSON contract tests.
5. Add app release signing, Firebase Crashlytics, and store-ready Android build configuration.

## Phase 3 Status

- Onboarding API added with status and completion endpoints.
- Onboarding stores goals, risk profile, knowledge level, income, spending habits, and learning preferences.
- Mobile signup screen added and wired to the real registration API.
- Mobile onboarding screen added and wired to the real onboarding API.
- Mobile dashboard shell added and wired to analytics summary API.
- Mobile routing now redirects between auth, onboarding, and dashboard states.
- Onboarding service tests added, including expected failure behavior for invalid goals.

Submission/report tracking lives in [docs/submission-notes.md](docs/submission-notes.md).
