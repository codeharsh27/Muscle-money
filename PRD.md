# Product Requirements Document: Muscle Money

## Objective
Muscle Money is a student-first finance learning app designed to help young users learn money skills, practice financial decisions safely, and build saving habits before they risk real money.

## Core Promise
> "Learn money by doing, without risking real money."

## Product Vision
**"Duolingo for Finance + safe investment practice."**
Combines four main loops:
1. Learn finance concepts.
2. Answer quizzes and earn XP.
3. Practice investing in a simulator.
4. Build saving discipline through a wallet-style ledger.

---

## Module Breakdown

### 1. Learning Module
**Differentiation**: Action-oriented, measurable, and adaptive learning connected directly to the simulator and wallet.
**Features**:
- Interactive missions (cards, mini-calculators, scenario questions).
- Personalised learning path (Money Foundations, Saving Discipline, Investing Basics, Risk & Return, Emergency Fund, Student Wealth Builder).
- Adaptive recommendations based on user goals, risk profile, and knowledge level.
- Gamification via XP, completion metrics, and streaks.

### 2. Simulator Engine
**Differentiation**: A controlled virtual investment environment that relies on a deterministic backend.
**Features**:
- Virtual cash and realistic market assets (NIFTYBEES, digital gold, TCS).
- Backend-driven pricing using market snapshots and robust ledger records to prevent frontend manipulation.
- Sell flows, portfolio visualization (P/L, percentage return, holdings list).
- Educational feedback ("Why this trade matters") and simulator challenges tied to lessons.
- Risk warnings and reflection prompts.

### 3. Wallet Module
**Differentiation**: A savings-habit wallet focused on building discipline.
**Features**:
- Ledger-driven manual savings tracking with idempotency keys.
- Savings goals and scheduled savings rules.
- "Money streaks" to gamify saving behavior.
- Direct connection to learning modules (e.g., saving an emergency fund after a lesson).

### 4. AI & Personalization
**Differentiation**: AI acts as a tutor, not a financial advisor.
**Features**:
- Explains concepts based on user level.
- Recommends next lessons and generates quiz prompts.
- Summarizes mistakes to improve learning.
- Onboarding personalization (capturing goals, risk profile, income, spending habits).

---

## 10x Roadmap Priorities (Developer Direction)

1. **Action-Oriented Dashboard**
   - Shift from metric display to daily missions (today's lesson, today's saving action, simulator challenge, XP progress, next best action).
2. **Structured Learning Tracks**
   - Build out comprehensive tracks (Foundations, Investing, Risk, etc.).
3. **Cross-Module Connectivity**
   - Trigger simulator challenges or wallet goals based on lesson completion.
4. **Educational Simulator**
   - Add deep reflection and analysis per trade.
5. **Deep Personalization**
   - Tailor the experience using onboarding profile data.
6. **Polished Mobile UX**
   - Improve empty states, progress visuals, charts, badges, and feedback messages.
7. **Real Market Ingestion (Backend)**
   - Implement scheduled jobs, Redis caching, and PostgreSQL market snapshots. No direct frontend API calls for market data.
8. **Strengthened AI Tutors**
   - Safe educational explanations and targeted quiz generation.
9. **Notification System**
   - Push notifications for streaks, saving prompts, lesson completions, and goal milestones.
10. **Comprehensive Testing**
    - API integration tests, Mobile integration tests, AI JSON contract tests, Market ingestion tests, and end-to-end onboarding tests.
