# Aura — User Manual

**AI-Powered Habit Tracker & Routine Planner**

Version 1.0.1 | February 2026

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [App Overview & Feature Breakdown](#2-app-overview--feature-breakdown)
3. [Getting Started](#3-getting-started)
4. [Home Screen](#4-home-screen)
5. [Creating & Managing Habits](#5-creating--managing-habits)
6. [Habit Detail Screen](#6-habit-detail-screen)
7. [Progress & Analytics](#7-progress--analytics)
8. [AI Coach](#8-ai-coach)
9. [Settings](#9-settings)
10. [Troubleshooting & FAQ](#10-troubleshooting--faq)

---

## 1. Introduction

### What is Aura?

Aura is an AI-powered habit tracking and routine planning mobile application. It helps users build positive daily routines by combining intuitive habit management with personalised artificial intelligence coaching. The AI analyses your habit data to provide tailored suggestions, weekly insights, behavioural pattern recognition, and actionable improvement steps.

### Purpose

Aura is designed for anyone looking to build consistent habits, whether for health, fitness, learning, mindfulness, or productivity. The app reduces the friction of habit tracking through a clean interface and leverages AI to keep users motivated with personalised guidance.

### Target Users

- Individuals seeking to establish or maintain daily routines
- Students and professionals aiming to improve productivity
- Health-conscious users tracking fitness and wellness habits
- Anyone interested in data-driven self-improvement

### Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | Supported |
| iOS      | Supported |

---

## 2. App Overview & Feature Breakdown

### Navigation Structure

Aura uses a bottom navigation bar with four main tabs:

| Tab | Icon | Description |
|-----|------|-------------|
| **Home** | Home | Daily dashboard with habits, stats, and AI suggestions |
| **Progress** | Bar Chart | Analytics, trends, achievements, and weekly AI summary |
| **AI Coach** | Sparkle | Personalised AI suggestions, insights, scores, and actions |
| **Settings** | Gear | Profile, appearance, notifications, account, and help |

### Feature Summary

| Feature | Description |
|---------|-------------|
| Habit Tracking | Create, complete, edit, and delete daily/weekly habits |
| Goal Setting | Set time-based or count-based goals for each habit |
| Streak Tracking | Automatic streak counting for consecutive completions |
| Reminders | Configurable push notifications for each habit |
| AI Suggestions | Personalised habit recommendations based on your patterns |
| AI Weekly Insights | Weekly analysis with patterns, highlights, and next steps |
| AI Scores | AI-powered scoring of habit performance |
| AI Actions | Prioritised action items for habit improvement |
| AI Tips | Category-based guidance for habit building |
| Progress Analytics | Completion rates, trends, heatmaps, and category breakdowns |
| Achievements | Badges and milestones across multiple categories |
| Health Integration | Connect to Apple Health / Google Health Connect |
| Data Export | Export habit data in CSV or JSON format |
| Theme Support | Light, Dark, and System-default themes |
| Multi-Auth | Email/Password, Google Sign-In, Apple Sign-In |

### Navigation Flow

```
┌─────────────────────────────────────────────────────────┐
│                      Login Screen                       │
│  (Email/Password · Google Sign-In · Apple Sign-In)      │
└──────────────────────────┬──────────────────────────────┘
                           │ Authentication
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  Main App (Bottom Nav)                   │
│                                                         │
│  ┌──────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Home │  │ Progress │  │ AI Coach │  │ Settings │   │
│  └──┬───┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│     │           │              │              │         │
│     ▼           ▼              ▼              ▼         │
│  ┌────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐   │
│  │ Daily  │ │ Weekly   │ │ 4 Tabs:  │ │ Profile   │   │
│  │ Habits │ │ Summary  │ │Suggestion│ │ Appearance│   │
│  │ Stats  │ │ Trends   │ │ Insights │ │ Notif.    │   │
│  │ Quote  │ │ Heatmap  │ │ Scores   │ │ Health    │   │
│  │ AI     │ │ Category │ │ Actions  │ │ Account   │   │
│  │ Card   │ │ Achieve. │ │          │ │ Help      │   │
│  └──┬─────┘ └──────────┘ └────┬─────┘ │ About     │   │
│     │                         │        └───────────┘   │
│     ▼                         ▼                         │
│  ┌──────────────┐   ┌──────────────────┐               │
│  │ Habit Detail │   │ Habit Creation   │               │
│  │   Screen     │   │ (from AI or FAB) │               │
│  └──────────────┘   └──────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Getting Started

### Downloading the App

1. Open the **Google Play Store** (Android) or **Apple App Store** (iOS).
2. Search for **"Aura Habit Tracker"**.
3. Tap **Install** / **Get** and wait for the download to complete.
4. Open the app once installation is finished.

### Creating an Account

Aura offers three sign-up methods:

#### Option A: Email & Password

1. Open the app to the **Welcome to Aura** screen.
2. Enter your **email address** in the Email field.
3. Enter a **password** (minimum 6 characters).
4. Tap the **"Sign Up"** link at the bottom if you see "Don't have an account?".
5. Tap the **Sign Up** button.
6. You will be taken to the Home screen upon successful registration.

`[Screenshot: Login Screen — Sign Up mode]`

#### Option B: Google Sign-In

1. On the login screen, tap **"Continue with Google"**.
2. Select your Google account from the system prompt.
3. Grant the requested permissions.
4. You will be signed in automatically.

#### Option C: Apple Sign-In (iOS only)

1. On the login screen, tap **"Continue with Apple"** (visible on iOS devices only).
2. Authenticate with Face ID, Touch ID, or your Apple ID password.
3. Choose whether to share or hide your email address.
4. You will be signed in automatically.

`[Screenshot: Login Screen — Social login buttons]`

### Signing In to an Existing Account

1. Open the app.
2. Enter your registered **email** and **password**.
3. Tap **Sign In**.
4. Alternatively, use **"Continue with Google"** or **"Continue with Apple"** if you originally signed up with those methods.

### Forgot Password

1. On the Sign In screen, enter your **email address** in the Email field.
2. Tap **"Forgot Password?"** (shown below the password field).
3. A password reset email will be sent to your inbox.
4. Open the email and follow the link to reset your password.
5. Return to the app and sign in with your new password.

---

## 4. Home Screen

The Home screen is your daily dashboard — the first thing you see when opening the app. It provides a quick overview of your habits, stats, and AI recommendations.

`[Screenshot: Home Screen — Full view]`

### Home Header

At the top of the screen, you will see a personalised greeting based on the time of day (e.g., "Good Morning, John"). This uses your first name from your profile.

### Motivational Quote Card

Below the header is a **Daily Wisdom** card that displays a rotating motivational quote to keep you inspired. A new quote appears each day.

`[Screenshot: Home Screen — Motivational Quote Card]`

### Summary Stats Card

The **Summary Stats Card** shows at-a-glance metrics for your habit performance:

| Stat | Description |
|------|-------------|
| **Completion Rate** | Percentage of habits completed today |
| **Current Streak** | Your longest active daily streak |
| **Total Habits** | Number of active habits you are tracking |

`[Screenshot: Home Screen — Summary Stats Card]`

### Today's Habits List

The core of the Home screen is your **habit list**, showing all habits scheduled for today. Each habit card displays:

- Habit **name** and **category** (colour-coded)
- Current **streak** count
- A **checkbox** to mark the habit as complete or incomplete

#### Completing a Habit

1. Tap the **checkbox** or the habit card to toggle completion.
2. The card will update visually to reflect the completed state.
3. Your streak counter will increment automatically.

#### Uncompleting a Habit

1. Tap the checkbox again on a completed habit.
2. The completion will be undone for today.

`[Screenshot: Home Screen — Habit List with completed and pending habits]`

### AI Suggestion Card

At the bottom of the Home screen, an **AI Suggestion Card** may appear with a personalised habit recommendation. This card shows:

- A suggested habit **title** and **description**
- The **category** and **estimated time commitment**
- An **"Add Habit"** button to create the suggested habit with one tap

`[Screenshot: Home Screen — AI Suggestion Card]`

### Creating a New Habit (FAB)

On the Home tab, a **floating action button (+)** appears in the bottom-right corner. Tap it to navigate to the [Habit Creation Screen](#5-creating--managing-habits).

---

## 5. Creating & Managing Habits

### Creating a New Habit

Tap the **+** button on the Home screen to open the Habit Creation screen.

`[Screenshot: Habit Creation Screen — Empty form]`

#### Step 1: Habit Name

- Enter a descriptive name for your habit (maximum 50 characters).
- A character counter appears as you approach the limit.

#### Step 2: Description (Optional)

- Add an optional description to provide context for your habit.

#### Step 3: Category Selection

Choose one of the five categories:

| Category | Icon | Example Habits |
|----------|------|----------------|
| **Health** | Heart | Drink water, Take vitamins |
| **Fitness** | Dumbbell | Exercise, Go for a run |
| **Learning** | Graduation cap | Read a book, Study |
| **Mindfulness** | Lotus | Meditate, Journal |
| **Productivity** | Briefcase | Plan the day, Deep work |

Each category has its own colour theme applied throughout the app.

`[Screenshot: Habit Creation Screen — Category selection]`

#### Step 4: Icon Selection

- Choose an icon to visually represent your habit.
- The available icons are contextual to the selected category.

#### Step 5: Frequency

Select how often you want to perform the habit:

| Frequency | Description |
|-----------|-------------|
| **Daily** | Every day |
| **Weekly** | Select specific days of the week (Mon, Tue, etc.) |
| **Custom** | Every X days / weeks / months |

`[Screenshot: Habit Creation Screen — Frequency selection]`

#### Step 6: Goal Setting (Optional)

Set a measurable target:

| Goal Type | Example |
|-----------|---------|
| **None** | No specific target — simply complete or skip |
| **Time-based** | e.g., 30 minutes of reading |
| **Count-based** | e.g., 8 glasses of water |

- Enter the **goal value** and **unit** (minutes, hours, times, pages, etc.).

`[Screenshot: Habit Creation Screen — Goal setting]`

#### Step 7: Reminders (Optional)

1. Toggle **reminders** on.
2. Set the **reminder time** using the time picker.
3. Choose a **notification style**:
   - **Standard** — A simple reminder notification
   - **Motivational** — An AI-generated motivational message
   - **Silent** — Badge only, no sound

`[Screenshot: Habit Creation Screen — Reminder setup]`

#### Step 8: Save

Tap the **Save** button (or **"Create Habit"**) to add the habit to your daily tracking.

### Creating a Habit from an AI Suggestion

1. Navigate to the **AI Coach > Suggestions** tab or find a suggestion on the Home screen.
2. Tap the **"Add Habit"** button on any suggestion card.
3. The Habit Creation screen opens **pre-filled** with the AI's recommended name, category, frequency, goal, and reminder time.
4. Review and adjust any fields as needed.
5. Tap **Save** to add the habit.

### Editing an Existing Habit

1. Navigate to a habit's **Detail Screen** (tap on a habit from the Home list).
2. Tap the **Edit** icon (pencil) in the app bar.
3. The Habit Creation screen opens in **edit mode** with all fields pre-filled.
4. Make your changes and tap **Save**.

### Deleting a Habit

1. Navigate to the habit's **Detail Screen**.
2. Tap the **Delete** icon (trash) in the app bar.
3. Confirm the deletion in the dialog that appears.
4. The habit and all associated data will be permanently removed.

---

## 6. Habit Detail Screen

Tap on any habit from the Home screen to open its **Detail Screen**. This screen provides comprehensive statistics and management options for that specific habit.

`[Screenshot: Habit Detail Screen — Full view]`

### Habit Statistics

At the top of the detail screen, you will see key performance metrics:

| Metric | Description |
|--------|-------------|
| **Completion Rate** | Percentage of scheduled days the habit was completed |
| **Current Streak** | Number of consecutive days completed |
| **Best Streak** | Longest streak ever achieved for this habit |

### Calendar View

A **calendar heatmap** shows your completion history, with colour-coded days indicating whether the habit was completed (filled) or missed (empty). This provides a visual overview of your consistency over time.

`[Screenshot: Habit Detail Screen — Calendar view]`

### Performance Chart

An interactive **line chart** displays your completion trend over time. You can switch between time ranges:

| Range | Description |
|-------|-------------|
| **Week** | Last 7 days |
| **Month** | Last 30 days |
| **All Time** | Entire habit history |

`[Screenshot: Habit Detail Screen — Performance chart]`

### AI Insight

An expandable **AI Insight** section provides personalised analysis for this specific habit, including patterns and recommendations for improvement. Tap to expand or collapse.

### Edit & Delete

From the detail screen's app bar, you can:

- **Edit** — Opens the habit in edit mode (see [Editing an Existing Habit](#editing-an-existing-habit))
- **Delete** — Permanently removes the habit after confirmation

---

## 7. Progress & Analytics

The **Progress** tab is your analytics dashboard, providing a comprehensive view of your overall habit performance.

`[Screenshot: Progress Screen — Full view]`

### AI Weekly Summary

At the top of the Progress screen, the **AI Weekly Summary** card provides:

- **Week range** (e.g., "Feb 17 – Feb 23")
- **Completion rate** for the period
- **Current streak** across all habits
- **Top performing category**
- **AI-generated insight** summarising your week
- **Highlights** — Key achievements and patterns
- **Encouragement** — A personalised motivational message
- **Next Steps** — Prioritised action items with timeframes

If the summary is outdated (older than 24 hours), a banner appears prompting you to refresh.

`[Screenshot: Progress Screen — AI Weekly Summary card]`

### Category Breakdown

A **pie/donut chart** visualises how your habits are distributed across categories (Health, Fitness, Learning, Mindfulness, Productivity). Each category shows the number of habits and its percentage share.

`[Screenshot: Progress Screen — Category breakdown chart]`

### Weekly Heatmap

A **7-day heatmap** displays daily completion rates for the current week. Each day shows:

- The **date number**
- A **colour intensity** reflecting the completion rate (darker = higher)
- A **completed/total** count (e.g., "5/7")

`[Screenshot: Progress Screen — Weekly heatmap]`

### Trend Charts

Interactive **line charts** show your completion rate trends. Toggle between:

| View | Period |
|------|--------|
| **Week** | Current week (Mon–Sun) |
| **Month** | Current month |
| **All Time** | Full history since first habit |

`[Screenshot: Progress Screen — Trend chart]`

### Best & Worst Performing Habits

Two ranked lists show:

- **Best Performing** — Habits with the highest completion rates
- **Worst Performing** — Habits that need the most attention

Each entry displays the habit name, category, success rate, and completion count.

### Achievement Gallery

A gallery of **badges and milestones** you've earned. Achievements are organised into categories:

| Category | Examples |
|----------|---------|
| **Streak** | "3-Day Streak", "7-Day Streak", "30-Day Streak" |
| **Completion** | "First Completion", "100 Completions" |
| **AI** | "Used AI Coach", "Applied AI Suggestion" |
| **Category** | "Balanced Tracker" (habits across all categories) |
| **Consistency** | "Never Missed a Week", "Perfect Month" |
| **Special** | Unique milestones and challenges |

Each achievement shows:

- **Badge icon** and **name**
- **Description** of how to earn it
- **Progress bar** (for locked achievements)
- **Unlock date** (for earned achievements)
- **Tips** for working towards the achievement

`[Screenshot: Progress Screen — Achievement gallery]`

### Quick Actions

At the bottom of the Progress screen, quick action buttons are available:

- **Export** — Export your habit data (navigates to export options)
- **Share** — Share your progress summary

---

## 8. AI Coach

The **AI Coach** tab provides personalised, AI-powered guidance to help you build better habits. It features a gradient hero section with the title "Your AI Coach" and the subtitle "Personalized insights to help you succeed."

`[Screenshot: AI Coach Screen — Hero section and tabs]`

### Tab Navigation

The AI Coach has four tabs, selectable via a pill-style tab bar:

| Tab | Icon | Description |
|-----|------|-------------|
| **Suggestions** | Lightbulb | AI-generated personalised habit recommendations |
| **Insights** | Chart | Weekly AI analysis with patterns and action steps |
| **Scores** | Speedometer | AI-powered scoring and performance evaluation |
| **Actions** | Checklist | Actionable items for habit improvement |

### Usage Limits

A **usage indicator** icon appears next to the tab bar. Tap it to view your current AI usage:

- Free-tier users have limited AI requests per period.
- The indicator turns **yellow/warning** when usage limits are reached.
- **Pro/Mastery** tier users have unlimited AI access.

### Suggestions Tab

The Suggestions tab shows **AI-generated habit recommendations** tailored to your existing habits, categories, completion rate, and streak data.

Each suggestion card includes:

| Field | Description |
|-------|-------------|
| **Title** | The recommended habit name |
| **Description** | What the habit involves |
| **Why This Helps** | AI explanation of the expected benefit |
| **Category** | Which category the habit falls under |
| **Estimated Impact** | High, Medium, or Low (colour-coded) |
| **Estimated Minutes** | Daily time commitment |
| **Frequency** | Daily or weekly (with specific days) |
| **Goal** | Suggested goal type and target |
| **Add Habit** button | One-tap to create the habit (pre-filled form) |

`[Screenshot: AI Coach — Suggestions tab with suggestion cards]`

### Insights Tab

The Insights tab provides a **weekly AI analysis** of your habit performance. It includes:

- **Weekly Summary** — Completion rate, streak, and top category
- **AI-Generated Insight** — A narrative analysis of your week
- **Highlights** — Bullet-point achievements and notable patterns
- **Encouragement** — A personalised motivational message
- **Discovered Patterns** — Behavioural patterns the AI has identified:
  - **Time Patterns** — "You complete habits better in the morning"
  - **Day Patterns** — "You're most consistent on weekdays"
  - **Habit Sequences** — "Meditation helps you complete other habits"
  - **Trigger Patterns** — "You complete habits after breakfast"
- **Next Steps** — Prioritised actions with timeframes (Today, This Week)

Each pattern shows a **confidence score** (High, Medium, Low).

`[Screenshot: AI Coach — Insights tab with patterns]`

### Scores Tab

The Scores tab provides **AI-powered scoring** of your habit performance, evaluating consistency, effort, and progress across dimensions.

`[Screenshot: AI Coach — Scores tab]`

### Actions Tab

The Actions tab shows **personalised, actionable items** generated by the AI to help you improve. Each action item includes:

| Field | Description |
|-------|-------------|
| **Title** | What to do |
| **Description** | Detailed explanation |
| **Type** | Today, This Week, or Challenge |
| **Priority** | High (red), Medium (orange), or Low (blue) |
| **Related Habit** | Which habit the action is linked to (if any) |
| **Metric** | How to measure success |
| **Checkbox** | Mark the action as completed |

Actions are sorted by priority and can be completed by tapping the checkbox.

`[Screenshot: AI Coach — Actions tab with action items]`

### Refreshing AI Content

- Tap the **refresh** button in the tab navigation area to regenerate AI content for the active tab.
- A **cooldown period** applies between refreshes. If you attempt to refresh during cooldown, a tooltip shows the remaining wait time.
- Content is automatically loaded when you first visit a tab.

### Tips (within AI Coach)

Throughout the AI Coach interface, **AI Tips** are organised by category and provide habit-building guidance:

| Tip Category | Focus |
|-------------|-------|
| **Getting Started** | Basics for new habit builders |
| **Staying Consistent** | Maintaining streaks and routines |
| **Overcoming Challenges** | Dealing with setbacks and obstacles |
| **Advanced Strategies** | Optimisation for experienced users |
| **Mindset & Motivation** | Psychological strategies for success |

Each tip includes:

- **Title** and **content**
- **Key Points** — Bullet-point takeaways
- **Actionable Step** — A specific thing you can do right now

---

## 9. Settings

The **Settings** tab provides comprehensive configuration options. It opens with a floating app bar and scrollable content.

`[Screenshot: Settings Screen — Full view]`

### Profile Section

At the top of Settings, your **profile card** displays:

- **Avatar** — Shows your initials or profile image (gradient circle)
- **Full Name** — Your display name
- **Email** — Your account email
- **Member Since** — Date you joined
- **Stats Row** — Days Tracked | Active Habits | Success Rate (last 7 days)
- **Upgrade to Pro** banner (if not subscribed)

#### Editing Your Profile

1. Tap the **edit icon** (pencil) on the profile card.
2. A modal opens where you can update:
   - **First Name**
   - **Last Name**
   - **Avatar URL** (profile image link)
3. Tap **Save** to apply changes.

`[Screenshot: Settings — Profile edit modal]`

### Appearance

| Setting | Options |
|---------|---------|
| **Theme** | Light, Dark, System Default |

1. Tap **Theme** to open the theme selector.
2. Choose your preferred theme.
3. The app will update immediately.

> **Tip:** You can also toggle between light and dark mode using the sun/moon icon on the AI Coach screen.

### Notifications

| Setting | Description |
|---------|-------------|
| **Enable Notifications** | Master toggle for all habit reminders |
| **Daily Summary** | Set the time for your daily summary notification |

#### Configuring Notifications

1. Toggle **"Enable Notifications"** on.
2. Grant notification permissions when prompted by the system.
3. Tap **"Daily Summary"** to choose the time for your daily summary reminder.
4. Choose a time using the time picker.
5. A confirmation snackbar will appear (e.g., "Daily summary set for 9:00 AM").

`[Screenshot: Settings — Notifications section]`

### Health Integration

> Available on **iOS** and **Android** only.

Connect Aura to your device's health platform to enhance AI insights with physical activity data.

| Platform | Health Source |
|----------|-------------|
| iOS | Apple Health |
| Android | Google Health Connect |

#### Connecting Health Data

1. Toggle **"Connect Health Data"** on.
2. Review the data access prompt (Steps, Sleep, Activity, Heart Rate).
3. Tap **"Connect"** to grant permissions.
4. Once connected, a **"Health Correlations"** option appears showing:
   - **7-Day Summary** — Average steps and sleep hours
   - **Key Findings** — AI-discovered correlations between health metrics and habit completion
   - **Recommendations** — Action plans based on health-habit patterns

`[Screenshot: Settings — Health Integration section]`

### Account

| Setting | Description |
|---------|-------------|
| **Subscription** | View or manage your Pro subscription |
| **AI Usage** | View current AI request usage and limits |
| **Export Data** | Download your habit data |
| **Sign Out** | Sign out of your account |
| **Delete Account** | Permanently delete your account and all data |

#### Exporting Data

1. Tap **"Export Data"**.
2. Choose the export format:
   - **CSV** — Spreadsheet-compatible format
   - **JSON** — Machine-readable format
3. The file will be saved to your device's Downloads folder (Android) or Documents folder (iOS).
4. A share dialog opens allowing you to send the file via email, messaging, or cloud storage.

#### Signing Out

1. Tap **"Sign Out"**.
2. Confirm in the dialog that appears.
3. You will be returned to the Login screen.

#### Deleting Your Account

1. Tap **"Delete Account"** (shown in red).
2. Read the warning about permanent data loss.
3. Confirm the deletion.
4. Your account and all associated data will be permanently removed.

> **Warning:** Account deletion is irreversible. All habits, history, achievements, and AI data will be permanently erased.

### Help & Support

| Option | Description |
|--------|-------------|
| **FAQ** | Common questions and answers |
| **Tutorials** | Step-by-step guides for app features |
| **Contact Support** | Reach the support team |
| **Report Bug** | Submit a bug report |
| **Request Feature** | Suggest new features |
| **AI Transparency** | Learn how AI works in Aura |

`[Screenshot: Settings — Help & Support section]`

### About

| Option | Description |
|--------|-------------|
| **Version** | Current app version (e.g., 1.0.1) |
| **Changelog** | View release notes and what's new |
| **Privacy Policy** | How your data is handled |
| **Terms of Service** | User agreement |
| **Open Source Licenses** | Third-party software credits |
| **Rate App** | Leave a review on the app store |
| **Credits** | Made by Stone |

`[Screenshot: Settings — About section]`

---

## 10. Troubleshooting & FAQ

### Login Issues

**Q: I forgot my password. How do I reset it?**
A: On the Sign In screen, enter your email and tap "Forgot Password?". A reset link will be sent to your email.

**Q: Google Sign-In is not working.**
A: Ensure your Google Play Services are up to date (Android). If the issue persists, try signing in with email and password instead.

**Q: Apple Sign-In is not showing.**
A: Apple Sign-In is only available on iOS devices. On Android, use email/password or Google Sign-In.

**Q: I get an error when signing up.**
A: Ensure your email is valid and your password is at least 6 characters. If the email is already registered, try signing in instead.

### Notification Issues

**Q: I'm not receiving habit reminders.**
A: Check the following:
1. Notifications are enabled in **Settings > Notifications**.
2. The app has notification permissions in your device's system settings.
3. Battery optimisation is not blocking background notifications (Android).
4. Do Not Disturb mode is not active on your device.

**Q: How do I change my daily summary time?**
A: Go to **Settings > Notifications > Daily Summary** and select a new time.

### AI Coach Issues

**Q: The AI Coach is not loading content.**
A: This can happen if:
1. You have no habits created yet — the AI needs habit data to generate recommendations.
2. You've reached the free-tier AI usage limit — wait for the cooldown period.
3. Your internet connection is unstable — the AI coach requires an active connection.

**Q: Why are AI suggestions not personalised?**
A: The AI requires at least a few days of habit tracking data to generate personalised content. Keep tracking consistently and the suggestions will improve.

**Q: My AI weekly summary says "outdated".**
A: Tap the refresh/regenerate button to generate a fresh weekly summary based on your latest data.

### Data & Syncing

**Q: Will my data sync across devices?**
A: Yes. Aura uses cloud storage (Firebase) to sync your data. Sign in with the same account on any device to access your habits.

**Q: How do I export my data?**
A: Go to **Settings > Account > Export Data** and choose CSV or JSON format.

### Health Integration

**Q: Health Connect is not installed (Android).**
A: Tap the "Install" button in the prompt to download Health Connect from the Google Play Store.

**Q: I connected health data but see "Not enough data yet."**
A: Health correlations require at least 7 days of combined health and habit data.

### General

**Q: How do I delete a habit?**
A: Open the habit's Detail Screen (tap on it from the Home list), then tap the delete icon in the app bar.

**Q: Can I undo a completed habit?**
A: Yes. Tap the checkbox again on any completed habit to undo the completion for today.

**Q: How do I contact support?**
A: Go to **Settings > Help & Support > Contact Support** to reach the team.

**Q: How do I report a bug?**
A: Go to **Settings > Help & Support > Report Bug** and provide a description of the issue.

---

*Aura — Build better habits with AI-powered insights.*

*Version 1.0.1 | Made by Stone*
