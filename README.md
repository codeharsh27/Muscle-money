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
- **Live Market Data:** Integration with the Yahoo Finance API for real-time stock quotes.

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

## 📱 Core App Screens & Modules

### 1. 🤖 Nova (AI Financial Coach)
- **What it is:** The heart of Muscle Money. Nova handles user onboarding to understand their salary, goals, and risk appetite.
- **How it helps:** Nova provides personalized, human-like, real-time advice. She only answers finance-related queries, ensuring the user stays focused on their wealth-building journey.

### 2. 💸 The Wallet (Dashboard)
- **What it is:** The command center for the user's real-world finances.
- **Features:** Displays the Financial Score, recent spending (auto-tracked via SMS), monthly savings, and Nova's daily insights. 
- **How it helps:** Gives the user a bird's-eye view of their financial health at a single glance.

### 3. 📚 Learning (Duolingo for Finance)
- **What it is:** Bite-sized, interactive courses ranging from "Budgeting 101" to "Advanced Options Trading."
- **Features:** Gamified progression with XP (Experience Points), levels, and day streaks. Every lesson completed and simulator trade executed increases the user's streak.
- **How it helps:** Makes financial education addictive and rewarding. It replaces "doom-scrolling" with "wealth-scrolling."

### 4. 📈 Stock Simulator (Paper Trading)
- **What it is:** A zero-risk environment where users can buy and sell real stocks (e.g., Reliance, TCS, AAPL) using virtual currency.
- **Features:** 
  - **Live Pricing:** Pulls real-time data from Yahoo Finance.
  - **Time Machine:** A visual tool showing users how their current simulated investments would compound over 10-15 years.
  - **Nova's Insights:** Nova reviews the simulated portfolio and provides feedback (e.g., *"Your portfolio is heavily weighted in Tech. Consider diversifying with some Index Funds to reduce volatility."*)
- **How it helps:** Users can test strategies and make mistakes without losing real money. It builds the confidence needed to eventually enter the real stock market.

---

## 🎓 Summary for Presentation

Muscle Money is not just an app; it is a **financial behavioral change engine**. By combining:
1. **Frictionless Data Collection** (SMS/Notification tracking)
2. **Actionable AI Intelligence** (Nova's coaching and scoring)
3. **Risk-Free Practice** (Stock Simulator)
4. **Gamified Education** (Learning streaks and XP)

We are equipping the next generation with the financial muscle they need to achieve true financial independence.
