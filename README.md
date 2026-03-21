# Aura - AI-Powered Habit Tracker

An intelligent habit tracking application built with Flutter and Firebase. Aura helps users build better habits through AI-powered coaching, health data integration, gamification, and detailed analytics.

## Features

### Core Habit Tracking
- **Flexible Goals** — Daily, weekly, or monthly targets with custom units and values
- **Smart Reminders** — Timezone-aware local notifications and server-side push notifications via Firebase Cloud Messaging
- **Streak Tracking** — Current and longest streak per habit with automatic calculation
- **Five Categories** — Health, Fitness, Productivity, Mindfulness, Learning

### AI Coach (Powered by Google Gemini)
Nine specialised Cloud Function agents provide personalised guidance:
- **Suggestions** — High-impact habit recommendations based on goals and performance
- **Weekly Insights** — Performance analysis with behavioural patterns and improvement areas
- **Pattern Discovery** — Identifies time-of-day, day-of-week, sequence, and trigger patterns
- **Habit Scoring** — Scores habits across four dimensions: Consistency (40%), Momentum (25%), Resilience (20%), Engagement (15%)
- **Daily Reviews** — End-of-day completion summaries with coaching commentary
- **Action Items** — Prioritised next steps based on current analysis
- **Tips** — Category-based, evidence-informed advice
- **Health Correlations** — Analyses links between biometric data and habit completion
- **Daily Summary Notifications** — Scheduled push notifications with AI-generated summaries

### Analytics & Progress
- **Completion Trends** — Line charts showing performance over time
- **Category Breakdowns** — Performance by habit category
- **Weekly Heatmap** — Calendar visualisation of daily completion rates
- **Key Metrics** — Tracked days, longest streak, active habits, completion rate
- **Weekly & Monthly Views** — Toggle between time periods

### Health Integration
- **Apple HealthKit** (iOS) and **Google Health Connect** (Android)
- Reads steps, sleep, heart rate, active energy, and workouts
- Daily aggregates correlated with habit performance by the AI coach

### Gamification
- **Achievements** — Six categories: Streak, Completion, AI, Category, Consistency, Special
- **Progress Tracking** — Visual progress toward each achievement
- **Streaks** — Current and best streak tracking per habit

### Data Export & Sharing
- **Export** — CSV and JSON export with platform-aware storage
- **Social Sharing** — Share achievements and streak milestones

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.9+, Dart |
| State Management | Provider |
| Backend | Firebase (Firestore, Auth, Cloud Functions, Cloud Messaging, Analytics) |
| AI | Google Gemini (gemini-3-flash-preview) via Cloud Functions |
| Health Data | Apple HealthKit, Google Health Connect (via `health` package) |
| Charts | fl_chart |
| Authentication | Email/Password, Google Sign-In, Apple Sign-In |
| Notifications | flutter_local_notifications, Firebase Cloud Messaging |

## Architecture

```
lib/
├── config/           Theme, icons, constants
├── models/           Data models (habit, achievement, AI responses)
├── providers/        State management (habit, progress, AI coach, scoring, settings, theme)
├── screens/          UI screens (home, progress, AI coach, settings, login, habit detail)
├── services/         Backend integrations (Firestore, auth, health, notifications, export, sharing)
├── utils/            Helper utilities
├── widgets/          Reusable UI components
└── main.dart         App entry point

functions/
├── agents/           9 AI agent modules (Gemini-powered)
├── helpers/          Shared utilities for Cloud Functions
└── index.js          Function exports
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9+)
- Firebase project configured
- Node.js 24+ (for Cloud Functions)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/stone0125/Aura.git
   cd Aura
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Cloud Functions dependencies**
   ```bash
   cd functions && npm install && cd ..
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Privacy & Permissions

- **Notifications** — Habit reminders and daily AI summaries
- **Health Data** — Optional; used for health-habit correlation analysis
- **Internet** — Required for cloud sync and AI features

---

Built by [stone0125](https://github.com/stone0125)
