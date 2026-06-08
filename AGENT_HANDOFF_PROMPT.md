# Prompt for new Cursor agent window

Copy everything below the line into a new chat.

---

## Prompt (copy from here)

You are continuing work on **DayLinx** (Flutter app in `smart_planner/`, repo root `SmartPlanner/`).

### Read first
1. `ANDROID_LOCK_SCREEN_WIDGET.md` — **your default task** (variant 1 «Pulse»)
2. `PROJECT_STRUCTURE.md` — architecture and key paths
3. `PRD_PRODUCT_SPEC.md` — product status (§3.3 notifications/widgets)
4. `smart_planner/DEVICE_CALENDAR.md` — device calendar only (no OAuth)

### What is already done
- Phases 0–5; device calendar read/write; templates; morning/evening digest; midnight overdue roll
- Local DB migrated to **isar_community** 3.3.2 (`package:isar_community/isar.dart`) for Android 16 KB page size
- Android **home widget** MVP (`DayLinxWidgetProvider`, medium 4×2, shared `DayStatusTodayLoader`)
- Android **day-status** foreground notification (opt-in)
- Checklist `moveCompletedToEnd`; `SlidingCompletionList` / `CollapsingCompletionTile`; dashboard tile `ValueKey` stability
- Calendar overlap UX: dashboard event strip (time-proportional layout ~50 px/hour; non-overlapping events share a row; overlapping rows with scaled height and right shift), grid day/3-day/week/month tabs, all-day + cross-midnight events, long-press grid slot create
- ~108 tests (`flutter test`)

### Your task (default)
Implement **Android lock screen widget variant 1** per `ANDROID_LOCK_SCREEN_WIDGET.md`:
- `DayStatusLockScreenPayloadBuilder` + tests
- `DayStatusLockScreenWidgetService` + Glance provider (API 34+)
- Sync from same triggers as home widget
- Read-only, 2 lines max, tap → dashboard today

Only if the user asks for something else — follow their instruction. Cloud sync is **not** planned.

### Rules
- Minimize scope; match existing code style
- Reuse `DayStatusTodayLoader` / `DayStatusLocaleCopy` — no duplicate event logic
- Do **not** re-add Google Calendar API unless explicitly asked
- Do **not** commit unless asked
- Run `flutter test` before finishing

## End of prompt
