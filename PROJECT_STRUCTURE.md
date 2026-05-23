# Project Structure & Architecture Blueprint (Flutter/Dart)

> **Documentation language:** All project documentation (this file, PRD, README, commit messages for docs, and Cursor/AI rules) must be written and maintained in **English**. Application UI copy may use other locales (currently Russian strings in widgets).

---

## Overview

The app uses a **feature-driven** layout. Each feature owns its logic, UI, and data contracts to keep scaling and testing manageable.

**Package root:** `smart_planner/`  
**Entry point:** `lib/main.dart` → `AppInitializer` → `SmartPlannerApp`

---

## Directory tree (as implemented)

```text
smart_planner/lib/
│
├── main.dart                          # App bootstrap
├── app.dart                           # MaterialApp, theme, BlocProvider, repositories
│
├── core/                              # Shared infrastructure
│   ├── app_initializer.dart           # Isar, notifications, workmanager, task seed
│   ├── theme/app_theme.dart           # Light + dark Material 3 themes
│   ├── database/isar_database.dart    # Isar singleton (Task, TaskCategory)
│   ├── network/google_calendar_api_client.dart  # OAuth stub (future)
│   └── utils/app_date_utils.dart      # startOfDay, calendar day helpers
│
├── features/
│   │
│   ├── calendar_integration/
│   │   ├── data/
│   │   │   ├── services/
│   │   │   │   ├── device_calendar_service.dart   # Permissions, calendars, events by day
│   │   │   │   └── calendar_service.dart          # typedef export
│   │   │   ├── repositories/device_calendar_repository.dart
│   │   │   └── calendar_preferences_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/          # CalendarEvent, DeviceCalendarInfo
│   │   │   ├── exceptions/
│   │   │   ├── repositories/calendar_repository.dart
│   │   │   └── calendar_integration_domain.dart
│   │   └── presentation/pages/calendar_settings_page.dart
│   │
│   ├── todo_list/
│   │   ├── data/
│   │   │   ├── repositories/todo_repository.dart
│   │   │   ├── repositories/task_attachment_repository.dart
│   │   │   ├── attachment_file_store.dart
│   │   │   ├── services/
│   │   │   │   ├── attachment_launcher_service.dart   # tel, sms, mailto, URL, geo fallback
│   │   │   │   ├── device_contact_picker.dart         # System contact pick + full reload
│   │   │   │   ├── map_app_launcher_service.dart      # Installed map apps (coords only)
│   │   │   │   └── osm_place_search_service.dart      # Nominatim forward geocoding
│   │   │   └── task_bootstrap.dart
│   │   ├── domain/
│   │   │   ├── entities/          # Task, TaskAttachment, payloads (+ .g.dart)
│   │   │   ├── task_overdue_rules.dart
│   │   │   ├── task_hierarchy.dart
│   │   │   ├── task_attachment_checklist.dart
│   │   │   ├── task_attachment_codec.dart
│   │   │   ├── task_date_visibility.dart
│   │   │   ├── task_overdue_selection.dart
│   │   │   ├── task_reopen.dart
│   │   │   └── todo_list_domain.dart
│   │   └── presentation/
│   │       ├── bloc/              # CompletedTasksBloc
│   │       ├── pages/
│   │       │   ├── completed_tasks_page.dart
│   │       │   └── todo_list_page.dart       # Legacy placeholder (unused in nav)
│   │       └── widgets/
│   │           ├── create_task_sheet.dart
│   │           ├── postpone_task_sheet.dart
│   │           ├── reopen_task_sheet.dart
│   │           ├── task_expandable_tile.dart
│   │           ├── task_child_tasks_section.dart
│   │           ├── location_map_picker_sheet.dart
│   │           ├── link_task_sheet.dart
│   │           ├── add_attachment_sheet.dart
│   │           ├── task_attachments_section.dart
│   │           ├── task_badge.dart
│   │           └── task_priority_ui.dart
│   │
│   ├── notifications/
│   │   ├── notification_helper.dart
│   │   ├── notification_channels.dart
│   │   └── background_service.dart            # workmanager; auto-postpone TODO
│   │
│   └── dashboard/
│       ├── data/
│       │   └── dashboard_day_markers_repository.dart  # Week strip dots cache
│       ├── domain/
│       │   ├── day_activity_marker.dart
│       │   └── dashboard_day_markers_builder.dart
│       └── presentation/
│           ├── bloc/              # DashboardBloc, events, states
│           ├── widgets/dashboard_week_date_strip.dart
│           └── dashboard_screen.dart
│
└── widgets/                         # Home-screen widget bridges (stubs)
    ├── android_widget_provider.dart
    └── ios_widget_bridge.dart

smart_planner/test/
├── task_date_visibility_test.dart
├── task_reopen_test.dart
└── widget_test.dart
```

---

## Layer rules

| Layer | Responsibility |
|-------|----------------|
| **domain** | Entities, business rules, repository interfaces; Isar `@collection` models live here for tasks (project convention). |
| **data** | Repositories, device/API services, DTO mapping, `SharedPreferences`. |
| **presentation** | Widgets, BLoC, navigation. |

**Dependency direction:** `presentation` → `domain` ← `data`. `core` is shared by all features.

---

## Key types & services

| Component | Role |
|-----------|------|
| `DashboardBloc` | Tasks/events for `selectedDate`; `dayMarkers` for date strip; complete, postpone |
| `DashboardDayMarkersRepository` | One Isar + one calendar fetch per week range (cached) |
| `CompletedTasksBloc` | Completed task list; reopen flow |
| `TodoRepository` | Isar CRUD; `getUncompletedTasksForDate`, `getOverdueUncompletedTasks`, `getCompletedTasks`, `reopenFromCompleted` |
| `DeviceCalendarService` | Permissions, calendars, `getEventsForDay` / `getEventsForToday` |
| `CalendarPreferencesRepository` | Persist selected calendar IDs |
| `TaskOverdueRules` | `recordPostpone`, `postponeToNextDay`; updates `overdueCount` |
| `TaskDateVisibility` | Filter uncompleted tasks for a calendar day |
| `TaskOverdueSelection` | Overdue due-date rules; dashboard overdue list only on “today” |
| `TaskReopen` | Build new `Task` from a completed one |
| `TaskExpandableTile` | Dashboard task UI (tiles, badges, expand, postpone actions) |
| `PostponeTaskSheet` | Bottom sheet to postpone to tomorrow or a chosen date |
| `AddAttachmentSheet` | Pick attachment type; forms per type (contact auto-opens picker) |
| `TaskAttachmentsSection` | Renders attachments in expanded tile |
| `LocationMapPickerSheet` | OSM map tap-to-select + Nominatim search |
| `TaskAttachmentRepository` | Isar CRUD for attachments; `nextSortOrder` |
| `TaskAttachmentCodec` | JSON payload encode/decode; `summaryLabel` for tiles |
| `AppTheme` | `light` / `dark`; app uses `ThemeMode.system` |

### Dashboard events (BLoC)

| Event | Effect |
|-------|--------|
| `LoadDashboardData` | Load tasks + events; optional `selectedDate`, `selectedCalendarIds` |
| `SelectDashboardDate` | Change day and reload |
| `ToggleTaskCompletion` | Mark task completed; refresh list for current day |
| `PostponeTaskToNextDay` | `Task.postponeToNextDay(referenceDate: selectedDate)` + save |
| `PostponeTask` | `Task.postponeDueDate(newDueDate)` + save |
| `LinkTaskAsChild` / `DetachTaskFromParent` | Set/clear `Task.parentTaskId` |
| `DeleteTaskAttachment` / `ToggleAttachmentChecklistItem` | Attachment CRUD / checklist toggle |

### Task postpone flow

1. User expands `TaskExpandableTile` on the dashboard.
2. **Tomorrow** → `DashboardScreen.postponeTaskToTomorrow` → `PostponeTaskToNextDay`.
3. **Postpone** → `PostponeTaskSheet` → `PostponeTask` with picked date.
4. `TaskOverdueRules.recordPostpone` updates `dueDate` and may increase `overdueCount`.
5. List reloads for the current `selectedDate` (task may disappear if moved off that day).

---

## Theming

Configured in `lib/app.dart`:

- `theme: AppTheme.light`
- `darkTheme: AppTheme.dark`
- `themeMode: ThemeMode.system`

Widgets should use `Theme.of(context).colorScheme` (not hardcoded colors) so light/dark stay consistent.

---

## Tech stack (`pubspec.yaml`)

- **Flutter** SDK ^3.12
- **flutter_bloc** — state
- **isar** + **isar_generator** — local DB
- **device_calendar** — Android/iOS calendar read
- **flutter_local_notifications**, **timezone**, **workmanager**
- **shared_preferences**, **path_provider**, **intl**
- **image_picker**, **url_launcher**, **geolocator**, **flutter_map**, **latlong2** — attachments (map pick)
- **flutter_contacts** — device contact picker
- **map_launcher** — open coordinates in user’s map app (chooser UI)
- **http** — Nominatim (OpenStreetMap) place search

---

## Android build notes

Permissions and queries in `android/app/src/main/AndroidManifest.xml`:

- Calendar read/write, notifications, exact alarms, boot receiver
- `READ_MEDIA_IMAGES` / legacy storage (image attachments)
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (map picker, current location)
- `READ_CONTACTS` (contact attachments)
- Package visibility `<queries>` for `https`, `http`, `geo`, `tel`, `mailto`, contact `PICK`

Build configuration:

- `android/app/build.gradle.kts` — `compileSdk = 36`
- `android/namespace_fix.gradle` — AGP 8+ namespace for library plugins; **compileSdk 36** for all Android library subprojects (e.g. `map_launcher`, `isar_flutter_libs`)
- Core library desugaring enabled for notifications
- **Warning at build time:** some plugins still apply Kotlin Gradle Plugin (KGP) separately; safe to ignore until plugin updates

**Do not use Web target** for this project (Isar limitation).

---

## Code generation

From `smart_planner/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## Tests

From `smart_planner/`:

```bash
flutter test
```

Domain unit tests: `task_date_visibility_test.dart`, `task_overdue_selection_test.dart`, `task_reopen_test.dart`, `task_hierarchy_test.dart`, `task_attachment_codec_test.dart`, `task_attachment_checklist_test.dart`.

---

## AI assistant onboarding

When starting code generation in Cursor/Claude:

1. Read `PRD_PRODUCT_SPEC.md` and this file (**English only** for docs).
2. Respect feature folders; do not put UI in `data/`.
3. Prefer extending existing services (`DeviceCalendarService`, `TodoRepository`) over duplicate logic.
4. Reuse `TaskExpandableTile`, `TaskBadge`, `TaskOverdueRules`, `AppDateUtils` where applicable.

Example prompt:

> Create X according to `PROJECT_STRUCTURE.md` and `PRD_PRODUCT_SPEC.md`. Follow feature-driven Clean Architecture. Document new APIs in English.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-05 | Initial blueprint (Russian) |
| 2026-05 | English translation; reflects implemented `smart_planner/lib` tree |
| 2026-05 | Date-filtered dashboard, completed/reopen, task tiles, system theme, tests |
| 2026-05 | Postpone UI, BLoC events, overdue badge documentation |
| 2026-05 | Linked child tasks (`parentTaskId`, `LinkTaskSheet`, root-only dashboard list) |
| 2026-05 | `TaskAttachment` feature: repositories, widgets, codec, file store, launcher services |
| 2026-05 | OSM search, `map_launcher`, `flutter_contacts`; Android compileSdk 36 |
