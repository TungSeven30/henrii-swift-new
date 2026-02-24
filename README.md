# Henrii

**You parent. Henrii keeps track.**

Henrii is a native iOS baby tracking app that turns logging into a conversation. Instead of tapping through menus, parents speak or type naturally—"fed 4oz," "nursed left 15 min," "she just woke up"—and Henrii structures the data, generates confirmations, and surfaces insights. Every interaction is designed for the 3AM test: completable in under 5 seconds, one-handed, half-asleep.

## Features

- **Conversational logging** — Natural language input replaces nested menus; type or speak what happened
- **Voice input** — On-device speech-to-text for hands-free logging
- **Event tracking** — Feeding (breast/bottle/solids), sleep, diapers, growth, health, milestones, activities, notes
- **Timers** — Feeding and sleep timers with Live Activities and Dynamic Island support
- **AI-powered insights** — Pattern recognition and contextual suggestions (e.g., "She's sleeping 30 min longer this week")
- **Query system** — Ask questions like "how's feeding going?" or "show me sleep trends"
- **Multi-baby support** — Track multiple children with separate conversation streams
- **Export & sharing** — Doctor reports, data export
- **Onboarding** — Conversational setup flow (baby name, birth date, permissions)

## Requirements

- iOS 18.0+
- Xcode 15+
- Swift 5.0

## Getting Started

1. Clone the repository.
2. Open the project in Xcode:
   ```bash
   open ImplementationAppBuild.xcodeproj
   ```
3. Build and run (⌘R) on a simulator or device.

## Project Structure

```
henrii-swift-new/
├── ImplementationAppBuild/           # Main app source
│   ├── Models/                      # SwiftData models
│   │   ├── Baby.swift
│   │   ├── BabyEvent.swift
│   │   └── ConversationEntry.swift
│   ├── ViewModels/
│   │   ├── AppViewModel.swift
│   │   ├── ConversationViewModel.swift
│   │   └── TimerViewModel.swift
│   ├── Views/                       # SwiftUI views (20+ files)
│   │   ├── HomeView.swift
│   │   ├── ComposerView.swift
│   │   ├── OnboardingView.swift
│   │   ├── TodayDashboardView.swift
│   │   ├── InsightsView.swift
│   │   └── ...
│   ├── Services/
│   │   ├── InputParser.swift
│   │   ├── SpeechService.swift
│   │   └── SettingsManager.swift
│   ├── Utilities/
│   │   └── DesignSystem.swift
│   └── ImplementationAppBuildApp.swift
├── ImplementationAppBuildTests/
├── ImplementationAppBuildUITests/
└── tmp/
    └── henrii_spec.md               # Full design specification
```

## Architecture

The app follows **MVVM** with **SwiftData** for persistence:

- **Models** — SwiftData `@Model` classes (`Baby`, `BabyEvent`, `ConversationEntry`)
- **ViewModels** — `@Observable` classes for business logic (`ConversationViewModel`, `TimerViewModel`, `AppViewModel`)
- **Views** — SwiftUI views; conversation stream is the primary interface (no tab bar)
- **Services** — `InputParser` (NLP engine for natural language), `SpeechService` (voice input), `SettingsManager` (user preferences)

Key data flow: User types/speaks → `InputParser.parse()` → `ParsedEvent` → `ConversationViewModel.processInput()` → `BabyEvent` + `ConversationEntry` → SwiftData.

## Design Specification

The full design philosophy, visual identity, and component specs are in [tmp/henrii_spec.md](tmp/henrii_spec.md), including:

- The 3AM Imperative and conversation-first principles
- Brand colors, typography, spacing, motion language
- Information architecture (Z-axis navigation, gestural access)
- Generative UI system (Bento Cards, trend charts, timeline views)
- Ambient intelligence and notification design

## License

TBD
