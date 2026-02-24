# Henrii Spec Implementation Plan

Detailed implementation plan to close all gaps in [GAP_ANALYSIS.md](GAP_ANALYSIS.md) and align the app with [henrii_final_spec.md](henrii_final_spec.md). Tasks are grouped into phases with dependencies; each task includes files to modify and acceptance criteria.

---

## Phase 1: Foundation

Foundation work that other phases depend on.

### 1.1 Design System Completion

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Add `marginTablet` (32pt) | `DesignSystem.swift` | Add `HenriiSpacing.marginTablet = 32`; use in iPad layout logic | Tablet layouts use 32pt horizontal margin when `horizontalSizeClass == .regular` |
| Verify/add dark mode color assets | `Assets.xcassets/*` | Ensure each semantic color has light/dark variants matching spec hex values | All 14 tokens render correctly in light and dark mode |
| Add Reduce Motion environment | `DesignSystem.swift`, new `ReduceMotionModifier` | Create modifier that reads `@Environment(\.accessibilityReduceMotion)` and provides `shouldReduceMotion` to views | When Reduce Motion ON: springs → crossfades; timer pulse → static; celebration effects off |
| Apply Reduce Motion across app | All animated views | Wrap spring animations in `if !reduceMotion`; use `.animation(nil)` or crossfade when true | No information conveyed solely through motion when enabled |

### 1.2 Data Model Extensions

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Sleep: add `location`, `method` | `BabyEvent.swift` | Add `sleepLocation: String?` (crib, bassinet, etc.), `sleepMethod: String?` (rocked, fed-to-sleep) | InputParser + UI can capture these; optional fields |
| Diapers: add `color` | `BabyEvent.swift` | Add `diaperColor: String?` for newborn-critical tracking | Parser extracts color keywords (green, yellow, etc.); shown in confirmation |
| Health: add vaccination model | New `Vaccination.swift`, `Baby.swift` | Create `Vaccination` @Model (name, date, notes); add `Baby.vaccinations` relationship | Profile shows vaccination list; manual entry UI |
| Milestones: add `photoData`, `context` | `BabyEvent.swift` | Add `milestonePhotoData: Data?`, `milestoneContext: String?` | Can attach photo and context to milestones |

### 1.3 Touch Target & Button Hierarchy Audit

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Enforce 44pt min touch targets | `StatusHeaderView`, `ComposerView`, chip buttons | Replace 36pt buttons with 44pt; add padding if needed | All interactive elements ≥44pt |
| Enforce 56pt primary buttons | Onboarding, primary CTAs | Audit and fix buttons per spec hierarchy | Start/Send/primary CTAs = 56pt min |
| Lock Screen 88×88pt (when Live Activity exists) | Phase 6 | Deferred to Live Activity implementation | — |

---

## Phase 2: Navigation & Gestures

### 2.1 Pinch-Out to Today Dashboard

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Add pinch gesture to HomeView | `HomeView.swift` | Add `MagnificationGesture`; when scale > 1.15, trigger `onShowToday()` | Pinch-out from conversation zooms into Today |
| Spatial zoom transition | `ContentView.swift`, `HomeView.swift` | Use `.matchedGeometryEffect` or custom transition so conversation “recedes” | Smooth zoom feel; not just navigation push |
| Pinch-in to return | `TodayDashboardView.swift` | Add pinch-in gesture; when scale < 0.9, pop/dismiss to Home | Pinch-in from Today returns to conversation |

### 2.2 Pull-Down for Search

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Replace search button with pull-down | `HomeView.swift` | Add `DragGesture` or `refreshable` on ScrollView; when pull-down from mid-screen, show Search | Pull-down from conversation opens Search; spec says “mid-screen” |
| Optional: Search as overlay vs sheet | `HomeView.swift` | Consider overlay that focuses composer in search mode per spec | Search feels integrated, not modal sheet |

### 2.3 Multi-Child Toggle

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Add baby toggle above composer | `HomeView.swift`, new `BabyToggleView.swift` | When `babies.count > 1`, show `[Baby A] [Baby B] [Both]` chips above composer | Toggle visible when 2+ babies; selects active logging target |
| Support "fed both 4oz" in InputParser | `InputParser.swift` | Parse "both" in feeding context; return flag or multi-baby intent | ParsedEvent indicates multi-child |
| Log to multiple babies in ConversationViewModel | `ConversationViewModel.swift`, `HomeView.swift` | When "both" or multi-child, insert identical events for each selected baby | "Fed both 4oz" creates 2 confirmation cards |
| Top-left child switcher | `StatusHeaderView.swift` or `HomeView` | Add compact baby switcher in header for quick profile switch | Tap switches active baby without opening Profile |

---

## Phase 3: Composer & Bento Cards

### 3.1 Composer Refinements

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Dictation orb 56×56pt | `ComposerView.swift` | Change mic button frame from 44×44 to 56×56 | Spec: 56pt for eyes-closed tapping |
| Hold-to-trigger voice | `ComposerView.swift`, `SpeechService.swift` | Add `LongPressGesture`; start listening on press, stop on release | Optional: tap still works for accessibility |
| Context chips 40pt height | `ContextChipsView.swift` | Set explicit `.frame(height: 40)` on chip container | Chips are 40pt tall |
| Contextual chip logic | `ContextChipsView.swift`, `ConversationViewModel` | After last event = feeding: show [Burp] [Spit-up] [Diaper]. After 4h sleep: show [Start Feed] [Diaper]. | Chips change based on `lastEvent` and time-since |
| Composer Liquid Glass | `ComposerView.swift` | Use `.ultraThinMaterial` or similar for pill background | Matches spec “Liquid Glass pill” |

### 3.2 New Bento Card Types

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Bento Medical Flag | `ConversationEntry.swift`, `ConversationBubbleView.swift` | Add `ConversationEntryType.medicalFlag`; red accent, "Call Pediatrician" action, cannot swipe away | Shown when temp elevated 24h+ or similar; requires explicit dismiss |
| Bento Handoff Summary | `ConversationEntry.swift`, `ConversationBubbleView.swift`, new `HandoffService` | Add type `handoffSummary`; detect device switch (e.g. iCloud account / device ID); generate "Morning. David handled 2 wake-ups..." | Card appears when different “parent” context; dismisses after read |
| Bento Daily Summary | `ConversationViewModel`, `ConversationBubbleView` | Add type `dailySummary`; three rings + natural language; generate at configurable time | Evening summary card in stream |
| Correction morph (no new message) | `ConversationViewModel.handleCorrection` | Instead of inserting new confirmation, find last matching confirmation and update its text; animate `withAnimation(.spring(damping: 0.9))` | "Actually 5oz" morphs existing card; no duplicate entry |

### 3.3 Conversation Scalability

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Collapsible summaries | `HomeView`, `ConversationBubbleView` | Group consecutive similar entries (e.g. 3 diapers in 1h) into "3 diapers logged" expandable row | Tapping expands to show individual entries |
| Day separators logic | `ConversationViewModel.insertDaySeparatorIfNeeded` | Ensure day separators insert correctly between days | Each new day has a separator |
| Mini-calendar navigation | New `CalendarStripView`, `HomeView` | Horizontal date strip; tap date to scroll to that day in stream | Quick jump to specific dates |

---

## Phase 4: Onboarding Completion

### 4.1 Onboarding Flow

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Add photo step (optional) | `OnboardingView.swift` | After birth date: "Want to add a photo?" → PhotosPicker; Skip prominent | Step 3 per spec |
| Add permissions step | `OnboardingView.swift` | "I can use Siri so you can log hands-free." → [Allow All] for Notifications, Speech, (HealthKit if used) | Single permissions step with value prop |
| Add partner invite step | `OnboardingView.swift` | "Want to invite [partner] to track together?" → Share link / QR; Skip easy | Generates shareable link; actual sharing TBD |
| Optimize for 30 seconds | `OnboardingView.swift` | Reduce steps, auto-advance where possible, minimal friction | Flow feels fast; no 5-page carousel |
| Liquid Glass onboarding layout | `OnboardingView.swift` | Use material backgrounds, immersive full-screen | Matches spec “immersive Liquid Glass” |

---

## Phase 5: Today Dashboard Overhaul

### 5.1 Gantt-Style Timeline

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Horizontal 24h timeline | `TodayDashboardView.swift` | Replace vertical list with horizontal ScrollView; time axis left (0–24h); events as blocks | Like flight tracker; blocks colored by category |
| Event blocks (duration = width) | `TodayDashboardView.swift` | Each event = rounded rect; width ∝ duration; y-position by hour | Gantt-style layout |
| Current time marker | `TodayDashboardView.swift` | Vertical animated line at current time | Always visible |
| Pinch-in to return | `TodayDashboardView.swift` | Pinch-in dismisses back to Home | Per spec |
| Long-press block edge to adjust | `TodayDashboardView.swift` | Long-press on block edge → drag to change start/end time | Updates `timestamp` / `endTime` / `durationMinutes` |
| 24h / 12h / Week segmented control | `TodayDashboardView.swift` | Picker for view mode; Week shows 7 days | Three modes |
| Empty state illustration | `TodayDashboardView.swift` | Use illustration + "Nothing logged yet today — I'm ready when you are" | Per spec |
| Loading skeleton | `TodayDashboardView.swift` | Skeleton blocks while loading | Shimmer placeholder |

---

## Phase 6: Search Natural Language

### 6.1 NL Query → Answer Card

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Query routing for medication/time | `InputParser`, `ConversationViewModel.handleQuery` | When query contains "when did she last have [med]" or "last [Tylenol]", find matching event | Parse intent |
| Generate answer card | `ConversationViewModel` | Instead of list, insert `ConversationEntry` type `queryResponse` with direct answer: "Maya had 2.5ml Tylenol yesterday at 4:15 PM." | Single answer card, not filtered list |
| Fallback to filtered list | `SearchView` | If no direct answer, show filtered results as today | Graceful degradation |
| Search focus on pull-down | `HomeView`, `SearchView` | When Search opens via pull-down, composer auto-focuses in search mode | Spec: "Focuses the Composer in search mode" |

---

## Phase 7: Insights & Profile Enhancements

### 7.1 Insights

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| WHO growth percentiles | `InsightsView.swift`, new `GrowthChartView` | Integrate WHO data (or chart library); plot weight/height with shaded percentile regions | Soft shaded regions; personal data on top |
| Milestone tracker | New `MilestoneTrackerView` | Circular progress; age ranges; developmental context | Per spec component |
| Bezier trend charts | `InsightsView` | Replace bars with smooth bezier curves; no gridlines; long-press for exact value | Softer, less clinical |
| AI natural language summaries | `InsightsView`, `ConversationViewModel` | Generate text like "Leo crossed into the 50th percentile for weight today" | Positive framing |
| 85% confidence threshold | `ConversationViewModel`, `SettingsManager` | Before surfacing unprompted insight, require confidence score; cap 1/day | Logic in `generateInsightIfNeeded` |
| Ghost Card treatment | `ConversationBubbleView` | Slightly transparent, distinct from logged data for insight cards | Visual distinction |

### 7.2 Baby Profile

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Vitals section | `BabyProfileView.swift` | Add APGAR, birth weight/length, blood type, allergies | Inset grouped list |
| Pediatrician section | `BabyProfileView.swift`, new `Pediatrician` model | Contact info, next appointment, one-tap call/directions | Tap to call |
| Vaccinations section | `BabyProfileView.swift` | List vaccinations; export vaccination card | Uses Phase 1.2 model |
| Medical notes section | `BabyProfileView.swift` | Chronological health notes with category filters | Filter by category |
| Growth chart in Profile | `BabyProfileView` | Reuse GrowthChartView; manual entry fields; units toggle | kg/lb, cm/in |

### 7.3 Settings

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Caregivers section | `SettingsView.swift` | Co-Parent, Nanny/Sitter, Grandparent; invite via link/QR; permissions per role | Per spec roles |
| Integrations section | `SettingsView.swift` | Toggles/links for Apple Health sync, Siri Shortcuts, Apple Watch | Placeholder or basic setup |
| Single parent hidden | `SettingsView.swift` | Hide partner/caregiver UI when not enabled | No empty "Invite Partner" clutter |

---

## Phase 8: Ambient Intelligence & Notifications

### 8.1 Smart Notifications

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| UNUserNotificationCenter integration | New `NotificationService.swift` | Request permission; schedule notifications per settings | Uses existing toggles |
| Feeding reminder (3h) | `NotificationService` | "It's been 3h since last feed" — Banner, no sound | Configurable interval |
| Medication due | `NotificationService` | "Amoxicillin due in 15 min" — Banner + sound + haptic; lock screen action "Logged" | Time-sensitive |
| Daily summary notification | `NotificationService` | Passive: "Daily summary ready" | Notification center only |
| Celebration (milestone) | `NotificationService` | Rich notification with image | When milestone achieved |
| Lock Screen actions | `NotificationService` | UNNotificationCategory with actions: Logged, Start Timer, Snooze | For time-sensitive |

### 8.2 Daily Intelligence

| Task | Files | Description | Acceptance |
|:-----|-------|-------------|------------|
| Morning briefing | New `DailyIntelligenceService` | Generate night summary; could be notification or in-app card | Wake-ups, feedings, total sleep |
| Evening summary | `DailyIntelligenceService` | Day totals; adapt by baby age | Feeds, naps, diapers |
| Weekly digest | `DailyIntelligenceService` | Trend overview; "growth spurt window" style context | Actionable |

---

## Phase 9: Live Activities & Widgets

### 9.1 ActivityKit (Live Activities)

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Add ActivityKit dependency | project.pbxproj | Link ActivityKit | — |
| Timer Live Activity | New `HenriiTimerActivity.swift` | Start/update/end Live Activity when feed/sleep timer runs | Full-width; Pause/Stop 88×88pt |
| Sync timer state | `TimerViewModel` | Push timer state to Live Activity | Real-time |
| Dynamic Island | `HenriiTimerActivity` | Compact/expanded Island UI; waveform for sleep | Per spec |

### 9.2 WidgetKit

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Widget extension | New target `HenriiWidgets` | Small: last feed + status; Medium: three metrics + timer; Large: mini timeline | Per spec sizes |
| App Groups | project | Share data with widget via App Groups / SwiftData in shared container | Widget reads last events |
| Timeline provider | `HenriiWidgets` | Provide entries for WidgetKit | Updates when app logs |

### 9.3 StandBy Mode (Optional)

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| StandBy scene | New `StandByView` | When charging horizontal: pure black, red-tinted text, "Last feed: X ago", large Start Feed button | iOS 17+ StandBy API if available |

---

## Phase 10: Accessibility

### 10.1 Dynamic Type

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Scalable text everywhere | All views | Use `dynamicTypeSize(...)` or ensure fonts scale; test up to AX5 | No truncation; reflow at 310% |
| Bento cards at large sizes | `ConversationBubbleView` | Convert row → column layout at large type | Per spec |
| Charts degrade to text | `InsightsView`, charts | At max type, show text list instead of chart | Accessible fallback |

### 10.2 VoiceOver

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Labels and hints | All interactive elements | Add `accessibilityLabel` and `accessibilityHint` | Every control announced clearly |
| Card type announcement | `ConversationBubbleView` | "Insight card: She's sleeping 30 min longer. Double-tap for details." | Descriptive |
| Custom Rotor | `HomeView` | Rotor actions: Edit, Delete, Add Note on conversation entries | Flick up/down for actions |
| Timer state | `TimerCardView` | "Sleep timer active. 2h 15m elapsed. Swipe right to pause." | Clear state |

### 10.3 Color & Contrast

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Color independence | Charts, cards | Add pattern overlays or icons; never color-only distinction | Passes WCAG AAA |
| Contrast audit | DesignSystem, Assets | Verify 4.5:1 text, 3:1 large text/UI | Tool or manual check |

---

## Phase 11: Edge Cases & Polish

### 11.1 Aging Out

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Declining log detection | New `AgingOutService` | Track rolling 7-day log count; when below threshold for 2+ weeks, enable reduced UI | Detect trend |
| Reduce chips over time | `ContextChipsView` | Fewer chips; remove redundant ones | "Slough off unnecessary chips" |
| Milestone journal mode | `HomeView` | When aged out, emphasize milestones over granular tracking | Transition per spec |

### 11.2 Offline & Sync

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Offline indicator | `StatusHeaderView` | Subtle cloud-slash icon when `NetworkMonitor` (or similar) says offline | Per spec |
| CloudKit sync (optional) | New `SyncService` | Sync SwiftData via CloudKit for multi-device | State syncs; Live Activity on all devices |
| Data migration/import | New `ImportService` | CSV import; manual bulk voice ("I fed 6oz at noon yesterday") | Parse and insert |

### 11.3 Motion & Haptics

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Consistent haptic mapping | All views | Log confirm: `.success`; timer start: `.impactMedium`; timer stop: `.impactHeavy` | Per spec |
| Animation durations | DesignSystem or constants | Card appear: 350ms spring 0.8; chip: 200ms 0.7; timer pulse: 2000ms | Documented |

---

## Phase 12: Siri & App Intents

### 12.1 App Intents

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Log feeding intent | New `HenriiAppIntents` | "Hey Siri, tell Henrii I just fed 4 ounces" | App Intent creates event |
| Start timer intent | `HenriiAppIntents` | "Start a sleep timer in Henrii" | Starts timer |
| Query intent | `HenriiAppIntents` | "Ask Henrii when the last diaper was" | Returns answer via Siri |
| Register intents | `ImplementationAppBuildApp` | App Shortcuts provider | Appears in Shortcuts app |

---

## Phase 13: Multi-Platform (Future)

### 13.1 iPad

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Sidebar layout | `ContentView`, `HomeView` | Persistent sidebar with Today Dashboard alongside conversation | Split view |
| margin.tablet | `DesignSystem` | 32pt margins | Applied |
| Keyboard shortcuts | All | ⌘N new log, ⌘T timer, ⌘F search | Power user support |

### 13.2 Apple Watch

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Watch app target | New `HenriiWatch` | Companion app | — |
| Complications | `HenriiWatch` | Last feed, active timer, daily totals | Per spec |
| Quick-log | `HenriiWatch` | Crown scroll + tap for presets | — |
| Timer from wrist | `HenriiWatch` | Start/stop timer | Sync with phone |

### 13.3 CarPlay

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| CarPlay scene | New `CarPlayManager` | Voice-only logging; "Hey Siri, tell Henrii I picked up from daycare" | Audio confirmation |

---

## Phase 14: Platform Target & NLP

### 14.1 iOS Target

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| Bump to iOS 26 (when released) | project.pbxproj | Set `IPHONEOS_DEPLOYMENT_TARGET = 26.0` | Enables Liquid Glass APIs |
| Or: Stay on iOS 18 | — | Document as intentional; use `.ultraThinMaterial` as fallback | Trade-off documented |

### 14.2 NLP Extensions

| Task | Files | Description | Acceptance |
|------|-------|-------------|------------|
| "she", "again" context | `InputParser`, `ConversationViewModel` | Resolve "she" → active baby; "again" → repeat last event type | Coreference |
| Time refs parsing | `InputParser` | "at 2pm", "yesterday at noon", "30 min ago" | Extract and apply to event timestamp |
| "fed both" | `InputParser` | Return multi-child flag (Phase 2.3) | — |

---

## Implementation Order

Recommended sequence (respecting dependencies):

1. **Phase 1** (Foundation) — Design system, data model, touch targets
2. **Phase 2** (Navigation) — Pinch, pull-down, multi-child
3. **Phase 3** (Composer & Cards) — Dictation, chips, new card types, correction morph
4. **Phase 4** (Onboarding)
5. **Phase 5** (Today Gantt)
6. **Phase 6** (Search NL)
7. **Phase 7** (Insights & Profile)
8. **Phase 8** (Notifications)
9. **Phase 9** (Live Activities & Widgets)
10. **Phase 10** (Accessibility)
11. **Phase 11** (Edge cases)
12. **Phase 12** (Siri/Intents)
13. **Phase 13** (Multi-platform) — Can parallelize iPad/Watch/CarPlay
14. **Phase 14** (iOS target, NLP) — Can interleave with earlier phases

---

## Summary by Effort

| Phase | Effort (est.) | Dependencies |
|-------|---------------|--------------|
| 1. Foundation | Medium | None |
| 2. Navigation | Medium | 1 |
| 3. Composer & Cards | High | 1 |
| 4. Onboarding | Low–Medium | 1 |
| 5. Today Gantt | High | 1 |
| 6. Search NL | Medium | 1, 3 |
| 7. Insights & Profile | High | 1 |
| 8. Notifications | Medium | 1 |
| 9. Live Activities | High | 1, 8 |
| 10. Accessibility | Medium | 1 |
| 11. Edge cases | Medium | 1, 8 |
| 12. Siri | Low–Medium | 1 |
| 13. Multi-platform | High | 1, 2, 9 |
| 14. Platform/NLP | Low | 1 |
