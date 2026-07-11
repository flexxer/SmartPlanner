# DayLinx

Flutter app for **device calendar events** and **local tasks** in a single day view.



Repository docs (English): [`../PRD_PRODUCT_SPEC.md`](../PRD_PRODUCT_SPEC.md), [`../PROJECT_STRUCTURE.md`](../PROJECT_STRUCTURE.md).



## Features (current)



- **Dashboard** with day selector (default: today), date picker, and **horizontal week strip**

  - Activity **dots** under each day: calendar events (primary / calendar color), local tasks (secondary)

  - Markers loaded in one batch per week range (cached; see `DashboardDayMarkersRepository`)

- **Local calendar events** — horizontal strip for the selected day

  - All-day events as chips above the strip; timed events in compressed timeline layout

  - Timed events in a **time-proportional** horizontal strip (~50 px/hour); non-overlapping events share a row; overlapping events in separate rows (no tile overlap) with later events offset down and to the right; row height scales with overlap count; gap markers for long breaks; **now** indicator on today

  - **Tap** event card → **`EventDetailScreen`**; **long-press** → edit (`EventFormSheet`); create from section header

- **Overdue tasks panel** (today only): collapsible block above the main list

- **Tasks** for the selected day

  - **Active** dated tasks on top

  - **Backlog** — tasks with no `dueDate`; always-visible section on any selected day (alongside dated tasks and events)

  - **Completed** tasks in a collapsible section at the bottom (dimmed, strikethrough)

  - **Compact tiles** (`TaskExpandableTile`): checkbox vs body tap zones; **tap body** → **`TaskDetailScreen`**

  - **Priority** — flag icon left of the title (all levels); compact **badges** below (context calendar when multiple calendars selected, due/overdue only when not redundant with section headers, linked event title, subtask/checklist/attachment counts)

  - Create via FAB → **`TaskFormSheet`**; edit/delete on detail screens and form sheets

- **Global search** (AppBar) — tasks and calendar events with informative result rows

- **Delete undo** — 10s SnackBar undo for tasks, events, and attachments; device delete skipped on read-only calendars (local Isar row removed)

- **Task detail** (`TaskDetailScreen`): priority icon + title, description, badges, **reorderable attachments**, scrollable checklists, **reorderable linked subtasks** (`Task.sortOrder`) with checkbox to reopen completed subtasks, postpone, link/unlink event

- **Event detail** (`EventDetailScreen`): time, recurrence, linked tasks, add task; AppBar **Sync** (outbound device calendars) + edit

- **Linked subtasks** vs **checklist** — separate concepts (`parentTaskId` + `sortOrder` vs attachment type)

- **Task attachments** (local, multiple per task): contact, photo, URL, location (Nominatim), note, checklist

  - **Checklist** — inline checkboxes on detail; optional **Move completed items to the end** in attachment settings (default on); slide animation when toggling

  - **Attachment templates** (user-defined): quick-add chips in `AddAttachmentSheet`; manage under **Library** → Attachments tab (rename from Templates planned)

  - Tap attachment → action sheet: **Open / View**, **Edit** (`AddAttachmentSheet`), **Delete** (SnackBar Undo), **Save as template**

- **Completion animations** — shared `SlidingCompletionList` (checklists, event linked tasks) and `CollapsingCompletionTile` (child subtasks); dashboard toggles via BLoC with stable per-task keys

- **Library hub** (rename from `TemplatesPage` planned): tabs **Tasks** (UI blueprints), **Attachments** (presets), **Categories** (planned — user tag CRUD, empty on first launch)

- **Finance** (planned): separate screen from dashboard AppBar; income/expense payments; checkbox status; default currency in Settings + per-payment currency on form

- **Categories** (planned): optional multi-tag on tasks, events, payments; distinct from `Task.calendarId` (device context)

- **Create / edit / delete** tasks and local events via **`TaskFormSheet`** / **`EventFormSheet`** (event create: optional outbound calendar sync; all-day, cross-midnight)

- **AppBar:** search, time grid, **Finance** (planned), **Library** (templates hub), **settings** (language, theme, reminders, digests, midnight roll, device calendars, **default currency** planned), refresh

- **Device calendar** — local-first Isar; **manual outbound sync** only (`EventCalendarSyncService`); settings calendars = sync picker pool

- **Dashboard calendar UX** — recurring from stored rules; “now” timeline hidden before the first event; week strip from Isar events + tasks

- **Recurring tasks** — optional daily/weekly repeat on tasks with a due date (same JSON rule model as events)

- **Android day-status notification** (optional, off by default): ongoing foreground notification with task progress when tasks exist, plus current or next calendar event; optional pin above other notifications; toggles under **Calendars**

- **Morning / evening task digest** (optional, on by default): Workmanager notifications ~08:00 and ~19:00 with today's task count

- **Light / dark theme** — system default, or force light/dark in **Settings → Theme**

- **Deep links (Android / iOS):** `daylinx://create?type=task&title=…&priority=2` or `type=event&start=14:00` opens the dashboard and the matching create sheet with prefilled fields (`app_links`)

- **Localization:** English, Russian, Spanish (`easy_localization`); default = device language



Calendar **events** and **tasks** are stored locally in Isar. Events sync **out** to device calendars only when the user chooses. Not Google Tasks API.

**Planned:** user **categories** (multi-tag), **payments** / **Finance** screen — see PRD §3.4–§3.5.



> **Note:** Completed tasks appear in the dashboard **Completed** section; event tap opens `EventDetailScreen` (linked tasks + attachments).



## Requirements



- Flutter SDK ^3.12 (stable recommended)

- Android or iOS device/emulator (**not Web** — Isar does not support Web)
- Android 15+ / OneUI 8.5+: local DB uses **isar_community** 3.3.2+ for 16 KB memory page compatibility

- **Internet** optional — required for OpenStreetMap tiles and Nominatim when adding a location



## Setup & run



```bash

cd smart_planner

flutter pub get

dart run build_runner build

flutter run

```



Grant permissions when prompted: calendar, contacts, photos, location (see PRD for details).



## Tests



```bash

flutter test

```



Includes: `task_date_visibility_test`, `task_overdue_rules_test`, `task_overdue_selection_test`, `task_reopen_test`, `task_hierarchy_test`, `task_attachment_*`, `dashboard_day_markers_builder_test`, `day_status_notification_builder_test`, `deep_link_parser_test`, `recurrence_*`, `compressed_events_strip_layout_test`, `calendar_event_layout_test`, `widget_test`.



## Project layout



| Path | Description |

|------|-------------|

| `lib/app.dart` | `MaterialApp`, locale delegates, repositories, persisted `ThemeMode`, `DashboardBloc` |

| `lib/core/` | Isar DB, theme (`AppTheme`, `AppColorUtils`, theme preferences), init, `AppDateUtils`, `localization/`, `presentation/widgets/` |

| `assets/translations/` | `en.json`, `ru.json`, `es.json` UI strings |

| `lib/features/dashboard/` | Main screen, week strip, events strip, task lists, `DashboardBloc` |

| `lib/features/todo_list/` | Tasks, attachments, `TaskDetailScreen`, `TaskFormSheet`, tiles |

| `lib/features/calendar_integration/` | Device calendar, local events, `EventDetailScreen`, `EventFormSheet`, `CalendarSettingsPage` |

| `lib/features/templates/` | UI task templates (save/apply); hub UI → rename to **Library** |
| `lib/features/categories/` | (planned) User-defined tags |
| `lib/features/finance/` | (planned) Payments / cashflow |

| `lib/features/deep_links/` | `daylinx://` parsing and routing to create sheets |
| `lib/features/notifications/` | Local notifications, Workmanager stub, Android day-status foreground service |



Key UI: `task_detail_screen.dart`, `event_detail_screen.dart`, `task_form_sheet.dart`, `event_form_sheet.dart`, `task_expandable_tile.dart`, `dashboard_local_events_strip.dart`, `dashboard_all_day_events_row.dart`, `calendar_grid_week_view.dart`, `attachment_action_sheet.dart`.



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

