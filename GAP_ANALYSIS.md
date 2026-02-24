# Henrii Spec Gap Analysis

Audit of the Henrii codebase against [henrii_final_spec.md](henrii_final_spec.md). Reference spec sections I–XIII.

---

## Executive Summary

| Category         | Implemented                      | Partial                            | Missing                                           |
| ---------------- | -------------------------------- | ---------------------------------- | ------------------------------------------------- |
| Design System    | Core tokens, typography, spacing | Dark mode assets, Liquid Glass     | margin.tablet                                     |
| Navigation       | No tab bar, avatar, swipe left   | —                                  | Pinch-out, pull-down search                       |
| Data Model       | 9 categories, core fields        | —                                  | Sleep location/method, diaper color, vaccinations |
| Composer & Cards | Composer, Bento types             | Dictation size, contextual chips   | Handoff, Daily Summary                            |
| Screens          | All 8 exist                      | Onboarding, Today, Search, Profile | Permissions, partner invite                      |
| Timer            | Slide-to-stop, L/R, Pause        | —                                  | Live Activities, Dynamic Island                   |
| Intelligence     | Query parsing, insights          | —                                  | 85% confidence, notifications                     |
| Platform         | iPhone only                      | —                                  | iPad, Watch, CarPlay, Siri                        |
| Accessibility    | —                                | Touch targets                      | Dynamic Type, VoiceOver, Reduce Motion            |

---

## I. Design Philosophy

| Requirement                       | Status      | Notes                                                                                                                      |
| --------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| 3AM Rule (5 sec, one thumb)       | Implemented | Composer, chips, quick log                                                                                                 |
| Shake-to-undo DISABLED            | Implemented | [ImplementationAppBuildApp.swift](ImplementationAppBuild/ImplementationAppBuildApp.swift) line 23                          |
| 5-second Undo toast               | Implemented | [UndoToastView](ImplementationAppBuild/Views/UndoToastView.swift), [HomeView](ImplementationAppBuild/Views/HomeView.swift) |
| Aging out / designed obsolescence | Missing     | No declining-log detection or reduced UI                                                                                   |

---

## II. Brand & Visual Identity

| Requirement                                  | Status      | Notes                                                                                   |
| -------------------------------------------- | ----------- | --------------------------------------------------------------------------------------- |
| Semantic color tokens                        | Implemented | [DesignSystem.swift](ImplementationAppBuild/Utilities/DesignSystem.swift): HenriiColors |
| Light/dark hex values per spec               | Partial     | Uses `Color("...")`; need to confirm Assets match spec (e.g. #F8F6F0, #121211)          |
| Typography (SF Pro Rounded, monospaced data) | Implemented | Font.henrii*                                                                            |
| Spacing 8pt grid                             | Implemented | HenriiSpacing xs(4), sm(8), md(12), lg(16), xl(24), xxl(32), margin(20)                 |
| margin.tablet (32pt)                         | Missing     | Only margin 20pt                                                                        |
| Liquid Glass (iOS 26)                        | Partial     | Uses `.ultraThinMaterial`; spec targets iOS 26, project targets iOS 18                  |
| Corner radii (8/12/16pt)                     | Implemented | HenriiRadius                                                                            |
| Motion (spring, haptics)                     | Partial     | Spring animations; haptic usage incomplete                                              |
| Reduce Motion support                        | Missing     | No `@Environment(\.accessibilityReduceMotion)` handling                                 |
| Custom icon set                              | Missing     | Uses SF Symbols only                                                                    |
| Illustration style                           | Missing     | No onboarding/empty-state illustrations                                                 |
| App icon (3D orb)                            | Unknown     | Depends on Assets                                                                       |

---

## III. Information Architecture

| Requirement                       | Status      | Notes                                                      |
| --------------------------------- | ----------- | ---------------------------------------------------------- |
| No tab bar                        | Implemented | NavigationStack + gestures                                 |
| Layer 0: Conversation             | Implemented | HomeView                                                   |
| Layer +1: Today Dashboard         | Partial     | Exists; spec: pinch-out; impl: tap status pills            |
| Layer +1: Insights                | Implemented | Swipe left gesture                                         |
| Layer -1: Search                  | Partial     | Spec: pull-down; impl: search button → sheet               |
| Layer: Profile/avatar             | Implemented | Tap top-right                                              |
| **Pinch-out** to Today            | Missing     | No pinch gesture; uses navigationDestination               |
| **Pull-down** for Search          | Missing     | Search via button                                          |
| Multi-child toggle above composer | Missing     | No `[Baby A] [Baby B] [Both]`; Add Baby exists in Settings |
| Top-left child switch             | Partial     | Profile/Settings; no dedicated switcher in main flow       |
| Age-based information hierarchy   | Missing     | Same UI for all ages                                       |

**Data model gaps:**

| Category   | Spec fields                     | Implemented          | Missing          |
| ---------- | ------------------------------- | -------------------- | ---------------- |
| Sleep      | location, method, interruptions | quality              | location, method |
| Diapers    | color (newborn-critical)        | type, notes          | color            |
| Health     | vaccination records             | temp, meds, symptoms | vaccinations     |
| Milestones | photos, context                 | description          | photos, context  |

---

## IV. Conversational Interface

| Requirement                                 | Status      | Notes                                                                                                                          |
| ------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Composer: "Tell Henrii..." placeholder      | Implemented | [ComposerView](ImplementationAppBuild/Views/ComposerView.swift)                                                                |
| Composer: Liquid Glass pill                 | Partial     | canvasElevated + shadow                                                                                                        |
| Dictation orb 56×56pt                       | Partial     | Mic button 44×44pt                                                                                                             |
| Dictation: hold to trigger                  | Partial     | Tap to start; no hold-to-listen                                                                                                |
| Context chips 40pt, 8pt above composer      | Partial     | Chips exist; not verified 40pt; placement OK                                                                                   |
| Contextual chips (post-feed: Burp, Spit-up) | Missing     | [ContextChipsView](ImplementationAppBuild/Views/ContextChipsView.swift) uses static chip set                                  |
| Timer: slide-to-stop                        | Implemented | [TimerCardView](ImplementationAppBuild/Views/TimerCardView.swift)                                                              |
| Timer: L/R breast toggle                     | Implemented |                                                                                                                                |
| Bento Confirmation cards                    | Implemented | [ConversationBubbleView](ImplementationAppBuild/Views/ConversationBubbleView.swift)                                            |
| Bento Insight, Nudge, Celebration            | Implemented |                                                                                                                                |
| Bento Medical Flag                          | Missing     | No semantic.alert card type                                                                                                    |
| Bento Handoff Summary                       | Missing     | No device-change detection                                                                                                    |
| Bento Daily Summary                         | Missing     | No three-ring daily card                                                                                                      |
| Correction morph (no new message)           | Partial     | [InputParser](ImplementationAppBuild/Services/InputParser.swift) parses corrections; ConversationViewModel may append vs morph |
| Collapsible summaries (e.g. "3 diapers")    | Missing     |                                                                                                                                |
| Day separators                              | Partial     | daySeparator type exists; insertion logic unclear                                                                              |
| Mini-calendar navigation                    | Missing     |                                                                                                                                |
| Multi-parent / Caregivers                   | Missing     | No avatars, handoff, roles                                                                                                     |

---

## V. Generative UI System

| Requirement                          | Status      | Notes                                                                       |
| ------------------------------------ | ----------- | --------------------------------------------------------------------------- |
| Summary cards with rings             | Implemented | [TodayDashboardView](ImplementationAppBuild/Views/TodayDashboardView.swift) |
| Trend charts (bezier, no grid)       | Partial     | Bar charts in Insights; no bezier, no pinch/long-press                      |
| Timeline: Gantt 24h blocks           | Partial     | Today = vertical list with duration bars, not horizontal Gantt               |
| Long-press block edge to adjust time | Missing     |                                                                            |
| 24h / 12h / Week segmented control   | Missing     |                                                                            |
| Milestone Tracker                    | Missing     |                                                                            |
| Growth chart (WHO percentiles)        | Missing     |                                                                            |
| Three-Ring Summary                   | Implemented | Today rings                                                                 |
| Loading skeleton                     | Missing     |                                                                            |
| Empty: illustration + text           | Partial     | SF Symbol + text, no custom illustration                                    |
| Offline cloud-slash                  | Missing     |                                                                            |
| Graceful degradation                 | Partial     | Basic error handling                                                        |

---

## VI. Ambient Intelligence

| Requirement                      | Status  | Notes                                                                                      |
| -------------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| 85% confidence threshold         | Missing | No confidence logic                                                                        |
| Ghost Cards for insights         | Missing | Insight cards exist but no "ghost" treatment                                               |
| 1 unprompted insight/day cap     | Partial | [SettingsManager](ImplementationAppBuild/Services/SettingsManager.swift) insight frequency |
| Smart Notifications              | Missing | Toggles only; no UNUserNotificationCenter                                                  |
| Morning/Evening/Weekly briefings | Missing |                                                                                            |
| Home Screen Widgets              | Missing | No WidgetKit                                                                               |
| Lock Screen Live Activity        | Missing | No ActivityKit                                                                             |
| Dynamic Island                   | Missing | No ActivityKit                                                                             |
| StandBy (red-tinted)             | Missing |                                                                                            |
| Siri Shortcuts / App Intents     | Missing | No App Intents                                                                             |

---

## VII. Screen-by-Screen

| Screen           | Implemented                              | Gaps                                                                                                 |
| ---------------- | ---------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Onboarding**   | Welcome, name, birth date, ready         | No photo step; no Siri/Notifications/HealthKit permission step; no partner invite; not "30 sec" flow |
| **Home**         | Status header, stream, composer, chips   | Pinch-out → Today missing; search access wrong                                                       |
| **Today**        | Rings, timeline list                     | Not Gantt; no pinch-in; no block drag; no 24h/12h/Week                                               |
| **Insights**     | Cards, insufficient-data message         | No WHO growth; no milestone tracker; no AI summaries                                                 |
| **Baby Profile** | Header, growth, report, export           | No vitals (APGAR, blood type, allergies); no pediatrician; no vaccinations; no medical notes         |
| **Settings**     | Profiles, AI, Notifications, Units, Data | No Caregivers; no Integrations (Health, Siri, Watch)                                                 |
| **Search**       | Category filters, text search            | No NL query → answer card ("When did she last have Tylenol?")                                        |
| **Sharing**      | Doctor report, CSV export                | No partner summaries; no grandparent App Clip                                                        |

---

## VIII. Component Specifications

| Requirement                             | Status      | Notes                          |
| --------------------------------------- | ----------- | ------------------------------ |
| Button hierarchy (Primary 56pt, etc.)   | Partial     | Some 44pt; primary mostly 56pt |
| Form patterns                           | Partial     | DatePicker, TextField used     |
| Timer component                         | Implemented | Slide-to-stop, Pause, L/R      |
| Card system (12pt radius, 16pt padding) | Implemented |                                |
| Lock Screen buttons 88×88pt             | N/A         | No Live Activity yet           |

---

## IX. Accessibility

| Requirement               | Status      | Notes                               |
| ------------------------- | ----------- | ----------------------------------- |
| Dynamic Type to 310%      | Missing     | No explicit scaling                 |
| VoiceOver labels & hints  | Missing     | No audit                            |
| Custom Rotor actions      | Missing     |                                     |
| Color independence        | Partial     | Icons + labels; no pattern overlays |
| Contrast (WCAG AA)        | Unknown     | Needs audit                         |
| Reduce Motion             | Missing     | No handling                         |
| 44×44pt min targets       | Partial     | Some 36pt (avatar, search)          |
| 56pt primary buttons      | Partial     | Mix of 44pt and 56pt                |
| Reachability (bottom 45%) | Implemented | Composer at bottom                  |

---

## X. Edge Cases

| Scenario                    | Status      | Notes                         |
| --------------------------- | ----------- | ----------------------------- |
| Twins / "Fed both 4oz"      | Missing     | No multi-select logging       |
| Premature / adjusted age    | Implemented | Baby.isPremature, dueDate     |
| Combo feed                  | Implemented | InputParser.parseFeeding      |
| Shake disabled              | Implemented |                               |
| 5-sec Undo                  | Implemented |                               |
| Offline mode                | Partial     | Parsing local; no cloud-slash |
| Aging out                   | Missing     |                               |
| Multiple devices / CloudKit | Missing     | SwiftData local only          |
| Data migration / import     | Missing     |                               |
| CarPlay                     | Missing     |                               |

---

## XI. Multi-Platform

| Platform              | Status  |
| --------------------- | ------- |
| iPad (sidebar, split) | Missing |
| Apple Watch           | Missing |
| CarPlay               | Missing |
| Keyboard shortcuts    | Missing |

---

## XII. NLP Intent Mapping

| Pattern                             | Status      | Notes                         |
| ----------------------------------- | ----------- | ----------------------------- |
| fed 4oz, bottle 4oz                 | Implemented | parseFeeding                  |
| nursed left 15 min                  | Implemented |                               |
| she just woke up                    | Implemented | parseSleep isSleepEnd         |
| down for nap, asleep                | Implemented |                               |
| diaper, blowout                     | Implemented | parseDiaper                   |
| temp 101.2, fever                   | Implemented | parseHealth                   |
| Tylenol 2.5ml                       | Implemented |                               |
| actually that was 5oz               | Implemented | parseCorrection               |
| fed both 4oz                        | Missing     | No multi-child logging        |
| nursed 10 right then 2oz bottle    | Implemented | combo                         |
| "she", "again" context              | Missing     | No pronoun/coreference        |
| Time refs ("at 2pm", "yesterday")   | Partial     | Some parsing                  |
| On-device / offline                 | Implemented | No network; rule-based parser |

---

## XIII. Platform & Target

| Item       | Spec    | Implementation                                                                |
| ---------- | ------- | ----------------------------------------------------------------------------- |
| iOS target | iOS 26+ | [project.pbxproj](ImplementationAppBuild.xcodeproj/project.pbxproj): iOS 18.0 |

---

## Priority Recommendations

1. **Navigation**: Add pinch-out → Today and pull-down → Search to match spec.
2. **Composer**: Increase dictation to 56pt; improve chip context (e.g. post-feed suggestions).
3. **Multi-child**: Add `[Baby A] [Baby B] [Both]` above composer; support "fed both" logging.
4. **Onboarding**: Add photo, permissions, and partner-invite steps.
5. **Today**: Replace list with horizontal Gantt timeline; support time editing via long-press.
6. **Search**: Add NL query → answer card, not only filtered list.
7. **Live Activities / Widgets**: Implement ActivityKit and WidgetKit for timers.
8. **Accessibility**: Add Dynamic Type scaling and Reduce Motion support.
9. **Data model**: Add sleep location/method, diaper color, vaccination records.
10. **iOS target**: Decide whether to move to iOS 26 for Liquid Glass and related features.
