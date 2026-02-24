# AGENTS.md — Henrii Project Context for AI Coding Agents

This file provides project-specific context for AI agents (Cursor, Copilot, Codex, etc.) working in the Henrii codebase.

## Project Context

Henrii is a native **iOS baby tracking app** built with **SwiftUI** and **SwiftData**. The core differentiator is a **conversation-first interface**—no tab bar, no nested menus. Parents log events via natural language or voice. The design philosophy is the **3AM Imperative**: every interaction must be completable in under 5 seconds, one-handed, at 3AM.

## Key Directories

| Path | Purpose |
|------|---------|
| `ImplementationAppBuild/` | Main app source |
| `ImplementationAppBuild/Models/` | SwiftData models: `Baby`, `BabyEvent`, `ConversationEntry` |
| `ImplementationAppBuild/ViewModels/` | `AppViewModel`, `ConversationViewModel`, `TimerViewModel` |
| `ImplementationAppBuild/Views/` | SwiftUI views (HomeView, ComposerView, OnboardingView, etc.) |
| `ImplementationAppBuild/Services/` | `InputParser`, `SpeechService`, `SettingsManager` |
| `ImplementationAppBuild/Utilities/` | `DesignSystem.swift` |
| `tmp/henrii_spec.md` | Full design specification |

## Conventions

- **Design system** — Use `HenriiColors`, `HenriiSpacing`, `HenriiRadius` from `ImplementationAppBuild/Utilities/DesignSystem.swift`. Never use raw hex values; use semantic tokens (e.g., `HenriiColors.canvasPrimary`, `HenriiColors.dataFeeding`).
- **Typography** — SF Pro Rounded for UI text (`Font.henriiBody`, `Font.henriiHeadline`, etc.). Monospaced numerals for timers and data values.
- **Spacing** — 8pt base grid; use `HenriiSpacing` constants (`xs`, `sm`, `md`, `lg`, `xl`, `margin`).
- **Corner radii** — `HenriiRadius.small` (8pt), `medium` (12pt), `large` (16pt).

## Parsing Logic

`ImplementationAppBuild/Services/InputParser.swift` converts natural language into `ParsedEvent`. It parses:

- Queries ("how's feeding?", "show me sleep trends")
- Corrections ("wait, that was 5oz")
- Feeding ("fed 4oz", "nursed left 15 min")
- Sleep ("she just woke up", "nap 45 min")
- Diapers, health, pumping, growth, activities, milestones

When adding support for new phrases, add patterns in the appropriate `parse*` method (e.g., `parseFeeding`, `parseSleep`). Follow the existing regex/keyword patterns.

## Data Model

- **SwiftData** `@Model` classes. Schema: `Baby`, `BabyEvent`, `ConversationEntry`.
- **BabyEvent** uses `EventCategory` enum (`feeding`, `sleep`, `diaper`, `growth`, `health`, `milestone`, `pumping`, `activity`, `note`).
- Events are linked to `Baby` via `BabyEvent.baby` relationship; `Baby.events` cascades on delete.
- **ConversationEntry** stores the conversation stream (user messages, confirmations, system notes); linked by `babyID` and optionally `eventID`.

## Design Reference

The full design spec is in `tmp/henrii_spec.md`. When modifying UI:

- Follow the **3AM Imperative** — minimize cognitive load and interaction steps.
- Use semantic color tokens and the defined type scale.
- Avoid tab bars; the composer owns the bottom of the screen.
- Dark mode uses Obsidian (`#121211`) not pure black (OLED smearing).
- Animations: spring-based physics; honor Reduce Motion.

## Testing

- **Unit tests** — `ImplementationAppBuildTests/`
- **UI tests** — `ImplementationAppBuildUITests/`

Run tests via Xcode or `xcodebuild -project ImplementationAppBuild.xcodeproj -scheme ImplementationAppBuild -destination 'platform=iOS Simulator,name=iPhone 16' test`.
