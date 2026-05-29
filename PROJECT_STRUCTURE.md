# Project Structure & Architecture Blueprint (Flutter/Dart)

> **Documentation language:** All project documentation (this file, PRD, README, commit messages for docs, and Cursor/AI rules) must be written and maintained in **English**. Application UI copy is localized via **easy_localization** (see [Localization](#localization)).

---

## Overview

The app uses a **feature-driven** layout. Each feature owns its logic, UI, and data contracts to keep scaling and testing manageable.

**Package root:** `smart_planner/`  
**Entry point:** `lib/main.dart` → `AppInitializer` + `EasyLocalization` → `DayLinxApp`  
**Git:** [github.com/flexxer/SmartPlanner](https://github.com/flexxer/SmartPlanner)

---

## Directory tree (as implemented)

```text
smart_planner/lib/
│
├── main.dart                          # App bootstrap + EasyLocalization wrapper
├── app.dart                           # MaterialApp, locale delegates, repositories
│
├── core/                              # Shared infrastructure
│   ├── app_initializer.dart           # Isar, notifications, workmanager, task seed
│   ├── localization/                  # easy_localization helpers + language picker
│   │   ├── app_locales.dart           # supported locales (en, ru, es)
│   │   ├── locale_preferences_repository.dart  # manual language override (SharedPreferences)
│   │   ├── l10n.dart                  # L10n.tr, overdueDays, priorityLabel, dateFormat
│   │   └── language_picker_section.dart  # dropdown on CalendarSettingsPage
│   ├── theme/app_theme.dart           # Light + dark Material 3 themes
│   ├── database/isar_database.dart    # Isar singleton (Task, TaskAttachment, CalendarEvent)
│   ├── network/google_calendar_api_client.dart  # OAuth stub (future)
│   └── utils/app_date_utils.dart      # startOfDay, startOfWeek, dayKeyMs, strip ranges
│
├── features/
│   │
│   ├── calendar_integration/
│   │   ├── data/
│   │   │   ├── services/
│   │   │   │   ├── device_calendar_service.dart   # Permissions, calendars, events by day
│   │   │   │   └── calendar_service.dart          # typedef export
│   │   │   ├── repositories/device_calendar_repository.dart
│   │   │   ├── repositories/local_calendar_event_repository.dart
│   │   │   ├── calendar_preferences_repository.dart
│   │   │   └── linked_calendars_loader.dart
│   │   ├── domain/
│   │   │   ├── entities/          # CalendarEvent, DeviceCalendarInfo
│   │   │   ├── calendar_context_colors.dart
│   │   │   ├── exceptions/
│   │   │   ├── repositories/calendar_repository.dart
│   │   │   └── calendar_integration_domain.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── calendar_settings_page.dart    # Calendar picker + language dropdown
│   │       │   ├── calendar_grid_screen.dart      # Week/month time grid
│   │       │   └── event_detail_screen.dart       # Full-screen event + linked tasks
│   │       └── widgets/
│   │           ├── event_form_sheet.dart          # Create + edit local events
│   │           ├── device_calendar_picker_field.dart
│   │           ├── calendar_grid_week_view.dart
│   │           └── calendar_grid_month_view.dart
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
│   │   │   │   └── osm_place_search_service.dart      # Nominatim search + reverse geocode
│   │   │   └── task_bootstrap.dart
│   │   ├── domain/
│   │   │   ├── entities/          # Task, TaskAttachment, payloads (+ .g.dart)
│   │   │   ├── task_overdue_rules.dart
│   │   │   ├── task_hierarchy.dart
│   │   │   ├── task_attachment_checklist.dart
│   │   │   ├── task_attachment_codec.dart
│   │   │   ├── task_date_visibility.dart
│   │   │   ├── task_overdue_selection.dart
│   │   │   ├── task_attachment_snapshot.dart    # Clone for attachment delete Undo
│   │   │   ├── task_reopen.dart
│   │   │   └── todo_list_domain.dart
│   │   └── presentation/
│   │       ├── bloc/              # CompletedTasksBloc (@deprecated)
│   │       ├── pages/
│   │       │   ├── task_detail_screen.dart    # Full-screen task details
│   │       │   ├── completed_tasks_page.dart  # @deprecated; not in nav
│   │       │   └── todo_list_page.dart       # Legacy placeholder (unused in nav)
│   │       └── widgets/
│   │           ├── task_form_sheet.dart           # Create + edit tasks
│   │           ├── task_linked_calendars_field.dart
│   │           ├── postpone_task_sheet.dart
│   │           ├── reopen_task_sheet.dart
│   │           ├── task_expandable_tile.dart      # Compact dashboard row (navigates to detail)
│   │           ├── task_detail_child_tasks_section.dart  # Reorderable subtasks on detail
│   │           ├── task_child_tasks_section.dart  # Legacy list (detail uses reorderable variant)
│   │           ├── task_linked_event_section.dart   # Legacy
│   │           ├── location_map_picker_sheet.dart
│   │           ├── link_task_sheet.dart
│   │           ├── add_attachment_sheet.dart      # Create + edit attachments
│   │           ├── attachment_action_sheet.dart   # Open / edit / delete menu
│   │           ├── attachment_default_action.dart # Open/view handlers per type
│   │           ├── task_attachments_section.dart
│   │           ├── task_badge.dart
│   │           ├── task_section_header.dart
│   │           └── task_priority_ui.dart
│   │
│   ├── templates/
│   │   ├── data/repositories/ui_template_repository.dart
│   │   ├── domain/                            # UiTemplate, factory, applicator
│   │   └── presentation/
│   │       ├── pages/templates_page.dart
│   │       └── widgets/template_form_sheet.dart
│   │
│   ├── deep_links/
│   │   ├── data/deep_link_service.dart          # app_links: initial + stream
│   │   ├── domain/
│   │   │   ├── deep_link_create_action.dart
│   │   │   └── deep_link_parser.dart            # daylinx://create?...
│   │   └── presentation/deep_link_dispatcher.dart  # opens Task/EventFormSheet
│   │
│   ├── notifications/
│   │   ├── notification_helper.dart           # Plugin init, channels, scheduled pushes
│   │   ├── notification_channels.dart
│   │   ├── background_service.dart            # workmanager; auto-postpone TODO
│   │   ├── data/
│   │   │   ├── notification_preferences_repository.dart  # day-status bar on/off
│   │   │   └── day_status_notification_controller.dart   # Android FGS start/stop/sync
│   │   ├── domain/
│   │   │   ├── day_status_notification_content.dart
│   │   │   └── day_status_notification_builder.dart      # title/body for today
│   │   └── presentation/widgets/
│   │       ├── day_status_bar_settings_section.dart      # Switch on CalendarSettingsPage
│   │       └── day_status_service_host.dart            # restore FGS after app start
│   │
│   └── dashboard/
│       ├── data/
│       │   └── dashboard_day_markers_repository.dart  # Week strip dots cache
│       ├── domain/
│       │   ├── day_activity_marker.dart
│       │   ├── dashboard_day_markers_builder.dart
│       │   ├── compressed_events_strip_layout.dart
│       │   └── event_time_status.dart
│       └── presentation/
│           ├── bloc/              # DashboardBloc, events, states
│           ├── widgets/
│           │   ├── dashboard_week_date_strip.dart
│           │   ├── dashboard_local_events_section.dart
│           │   ├── dashboard_local_events_strip.dart
│           │   ├── event_linked_tasks_sheet.dart
│           │   └── link_calendar_event_sheet.dart
│           └── dashboard_screen.dart            # DeepLinkDispatcher → DayStatusServiceHost
│
└── widgets/                         # Home-screen widget bridges (stubs)
    ├── android_widget_provider.dart
    └── ios_widget_bridge.dart

smart_planner/assets/translations/     # en.json, ru.json, es.json (easy_localization)
smart_planner/test/
├── dashboard_day_markers_builder_test.dart
├── task_attachment_checklist_test.dart
├── task_attachment_codec_test.dart
├── task_date_visibility_test.dart
├── task_hierarchy_test.dart
├── task_overdue_rules_test.dart
├── task_overdue_selection_test.dart
├── task_reopen_test.dart
├── compressed_events_strip_layout_test.dart
├── recurrence_evaluator_test.dart
├── recurrence_rule_test.dart
├── day_status_notification_builder_test.dart
├── deep_link_parser_test.dart
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
| `DashboardBloc` | `tasks`, `undatedTasks`, `completedTasks`, `overdueTasks` (today), `calendarEvents`, `linkedCalendarsById`, `dayMarkers`; optional `DayStatusNotificationController` sync after successful load/reload |
| `DashboardLoaded` | Active/completed/undated/overdue task lists; `linkedCalendarsById` for context calendar badges |
| `DashboardDayMarkersRepository` | One Isar + one calendar fetch per week range (cached) |
| `DashboardWeekDateStrip` | Horizontal ~21-day strip; activity dots per day |
| `DashboardLocalEventsStrip` | Compressed horizontal event cards; live now line (today) |
| `CompressedEventsStripLayout` | Card/gap segment positions; focus scroll anchor |
| `EventTimeStatus` / resolver | past / current / future styling on strip cards |
| `LocalCalendarEventRepository` | Isar calendar events; device upsert; `linkTask` / `unlinkTask` |
| `DayActivityMarker` | `hasCalendarEvents`, `hasLocalTasks`, optional calendar color |
| `CompletedTasksBloc` | @deprecated — not in AppBar nav |
| `DashboardScreen` AppBar | Templates stub; calendars; refresh |
| `TodoRepository` | Task CRUD; `getUncompletedTasksForDate`, `getUndatedTasks`, `getCompletedTasksForDate`, `getOverdueUncompletedTasks`, `deleteTask`, `reopenFromCompleted`, `reorderChildTasks`, `compareChildTasks` (`Task.sortOrder`) |
| `TaskDateVisibility` | Dated tasks per day; undated tasks in dashboard backlog section only |
| `LinkedCalendarsLoader` | Device calendars enabled in app settings (for forms + markers) |
| `TaskLinkedCalendarsField` | Horizontal chips to pick `Task.calendarId` |
| `DeviceCalendarService` | Permissions, calendars, `getEventsForDay` / `getEventsForToday` |
| `CalendarPreferencesRepository` | Persist selected calendar IDs |
| `TaskOverdueRules` | `dynamicOverdueDays`, `recordPostpone`, `postponeToNextDay` |
| `TaskDateVisibility` | Filter uncompleted tasks for a calendar day |
| `TaskOverdueSelection` | Overdue due-date rules; dashboard overdue list only on “today” |
| `TaskReopen` | Build new `Task` from a completed one |
| `TaskExpandableTile` | Compact dashboard row: checkbox + tap body → `TaskDetailScreen`; badges only (no in-place expand) |
| `TaskDetailScreen` | Full task UI: description, badges, reorderable subtasks, attachments, postpone, AppBar → `TaskFormSheet` |
| `EventDetailScreen` | Full event UI: time, calendar, linked tasks, add task, AppBar → `EventFormSheet` |
| `TaskBadge` | Optional `onTap` — linked event, subtasks, link-to-event |
| `TaskDetailChildTasksSection` | `ReorderableListView` for active children; `ReorderChildTasks` |
| `TaskTileSectionHeader` | Section titles (child tasks / attachments) |
| `EventLinkedTasksSheet` | Legacy bottom sheet; superseded by `EventDetailScreen` for strip tap |
| `TaskFormSheet` / `EventFormSheet` | Unified create/edit sheets; delete icon + confirm dialog in edit mode |
| `AttachmentActionSheet` | Bottom sheet: open, edit (`AddAttachmentSheet`), delete (Undo snackbar) |
| `AttachmentDefaultAction` | Per-type open/view (URL, maps, contact, image, note dialog) |
| `OsmPlaceSearchService` | Nominatim `search` + `reverseGeocode` → `display_name` |
| `LocationAttachmentPayload` | `placeName` (OSM), optional user `label` override |
| `PostponeTaskSheet` | Bottom sheet to postpone to tomorrow or a chosen date |
| `AddAttachmentSheet` | Create attachment; `attachmentToEdit` + `UpdateTaskAttachment` for edit |
| `TaskAttachmentsSection` | Attachment cards on `TaskDetailScreen`; tap → action sheet |
| `LocationMapPickerSheet` | OSM map tap-to-select + Nominatim search |
| `TaskAttachmentRepository` | Isar CRUD for attachments; `nextSortOrder` |
| `TaskAttachmentCodec` | JSON payload encode/decode; `summaryLabel` for tiles |
| `AppTheme` | `light` / `dark`; app uses `ThemeMode.system` |
| `LocalePreferencesRepository` | Persists manual language (`en` / `ru` / `es`); empty = follow device locale |
| `LanguagePickerSection` | Dropdown on `CalendarSettingsPage`; calls `context.setLocale` / `resetLocale` |
| `L10n` | `tr`, `overdueDays` (plural), `priorityLabel`, `recurrenceLabel`, `dateFormat` |
| `TaskPriorityUi` | Badge colors; labels via `L10n.priorityLabel` |
| `CalendarSettingsPage` | Device calendar multi-select + **language** + **day-status notification** toggle (Android) |
| `NotificationHelper` | `flutter_local_notifications` init; Android channels (meetings, digest, overdue, **day status**) |
| `DayStatusNotificationController` | Android foreground service via `startForegroundService` / `show` / `stopForegroundService`; always reflects **today** |
| `DayStatusNotificationBuilder` | Title with `done`/`total` when tasks exist, else plain title; body = current/next event |
| `NotificationPreferencesRepository` | `day_status_bar_enabled` (default **false**); `day_status_bar_pinned` (default **true**) |
| `DayStatusBarSettingsSection` | `SwitchListTile` on `CalendarSettingsPage`; calls `setDayStatusBarEnabled` |
| `DayStatusServiceHost` | Post-frame `ensureStartedIfEnabled()` when feature is on |
| `DeepLinkService` | `app_links`: `getInitialLink` + `uriLinkStream` → `DeepLinkParser` |
| `DeepLinkDispatcher` | Pops to dashboard, waits for `DashboardLoaded`, opens create sheet with prefilled fields |
| `DeepLinkParser` | `daylinx://create?type=task\|event&title=…`; sanitizes title (max 200 chars) |

### Dashboard events (BLoC)

| Event | Effect |
|-------|--------|
| `LoadDashboardData` | Load tasks, events, overdue (if today), week `dayMarkers`; optional `selectedDate`, `selectedCalendarIds` |
| `SelectDashboardDate` | Change day and reload |
| `ToggleTaskCompletion` | Toggle `isCompleted`; reload active + completed lists for `selectedDate` |
| `LinkTaskToCalendarEvent` / `UnlinkTaskFromCalendarEvent` | Persist task↔event link in Isar |
| `UpdateTask` | Save task edits from `TaskFormSheet` (edit mode) |
| `DeleteTask` | Unlink event, delete attachments, detach children, `deleteTask`, reload dashboard |
| `DeleteCalendarEvent` | `deleteLocalEvent` (unlinks linked tasks), reload dashboard |
| `ReorderChildTasks` | Persist `Task.sortOrder` for children under a parent |
| `UpdateTaskAttachment` | Save edited attachment from `AddAttachmentSheet` |
| `RestoreTaskAttachment` | Undo delete via SnackBar |
| `PostponeTaskToNextDay` | `Task.postponeToNextDay(referenceDate: selectedDate)` + save |
| `PostponeTask` | `Task.postponeDueDate(newDueDate)` + save |
| `LinkTaskAsChild` / `DetachTaskFromParent` | Set/clear `Task.parentTaskId`; assign `sortOrder` on attach |
| `DeleteTaskAttachment` / `ToggleAttachmentChecklistItem` | Attachment CRUD / checklist toggle |
| `ExpandDashboardTask` / `ClearExpandedDashboardTask` | Legacy (tile no longer expands on dashboard) |

After any successful `DashboardLoaded` emit or `_emitReloadedTasks`, `DashboardBloc` calls `DayStatusNotificationController.syncTodayStatus()` (no-op when disabled or non-Android).

### Day-status foreground notification (Android)

1. User enables **Show status bar in notifications** on `CalendarSettingsPage` → `NotificationPreferencesRepository` + `DayStatusNotificationController.setDayStatusBarEnabled(true)`.
2. Controller loads **today’s** uncompleted/completed tasks and visible calendar events, builds copy via `DayStatusNotificationBuilder`, starts FGS (`notificationId` 7391, channel `day_status_bar` or `day_status_bar_pinned` when pin enabled).
3. `DashboardBloc` refreshes the notification after task/event mutations (completion, postpone, link, delete, etc.).
4. User disables the toggle → `stopForegroundService()`. `DayStatusServiceHost` restores the service on cold start if still enabled.
5. **Energy:** FGS uses `specialUse` type; `android:stopWithTask="true"` stops the service when the app task is removed from recents.

### Navigation (dashboard → detail)

1. **Task body tap** → `DashboardScreen.openTaskDetail` → `TaskDetailScreen` (with `BlocProvider.value` for `DashboardBloc`).
2. **Event card tap** → `DashboardScreen.openEventDetail` → `EventDetailScreen`.
3. **AppBar edit** on detail screens → `TaskFormSheet` / `EventFormSheet`; dashboard reloads via BLoC on return.

### Task postpone flow

1. User opens **`TaskDetailScreen`** (or used to expand tile — now detail only).
2. **Tomorrow** → `DashboardScreen.postponeTaskToTomorrow` → `PostponeTaskToNextDay`.
3. **Postpone** → `PostponeTaskSheet` → `PostponeTask` with picked date.
4. `TaskOverdueRules.recordPostpone` updates `dueDate` only; `dynamicOverdueDays` is derived from dates.
5. List reloads for the current `selectedDate` (task may disappear if moved off that day).

### Child task reorder flow

1. On `TaskDetailScreen`, user drags a row in `TaskDetailChildTasksSection`.
2. UI reorders local list; dispatches `ReorderChildTasks(parentTaskId, orderedChildIds)`.
3. `TodoRepository.reorderChildTasks` writes `Task.sortOrder` = index for each child.

---

## Theming

Configured in `lib/app.dart`:

- `theme: AppTheme.light`
- `darkTheme: AppTheme.dark`
- `themeMode: ThemeMode.system`

Widgets should use `Theme.of(context).colorScheme` (not hardcoded colors) so light/dark stay consistent.

---

## Localization

User-facing strings live in **`assets/translations/`** as JSON (`en.json`, `ru.json`, `es.json`). The app uses **[easy_localization](https://pub.dev/packages/easy_localization)** with `flutter_localizations` for Material date/time pickers.

| Piece | Location / behavior |
|-------|---------------------|
| Bootstrap | `main.dart`: `EasyLocalization.ensureInitialized()`, `startLocale` from `LocalePreferencesRepository` (or device default) |
| App shell | `app.dart`: `locale`, `supportedLocales`, `context.localizationDelegates` on `MaterialApp` |
| Widgets | Prefer `'some_key'.tr()` or `'key'.tr(namedArgs: {'name': value})` |
| No `BuildContext` | `L10n.tr('key')` in BLoC, services, codecs (after EasyLocalization init) |
| Plurals | e.g. `'overdue_days'.plural(n)` via `L10n.overdueDays(days)` |
| Dates | `L10n.dateFormat('d MMMM', context: context)` — uses active locale, not hardcoded `'ru'` |
| Manual override | **Calendars** screen (`CalendarSettingsPage`) → **Language** dropdown: System / English / Russian / Spanish; persists to SharedPreferences key `app_locale_language_code` |

**Adding a string:** add the same key to all three JSON files, then use `.tr()` in presentation (or `L10n.tr` in domain/data when shown to the user). Do not hardcode UI copy in widgets.

**Supported locales:** `AppLocales.supported` — `en` (fallback), `ru`, `es`.

---

## Tech stack (`pubspec.yaml`)

- **Flutter** SDK ^3.12
- **flutter_bloc** — state
- **isar** + **isar_generator** — local DB
- **device_calendar** — Android/iOS calendar read
- **flutter_local_notifications**, **timezone**, **workmanager**
- **easy_localization** — JSON translations (`assets/translations/`)
- **flutter_localizations** (SDK) — Material/Cupertino locale delegates
- **shared_preferences**, **path_provider**, **intl**
- **image_picker**, **url_launcher**, **geolocator**, **flutter_map**, **latlong2** — attachments (map pick)
- **flutter_contacts** — device contact picker
- **map_launcher** — open coordinates in user’s map app (chooser UI)
- **http** — Nominatim (OpenStreetMap) place search

---

## Android build notes

Permissions and queries in `android/app/src/main/AndroidManifest.xml`:

- Calendar read/write, notifications, exact alarms, boot receiver
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` (day-status FGS)
- `ForegroundService` + `ActionBroadcastReceiver` from `flutter_local_notifications`
- Deep links: `intent-filter` for `daylinx://` on `MainActivity` (`launchMode=singleTop`)
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

Domain unit tests: `task_date_visibility_test.dart`, `task_overdue_rules_test.dart`, `task_overdue_selection_test.dart`, `task_reopen_test.dart`, `task_hierarchy_test.dart`, `task_attachment_codec_test.dart`, `task_attachment_checklist_test.dart`, `dashboard_day_markers_builder_test.dart`, `day_status_notification_builder_test.dart`.

---

## AI assistant onboarding

When starting code generation in Cursor/Claude:

1. Read `PRD_PRODUCT_SPEC.md` and this file (**English only** for docs).
2. Respect feature folders; do not put UI in `data/`.
3. Prefer extending existing services (`DeviceCalendarService`, `LocalCalendarEventRepository`, `TodoRepository`) over duplicate logic.
4. Reuse `TaskExpandableTile`, `TaskDetailScreen`, `EventDetailScreen`, `TaskBadge`, `DashboardLocalEventsStrip`, `TaskOverdueRules`, `AppDateUtils`, `L10n` where applicable.
5. New UI strings: add keys to `en.json`, `ru.json`, `es.json`; use `.tr()` — no hardcoded copy in widgets.

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
| 2026-05 | Overdue tasks block, week strip markers, tile tap zones, subtask/checklist UX, location `placeName` |
| 2026-05 | Local events strip, `completedTasks` on dashboard, compact tiles + tappable badges, templates AppBar stub, edit sheets |
| 2026-05 | Undated section; dynamic overdue; `TaskFormSheet`/`EventFormSheet`; calendar context (`calendarId`); delete flows |
| 2026-05 | Detail screens; compact tiles; attachment action sheet; `Task.sortOrder`; attachment edit/restore BLoC events |
| 2026-05 | **easy_localization** (`en` / `ru` / `es`); `core/localization/`; language picker on `CalendarSettingsPage`; templates feature in tree |
| 2026-05 | Android **day-status foreground notification** (`DayStatusNotificationController`, `DashboardBloc` sync, settings toggle, `specialUse` FGS) |
| 2026-05 | **Deep links** (`daylinx://create`, `app_links`, `DeepLinkDispatcher`, prefilled task/event sheets) |
| 2026-05 | Product name **DayLinx** (`DayLinxApp`, `daylinx://`; formerly Dayline) |
| 2026-05 | Dashboard **backlog** as top-level section (not collapsible); task empty state at scroll bottom |
