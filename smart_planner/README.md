# Smart Planner

Flutter app for **device calendar events** and **local tasks** (Smart Time & Task Linker MVP).

Repository docs (English): [`../PRD_PRODUCT_SPEC.md`](../PRD_PRODUCT_SPEC.md), [`../PROJECT_STRUCTURE.md`](../PROJECT_STRUCTURE.md).

## Features (current)

- **Dashboard** with day selector (default: today)
- **Calendar events** for the selected day (multi-calendar, color-coded)
- **Tasks** as expandable full-width tiles (priority & due badges, overdue indicator)
- **Linked subtasks** — link existing tasks under a parent (`parentTaskId`); progress badge on parent
- **Task attachments** (local, multiple per task):
  - Contact (device picker), photo, URL, geolocation, note, checklist
- **Postpone task** from expanded tile: tomorrow (relative to selected day) or pick a date
- **Create task** via FAB (due date defaults to selected day)
- **Completed tasks** archive with **reopen** (new copy + new due date; attachments copied)
- **Light / dark theme** follows system settings

Calendar **events** ≠ local **tasks** (Isar); not Google Tasks API.

## Requirements

- Flutter SDK ^3.12 (stable recommended)
- Android or iOS device/emulator (**not Web** — Isar does not support Web)
- **Internet** optional — required only for OpenStreetMap tiles and Nominatim place search when adding a location

## Setup & run

```bash
cd smart_planner
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Grant permissions when prompted:

- **Calendar** — events on the dashboard
- **Contacts** — contact attachments
- **Photos** — image attachments
- **Location** — map picker and “current location”

Android: Settings → Apps → Smart Planner → Permissions.

## Tests

```bash
flutter test
```

Includes: `task_date_visibility_test`, `task_reopen_test`, `task_hierarchy_test`, `task_attachment_codec_test`, `task_attachment_checklist_test`, `widget_test`.

## Project layout

| Path | Description |
|------|-------------|
| `lib/app.dart` | `MaterialApp`, repositories, `ThemeMode.system`, `DashboardBloc` |
| `lib/core/` | Isar DB, theme, init, date utils |
| `lib/features/dashboard/` | Main screen, postpone actions |
| `lib/features/todo_list/` | Tasks, attachments, sheets & tiles |
| `lib/features/calendar_integration/` | Device calendar |
| `lib/features/notifications/` | Local notifications & background stub |

Key attachment UI: `add_attachment_sheet.dart`, `task_attachments_section.dart`, `location_map_picker_sheet.dart`.

## UI locale

App `locale` is Russian (`ru`); documentation is English.

## License

Private / project-specific — see repository owner.
