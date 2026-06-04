# DayLinx — Refactoring & Development Roadmap

> **Purpose:** Handoff for a new agent session.  
> **Package root:** `smart_planner/`  
> **Docs:** `PROJECT_STRUCTURE.md`, `PRD_PRODUCT_SPEC.md`, `DEVICE_CALENDAR.md`  
> **Last updated:** 2026-06-04 (Sprint E + dashboard/calendar UX fixes)

---

## 1. Current state (what is done)

### Architecture & hygiene (Phases 0–3)
- Feature-driven layout under `smart_planner/lib/features/`
- `DashboardBloc` split: `DashboardDataLoader`, `DashboardTaskMutations`, `DashboardCalendarMutations` (+ coordinator in `dashboard_bloc.dart`)
- Shared UI: `FormSheetScaffold`, `TaskBadgesRow`, `AttachmentCoordinator`, `LinkedCalendarsField`, etc.
- Orchestration: `TaskEventLinkService`, `ReminderSyncService` (single `ItemReminderScheduler` via `AppInitializer`)

### Data & sync-ready schema (Phase 4)
- Isar: `SyncAccount`, `SyncRecord` (not used for import yet — future cloud sync)
- `EventSource` on `CalendarEvent`; `Task.googleTaskListId` / `googleTaskId` (future Tasks API)
- Interfaces: `TaskRepository`, `CalendarEventStore`

### Notifications & background (Phase 5)
- `ItemReminderScheduler` + `ReminderSyncService` (tasks + events, recurring via `RecurrenceEvaluator`)
- `TimezoneMonitor` → reschedule on TZ change
- Workmanager: `check_overdue_tasks` (digest notification), `refresh_day_status` (FGS + home widget payload)
- Day-status FGS: `DayStatusNotificationController`, settings toggle
- **Sprint B:** automatic midnight roll of overdue tasks (`OverdueMidnightRollService`, settings toggle)

### Calendar strategy (post–Phase 6 pivot)
- **Removed:** Google Calendar API / OAuth (`google_sign_in`, `googleapis`, `GOOGLE_OAUTH_SETUP.md`)
- **Single path:** `device_calendar` — read + **write-back** (Sprint A)
- `CalendarEventWriteService` — create/update/delete on device + Isar metadata
- `DeviceCalendarEventBridge` — maps domain → plugin `Event`
- Read-only calendars → Isar-only + snackbar `event_saved_read_only_calendar`
- Settings: calendar picker + **Open device calendar** (`CalendarSystemSettingsLauncher` + `MainActivity` MethodChannel)

### Tests
- ~63 unit/widget tests passing (`flutter test`)
- Gaps: no integration tests for `CalendarEventWriteService` / plugin (mock `DeviceCalendarPlugin` optional)

---

## 2. Known gaps & tech debt

| Area | Issue | Priority |
|------|--------|----------|
| **PRD** | Still mentions Google OAuth stub, “local events only” in places | High (docs) |
| **Dashboard UX** | — (Sprint E: single `calendarEvents` strip via merger) | — |
| **Write-back** | Moving event between calendars (change `calendarId` on edit) not tested; recurrence on device is basic mapping | Medium |
| **Overdue** | Midnight roll may be delayed by Android battery optimization | Low |
| **Widget** | `DayLinxWidgetProvider` + payload refresh exist; full UI per `ANDROID_HOME_WIDGET_SKETCH.md` not done | High (Sprint C) |
| **Templates** | `TemplatesPage`, FAB/deep-link apply, save from task detail | — (Sprint D done) |
| **Recurring tasks** | Not in `Task` schema | Low |
| **Sync** | `SyncAccount` / `SyncRecord` unused | Low (until cloud epic) |
| **Analyzer** | Many `prefer_initializing_formals`, `annotate_overrides` infos | Low |
| **iOS** | `ios_widget_bridge.dart` TODO; `calshow://` for calendar settings only | Low |

---

## 3. Recommended sprint order

```text
[A] Device write-back          ✅ DONE
[B] Background + overdue roll  ✅ DONE
[C] Home widget MVP            ✅ DONE
[D] Templates module           ✅ DONE
[E] Product polish & docs      ✅ DONE
[F] Cloud sync (optional epic)   ← NEXT (optional)
```

---

## 4. Sprint B — Background & overdue ✅

**Goal:** Close PRD § “automatic midnight roll” and align overdue background behavior.

### Tasks
1. **`OverdueMidnightRollWorker`** (or extend `OverdueBackgroundWorker`)
   - Workmanager: daily task ~00:05 local (or on `refresh_day_status` when date changes)
   - For each overdue uncompleted task: apply `TaskOverdueRules.recordPostpone` / `postponeToNextDay` per product rule (confirm PRD: roll to today vs tomorrow)
   - Respect user setting toggle in `NotificationPreferencesRepository` (new key `autoRollOverdueAtMidnight`)
2. **Settings UI** — subsection under Reminders or Notifications
3. **Cancel/update** overdue digest when roll runs or no overdue left
4. **Tests** — `TaskOverdueRules` + roll logic with fixed `referenceDay`
5. **Docs** — update `PRD_PRODUCT_SPEC.md` (overdue = Implemented/Partial → Implemented), remove OAuth rows

### Key files
- `lib/features/notifications/background_service.dart`
- `lib/features/notifications/data/overdue_background_worker.dart`
- `lib/features/todo_list/domain/task_overdue_rules.dart`
- `lib/features/notifications/data/notification_preferences_repository.dart`

### Acceptance
- At day boundary, overdue tasks appear on “today” without manual postpone (when setting on)
- Existing overdue panel + `dynamicOverdueDays` unchanged
- `flutter test` green

---

## 5. Sprint C — Home widget MVP ✅

**Goal:** Match `ANDROID_HOME_WIDGET_SKETCH.md` medium 4×2 layout.

### Tasks
1. **Payload** — extend `DayStatusWidgetPayloadBuilder` / `DayStatusTodayLoader` slices (top N events, top M tasks, overdue chip)
2. **Android** — `DayLinxWidgetProvider.kt` + `res/layout/widget_day_medium.xml` (already started in repo — verify and complete)
3. **Tap actions** — `HomeWidgetLaunchIntent` with extras: open app, open task, toggle complete (optional phase C2)
4. **Reuse** — same data as day-status notification; no duplicate business rules
5. **Settings** — note in day-status section: widget updates with background refresh

### Key files
- `ANDROID_HOME_WIDGET_SKETCH.md`
- `lib/features/notifications/data/day_status_home_widget_service.dart`
- `lib/features/notifications/domain/day_status_widget_payload_builder.dart`
- `android/.../DayLinxWidgetProvider.kt`

### Acceptance
- Widget shows today progress + next event + task count on device
- Pull-to-refresh / 15 min WM updates widget
- No regression on FGS notification

---

## 6. Sprint D — Templates module ✅

**Goal:** Replace AppBar snackbar stub with real template CRUD + apply.

### Done
1. **`TemplatesPage`** — list, create/edit (`TemplateFormSheet`), delete, apply → `TaskFormSheet`
2. **Save from task** — task detail menu → `UiTemplateFactory.fromTask`
3. **Apply** — `UiTemplateApplicator` in `TaskFormSheet`; relation sheet; FAB «from template» (`TemplatePickerSheet`); deep link `daylinx://create?type=template&templateId=N`
4. **AppBar** — `Icons.layers_outlined` → `TemplatesPage`
5. **i18n** — `templates_*`, `dashboard_create_from_template`, `task_save_as_template`

### Key files
- `lib/features/templates/`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/deep_links/domain/deep_link_parser.dart` (`type=template`)

---

## 7. Sprint E — Product polish ✅

| Item | Done |
|------|------|
| **Dashboard events merge** | Removed duplicate `DashboardLoaded.events`; strip uses `calendarEvents` only (`VisibleCalendarEventsMerger`) |
| **Calendar write-back QA** | Move event to another writable calendar (delete old device row + create); recurring delete dialog → `deleteEventInstance` |
| **Read-only UX** | Badge + disabled chips / picker for read-only calendars when creating |
| **Onboarding** | Snackbar after calendar permission grant; saving **Settings** reloads dashboard (no “calendars updated” snackbar on full settings page) |
| **Calendar selection** | Only checked calendars are queried; disabled calendars hidden on dashboard and markers |
| **Recurring display** | Android Instances per occurrence; merger expands `recurrenceRuleJson` when a day has no device instance |
| **Event strip “now”** | Timeline hidden before the first event starts (avoids overlay on first card) |
| **Week strip badges** | Task count uses `TaskDateVisibility` (not reminder-only without due on that day) |
| **Recurring tasks** | `Task.recurrenceRuleJson`, form dropdown (none/daily/weekly), `TaskDateVisibility` + markers |
| **Morning/evening digest** | WM one-off 08:00 / 19:00, `TaskDailyDigestWorker`, settings toggles |
| **PRD + README** | Updated product status rows |

---

## 8. Sprint F — Cloud sync (defer)

Only if product requires multi-device or Google Tasks:

- Wire `SyncRecordRepository` to device/cloud IDs
- Google Tasks API or restore OAuth (separate from device calendar)
- Conflict resolution using `CalendarEvent.updatedAt`

**Do not start** until B–D are stable.

---

## 9. Agent startup checklist (new window)

```bash
cd smart_planner
flutter pub get
flutter test
flutter analyze lib
```

1. Read this file + `PROJECT_STRUCTURE.md` revision table (last rows).
2. Read `PRD_PRODUCT_SPEC.md` §2–3 for status columns (update as you go).
3. Confirm branch / uncommitted work: write-back, calendar settings launcher, removed Google API.
4. Ask user: **B** (overdue roll) vs **C** (widget) if priority unclear.
5. **Do not** re-add `google_sign_in` / Calendar API without explicit request.

---

## 10. Suggested commit slices (when user asks to commit)

1. `feat(calendar): device write-back via CalendarEventWriteService`
2. `feat(settings): open system calendar from app settings`
3. `chore: remove Google Calendar API and OAuth deps`
4. `docs: PRD and roadmap for device-calendar-only strategy`

---

## 11. Risk notes

- **`device_calendar` write** on OEM skins (Samsung, Xiaomi) — test on real device; read-only shared calendars common.
- **Workmanager** on Android 12+ — battery optimization may delay midnight roll; document in settings.
- **Isar** — `EventSource.googleApi` legacy enum value kept for old rows; do not remove without migration.
- **FGS + WM** — two background paths; keep `DayStatusBackgroundSync` idempotent.

---

## 12. Quick reference — important paths

| Concern | Path |
|---------|------|
| App DI | `lib/app.dart` |
| Dashboard load | `lib/features/dashboard/data/dashboard_data_loader.dart` |
| Dashboard BLoC | `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart` |
| Calendar write | `lib/features/calendar_integration/data/calendar_event_write_service.dart` |
| Device calendar | `lib/features/calendar_integration/data/services/device_calendar_service.dart` |
| Event form | `lib/features/calendar_integration/presentation/widgets/event_form_sheet.dart` |
| Background | `lib/features/notifications/background_service.dart` |
| Widget sketch | `ANDROID_HOME_WIDGET_SKETCH.md` |
| Device calendar doc | `smart_planner/DEVICE_CALENDAR.md` |
