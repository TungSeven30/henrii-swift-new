# HENRII — Golden Master Design Specification

**PROJECT:** Henrii v1.0 — iOS 26+ Target
**CLASSIFICATION:** Final Merged Spec — Production Build Reference
**ROLE:** Senior UI/UX Designer, Conversational & AI-Native Interfaces

---

## I. DESIGN PHILOSOPHY: THE 3AM IMPERATIVE

Every existing baby tracker fails because it treats the user as a data-entry clerk. Parents are navigating complex UIs, tapping through nested menus, and interpreting dashboards — at 3AM, one-handed, half-asleep, with 10% of their normal cognitive bandwidth.

Henrii flips this entirely. The conversation *is* the interface. The AI does the thinking. The UI generates itself around what matters *right now*.

### Core Principles

1. **The 3AM Rule.** Every feature, every interaction, every pixel must pass this test: Can a sleep-deprived parent, holding a baby in one arm, complete this in under 5 seconds with one thumb? If not, redesign it or remove it.

2. **Conversation-First, Not Chat-Bolted-On.** We do not ask parents to navigate. We do not ask them to categorize their intent before acting. They speak or type, and Henrii structures the data, generates the UI, and responds with whatever format is most useful.

3. **Ambient Intelligence.** Henrii should feel like it's already paying attention. It notices patterns before parents do. It surfaces insights at the right moment — not buried in a dashboard tab. The app is proactive, not reactive.

4. **Reduce, Don't Add.** Every screen, component, and interaction must *reduce* cognitive load. UI elements vanish when not needed. Data density scales with user intent. If a feature requires explanation, it's too complex. If a screen requires scrolling to understand, it's too dense.

5. **Emotional Design.** This app lives in one of the most emotionally intense periods of people's lives. Henrii must feel like a calm, capable, experienced night nurse — warm, reassuring, and completely devoid of clinical anxiety. Never condescending. Never saccharine. Never anxious.

6. **Designed Obsolescence.** Henrii gets *quieter* over time. At week 2, parents track every ounce. At month 14, they track almost nothing. Henrii detects declining logging frequency and stops prompting. It sloughs off unnecessary chips, transitions into a low-pressure milestone journal, and is designed to beautifully make itself obsolete.

---

## II. BRAND & VISUAL IDENTITY

**App Name:** Henrii
**Tagline:** "You parent. Henrii keeps track."

We are designing for the *parent*, not the baby. Henrii is a premium, AI-native utility. We strictly reject pastel pinks/blues (too childish) and sterile whites (too clinical). The tone conveys calm intelligence — warmth without infantilization.

### Color System (Semantic Tokens)

All components use semantic tokens, never raw hex values. Every color meets WCAG AA minimum (4.5:1 for normal text, 3:1 for large text/UI).

| Token | Purpose | Light Mode | Dark Mode |
|-------|---------|------------|-----------|
| `canvas.primary` | Base background | Warm Oat `#F8F6F0` | Deep Obsidian `#121211` |
| `canvas.elevated` | Cards, sheets | Soft Linen `#F2EFEA` | Warm Charcoal `#1C1C1E` |
| `accent.primary` | Core actions, CTAs | Terracotta `#D96C52` | Terracotta Light `#E8856B` |
| `accent.secondary` | Secondary interactions | Muted Clay `#B5745C` | Soft Clay `#D4937E` |
| `data.feeding` | Feed-related UI | Soft Amber `#E3A77A` | Warm Amber `#EBB88F` |
| `data.sleep` | Sleep-related UI | Muted Slate `#6B7A8F` | Soft Slate `#8A9AAF` |
| `data.diaper` | Diaper-related UI | Sage `#8B9A84` | Light Sage `#A4B39D` |
| `data.growth` | Growth/milestones | Sprout Green `#4BBA4B` | Emerald `#82D982` |
| `semantic.alert` | Warnings, medical flags | Muted Crimson `#C85A5A` | Alert Rose `#E88282` |
| `semantic.celebration` | Milestones, streaks | Golden Honey `#D4A843` | Warm Gold `#E5C06A` |
| `text.primary` | Primary text | `#1A1A19` | `#F0EDE8` |
| `text.secondary` | Supporting text | `#6B6966` (60% opacity logic) | `#9A9590` |
| `text.tertiary` | Captions, hints | `#9A9590` | `#6B6966` |

> ✍️ **DESIGNER'S NOTE: The OLED Dark Mode Tradeoff**
>
> We use `#121211` (Obsidian) instead of `#000000` (Pure Black) for dark mode canvas. Pure black causes severe OLED smearing when white text scrolls, and creates harsh astigmatism halation for tired eyes in a pitch-black nursery. Obsidian emits near-zero lux while maintaining optical softness. This app will be used in dark rooms *constantly*.

> ✍️ **DESIGNER'S NOTE: Why Terracotta**
>
> Every "premium but approachable" app defaults to indigo or blue. Terracotta is warm, confident, gender-neutral, and instantly recognizable on a home screen full of pastel competitors. It communicates "this was designed by adults, for adults" without being cold.

### Typography System

| Style | Font | Size (Default) | Weight | Line Height | Usage |
|-------|------|----------------|--------|-------------|-------|
| Large Title | SF Pro Rounded | 34pt | Bold | 41pt | Screen titles |
| Title 2 | SF Pro Rounded | 22pt | Bold | 28pt | Section headings |
| Headline | SF Pro Rounded | 17pt | Semibold | 22pt | Card titles, emphasis |
| Body | SF Pro Rounded | 17pt | Regular | 140% (24pt) | Conversational text, UI labels |
| Callout | SF Pro Rounded | 16pt | Regular | 21pt | Supporting content |
| Subheadline | SF Pro Text | 15pt | Regular | 20pt | Secondary information |
| Footnote | SF Pro Text | 13pt | Regular | 18pt | Timestamps, metadata |
| Caption | SF Pro Text | 12pt | Regular | 16pt | Labels inside charts |
| Data/Timer | SF Pro Text (Monospaced Numerals) | 17pt–48pt | Medium | — | Timers, ounces, durations |

SF Pro Rounded is used for all conversational and heading text — it subtly softens the interface and makes the AI feel human and approachable. Monospaced numerals are mandatory for timers and data values to prevent horizontal jitter when digits change.

All text supports Dynamic Type fully, scaling from xSmall to AX5 (310%). Layouts reflow gracefully; no truncation.

### Iconography

Custom icons drawn with a rounded 2pt stroke. Metaphors reference baby care (bottle, breast, diaper, moon) without childish detail. Icons align with SF Symbols weight system. In navigation contexts, icons float on translucent Liquid Glass plates per iOS 26 conventions.

Icon set must include: bottle, breast, diaper, moon/sleep, thermometer, growth/ruler, milestone/star, timer/clock, camera/photo, settings/gear, search, voice/mic, edit/pencil, share, export, add, close, undo, pause, stop, play.

### Illustration Style

Minimal, geometric shapes with subtle warm gradients. Abstract, modern, gender-neutral. No character art, no cartoon babies. Illustrations appear in: onboarding, empty states, milestone celebrations, and the aging-out flow. Style should feel closer to editorial illustration than clip art.

### App Icon

A beautifully rendered, tactile 3D orb — a continuous interlocking loop symbolizing the parent-child bond — in Terracotta, resting in a deep obsidian Liquid Glass enclosure. It promises calm intelligence and stands out against every pastel competitor icon on the home screen.

### Spacing & Grid System

Strict 8pt base grid for all spacing, padding, and sizing.

| Token | Value | Usage |
|-------|-------|-------|
| `space.xs` | 4pt | Tight internal gaps (icon-to-label) |
| `space.sm` | 8pt | Chip padding, tight component spacing |
| `space.md` | 12pt | Default component spacing |
| `space.lg` | 16pt | Card internal padding, section gaps |
| `space.xl` | 24pt | Section separation |
| `space.2xl` | 32pt | Major section breaks, time block separation in thread |
| `margin.phone` | 20pt | Horizontal page margins (iPhone) |
| `margin.tablet` | 32pt | Horizontal page margins (iPad) |

**Rule:** Internal spacing is always ≤ external spacing. This clarifies hierarchy and grouping.

### Depth & Materials (iOS 26 Liquid Glass)

Henrii leverages dynamic spatial blurring (`.ultraThinMaterial` with dynamic luminance). Backgrounds don't just darken when a card is generated — they physically recede via a Z-axis depth blur, separating the "Now" from the "History."

| Surface | Treatment |
|---------|-----------|
| Navigation/Composer | Liquid Glass with translucent tint |
| Generated Bento Cards | Liquid Glass with subtle depth shadow |
| Conversation bubbles | Flat, no glass (reduce visual noise) |
| Modals/Sheets | Standard iOS sheet material |
| Inactive content | Subtle depth blur to recede |

Corner radii: 16pt for large containers, 12pt for cards, 8pt for buttons/chips. Glass plates morph subtly as users scroll or interact.

> ✍️ **DESIGNER'S NOTE: Liquid Glass Restraint**
>
> Liquid Glass is captivating but can over-emphasize minor controls — back arrows and close icons gain too much visual weight. Henrii limits Liquid Glass to major interactive surfaces (navigation, composer, generated cards) and keeps secondary icons flat. In dark mode, glass is more prominent by nature, so we further limit glass surfaces to prevent visual noise. High-contrast mode increases opacity and reduces blur when enabled.

### Motion Language

Motion signals hierarchy and continuity. All animations use spring-based physics with natural easing.

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Card appear | 350ms | Spring (damping 0.8) | Bento Cards entering conversation |
| Card morph (correction) | 250ms | Spring (damping 0.9) | Data correction animation |
| Screen transition | 300ms | Ease-in-out | Navigation between views |
| Chip slide-in | 200ms | Spring (damping 0.7) | Context chips appearing |
| Timer pulse | 2000ms | Ease-in-out (loop) | Active timer breathing effect |
| Haptic confirm | — | `.success` | Log confirmation |
| Haptic timer start | — | `.impactMedium` | Timer activation |
| Haptic timer stop | — | `.impactHeavy` | Timer deactivation |

**Reduce Motion:** When system Reduce Motion is enabled, all springs become simple crossfades. Liquid Glass blurs, card morphing, and celebration effects are disabled. No information is conveyed solely through motion.

---

## III. INFORMATION ARCHITECTURE

### The Data Model

Henrii tracks a comprehensive schema:

| Category | Fields |
|----------|--------|
| **Feeding** | Time, duration, amount (oz/ml), type (breast L/R, bottle, solids), food type, notes |
| **Sleep** | Start, end, quality, location, method, interruptions |
| **Diapers** | Time, type (wet/dirty/both), color (newborn-critical), notes |
| **Growth** | Weight, height, head circumference, date, percentile |
| **Health** | Temperature, medications (name, dose, time), symptoms, vaccination records |
| **Milestones** | Developmental markers, date achieved, photos, context |
| **Pumping** | Time, duration, amount, side |
| **Activities** | Tummy time, baths, outings, playtime |
| **Notes** | Freeform entries, photos, moments |

**The parent never sees this structure.** They input unstructured strings; the AI structures the JSON. "Nursed left side 15 min" or "she just woke up" → Henrii maps utterances to structured objects.

### Navigation Architecture: The Z-Axis Model

**There is no Tab Bar in Henrii.**

Tab bars force users to categorize their intent before acting — that's cognitive load. Henrii's navigation model is spatial and gestural, with the conversation as the gravitational center.

| Layer | Content | Access |
|-------|---------|--------|
| **Layer 0 (Base)** | Continuous Conversation Stream (Home) | Default state |
| **Layer 1 (Floating)** | Universal Composer Pill | Anchored to bottom, 100% of the time |
| **Layer +1 (Above)** | Today Dashboard (structured timeline) | Pinch-out from conversation |
| **Layer +1 (Left)** | Insights & Trends | Swipe left from Home |
| **Layer -1 (Below)** | Search & History | Swipe/pull down from mid-screen |
| **Layer (Modal)** | Baby Profile, Settings | Tap top-right avatar |

**Gestural Navigation:**
- **Pinch-Out:** Semantic zoom into the Today Dashboard
- **Swipe Down (mid-screen):** Universal Search & History
- **Swipe Left:** Insights & Trends
- **Tap Top-Right Avatar:** Baby Profile, Settings, Sharing

The user's thumb rests at bottom center. Dedicating 100% of that prime real estate to the Composer reduces time-to-action to zero.

> ✍️ **DESIGNER'S NOTE: Killing the Tab Bar**
>
> This is the most controversial decision in the spec. Apple's HIG strongly recommends tab bars for primary navigation. We're abandoning it because Henrii's core thesis demands it — if conversation is the primary interface, the composer must own the bottom of the screen. The tab bar competes for the same space and forces categorical thinking.
>
> **Pivot condition:** If usability testing shows >20% of users feel "lost" or can't discover secondary views, we introduce a subtle single-line dynamic header with haptic breadcrumbs. But the tab bar remains dead.

### Multi-Child Support

If multiple children exist, a persistent toggle appears above the composer: `[👶 Baby A] [👶 Baby B] [Both]`. "Fed both 4oz" logs identical entries for both children instantly, splitting into two parallel Bento Cards.

A top-left avatar provides profile switching for children with separate conversation histories. Each child retains its own data and conversation stream.

### Information Hierarchy Per Baby Age

Henrii adapts what it surfaces based on the baby's age:

| Age | Primary Focus | Secondary | De-emphasized |
|-----|--------------|-----------|---------------|
| 0–2 weeks | Feeding frequency, wet/dirty diapers, weight gain | Sleep patterns | Everything else |
| 2 weeks–3 months | Feeding amounts, sleep consolidation | Growth, tummy time | Solids, milestones |
| 3–6 months | Sleep training readiness, growth spurts | Milestones, solids intro | Diaper counts |
| 6–12 months | Solids progression, milestones | Sleep patterns, growth | Individual feed tracking |
| 12+ months | Milestones, activities | Sleep, meals | Granular tracking (fade out) |

---

## IV. CONVERSATIONAL INTERFACE DESIGN

This is the heart of Henrii. Every detail matters.

### The Composer (The Command Center)

A floating Liquid Glass pill anchored 16pt above the keyboard safe area. This is not a chat text field — it's a command center that also accepts natural language.

**Components:**

| Element | Spec | Behavior |
|---------|------|----------|
| **Text Input** | Full-width field, placeholder: "Tell Henrii..." | Accepts exhausted parent-speak: "nursed L 15m", "blowout 💩", "fed 4oz at 2pm" |
| **Dictation Orb** | 56×56pt, right edge of composer | Hold to trigger on-device Siri Spatial Voice. Processes whispered natural language. Immediate haptic feedback on activation. |
| **Smart Context Chips** | 40pt tall, floating 8pt above composer | Contextually aware. At 3AM after 4 hours of sleep: `[🍼 Start Feed]` `[💩 Diaper]`. After logging a feed: `[Burp]` `[Spit-up]` `[Diaper]`. One-tap logging. |
| **Timer Start/Stop** | Pill button, 70×44pt minimum | Appears contextually. When active: shows elapsed time, pulsing Liquid Glass, Pause button, breast L/R toggle. |
| **Send Button** | 44×44pt, appears when text is entered | Replaces dictation orb when typing |

**Voice Input Design:**
- Voice is a first-class citizen, not an afterthought. The 56pt dictation orb is large enough for eyes-closed tapping.
- On-device processing for instant response and offline capability.
- Immediate haptic + subtle audio feedback confirms listening.
- The system maintains context across turns ("she" = the active child, "again" = same as last event).
- Voice remains optional — never mandatory. Every voice action has a tap equivalent.

**One-Tap Timers:**
For feeds and sleep, the most common actions. A single tap starts the timer with current time. The timer persists across the composer, Live Activities, Dynamic Island, and Lock Screen. Stopping the timer auto-logs the event and generates a summary card with suggestions ("Log burp?").

### AI Response Design: Bento Cards

**Henrii does not reply with chat bubbles.** Henrii replies with Bento Cards — compact, functional UI elements that inject themselves into the conversation stream.

This is the critical design difference. The conversation is not a chat log — it's a living timeline where AI responses are interactive UI elements, not text messages.

**Response Types:**

| Type | Visual Treatment | Example | Interaction |
|------|-----------------|---------|-------------|
| **Confirmation** | Micro-pill, single line | `[🍼 4oz formula • 2:34 PM]` | Swipe left: Edit/Delete. Tap: Expand details. Haptic `.success` tick on creation. |
| **Insight Card** | Liquid Glass card, `data.*` accent color | "She's sleeping 30 min longer this week 📈" with mini trend line | Tap: Expand to full trend view. Dismiss: Swipe left. |
| **Interactive Chart** | Full-width generated visualization | Sleep timeline, feeding pattern, growth curve | Tap data points for detail. Pinch to zoom. Long-press for exact values. |
| **Nudge** | Subtle, softer color, edge-aligned | "It's been 3h since last feed — start a timer?" | Tap to act, swipe to dismiss. Auto-dismiss after 30 minutes. |
| **Celebration** | Liquid Glass with subtle particle effect | "First time sleeping through the night! 🎉" | Tap: Expand to photo prompt + share option. |
| **Medical Flag** | `semantic.alert` accent, prominent | "Temperature elevated 24h — here's what to watch for" | Tap: Expand to guidance + "Call Pediatrician" action. Cannot be swiped away — requires explicit dismiss. |
| **Handoff Summary** | Temporary card at bottom on device switch | "Morning. David handled 2 wake-ups. Last feed 4oz at 4:30 AM. Maya is currently asleep." | Auto-generated when a different parent opens the app. Dismisses after reading. |
| **Daily Summary** | Rich card with rings/metrics | Three overlapping rings (Sleep, Feed, Diaper) + natural language: "A solid day. 45 min more sleep than yesterday." | Tap: Expand to full day view. Share button for partner. |

**Correction Model:**
When a user corrects data ("Wait, that was 5oz"), Henrii does NOT create a new message. It seamlessly morphs the existing card — the `4` becomes `5` with a fluid spring animation. The timeline stays clean. If the AI is uncertain about a correction, the changed data highlights in `semantic.celebration` (gold) with a `[?]` tap-to-confirm interaction.

**Confidence Communication:**
- **Confident:** Clean card, no qualifiers
- **Uncertain:** Card with highlighted field + `[?]` confirm tap
- **Needs clarification:** Brief text question above the composer, not a card

**Conversation Scalability:**
To prevent the stream from becoming a wall, Henrii groups consecutive similar logs into collapsible summaries. Three diapers in one hour collapse into "3 diapers logged" (expandable on tap). Days separate with subtle labels. Days with 50+ entries auto-group into time periods (morning, afternoon, evening, night). A mini-calendar provides quick navigation to specific dates.

### Multi-Parent & Caregiver Support

| Role | Permissions | UI Presence |
|------|-------------|-------------|
| **Co-Parent** | Full read/write/edit | Full avatar next to entries, handoff summaries |
| **Nanny/Sitter** | Add-only during shift, hides medical history | Simplified composer, no insights access |
| **Grandparent** | View-only milestones, photos, basic status | Read-only App Clip with filtered content |

Entries include the logger's tiny (16pt) avatar and timestamp. Partners can reply in conversation or log events independently.

**The Handoff Summary:** When a different parent's device opens the app, Henrii detects the device shift and generates a temporary Handoff Card: "Morning. David handled 2 wake-ups. Last feed was 4oz at 4:30 AM. Maya is currently asleep." Partner coordination notifications are delivered as *silent notifications* that update the Lock Screen Live Activity without buzzing — because you never wake the sleeping parent.

---

## V. GENERATIVE UI SYSTEM

When Henrii visualizes data, it dynamically assembles components. Every generated element must look bespoke — indistinguishable from a hand-crafted screen.

### Component Library

| Component | Description | Data Rules | Interaction |
|-----------|-------------|------------|-------------|
| **Summary Card** | Daily/weekly/monthly metrics with icons, totals, % change | Sparse data: friendly text + illustration. Normal: metrics + mini-charts. Rich: full visualization. | Tap: expand. Swipe: dismiss/share. |
| **Trend Chart** | Soft, organic cubic bezier curves | <5 points: show exact values. 5–10: labeled curve. >10: smooth trendline. **No gridlines. No Y-axis labels by default.** | Long-press: haptic pop + exact value tooltip. Pinch: zoom. |
| **Timeline View** | Horizontal 24h scroll, events as colored rounded blocks (Gantt-style) | Each event: icon + label chip. Current time: vertical marker. | Long-press block edge: drag to adjust start/end time. Tap: edit. |
| **Comparison View** | Side-by-side bars, this week vs. last | Context labels ("Feeding 10% more this week"). Footnotes if sample sizes <5. | Tap bars for detail. |
| **Milestone Tracker** | Circular progress indicators | Shows age ranges, completion status, developmental context | Tap: expand with guidance ("Tummy time helps build neck strength"). |
| **Medical Reference Card** | Normal ranges, when-to-call guidance | Uses `semantic.alert` color. Cites AAP/WHO guidelines. | Tap: expand. Action button: "Call Pediatrician." |
| **Photo Memory Card** | Moment capture integrated with data | Links photo to concurrent data (weight at 3-month milestone) | Tap: full-screen. Share. |
| **Schedule Suggestion** | Pattern-based gentle recommendation | Only surfaces at 85% statistical confidence | Accept/dismiss. Links to timer. |
| **Growth Chart** | WHO pediatric percentiles as soft shaded regions | Adjusted age for preemies. Personal data plotted on top. | Pinch zoom. Tap for exact measurements. |
| **Three-Ring Summary** | Sleep/Feed/Diaper rings (Activity Rings style) | Natural language summary below | Tap: expand to full day breakdown. |

> ✍️ **DESIGNER'S NOTE: Erasing the Grid**
>
> We hide X/Y axes and gridlines on charts by default. Medical charts induce clinical anxiety. A parent doesn't need a Y-axis to understand "she's sleeping longer this week." The shape of the curve tells the story. Exact data is always available via long-press (haptic pop). This is an emotional design decision — we optimize for reassurance, not clinical precision.

### Visual Consistency Rules

Every generated component must match the design system exactly:
- Typography: Uses defined type scale, never system defaults
- Colors: Semantic tokens only, never raw hex
- Spacing: 8pt grid, 16pt internal card padding
- Corner radii: 12pt for cards
- Animations: Spring-based appear with defined curves
- Dark mode: Full treatment, not inverted

### States for All Generated Components

| State | Treatment |
|-------|-----------|
| **Loading** | Skeleton placeholder matching final layout dimensions. Subtle shimmer animation. |
| **Empty** | Friendly illustration + text ("No feeds logged yet — tell me when you're ready"). Never a blank screen. |
| **Error** | Warm error message + retry action. Fallback to deterministic text list (Apple Health style). |
| **Insufficient Data** | Partial card with explanation ("Need a few more days of data to show trends"). |
| **Offline** | Cached version with subtle cloud-slash icon. Updates silently on reconnection. |

### Graceful Degradation

If the generative engine fails (offline, timeout, error), the system falls back to a deterministic, highly legible text list. The fallback must still be well-designed — it's not an error state, it's an alternative rendering.

---

## VI. AMBIENT INTELLIGENCE DESIGN

### Pattern Recognition & Surfacing

Henrii operates on an **85% statistical confidence threshold** before surfacing insights. No guessing, no noise.

When a pattern crosses the threshold, Henrii places a **Ghost Card** (slightly transparent, visually distinct from logged data) in the conversation stream: "Insight: Leo sleeps 40 min longer on days he has an evening bath."

**Cadence control:** Maximum 1 unprompted insight per day. Urgent medical patterns override this limit.

### Smart Notifications

Henrii does not spam push notifications. Every notification earns its interruption.

| Priority | Type | Delivery | Example |
|----------|------|----------|---------|
| **Time-Sensitive** | Medication due, medical alert | Banner + sound + haptic | "Amoxicillin due in 15 min" with 1-tap "Logged" action on lock screen |
| **Active** | Feeding reminder, handoff info | Banner, no sound | "It's been 3h since last feed" |
| **Silent** | Partner coordination | Lock Screen Live Activity update only | "Sarah just logged a feed" — no buzz, never wake the sleeping parent |
| **Passive** | Daily summary, milestone | Notification center only | "Daily summary ready" |
| **Celebration** | Milestone achieved | Rich notification with image | "First time sleeping 6 hours straight! 🎉" |

**Lock Screen Actions:** Time-sensitive notifications include inline actions (1-tap "Logged", "Start Timer", "Snooze 30 min") so parents never have to unlock the phone.

### Daily Intelligence

| Timing | Content | Adaptation |
|--------|---------|------------|
| **Morning Briefing** | Night summary: wake-ups, feedings, total sleep, comparison to recent average | Newborns: emphasize feeding count. Older babies: emphasize sleep consolidation. |
| **Evening Summary** | Day totals: feedings (amount), naps (duration), diapers, activities | Adapts metrics shown based on baby age and what's medically relevant at that stage. |
| **Weekly Digest** | Trend overview: patterns, growth, milestones approaching | Includes actionable context ("She's in a growth spurt window — expect increased feeding"). |

### Widgets & Live Activities

**Home Screen Widgets:**

| Size | Content |
|------|---------|
| **Small** | Time since last feed + current status (sleeping/awake) |
| **Medium** | Three metrics (feed/sleep/diaper) + active timer if running |
| **Large** | Mini timeline of today + metrics + next expected event |

**Dynamic Island:**
When a sleep timer is active, the Island shows a soft, slow-breathing waveform in `data.sleep` color, matching a baby's respiratory rate. Expanded view shows elapsed time + Pause/Stop controls.

**Lock Screen Live Activity:**
Full-width during active timers. The `[Pause]` and `[Stop]` buttons are **88×88pt minimum**. You must be able to hit them blindly in the dark.

**StandBy Mode (Nightstand):**
When charging horizontally, the screen goes pure black with ultra-dim, **red-tinted text** (preserving night vision — blue light destroys dark adaptation). Shows only: "Last feed: 3h 12m ago" and a massive "Start Feed" button. Nothing else.

> ✍️ **DESIGNER'S NOTE: Red-Tinted StandBy**
>
> This is based on military and astronomy best practices for preserving scotopic (night) vision. Red light doesn't trigger the cone cells that reset dark adaptation. A parent who checks the time at 2AM and then has to navigate a dark nursery will retain their night vision. Every other baby app ignores this.

### Siri Shortcuts & App Intents

Henrii registers App Intents for common actions, enabling voice logging without opening the app:

- "Hey Siri, tell Henrii I just fed 4 ounces"
- "Hey Siri, start a sleep timer in Henrii"
- "Hey Siri, ask Henrii when the last diaper was"

Intents work from iPhone, Apple Watch, HomePod, and CarPlay.

---

## VII. SCREEN-BY-SCREEN DESIGN SPECIFICATIONS

All screens support: Dark mode (designed concurrently), Dynamic Type to 310%, VoiceOver with custom rotor actions, and Reduce Motion alternatives. Minimum touch targets: 44×44pt (primary actions: 56pt+).

### Screen 1: First Launch & Onboarding

**The onboarding IS the first conversation.** No 5-page swipe carousels. No feature tours. A parent who just had a baby downloaded 4 tracker apps. Win them in 30 seconds.

**Layout:** Immersive full-screen Liquid Glass environment.

**Flow:**
1. "Hi. I'm Henrii. What's your baby's name?" → Keyboard auto-deploys. Large input field.
2. "Nice to meet you, [name]. When was he born?" → Native date picker morphs in from bottom (one-hand reachable).
3. *Optional:* "Want to add a photo?" → Camera/library picker. Skip is prominent.
4. "I can use Siri so you can log hands-free from across the room. Sound good?" → `[Allow All]` pill. Clear value statement for each permission (Notifications, HealthKit, Siri).
5. "Want to invite [partner name] to track together?" → Share link/QR. Skip is easy.
6. First conversation message: "You're all set. Just tell me what's happening and I'll handle the rest." + Quick-start chip: `[🍼 Log first feed]`

**States:**
- Default: Conversational flow
- Loading: Subtle pulse while saving profile
- Error: Inline, friendly ("Hmm, couldn't save that — try again?")
- Skip: Every step has a visible skip option except baby name

**The feeling:** The app is already working for them in 30 seconds. Not "setting up" — *already helping*.

### Screen 2: Home / Conversation Hub (The Core)

This is where parents spend 90% of their time.

**Layout:**
- **Top edge:** Semi-transparent dynamic status header fading into top: `🍼 2h 15m ago • 💤 45m ago • 💩 3h ago`. Always visible, never loud. Tapping any metric jumps to that category's recent entries.
- **Center:** Infinite scroll conversation stream (scrolls upward, newest at bottom). Bento Cards interspersed with confirmations, insights, and generated UI.
- **Bottom:** Floating Composer Pill with context chips above it.

**Active Timer State:** When a timer is running, a pulsing Liquid Glass card pins above the composer with elapsed time, Pause, and Stop (slide-to-stop). For breastfeeding: Left/Right toggle visible. Syncs with Dynamic Island and Live Activities.

**Interactions:**
- Swipe left on any card: Edit or Delete
- Shake phone: Systemic Undo prompt (disabled — see edge cases; replaced with 5-second undo toast)
- Pull down (top): Refresh / time navigation
- Pinch out: Transition to Today Dashboard

**States:**
- Default: Conversation with status header
- Timer active: Pulsing card pinned above composer
- Voice listening: Dictation orb expanded, waveform animation
- Empty (new user): Warm welcome message + "Log your first feed" chip + illustration
- Error (failed log): Inline error with undo option
- Offline: Subtle cloud-slash icon in status header

### Screen 3: Today View / Dashboard

**Access:** Pinch-out gesture from Home Hub. A spatial zoom transition — the conversation recedes and the structured view emerges.

**Layout:** A continuous vertical 24-hour timeline (like an elegant flight tracker). Time axis on the left. Data plotted as colorful, rounded blocks on the right (Gantt chart style). Each block uses the semantic data color for its category.

**Components:**
- Vertical time axis (hours)
- Colored event blocks (width = duration, color = category)
- Current time marker (animated line)
- Summary metrics at top (total feeds, sleep hours, diapers)
- Quick-add button for manual entry

**Interactions:**
- Long-press any block's edge: Natively drag/slide start or end time to adjust visually
- Tap block: Expand details inline
- Segmented control: 24h / 12h / Week view
- Pinch in: Return to conversation

**States:**
- Data: Full timeline with events
- Empty: Illustration + "Nothing logged yet today — I'm ready when you are"
- Loading: Skeleton timeline blocks
- Edge: When entries exceed visible area, smooth scroll with momentum

### Screen 4: Insights & Trends

**Access:** Swipe left from Home.

**Layout:** Masonry grid of dynamically generated insight widgets. The AI determines which visualizations are most relevant based on the baby's age, recent patterns, and data availability.

**Content:**
- Growth charts with WHO pediatric percentile overlays as soft shaded regions
- Sleep trend analysis (duration, consolidation, regression detection)
- Feeding pattern evolution (amounts, frequency, solid food progression)
- Milestone tracker with developmental context and expected age ranges
- Weekly comparison cards
- AI-generated natural language summaries ("Leo crossed into the 50th percentile for weight today. He is tracking perfectly.")

**Tone:** AI frames data positively when possible. Never alarmist unless medically warranted.

**Interactions:**
- Tap any widget: Expand to full detail view
- Long-press: Share/export options
- Pull to refresh: Regenerate with latest data
- Swipe right: Return to conversation

**States:** Data, loading (skeleton grid), insufficient data ("Need a few more days to show trends — keep logging and I'll have insights soon"), error (retry button).

### Screen 5: Baby Profile & Medical Info

**Access:** Tap top-right avatar from any screen.

**Layout:** Standard iOS Inset Grouped list style (`UICollectionViewListCell`).

**Sections:**
- **Header:** Photo, name, age (adjusted age if premature), quick child-switch action
- **Vitals:** Birth details (weight, length, APGAR if available), blood type, allergies
- **Pediatrician:** Contact info, next appointment, one-tap call/directions
- **Vaccinations:** List with dates and upcoming schedule. Export vaccination card.
- **Growth Log:** Interactive chart (weight, height, head circumference) with manual entry fields. Units toggle (kg/lb, cm/in).
- **Medical Notes:** Chronological list with category filters
- **Export/Share:** PDF/CSV export. Native share sheet.

**Floating Action Button:** High-contrast `[Generate Doctor's Report]`. Instantly compiles the last 7 days (or since last visit) of sleep/feed averages, growth data, and active symptoms into a clean, clinical 1-page PDF. Native iOS Share Sheet for AirDrop to pediatrician.

### Screen 6: Settings & Preferences

**Layout:** Grouped list with clear section headers.

**Sections:**

| Section | Contents |
|---------|----------|
| **Baby Profiles** | Add/edit children, manage profiles |
| **Caregivers** | Co-Parent (full edit), Nanny/Sitter (add-only, hides medical), Grandparent (view-only milestones). Invite via link/QR. |
| **AI Behavior** | Insight frequency slider (Minimal → Verbose). Tone selector (Direct / Warm / Playful) with preview. Notification preferences per category. |
| **Data & Privacy** | What's stored, what's synced (CloudKit). Data retention controls. Export all data (JSON/CSV). Delete account. |
| **Units & Format** | oz/ml, kg/lb, cm/in, 12h/24h, date format, language |
| **Integrations** | Apple Health sync, Siri Shortcuts, Apple Watch companion |
| **Subscription** | Plan management (if applicable) |
| **About** | Version, support, feedback |

**Single Parent Consideration:** Partner/caregiver features remain hidden unless explicitly enabled. No empty "Invite Partner" cards cluttering the experience.

### Screen 7: Search & History

**Access:** Pull down from mid-screen on the Hub.

**Layout:** Focuses the Composer in search mode. Natural language search.

**Interaction:** User types "When did she last have Tylenol?" — Henrii bypasses standard list results and generates an answer card: "Maya had 2.5ml of Tylenol yesterday at 4:15 PM. She is clear for another dose."

**Fallback:** If the AI can't generate a direct answer, show filtered results as conversation snippets with highlighted matches. Tapping a result jumps to that point in the conversation.

**Filters:** Category chips (feeding, sleep, diapers, health, all), date range picker (slides from bottom), and voice search using the same dictation system.

### Screen 8: Sharing & Reports

**Access:** Via Profile screen or long-press share on any card.

| Feature | Design |
|---------|--------|
| **Pediatrician Report** | Auto-compiled narrative summary ("Since the 3-month visit, she gained 1.2 kg, slept avg 14h/day...") + charts + PDF export. Offline-cached for clinic visits. |
| **Partner Summaries** | Configurable daily/weekly auto-send with key events and patterns. |
| **Family Sharing (Grandparents)** | Generates a secure web-link App Clip. *Crucially filters out blowout diapers and granular medical data.* Shows only: photos, high-level milestones, basic "Last fed at..." data. Large type, simple navigation. |
| **Export** | PDF (formatted report), CSV (raw data), image (individual cards/charts). Native share sheet. |
| **Social Sharing** | Optional milestone sharing with tasteful, minimal design. Consent-first: preview before sharing. |

---

## VIII. COMPONENT SPECIFICATIONS

### Button Hierarchy

| Type | Height | Shape | Style | Haptic | Usage |
|------|--------|-------|-------|--------|-------|
| **Primary** | 56pt min | Capsule | Fill `accent.primary`, white text, subtle shadow | `.success` | Start/Stop timers, Send, primary CTAs |
| **Secondary** | 44pt | Capsule | Outline `accent.primary` stroke, accent text. Fills on press. | `.light` | Save, Edit, secondary actions |
| **Tertiary** | 44pt | Text only | `accent.primary` text, no border. Underlines on press. | None | Skip, Cancel, Learn More |
| **Ghost / Chip** | 36pt | Rounded rect (12pt radius) | `canvas.elevated` background, thick material | `.selection` | Quick-action chips, filters |
| **Destructive** | 44pt | Capsule | Fill `semantic.alert`, white text, caution icon | `.warning` | Delete entries, remove profile |

**States for all buttons:** Default, Pressed (darkened/filled), Disabled (40% opacity), Loading (spinner replacing label).

### Form Patterns

- Input fields: 48pt height minimum, large hit areas
- Labels float inside fields, shrink on focus
- Validation: Inline beneath fields, `semantic.alert` color, clear messages
- Success: Checkmark animation
- Numeric inputs: Numeric keyboard auto-deployed for amounts
- Date/time pickers: Slide from bottom (one-hand reachable)
- All inputs optimized for one-handed use

### The Timer Component (Most-Used Interactive Element)

| State | Design | Interaction |
|-------|--------|-------------|
| **Idle** | Ghost button: `[Start Feed]` or `[Start Sleep]` contextually | One tap to start |
| **Active** | Pulsing Liquid Glass card. Large elapsed time (Data font, 48pt). Prominent Pause button. For breastfeeding: L/R side toggle. | **Slide-to-stop** (prevents accidental taps from phone drops/fumbles) |
| **Paused** | Card stops pulsing, Resume button replaces Pause | Tap Resume or Slide-to-stop |
| **Completed** | Summary Bento Card generates with duration + suggestions ("Log burp?") | Auto-generated, editable |

> ✍️ **DESIGNER'S NOTE: Slide-to-Stop**
>
> Sleep-deprived parents drop phones on their faces or fumble them. Accidental taps ruin sleep logs. A 1-second slide-to-stop (like iOS "Slide to Power Off") prevents catastrophic data loss. The consequence of accidentally stopping a 3-hour sleep timer is severe enough to warrant the friction.

Timer runs across: In-app, Lock Screen Live Activity, Dynamic Island, Apple Watch complication, and Home Screen widget. State syncs in real-time via CloudKit.

### Card System

All cards: 12pt corner radius, 16pt internal padding, 8pt gap between internal elements. `canvas.elevated` background with subtle depth shadow. Titles use Headline style; body uses Body style. Charts inside cards follow semantic color palette.

Cards can be: tapped (expand), swiped left (edit/delete/share), long-pressed (more options), and dismissed.

### Data Visualization

- Charts use semantic data colors with high contrast in both modes
- Animations: Subtle ease-in curves, no overshoot (reduces motion sickness)
- Tap data points: Tooltip with exact values (haptic pop)
- No gridlines or axis labels by default (long-press reveals)
- Bezier curves, not angular line charts
- Color is never the sole differentiator — always paired with icons, patterns, or labels

---

## IX. ACCESSIBILITY — NON-NEGOTIABLE

Accessibility is not a feature. It's the foundation. Every element described in this spec must comply.

### Dynamic Type (to 310%)

- Every text element scales from xSmall to AX5
- Layouts reflow gracefully — no truncation, no overlap
- Bento Cards convert from row-layouts (horizontal) to column-layouts (vertical) automatically at large sizes
- Inline charts degrade into accessible text lists at maximum type sizes
- The 8pt grid ensures alignment across all sizes

### VoiceOver

- All interactive elements have descriptive labels AND hints
- Cards indicate their type: "Insight card: She's sleeping 30 minutes longer this week. Double-tap for details."
- Custom Rotor Actions: Flick up/down on a conversation entry to "Edit", "Delete", or "Add Note" without opening a detail view
- Reading order explicitly mapped to match visual hierarchy
- Timer state announced: "Sleep timer active. 2 hours 15 minutes elapsed. Swipe right to pause."

### Color Independence

We never rely solely on color. The difference between a Sleep card and a Feeding card is:
- Explicit text label
- Distinct iconography (🍼 vs 💤 vs 💩)
- Pattern overlays on charts (dots vs diagonal lines vs solid)
- Passes WCAG AAA for color independence

### Contrast

- All text: minimum 4.5:1 contrast ratio (WCAG AA)
- Large text (18pt+ or 14pt+ bold): minimum 3:1
- UI components and graphical objects: minimum 3:1
- High-contrast mode available: increases opacity, reduces transparency/blur, Liquid Glass effects diminish

### Reduce Motion

- All spring animations → simple crossfade
- Liquid Glass blurs → static surfaces
- Card morphing → instant swap
- Celebration effects → static illustration
- Timer pulse → static active state indicator
- No information conveyed solely through motion

### Motor Accessibility

- Minimum touch targets: 44×44pt for all interactive elements
- Primary buttons and timers: 56pt+
- Lock Screen Live Activity buttons: 88×88pt
- Adequate spacing between targets to prevent accidental taps
- Full Switch Control and external keyboard navigation support
- Visible focus indicators on all focusable elements
- Optional voice commands for all primary actions

### Reachability

100% of interactive elements exist in the bottom 45% of the screen during primary use (conversation logging). The composer, chips, and timer controls are all thumb-reachable without stretching.

---

## X. EDGE CASES & SPECIAL SCENARIOS

| Scenario | Design Solution |
|----------|----------------|
| **Twins/Multiples** | Persistent toggle above composer: `[👶 Baby A] [👶 Baby B] [Both]`. "Fed both 4oz" logs identical entries, splitting into parallel cards. |
| **Premature Babies** | If due date differs significantly from birth date during onboarding, Henrii enables Adjusted Age mode. WHO growth charts and milestone expectations recalculate based on due date. Explicit "(adjusted)" label on age display. |
| **Breast + Bottle Combo** | Henrii natively understands "nursed 10 min right, then topped off with 2oz bottle." Generates a single unified "Combo Feed" card. Quick-action chips adapt contextually. |
| **Caregiver Handoffs** | Summary messages auto-generated on caregiver change. Permissions restrict sensitive data. Handoff card highlights outstanding tasks ("Medication due at 6 PM"). |
| **Pediatrician Visit Mode** | One-tap report generation from Profile. Compiles relevant data since last visit. Offline-cached. AirDrop-ready PDF. |
| **First-Time vs. Experienced Parents** | Brief onboarding questionnaire adapts content density. First-time parents get educational context in insight cards. Experienced parents see data-only. Adjustable in settings. |
| **Single Parents** | Partner features hidden unless enabled. No empty "Invite Partner" prompts. UI feels complete as a solo experience. |
| **Sleep Deprivation Errors** | Every log generates a 5-second Undo toast. Shake-to-undo is DISABLED globally (parents rock babies, triggering false positives). All entries have Edit/Delete via swipe. Edit history maintained. |
| **Data Migration** | Import tools for common trackers (CSV, Huckleberry, Baby Tracker, etc.). Manual bulk voice entry: "I fed 6oz at noon yesterday." |
| **Offline Mode** | Fully functional. On-device CoreML handles NLP parsing. Subtle cloud-slash icon in status header. Syncs silently via CloudKit on reconnection. |
| **Aging Out** | Henrii detects declining logging frequency. Stops prompting. Removes unnecessary chips. Transitions to low-pressure milestone journal. Celebrates the journey. Offers full data export. Designed to beautifully make itself obsolete. |
| **Multiple Devices** | Start timer on iPhone, check on Apple Watch, stop on iPad. State syncs in real-time. Live Activities reflect on all devices. |
| **CarPlay** | Voice-only logging while driving. "Hey Siri, tell Henrii I just picked up from daycare." Confirmation via audio, no visual interaction required. |

> ✍️ **DESIGNER'S NOTE: Shake-to-Undo Disabled**
>
> This seems counterintuitive, but parents physically rock babies constantly. Every rocking motion triggers the accelerometer. False-positive undo prompts at 3AM are unacceptable. The 5-second undo toast + swipe-to-edit covers the use case without the false positive problem.

---

## XI. RESPONSIVE & MULTI-PLATFORM BEHAVIOR

### iPad

- Conversation Hub gains a persistent sidebar showing Today Dashboard alongside the conversation
- Generated cards can display at larger sizes with more data density
- Split View and Slide Over fully supported
- Keyboard shortcuts for power users (⌘+N: new log, ⌘+T: start timer, ⌘+F: search)

### Apple Watch (Companion App)

- Complications: Time since last feed, active timer, daily totals
- Quick-log via Digital Crown scroll + tap (preset actions)
- Timer start/stop from wrist
- Voice logging via watch microphone
- Haptic nudges for feeding reminders

### Orientation

- iPhone: Portrait-primary. Landscape supported for chart viewing.
- iPad: Both orientations fully designed. Landscape shows sidebar + content.

---

## XII. NLP INTENT MAPPING

The AI must parse exhausted parent-speak accurately. Key patterns:

| Input Pattern | Mapped Intent | Extracted Data |
|---------------|--------------|----------------|
| "fed 4oz" / "ate 4 ounces" / "bottle 4oz" | Bottle feeding | amount: 4oz, time: now |
| "nursed left 15 min" / "nursed L 15m" | Breastfeeding | side: left, duration: 15min, time: now |
| "she just woke up" / "awake" | Sleep end | end_time: now |
| "down for a nap" / "sleeping" / "asleep" | Sleep start | start_time: now |
| "diaper" / "changed" / "blowout 💩" | Diaper | type: inferred from context/emoji, time: now |
| "temp 101.2" / "fever" | Temperature | value: 101.2°F, time: now |
| "gave Tylenol 2.5ml" | Medication | name: Tylenol, dose: 2.5ml, time: now |
| "actually that was 5oz" / "wait, 5 not 4" | Correction | updates most recent matching entry |
| "fed both 4oz" | Multi-child feed | logs for all active children |
| "nursed 10 right then 2oz bottle" | Combo feed | breast: right 10min + bottle: 2oz |

Context awareness: "she" = active child. "again" = repeat last action. Time references: "at 2pm", "30 minutes ago", "yesterday at noon."

Offline: On-device CoreML model handles parsing without network. Syncs structured data when reconnected.

---

## XIII. DELIVERY FORMAT MANIFEST

The following constitutes the complete build reference:

1. **Design System Foundations** — Color tokens (light/dark), typography scale, spacing system, depth/material specs, motion definitions, icon set
2. **Component Library** — Every reusable element with all variants (Default, Pressed, Disabled, Loading, Skeleton). Button hierarchy, form patterns, card system, timer component, data visualization specs.
3. **Screen Designs** — All 8 screens, all states (default, loading, empty, error, edge cases), full annotations, dark mode treatments
4. **Interaction Specifications** — Every gesture, transition, micro-interaction, and haptic mapping
5. **Conversational UI Patterns** — Composer design, Bento Card types, correction model, confidence communication, conversation scalability rules
6. **Generative UI Templates** — All dynamic component types with data density rules, visual consistency requirements, and graceful degradation paths
7. **Ambient Intelligence Rules** — Pattern detection thresholds, notification priority matrix, daily intelligence templates, widget/Live Activity specs
8. **Accessibility Matrix** — Per-screen VoiceOver reading orders, custom rotor actions, Dynamic Type reflow rules, color independence verification, contrast audit
9. **NLP Intent Schema** — Parse patterns, context awareness rules, offline model requirements
10. **Multi-Platform Specs** — iPad layout adaptations, watchOS companion, CarPlay voice-only mode, Siri Shortcuts/App Intents

---

*Henrii is designed to make baby tracking effortless at 3AM. Its conversation-first architecture reduces cognitive load to near-zero, while ambient intelligence surfaces only what matters. By combining iOS 26's Liquid Glass aesthetic with a robust semantic design system and uncompromising accessibility, Henrii feels modern yet comforting.*

*Parents can trust Henrii to remember, understand, and anticipate — freeing them to focus on what matters most.*

*"You parent. Henrii keeps track."*
