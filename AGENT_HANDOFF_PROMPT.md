# Prompt for new Cursor agent window

Copy everything below the line into a new chat.

---

## Prompt (copy from here)

You are continuing work on **DayLinx** (Flutter app in `smart_planner/`, repo root `SmartPlanner/`).

### Read first
1. `PRD_PRODUCT_SPEC.md` — **§3.4 Categories**, **§3.5 Finance**, **§7 Implementation phases**
2. `PROJECT_STRUCTURE.md` — planned `features/categories/`, `features/finance/`, Library hub, schema notes
3. `smart_planner/DEVICE_CALENDAR.md` — local-first events; manual outbound sync only
4. `ANDROID_LOCK_SCREEN_WIDGET.md` — only if user asks for lock screen widget

### What is already done
- Device calendar: **no automatic import**; events in Isar; outbound sync via `EventCalendarSyncService` + `EventSyncCalendarsSelector`
- Phases 0–5 baseline; templates hub (`TemplatesPage`); digest; overdue roll; home widget; day-status FGS
- Local DB: **isar_community** 3.3.2 (`package:isar_community/isar.dart`)
- Calendar overlap UX; ~106 tests (`flutter test`)

### Your task (default)
Implement **Categories + Finance** per PRD **§7** (start with **P0 + P1**, then P2–P3 as scope allows):

**P0 — Schema & repos**
- Isar: `Category`, `CategoryLink` (many-to-many tags on task / calendarEvent / payment), `Payment`
- `CategoryTagService`, `CategoryRepository`, `PaymentRepository`
- `CurrencyPreferencesRepository` in `core/finance/` (SharedPreferences `app_default_currency_code`)
- Extend `SyncEntityType`; register schemas in `IsarDatabase`
- Unit tests for links and money aggregates

**P1 — Library hub**
- Rename UI hub **Templates → Library** (`LibraryPage`, keys `library_*`)
- Add 3rd tab **Categories** with CRUD (`CategoriesTab`, `CategoryFormSheet`)
- **Empty category list** on first launch (no seed)
- FAB creates category on categories tab (same pattern as template tabs)

**P2–P3 (if time)**
- `CategoryTagsField` on task/event forms
- `FinanceScreen` + dashboard AppBar entry
- `PaymentFormSheet` (currency from settings default, editable); list checkbox planned ↔ completed
- Settings → **Finance** section: default currency dropdown

### Product rules (fixed)
- **Multiple tags** per task/event/payment via `CategoryLink` (optional)
- Payment may link to **both** task and event
- **No recurring payments** in MVP
- **`amountMinor` int** — never store money as double
- Do **not** conflate `Task.calendarId` with user categories
- Reuse `FormSheetScaffold`, match existing code style

### Rules
- Minimize scope; match existing Clean Architecture
- Do **not** re-add automatic device calendar import
- Do **not** commit unless asked
- Run `flutter test` before finishing
- Docs in **English**; UI strings in en/ru/es JSON

## End of prompt
