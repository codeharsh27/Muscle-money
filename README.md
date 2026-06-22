<div align="center">

# Muscle Money 2.0

**Duolingo for Finance — built for students and young adults
who want to build real financial habits, not just read about them.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-TypeScript-red?logo=nestjs)](https://nestjs.com)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![Gemini](https://img.shields.io/badge/AI-Gemini%201.5%20Flash-orange)](https://deepmind.google/technologies/gemini/)

[Portfolio](https://harshmule.vercel.app) · 
[LinkedIn](https://linkedin.com/in/harshmule27) · 
[Follow on X](https://x.com/codeharsh27)

</div>

---

## The Problem

Most finance apps fail young adults in two ways.

They either lecture (dense content nobody reads) or track 
(dashboards nobody checks). Neither changes behavior.

People already know they should save. Telling them again 
doesn't work. The real problem is building something that 
makes better financial habits feel automatic — not effortful.

---

## What Muscle Money Does

Four things working together in one app:

**1. Automatic expense tracking** — SMS and notification 
parsing captures every UPI/bank transaction in the background. 
No manual entry. No friction.

**2. Nova (AI financial companion)** — not a chatbot, a coach. 
Nova knows your income, spending patterns, and goals. 
It gives specific, actionable advice based on your 
actual behavior, not generic tips.

**3. Zero-risk stock simulator** — practice investing with 
₹15,00,000 in virtual money using live Yahoo Finance data. 
Make mistakes without losing real money.

**4. Gamified financial education** — XP, streaks, and 
interactive quizzes. The same behavioral psychology 
that makes Duolingo addictive, applied to finance.

---

## Why Nova Is Different

Most AI assistants in finance apps are glorified FAQ bots.

Nova is prompt-engineered to behave like a personal CFO 
who has read your bank statements. It combines your 
Financial Score (a 0–100 rating based on savings ratio, 
spending velocity, and goal adherence) with your recent 
transaction data to give advice that is specific to you.

Example Nova insight:
> "You spent 30% of your income on dining this week. 
> Cook at home for 3 days and your score goes up 5 points — 
> keeping your savings goal on track."

Not generic. Not a chart. A specific next action.

---

## Architecture

Muscle Money is a full-stack monorepo built with Turborepo.
muscle-money/

├── apps/

│   ├── mobile/          # Flutter app (iOS + Android)

│   └── api/             # NestJS core API

├── packages/

│   ├── ai-service/      # FastAPI — Nova AI orchestration

│   └── shared/          # Shared types and utilities

├── infrastructure/      # Docker + deployment configs

└── redis/               # Session and cache layer
**Mobile:** Flutter + Dart + Riverpod + GoRouter
Clean Architecture with strict separation of 
Presentation / Domain / Data layers.

**Backend:** NestJS (TypeScript) for core API, 
FastAPI (Python) for AI orchestration and ML features.
Turborepo monorepo — shared types across services.

**AI Layer:** OpenRouter + Gemini 1.5 Flash.
Nova is not a generic LLM call — it has a specific 
system prompt, financial context injection per user, 
and guardrails that keep it focused on finance only.

**Automated Tracking:** Android Notification Listener 
+ SMS reading (with explicit user permission). 
Regex parsing extracts Amount, Merchant, and 
Transaction Type from bank/UPI messages instantly.

**Market Data:** Yahoo Finance API for live stock 
prices and historical charting in the simulator.

---

## Key Technical Decisions

**Why offline-first local storage?**
Financial data needs to be available instantly — 
waiting for a network call to show your balance 
breaks the experience. Local-first with background 
sync keeps the app fast regardless of connectivity.

**Why a monorepo?**
Shared TypeScript types between the Flutter app 
and NestJS backend eliminate a whole class of 
bugs where the frontend and backend disagree 
on data shapes.

**Why FastAPI separate from NestJS?**
AI inference is Python-native. Keeping it in a 
separate FastAPI service means the Node.js API 
never blocks on AI calls — and the AI layer can 
be scaled independently.

---

## Features

| Feature | Description |
|---|---|
| Automatic Expense Tracking | SMS + notification parsing, zero manual input |
| Nova AI Coach | Context-aware financial guidance based on your actual data |
| Financial Score | 0–100 dynamic rating: savings ratio + spending velocity + goal adherence |
| Stock Simulator | Paper trading with live Yahoo Finance data + ₹15L virtual balance |
| Time Machine | Projects your portfolio 10–15 years forward using compound interest |
| Learning Hub | XP + streaks + quizzes — Duolingo-style finance education |
| Onboarding Personalization | Income, goals, debt, risk appetite → personalized from day one |

---

## Getting Started

### Prerequisites
```bash
Flutter SDK 3.x
Node.js 18+
Python 3.10+
Docker (for Redis)
```

### Clone and install
```bash
git clone https://github.com/codeharsh27/Muscle-money.git
cd Muscle-money
npm install          # installs all monorepo packages
```

### Environment setup
```bash
cp .env.example .env
# Add your keys:
# OPENROUTER_API_KEY
# YAHOO_FINANCE_API_KEY
# SUPABASE_URL + SUPABASE_KEY
```

### Run services
```bash
# Start Redis
docker-compose up -d redis

# Start NestJS API
cd apps/api && npm run dev

# Start FastAPI AI service
cd packages/ai-service && uvicorn main:app --reload

# Start Flutter app
cd apps/mobile && flutter run
```

---

## Built By

**Harsh Mule** — Product Engineer

I built Muscle Money because I watched friends lose 
track of money every month not because they didn't 
care, but because existing tools made tracking feel 
like work.

Nova exists because financial advice shouldn't be 
generic. It should know you.

[harshmule.vercel.app](https://harshmule.vercel.app) · 
[harshux27@gmail.com](mailto:harshux27@gmail.com)
