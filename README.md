# Lullora — AI-Powered Sleep Hypnosis Research App

A cross-platform mobile application built with Flutter for investigating the effectiveness of AI-generated hypnosis on sleep quality through a controlled 3-night randomized study.

---

## Overview

Lullora is a research-grade application designed to conduct a within-subjects study comparing three sleep conditions: **normal sleep (control)**, **fixed hypnosis**, and **personalized AI-generated hypnosis**. The app guides participants through the full study lifecycle — from enrollment and baseline questionnaires to nightly sleep sessions with integrated sleep tracking, and post-experiment evaluation.

Each participant experiences all three conditions across three consecutive nights in a randomized order, while the app collects validated sleep assessments (PSQI, SSS, LSEQ), objective sleep metrics via the Asleep SDK, and usability feedback (SASSI).

---

## Key Features

### Study Protocol

- **3-night randomized crossover design** with automatic condition assignment via Fisher-Yates shuffle
- **Validated questionnaires**: PSQI, Hypnosis Suggestibility, SSS, LSEQ, SASSI
- **Informed consent and enrollment** workflow

### AI-Powered Personalization

- **Custom hypnosis script generation** using Together AI (Meta Llama 4 Maverick)
- **Text-to-speech conversion** via ElevenLabs with selectable voice profiles
- Personalization based on user-selected character personas and sleep goals

### Sleep Tracking

- **Objective sleep monitoring** through Asleep SDK (iOS/Android)
- Real-time session state management with resume support
- Sleep metrics visualization and cross-condition comparison

### Post-Study

- **Free play mode** for replaying generated hypnosis sessions
- **Analytics dashboard** with sleep quality metrics and session history
- Open feedback collection

---

## Tech Stack

| Layer                | Technology                                       |
| -------------------- | ------------------------------------------------ |
| Framework            | Flutter 3.0+ / Dart 3.0+                         |
| State Management     | Riverpod 2.5 + Code Generation                   |
| Navigation           | go_router                                        |
| Backend & Auth       | Supabase (PostgreSQL + Auth + RLS)               |
| AI Script Generation | Together AI API                                  |
| Voice Synthesis      | ElevenLabs API                                   |
| Sleep Tracking       | Asleep SDK (native iOS/Android)                  |
| Audio Playback       | just_audio, audioplayers                         |
| UI                   | Material Design 3, google_fonts, flutter_animate |

---

## Project Structure

```
lib/
├── config/             # Supabase initialization, app theme
├── models/             # Data models (participant, session, questionnaires, etc.)
├── services/           # Business logic layer
│   ├── auth_service           # Supabase authentication
│   ├── database_service       # CRUD operations for all tables
│   ├── asleep_service         # Sleep SDK integration
│   ├── together_ai_service    # LLM script generation
│   ├── elevenlabs_service     # Text-to-speech API
│   ├── randomization_service  # Condition order randomization
│   └── audio_player_service   # Hypnosis audio playback
├── screens/            # UI screens organized by study phase
│   ├── auth/                  # Login & signup
│   ├── pre_experiment/        # Demographics, Hypnosis Suggestibility, PSQI, enrollment
│   ├── nightly/               # SSS, condition screens, LSEQ
│   ├── post_experiment/       # SASSI questionnaire
│   ├── sessions/              # Free play & audio selection
│   ├── analytics/             # Sleep reports & metrics
│   ├── dashboard/             # Home & main navigation
│   └── profile/               # User settings
└── widgets/            # Reusable UI components
```

---

## Database Schema

The app uses four Supabase (PostgreSQL) tables, all secured with Row-Level Security:

| Table                       | Purpose                                                       |
| --------------------------- | ------------------------------------------------------------- |
| `study_participants`        | Enrollment status, condition order, current night progress    |
| `pre_experiment_responses`  | Demographics, Hypnosis Suggestibility scores, PSQI responses  |
| `nightly_sessions`          | Per-night condition data, sleep metrics, pre/post assessments |
| `post_experiment_responses` | SASSI usability scores, open feedback                         |

Full schema documentation is available in [docs/database_schema.md](docs/database_schema.md).

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- A Supabase project
- API keys for Together AI and ElevenLabs

### Environment Setup

1. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

2. Fill in your credentials in `.env`:

   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_anon_key_here
   TOGETHER_API_KEY=your_together_ai_key_here
   ELEVENLABS_API_KEY=your_elevenlabs_key_here
   ```

   > **Note**: Never commit `.env` to version control. It is included in `.gitignore`.

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run code generation (for Riverpod providers):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. Run the app:
   ```bash
   flutter run
   ```

### Platform-Specific Builds

```bash
flutter run -d ios       # iOS Simulator / Device
flutter run -d android   # Android Emulator / Device
flutter run -d chrome    # Web (limited — sleep tracking requires native)
```

---

---

## License

Research use only. Not intended for clinical or therapeutic application.
