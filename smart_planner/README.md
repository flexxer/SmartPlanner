# DayLinx

Flutter app for **device calendar events** and **local tasks** in a single day view.



Repository docs (English): [`../PRD_PRODUCT_SPEC.md`](../PRD_PRODUCT_SPEC.md), [`../PROJECT_STRUCTURE.md`](../PROJECT_STRUCTURE.md).



## Features (current)



- **Dashboard** with day selector (default: today), date picker, and **horizontal week strip**

  - Activity **dots** under each day: calendar events (primary / calendar color), local tasks (secondary)

  - Markers loaded in one batch per week range (cached; see `DashboardDayMarkersRepository`)

- **Local calendar events** — horizontal strip for the selected day

  - Compressed timeline layout, gap markers for long breaks, **now** indicator on today

  - **Tap** event card → **`EventDetailScreen`**; **long-press** → edit (`EventFormSheet`); create from section header

- **Overdue tasks panel** (today only): collapsible block above the main list

- **Tasks** for the selected day

  - **Active** dated tasks on top

  - **Undated** — tasks with no `dueDate`, collapsible section on any selected day

  - **Completed** tasks in a collapsible section at the bottom (dimmed, strikethrough)

  - **Compact tiles** (`TaskExpandableTile`): checkbox vs body tap zones; **tap body** → **`TaskDetailScreen`**

  - Badges: **context calendar**, priority, due date, overdue (`dynamicOverdueDays`), linked event, subtasks, checklist, attachments

  - Create via FAB → **`TaskFormSheet`**; edit/delete on detail screens and form sheets

- **Task detail** (`TaskDetailScreen`): full title, description, badges, scrollable attachments/checklists, **reorderable linked subtasks** (`Task.sortOrder`), postpone, link/unlink event

- **Event detail** (`EventDetailScreen`): time, calendar, recurrence, linked tasks, add task to event; AppBar edit

- **Linked subtasks** vs **checklist** — separate concepts (`parentTaskId` + `sortOrder` vs attachment type)

- **Task attachments** (local, multiple per task): contact, photo, URL, location (Nominatim), note, checklist

  - Tap attachment → action sheet: **Open / View**, **Edit** (`AddAttachmentSheet`), **Delete** (SnackBar Undo)

- **Create / edit / delete** tasks and local events via **`TaskFormSheet`** / **`EventFormSheet`** (delete with confirmation in edit mode)

- **AppBar:** templates, calendar settings (includes **language** picker), time grid, refresh

- **Android day-status notification** (optional, off by default): ongoing foreground notification with today’s task progress (✓ done / total) and current or next calendar event; updates when the dashboard data changes; toggle under **Calendars** → **Show status bar in notifications**

- **Light / dark theme** follows system settings

- **Deep links (Android / iOS):** `daylinx://create?type=task&title=…&priority=2` or `type=event&start=14:00` opens the dashboard and the matching create sheet with prefilled fields (`app_links`)

- **Localization:** English, Russian, Spanish (`easy_localization`); default = device language



Calendar **events** (device + local Isar) ≠ local **tasks** (Isar); not Google Tasks API.



> **Note:** Standalone `CompletedTasksPage` is deprecated and not linked from the AppBar. `EventLinkedTasksSheet` remains in the repo but is no longer the primary event tap target.



## Requirements



- Flutter SDK ^3.12 (stable recommended)

- Android or iOS device/emulator (**not Web** — Isar does not support Web)

- **Internet** optional — required for OpenStreetMap tiles and Nominatim when adding a location



## Setup & run



```bash

cd smart_planner

flutter pub get

dart run build_runner build --delete-conflicting-outputs

flutter run

```



Grant permissions when prompted: calendar, contacts, photos, location (see PRD for details).



## Tests



```bash

flutter test

```



Includes: `task_date_visibility_test`, `task_overdue_rules_test`, `task_overdue_selection_test`, `task_reopen_test`, `task_hierarchy_test`, `task_attachment_*`, `dashboard_day_markers_builder_test`, `day_status_notification_builder_test`, `deep_link_parser_test`, `recurrence_*`, `compressed_events_strip_layout_test`, `widget_test`.



## Project layout



| Path | Description |

|------|-------------|

| `lib/app.dart` | `MaterialApp`, locale delegates, repositories, `ThemeMode.system`, `DashboardBloc` |

| `lib/core/` | Isar DB, theme, init, `AppDateUtils`, `localization/` |

| `assets/translations/` | `en.json`, `ru.json`, `es.json` UI strings |

| `lib/features/dashboard/` | Main screen, week strip, events strip, task lists, `DashboardBloc` |

| `lib/features/todo_list/` | Tasks, attachments, `TaskDetailScreen`, `TaskFormSheet`, tiles |

| `lib/features/calendar_integration/` | Device calendar, local events, `EventDetailScreen`, `EventFormSheet`, `CalendarSettingsPage` |

| `lib/features/templates/` | UI task templates (save/apply) |

| `lib/features/deep_links/` | `daylinx://` parsing and routing to create sheets |
| `lib/features/notifications/` | Local notifications, Workmanager stub, Android day-status foreground service |



Key UI: `task_detail_screen.dart`, `event_detail_screen.dart`, `task_form_sheet.dart`, `event_form_sheet.dart`, `task_expandable_tile.dart`, `dashboard_local_events_strip.dart`, `attachment_action_sheet.dart`.



## UI locale



User-facing strings use **[easy_localization](https://pub.dev/packages/easy_localization)**:

| Item | Detail |
|------|--------|
| Files | `assets/translations/en.json`, `ru.json`, `es.json` |
| Default | Device locale when supported; otherwise English |
| Override | App bar → **Calendars** → **Language** (System / English / Russian / Spanish) |
| In code | `'key'.tr()` in widgets; `L10n.tr` / `L10n.overdueDays` in `lib/core/localization/l10n.dart` |

Add new UI text in **all three** JSON files with the same key. Repository documentation stays in English.



## Repository



Public source: [github.com/flexxer/SmartPlanner](https://github.com/flexxer/SmartPlanner)

