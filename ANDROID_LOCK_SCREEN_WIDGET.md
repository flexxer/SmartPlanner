# Android lock screen widget — «Pulse» (variant 1)

> **Status:** **Planned** — spec for next agent.  
> **Goal:** Minimal, read-only glance at today: one event line + task progress. No lists, no checkboxes.  
> **Platform:** Android 14+ (API 34) lock screen widgets via Jetpack Glance (`widgetCategory=keyguard`).  
> **Fallback:** Android &lt;14 — point users to existing **day-status notification** (same data, lock-screen visible when enabled).

---

## 1. Product choice

We chose **variant 1 «Pulse»** over richer layouts (dual-line events, progress bar, task lists) to avoid lock-screen clutter.

```text
● 11:00–19:00  Репетиция
✓ 2/5  ·  просрочено 1
```

| Line | Content | Hide when |
|------|---------|-----------|
| **1** | Current event (`now`) or next upcoming event today | No events today → show localized “no events” (reuse `day_status_notification_no_events`) |
| **2** | `✓ {done}/{total}` when `total > 0`; append `· просрочено N` when `overdueCount > 0` | When `total == 0` and `overdueCount == 0` → hide line 2 or show plain “Today's plan” |

**Rules:**

- Read-only — tap anywhere opens app → dashboard **today** (`MainActivity`, same as home widget).
- No refresh / add-task buttons on lock screen (security + space).
- Reuse business rules from `DayStatusNotificationBuilder` / `DayStatusLocaleCopy` — **no duplicate event slicing**.
- Locale: `BackgroundLanguageResolver` + existing `day_status_*` / `overdue_*` keys where possible.

---

## 2. Relationship to existing surfaces

| Surface | Role vs lock screen |
|---------|---------------------|
| **Day-status notification** | Same snapshot; Android &lt;14 substitute |
| **Home widget** (`DayLinxWidgetProvider`) | Richer 4×2 layout; shares `DayStatusTodayLoader` |
| **Dashboard** | Source of truth after tap |

**Data flow (target):**

```text
DayStatusTodayLoader.load()
  → DayStatusLockScreenPayloadBuilder.build()   # new, thin
  → DayStatusLockScreenWidgetService.syncToday() # new
  → Glance / SharedPreferences → LockScreenWidgetProvider
```

Wire sync from the same places as home widget:

- `DashboardBloc` after load / task toggle
- `DayStatusBackgroundSync` (15 min Workmanager)
- `DayStatusNotificationController.syncTodayStatus()` (optional: call lock-screen sync in same method)

---

## 3. Payload

### Dart model

Add `lib/features/notifications/domain/day_status_lock_screen_payload.dart`:

```dart
class DayStatusLockScreenPayload {
  const DayStatusLockScreenPayload({
    required this.primaryLine,   // event line (with ● prefix applied in native or Dart)
    required this.secondaryLine, // progress + overdue; empty to hide
    required this.tapDateLabel,  // optional: "Today" for accessibility
  });

  final String primaryLine;
  final String secondaryLine;
  final String tapDateLabel;

  Map<String, String> toWidgetData() => {
    'ls_primary': primaryLine,
    'ls_secondary': secondaryLine,
    'ls_date': tapDateLabel,
  };
}
```

### Builder logic

Add `DayStatusLockScreenPayloadBuilder` (or method on `DayStatusLocaleCopy`):

1. Load `DayStatusTodaySnapshot` (already exists).
2. **Primary line** — mirror `_sliceEvents` from `day_status_locale_copy.dart`:
   - If current event: `{nowLabel} {timeRange} {title}` or compact `● {timeRange}  {title}`
   - Else first `next` event: `{time}  {title}`
   - Else `s.noEvents`
3. **Secondary line**:
   - `done/total` via `s.titleProgress` pattern without “tasks” word if too long — prefer `✓ 2/5`
   - Append ` · {overdue}` when `snapshot.overdueTasks.isNotEmpty` (reuse footer overdue copy)
4. **Tests** — `test/day_status_lock_screen_payload_builder_test.dart` mirroring `day_status_widget_payload_builder_test.dart`.

---

## 4. Android implementation

### Why not `home_widget` only?

`home_widget` drives `AppWidgetProvider` (home screen). Lock screen widgets on Android 14+ need **Glance** with `android:widgetCategory` including `keyguard`. Plan a **separate native provider**; Dart still pushes SharedPreferences keys (same pattern as `DayStatusHomeWidgetService`).

### Files to add / touch

| File | Action |
|------|--------|
| `android/.../DayLinxLockScreenWidget.kt` | Glance `GlanceAppWidget` + receiver |
| `android/.../res/xml/daylinx_lock_screen_widget_info.xml` | `minSdkVersion` 34, `widgetCategory=keyguard` |
| `android/.../res/layout` or Glance composables | 2 `Text` lines, theme-aware colors |
| `AndroidManifest.xml` | Register receiver |
| `lib/features/notifications/data/day_status_lock_screen_widget_service.dart` | Push `ls_*` keys + `updateWidget` |
| `lib/app.dart` / `DayStatusBackgroundSync` | Call lock-screen sync alongside home widget |

### Layout sketch

```text
┌─────────────────────────────────────┐
│ ● 11:00–19:00  Репетиция            │  ← primary, max 1 line ellipsize end
│ ✓ 2/5  ·  просрочено 1              │  ← secondary, smaller style; GONE if empty
└─────────────────────────────────────┘
```

- `targetCellWidth` / `targetCellHeight`: smallest lock-screen slot (check Glance lock-screen size docs; typically 2×1 cells).
- `android:widgetFeatures="reconfigurable"` — optional later; not required for v1.
- **Sensitive content:** use `android:widgetLayout` with public visibility; no task titles on line 2 (only counts) — already satisfied.

### Tap

`actionStartActivity` → `MainActivity` with `FLAG_ACTIVITY_NEW_TASK` (same as `DayLinxWidgetProvider.openAppPendingIntent`).

---

## 5. Settings & discovery

- **No new toggle for v1** — widget appears when user adds it from lock-screen customization (Android 14+).
- Add one line under **Calendars** day-status section: “Lock screen widget (Android 14+)” with short hint linking to system picker (optional `lock_screen_widget_hint` i18n key).
- Document in PRD §3.3 when implemented.

---

## 6. iOS (defer)

iOS lock screen uses WidgetKit (inline / rectangular). Same payload builder can feed an extension later via `ios_widget_bridge.dart`. **Out of scope for first implementation** unless user asks.

---

## 7. Acceptance criteria

- [ ] Lock screen widget shows 1–2 lines for today on Android 14+ device/emulator.
- [ ] Event line matches notification “now/next” logic for the same snapshot.
- [ ] Progress line hidden when no tasks; overdue suffix only when count &gt; 0.
- [ ] Tap opens app to dashboard today.
- [ ] Updates when dashboard reloads and on 15 min background sync (same as home widget).
- [ ] `flutter test` green; new payload builder tests added.
- [ ] PRD + `PROJECT_STRUCTURE.md` status updated to **Implemented**.

---

## 8. Agent startup

```bash
cd smart_planner
flutter pub get
flutter test
flutter analyze lib
```

Read: `PROJECT_STRUCTURE.md`, `PRD_PRODUCT_SPEC.md` §3.3, `DayStatusLocaleCopy`, `DayStatusHomeWidgetService`, `DayLinxWidgetProvider.kt`.

**Do not** re-add Google Calendar API. **Do not** add checkboxes or task lists to lock screen. Minimize scope to variant 1 only.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-06 | Initial spec — variant 1 «Pulse»; reuse day-status snapshot |
