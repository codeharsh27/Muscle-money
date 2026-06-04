# Muscle Money 2.0 🚀
*Building Financial Muscle Through Gamification & AI*

Welcome to **Muscle Money 2.0**—a comprehensive fintech ecosystem designed specifically for students and young adults. The product direction is **"Duolingo for Finance"**, combining adaptive learning, gamified progress tracking, a zero-risk stock simulator, and automated expense tracking, all guided by an empathetic AI named **Nova**.

---

## 🎯 Motivation Behind the App

Financial literacy is arguably one of the most critical life skills, yet it is rarely taught effectively in traditional education systems. Young adults are entering a complex economy burdened by inflation, predatory lending, and an overwhelming array of investment options. 

The traditional approach to learning finance—reading dense books or watching theoretical lectures—has failed. People learn best by *doing*, but "doing" finance in the real world comes with the risk of losing hard-earned money. 

**Our Goal:** To bridge this gap by creating an environment where users can learn the theory (Learning), practice without risk (Simulator), automate their budgeting seamlessly (Wallet Tracking), and receive tailored guidance (Nova AI)—all in one unified, engaging platform.

---

## 🏗️ Technology Stack

Muscle Money leverages a modern, robust, and scalable architecture:

- **Frontend (Mobile App):** Flutter (Dart) for high-performance, beautiful, cross-platform UI. State management is powered by Riverpod, and routing by GoRouter.
- **Backend APIs:** A Turborepo monorepo containing a NestJS (TypeScript) API for core application data and a FastAPI (Python) service for machine learning and AI orchestration.
- **AI Brain:** Powered by OpenRouter and Gemini 1.5 Flash. The LLM is highly tuned with a specific system prompt to act as "Nova"—a conversational, non-robotic, expert financial coach.
- **Local Database & Automation:** Local persistent storage for offline-first capabilities, along with native Android plugins (`telephony`, `flutter_local_notifications`) for background SMS and notification interception.
- **Live Market Data:** Integration with the Yahoo Finance API for real-time stock quotes and historical charting.

---

## 🧠 Automated Tracking: SMS & Notification Listener

One of the most powerful features of Muscle Money is its **frictionless expense tracking**. Traditional budgeting apps fail because they require manual data entry. Muscle Money automates this completely.

### How It Works:
1. **Background Interception:** With explicit user permission, the app uses Android's Notification Listener and SMS reading capabilities to listen for incoming messages from banks, UPI apps (PhonePe, GPay, Paytm), and credit card providers.
2. **Regex Parsing:** When a transaction occurs, the app silently parses the SMS/Notification text to extract the **Amount**, **Merchant**, and **Transaction Type** (Debit/Credit).
3. **Categorization:** The transaction is instantly categorized (e.g., Food, Transport, Utilities) and pushed to the user's local Wallet state.

### The Benefit:
Users get real-time, accurate financial tracking without ever having to type a single number. Their financial profile is built invisibly in the background.

---

## 📊 Financial Score & Nova's Actionable Insights

With the data gathered from the automated tracking, **Nova (The AI)** acts as a personal CFO.

- **The Financial Score (0-100):** A dynamic rating calculated based on the user's savings ratio, spending velocity, and adherence to their goals. 
- **Actionable Steps:** Instead of just showing charts, Nova analyzes the recent spending data and provides smart, actionable steps. For example:
  > *"Hey! I noticed you spent 30% of your income on dining out this week. Let's try cooking at home for the next 3 days to boost your score by 5 points and keep your savings goal on track."*

---

## 📱 Detailed Screen-by-Screen Breakdown

Muscle Money is divided into several highly specialized screens, each designed to tackle a different aspect of personal finance.

### 1. 🛫 Onboarding & Personalization Screen
- **Purpose:** To tailor the app entirely to the individual user before they even see the dashboard.
- **Details:** The user is introduced to Nova, their AI coach. They input their monthly income, their primary financial goals (e.g., "Pay off student loans", "Save for a car"), their current debt, and their risk appetite. 
- **How it helps:** Nova uses this exact data to craft a personalized curriculum and baseline financial score. It ensures the app doesn't give generic advice, but rather advice modeled on the user's actual life situation.

### 2. 💸 The Dashboard (Command Center)
- **Purpose:** A holistic, bird's-eye view of the user's financial health.
- **Details:** 
  - Displays the dynamic **Financial Score**.
  - Shows the **Daily Streak** (which increases when the user completes a lesson or makes a simulated trade).
  - Lists **Recent Spendings** pulled directly and automatically via the SMS/Notification listeners.
  - Highlights a **Daily Insight** generated by Nova based on yesterday's spending behavior.
- **How it helps:** Users no longer have to check 3 different bank apps to know where they stand. Everything is aggregated, scored, and explained in plain English.

### 3. 🤖 Nova (AI Assistant Chat Tab)
- **Purpose:** A 24/7 dedicated financial advisor.
- **Details:** A conversational UI where users can chat directly with Nova. The AI is specifically prompt-engineered to *only* discuss finance. If a user tries to ask about sports or pop culture, Nova gracefully pivots the conversation back to their financial goals.
- **How it helps:** Nova acts as a judgment-free zone. A user can ask, "I have ₹5,000 left this month, should I put it in a mutual fund or pay off my credit card?" and Nova will calculate the mathematical best option while explaining *why* in simple terms.

### 4. 📚 Learning Tab (Duolingo for Finance)
- **Purpose:** To gamify financial education and make learning addictive.
- **Details:** 
  - Organized into distinct modules (e.g., "Budgeting 101", "The Magic of Compounding", "Understanding Equities").
  - Users earn **XP (Experience Points)** for completing interactive quizzes.
  - Features a **Day Streak** system that punishes inactivity and rewards consistency.
- **How it helps:** It leverages behavioral psychology. By turning education into a game, users replace "doom-scrolling" on social media with "wealth-scrolling" on Muscle Money.

### 5. 📈 Stock Simulator (Zero-Risk Paper Trading)
The Simulator is arguably the most complex and robust feature of Muscle Money. It is designed to remove the fear of the stock market.

- **Market Watchlist Screen:** Displays real-world stocks (e.g., Reliance, TCS, AAPL) with live price feeds pulled directly from the Yahoo Finance API.
- **Asset Detail Screen:** 
  - Shows live Candlestick charts so users can learn technical analysis.
  - Allows users to execute "Buy" and "Sell" orders using a virtual cash balance (e.g., starting with ₹1,500,000 in virtual money).
  - If the live market is closed or the network drops, the app seamlessly falls back to mock pricing so the user can *always* practice trading.
- **Simulator Portfolio:**
  - Tracks all open positions, showing Unrealized Profit/Loss in real-time.
  - **The Time Machine Feature:** A specialized tool that projects the user's current simulated portfolio 10-15 years into the future, visualizing the power of compound interest.
  - **Nova's Portfolio Review:** Nova actively monitors the user's simulated holdings and provides feedback (e.g., *"Your portfolio is heavily weighted in Tech. Consider diversifying with some Index Funds to reduce volatility."*)
- **How it helps:** It bridges the gap between theory and reality. Users can test aggressive or conservative strategies, make massive mistakes, and learn from them without losing a single real rupee.

---

## 🎓 Summary for Presentation

Muscle Money is not just an app; it is a **financial behavioral change engine**. By combining:
1. **Frictionless Data Collection** (SMS/Notification tracking)
2. **Actionable AI Intelligence** (Nova's coaching and scoring)
3. **Risk-Free Practice** (Stock Simulator)
4. **Gamified Education** (Learning streaks and XP)

We are equipping the next generation with the financial muscle they need to achieve true financial independence.
