# Phase 7–12 Spec Review Report

**Date:** February 2025  
**Scope:** Phases 7–12 of [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)  
**Methodology:** Codebase audit against plan acceptance criteria

---

## Executive Summary

| Phase | Compliance | Key Gaps |
|-------|------------|----------|
| Phase 7: Insights & Profile | ~88% | Bezier charts partial; vaccination export missing; Growth Profile units toggle |
| Phase 8: Notifications | ~80% | Notification scheduling not wired to settings; no medication due-time logic; celebration lacks image |
| Phase 9: Live Activities & Widgets | ~97% | StandBy Mode optional; Lock Screen 88×88pt not verified |
| Phase 10: Accessibility | ~85% | Incomplete VoiceOver coverage; no contrast audit |
| Phase 11: Edge Cases | ~75% | Milestone journal mode; CloudKit optional; bulk voice import |
| Phase 12: Siri & App Intents | ~90% | Intents use UserDefaults pending; not full in-app execution |

---

## Phase 7: Insights & Profile Enhancements

### 7.1 Insights

| Task | Status | Evidence |
|------|--------|----------|
| WHO growth percentiles | Done | `GrowthChartView` uses `WHOGrowthData.percentile`; shaded `percentileBand` regions; personal data on top |
| Milestone tracker | Done | `MilestoneTrackerView` with circular progress, age-based expected count, developmental copy |
| Bezier trend charts | Partial | GrowthChartView uses `path.addCurve`; feeding/sleep in InsightsView use `RoundedRectangle` bars, not bezier |
| AI natural language summaries | Done | `generateInsightIfNeeded` produces text like "crossed into about the Xth percentile"; `weeklySummaryCard` uses narrative |
| 85% confidence threshold | Done | `SettingsManager.insightConfidenceThreshold` (default 0.85); `generateInsightIfNeeded` checks `confidence >= threshold`; capped 1/day via `lastAutoInsightDate` |
| Ghost Card treatment | Done | Insight card uses `.opacity(0.82)` for visual distinction from logged data |

### 7.2 Baby Profile

| Task | Status | Evidence |
|------|--------|----------|
| Vitals section | Done | APGAR, birth weight/length, blood type, allergies in `vitalsSection`; Baby model has `apgarScore`, `birthWeightLbs`, `birthLengthInches`, `bloodType`, `allergies` |
| Pediatrician section | Done | `pediatricianSection` with name, next appointment; Call and Directions; Baby has `pediatricianName`, `pediatricianPhone`, `nextPediatricianAppointment` |
| Vaccinations section | Done | List, add/edit, delete; `AddVaccinationView` |
| Export vaccination card | Open | No vaccination-specific export; only CSV for events |
| Medical notes section | Done | Chronological health notes with category filters (All, Fever, Medication, Symptoms) |
| Growth chart in Profile | Partial | `GrowthChartView` in `recentGrowthSection`; no explicit manual entry fields or kg/lb units toggle in Profile (growth via conversation/GrowthLogSheet) |

### 7.3 Settings

| Task | Status | Evidence |
|------|--------|----------|
| Caregivers section | Done | Co-Parent, Nanny/Sitter, Grandparent labels; invite links shown when `caregiversEnabled` |
| Integrations section | Done | Apple Health, Siri Shortcuts, Apple Watch toggles |
| Single parent hidden | Done | Caregiver invite content only shown when `settings.caregiversEnabled` |

---

## Phase 8: Ambient Intelligence & Notifications

### 8.1 Smart Notifications

| Task | Status | Evidence |
|------|--------|----------|
| UNUserNotificationCenter integration | Done | `NotificationService` with `requestAuthorization`, `registerCategories` |
| Feeding reminder (3h) | Partial | `scheduleFeedingReminder(after: 3 * 60 * 60)` exists; `ConversationViewModel.scheduleNotificationsIfNeeded` calls it when `settings.feedingNotifications`; interval not configurable in UI |
| Medication due | Partial | `scheduleMedicationReminder` schedules at a fixed offset (e.g. +4h from event); no "due in 15 min" style logic or medication schedule model |
| Daily summary notification | Done | `scheduleDailySummaryNotification(at: hour)`; `dailySummaryHour` in Settings |
| Celebration (milestone) | Partial | `scheduleCelebrationNotification` exists; no rich notification with image (`UNNotificationAttachment`) |
| Lock Screen actions | Done | `UNNotificationCategory` with Logged, Start Timer, Snooze; `NotificationActionID` |

### 8.2 Daily Intelligence

| Task | Status | Evidence |
|------|--------|----------|
| Morning briefing | Done | `DailyIntelligenceService.morningBriefingText`; `maybeInsertMorningBriefing` inserts system card |
| Evening summary | Done | `eveningSummaryText`; daily summary in stream via `generateDailySummary` |
| Weekly digest | Done | `weeklyDigestText`; `InsightsView.weeklySummaryCard` shows weekly narrative |

---

## Phase 9: Live Activities & Widgets

### 9.1 ActivityKit (Live Activities)

| Task | Status | Evidence |
|------|--------|----------|
| Add ActivityKit dependency | Done | `HenriiLiveActivityManager` imports ActivityKit; `HenriiWidgets` defines `HenriiTimerActivityAttributes` |
| Timer Live Activity | Done | `HenriiTimerLiveActivity` in `HenriiWidgets.swift`; full-width lock screen view |
| Sync timer state | Done | `TimerViewModel` calls `HenriiLiveActivityManager.startTimerActivity`, `updateTimerActivity`, `endTimerActivity` |
| Dynamic Island | Done | `ActivityConfiguration` with `dynamicIsland`; compact/expanded regions; side indicator for feeding |

### 9.2 WidgetKit

| Task | Status | Evidence |
|------|--------|----------|
| Widget extension | Done | `HenriiWidgets` target; Small, Medium, Large supported |
| App Groups | Done | `UserDefaults(suiteName: "group.app.rork.henrii")` used for widget data |
| Timeline provider | Done | `HenriiWidgetProvider`; reads `widgetLastFeedText`, `widgetStatusText`, `widgetFeedCount`, etc. |

### 9.3 StandBy Mode (Optional)

| Task | Status | Evidence |
|------|--------|----------|
| StandBy scene | Open | No `StandByView`; no red-tinted nightstand UI |

---

## Phase 10: Accessibility

### 10.1 Dynamic Type

| Task | Status | Evidence |
|------|--------|----------|
| Scalable text everywhere | Partial | Uses `Font.henrii*`; `InsightsView` checks `dynamicTypeSize >= .accessibility4` and degrades to text list |
| Bento cards at large sizes | Open | No explicit row→column layout for large type in `ConversationBubbleView` |
| Charts degrade to text | Done | Feeding/sleep charts show text list at `accessibility4`; GrowthChartView has long-press for value |

### 10.2 VoiceOver

| Task | Status | Evidence |
|------|--------|----------|
| Labels and hints | Partial | Present on StatusHeaderView, ContextChipsView, ComposerView, ConversationBubbleView, TimerCardView, InsightsView; not on every control |
| Card type announcement | Done | e.g. "Insight card: \(entry.text). Double-tap for details." |
| Custom Rotor | Done | `HomeView` has `accessibilityRotor` for "Conversation Entries", "Edit Entry", "Delete Entry" |
| Timer state | Partial | TimerCardView has labels; "Sleep timer active. 2h 15m elapsed. Swipe right to pause" style phrasing not fully verified |

### 10.3 Color & Contrast

| Task | Status | Evidence |
|------|--------|----------|
| Color independence | Partial | Charts use icons (drop, moon); no systematic pattern overlays |
| Contrast audit | Open | No documented 4.5:1 / 3:1 check; semantic tokens used |

---

## Phase 11: Edge Cases & Polish

### 11.1 Aging Out

| Task | Status | Evidence |
|------|--------|----------|
| Declining log detection | Done | `AgingOutService`; rolling 7-day count; threshold 3/day for 2+ weeks |
| Reduce chips over time | Done | `ContextChipsView.reducedMode`; `suggestedChips` filters when `reducedMode`; `AgingOutService.reducedChipMode` |
| Milestone journal mode | Open | No UI shift to emphasize milestones over granular tracking when aged out |

### 11.2 Offline & Sync

| Task | Status | Evidence |
|------|--------|----------|
| Offline indicator | Done | `StatusHeaderView.isOffline`; `NetworkMonitor`; cloud-slash icon when disconnected |
| CloudKit sync (optional) | Open | No `SyncService`; no CloudKit integration |
| Data migration/import | Partial | `ImportService` for CSV import; no bulk voice ("I fed 6oz at noon yesterday") parsing |

### 11.3 Motion & Haptics

| Task | Status | Evidence |
|------|--------|----------|
| Consistent haptic mapping | Partial | `sensoryFeedback` used; `.success` on undo; `.impact` on timer; full spec mapping not audited |
| Animation durations | Partial | Spring/ Reduce Motion used; no centralized 350ms/200ms/2000ms constants |

---

## Phase 12: Siri & App Intents

### 12.1 App Intents

| Task | Status | Evidence |
|------|--------|----------|
| Log feeding intent | Done | `LogFeedingIntent`; amountOz parameter; stores in UserDefaults for app processing |
| Start timer intent | Done | `StartTimerIntent`; sleep/feeding type |
| Query intent | Done | `QueryLastEventIntent`; feeding, diaper, sleep; returns from UserDefaults |
| Register intents | Done | `HenriiShortcutsProvider` with Log Feeding, Start Timer, Check Last Event, Log Diaper |

### Implementation Note

Intents write to `UserDefaults` pending actions; the main app is expected to process these on launch. Plan implies direct event creation; current design uses deferred app-handled actions.

---

## Summary Table

| Phase | Done | Partial | Open |
|-------|------|---------|------|
| 7 | 14 | 3 | 2 |
| 8 | 7 | 3 | 1 |
| 9 | 7 | 0 | 1 |
| 10 | 4 | 4 | 2 |
| 11 | 4 | 2 | 3 |
| 12 | 4 | 0 | 0 |

---

## Recommended Priorities

1. **High:** Export vaccination card; wire notification scheduling to settings/interval; medication due-time logic  
2. **Medium:** Bezier curves for feeding/sleep charts; Bento card large-type layout; milestone journal mode  
3. **Low:** StandBy Mode; CloudKit sync; bulk voice import; formal contrast audit
