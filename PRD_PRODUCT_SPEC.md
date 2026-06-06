# Product Requirements Document (PRD) — DayLinx

> **Documentation language:** All project documentation (PRD, architecture, README, inline specs, and AI context files) must be written and maintained in **English**. User-facing app strings are localized via **easy_localization** (`en`, `ru`, `es`); see §4 and §5.

---

## 1. Product overview

A mobile app that aggregates multiple calendars and provides flexible task lists, with a focus on informative home-screen widgets and smart reminders.

**Product name:** DayLinx (repository folder: `smart_planner/`)  
**Repository layout:** Flutter app in `smart_planner/`  
**Source:** [github.com/flexxer/SmartPlanner](https://github.com/flexxer/SmartPlanner)

---

## 2. Target audience

Professionals, freelancers, and people with high cognitive load who juggle multiple life contexts (work, side projects, home, hobbies).

---

## 3. Functional requirements (MVP)

### 3.1 Multi-calendar aggregation

| Requirement | Status | Notes |
|-------------|--------|-------|
| Read device calendars (Google accounts synced to Android Calendar) | **Implemented** | `device_calendar` + calendar picker; no in-app OAuth |
| Show events from multiple accounts (Personal, Work, Projects) | **Implemented** | User selects calendars in settings |
| Write events to writable device calendars | **Implemented** | `CalendarEventWriteService` + `DeviceCalendarEventBridge`; read-only calendars → Isar-only + snackbar |
| Color-code events by calendar source | **Implemented** | `CalendarContextColors` + accent bar on strip cards |
| Events for a user-selected day | **Implemented** | Device fetch → Isar upsert → `DashboardLocalEventsStrip` for selected day |
| Local calendar events CRUD + task linking | **Implemented** | `LocalCalendarEventRepository`; link/unlink tasks; create/edit sheets |
| Live “now” timeline on today’s event strip | **Implemented** | Pulsing indicator + auto-scroll; hidden when now is before the first event of the day |
| Week strip activity badges | **Implemented** | Event count + task count (`TaskDateVisibility`); not reminder-only without due on that day |
| Recurring events on dashboard | **Implemented** | Device instances per occurrence + `VisibleCalendarEventsMerger` expansion from stored rules |
| Week time grid scroll to current time | **Implemented** | `CalendarGridWeekView` scrolls to now when the visible week includes today |

### 3.2 To-Do engine

| Requirement | Status | Notes |
|-------------|--------|-------|
| Tasks without strict time binding | **Implemented** | Optional `dueDate` (`null` = no deadline); **Backlog** section on every selected day (`backlog_section`), always visible alongside dated tasks |
| Roll unfinished tasks with overdue indicator | **Implemented** | **Overdue** panel on today; badge via `Task.dynamicOverdueDays`; optional **midnight roll** moves overdue tasks to today (`OverdueMidnightRollService`, Workmanager ~00:05 + 15 min refresh fallback; toggle in **Reminders** settings, default on) |
| Tasks filtered by selected calendar day | **Implemented** | Dated tasks via `getUncompletedTasksForDate`; undated via `getUndatedTasks` |
| Postpone task (tomorrow or pick date) | **Implemented** | `TaskDetailScreen` + `PostponeTaskSheet`; `PostponeTask` / `PostponeTaskToNextDay` |
| Context calendars (device lists) | **Implemented** | `Task.calendarId` (device calendar id); `TaskLinkedCalendarsField` in `TaskFormSheet`; context badge on tiles via `CalendarContextColors` |
| Create / edit / delete task or event | **Implemented** | `TaskFormSheet` / `EventFormSheet`; delete with confirmation in edit mode (`DeleteTask`, `DeleteCalendarEvent`) |
| Recurring tasks (bills, stand-ups) | **Planned** | Not in schema yet |
| Local CRUD + priority sorting | **Implemented** | Isar + `TodoRepository` |
| Completed tasks on selected day | **Implemented** | Active tasks on top; collapsible **Completed** section at bottom (dimmed, strikethrough); toggle moves task between lists |
| Completed tasks archive screen | **Removed** | Use dashboard **Completed** section; `TodoRepository.reopenFromCompleted` remains for reopen flows |
| Reopen completed task (new copy, new due date) | **Implemented** | `TaskReopen` + `reopenFromCompleted`; original stays completed |
| Task list tiles with badges | **Implemented** | `TaskPriorityIcon` beside title; `TaskBadgesRow` with context-aware due/link labels; counts for subtasks, checklist, attachments |
| Global search (tasks + events) | **Implemented** | `SearchScreen` from dashboard AppBar |
| Delete with 10s undo | **Implemented** | `RecordDeleteCoordinator` + `delete_undo_snackbar`; restore re-syncs device calendar when applicable |
| Attachment templates (user presets) | **Implemented** | Isar `AttachmentTemplate`; hub tab + quick-add chips in `AddAttachmentSheet` |
| Templates hub (task + attachment tabs) | **Implemented** | `TemplatesPage` with `TaskTemplatesTab` and `AttachmentTemplatesTab` |
| Task / event detail screens | **Implemented** | `TaskDetailScreen`, `EventDetailScreen`; AppBar edit; full attachments + reorderable subtasks on task detail |
| Templates module (AppBar) | **Implemented** | `TemplatesPage` CRUD; apply via FAB, relation sheet, `TaskFormSheet`, deep link `type=template`; save from task detail |
| Linked subtasks (existing task under a parent task) | **Implemented** | `Task.parentTaskId` + `Task.sortOrder`; manual reorder on `TaskDetailScreen`; link via picker; detach; progress badge on parent |
| Task attachments (local) | **Implemented** | `TaskAttachment`: contact, image, URL, location, note, checklist; multiple per task (see §3.2.1) |

**Important distinction:** **Calendar events** (meetings) come from the device calendar. **Tasks** are stored locally in Isar—they are not Google Calendar tasks unless a future sync feature is added.

**Subtasks vs checklist:** **Linked subtasks** are separate `Task` rows (`parentTaskId`). A **checklist** is a `TaskAttachment` of type `checklist` (plain items inside the attachment payload, not separate tasks).

#### Overdue badge (localized, e.g. “Overdue by N days”)

Shown on a task tile when `Task.dynamicOverdueDays > 0` (key `overdue_days`, ICU plural per locale):

- `0` if the task is completed or has no `dueDate`.
- Otherwise calendar days from `dueDate` (start of day) to today (start of day) when the due day is strictly before today.

Postponing only updates `dueDate`; overdue days are recalculated on read (`TaskOverdueRules.dynamicOverdueDays`).

#### 3.2.1 Task attachments (local)

Stored as `TaskAttachment` in Isar (`taskId`, `type`, `payloadJson`, optional `label`, `sortOrder`). Multiple attachments per task. Images are copied into app documents (`AttachmentFileStore`).

| Type | Add flow | View / interact (detail screen) |
|------|----------|-------------------------------|
| **Contact** | Choosing type opens the **device contact picker** immediately; full contact re-fetched after pick (`flutter_contacts`) | Tap card → action sheet → **Open** (call / SMS / email via `AttachmentLauncherService`) |
| **Image** | Gallery pick; **preview** in add/edit sheet | **Open** → full-screen viewer |
| **URL** | Title + URL fields | **Open** → browser; title shown in card header |
| **Location** | Optional place name; **OSM map picker** with **Nominatim search** and reverse geocode; current location | **Open** → map app chooser (`map_launcher`) or geo fallback |
| **Note** | Title + body | **Open** → full-text dialog |
| **Checklist** | Title; items with **+** next to input; pending line saved on Save without pressing +; **Attachment settings** checkbox **Move completed items to the end** (default **on**, stored as `moveCompletedToEnd` in payload JSON) | Checkboxes inline (toggle without opening sheet); uncompleted items stay on top when setting is on; slide + strikethrough animation via `SlidingCompletionList`; progress badge on parent tile |

**Attachment actions (all types):** tap attachment card → bottom sheet — **Open / View**, **Edit** (`AddAttachmentSheet` with `attachmentToEdit`), **Delete** (SnackBar **Undo** / `RestoreTaskAttachment`). Edit save → `UpdateTaskAttachment` in `DashboardBloc`.

**Location note:** External map apps (Google Maps, Yandex, etc.) cannot return a picked point to third-party apps without Google Places SDK and an API key. Coordinates are saved via the in-app OpenStreetMap picker.

### 3.3 Notifications and widgets

| Requirement | Status | Notes |
|-------------|--------|-------|
| Push: meeting reminders (15/30 min before) | **Planned** | Channels defined; scheduling TBD |
| Push: morning/evening task digest | **Implemented** | Workmanager ~08:00 / ~19:00 (`TaskDailyDigestWorker`); toggles in Settings |
| Android ongoing **day-status** notification (foreground service) | **Implemented** | Opt-in on **Calendars** settings; `DayStatusNotificationController` + `flutter_local_notifications` FGS (`specialUse`); title = today’s task progress, body = current/next event; synced from `DashboardBloc`; default **off** |
| Android home widget: day schedule + focus tasks | **Implemented** | Medium 4×2 (`DayLinxWidgetProvider`); same payload as day-status via `DayStatusHomeWidgetService`; ↻ refresh + add task; complete-from-widget = planned |
| Android lock screen widget: today pulse (event + progress) | **Planned** | Variant 1 «Pulse» — 2 lines, read-only; Android 14+ Glance `keyguard`; spec `ANDROID_LOCK_SCREEN_WIDGET.md`; reuses `DayStatusTodayLoader` |
| Background check for overdue tasks | **Implemented** | `workmanager`: overdue digest (`OverdueBackgroundWorker`, 12h); midnight roll + digest refresh; day-status/widget refresh (15 min) |
| Custom URL scheme deep links (`daylinx://create`) | **Implemented** | `app_links`; opens dashboard + `TaskFormSheet` / `EventFormSheet` with prefilled `title`, `priority`, `start` |

---

## 4. Non-functional requirements

| Area | Choice |
|------|--------|
| Cross-platform | Flutter (primary target: Android; iOS structure prepared) |
| Local storage | **Isar** (offline-first tasks, attachments, local calendar events) |
| State management | **flutter_bloc** |
| Architecture | Feature-driven Clean Architecture (`data` / `domain` / `presentation`) |
| Calendar on device | `device_calendar` |
| Local notifications | `flutter_local_notifications` + `timezone` |
| Theming | **System light/dark** — `ThemeMode.system`, Material 3 light + dark (`AppTheme`) |
| Localization | **easy_localization** — `assets/translations/en.json`, `ru.json`, `es.json`; default = device locale; manual override on **Calendars** settings screen |
| Future AI modules | Keep domain layer free of UI/framework deps where possible |

**Platform note:** Isar does **not** support Web. Run on Android/iOS/desktop, not Chrome.

---

## 5. Dashboard (current UX)

### Date navigation

- **Date bar:** previous / next day, center label (tap → date picker), “Today” when another day is selected.
- **Week strip** (`DashboardWeekDateStrip`): horizontally scrollable ~3 weeks; tap a day to select it.
  - **Dots** (3.5 px) under the day number: **calendar** = `ColorScheme.primary` or first event’s calendar color; **local tasks** = `ColorScheme.secondary`.
  - Markers prefetched for the visible range (one Isar read + one `getEvents` call, cached in `DashboardDayMarkersRepository`).
- **Default day:** today.
- **Calendar events** and **tasks** both respect the selected day.

### Local calendar events (`DashboardLocalEventsSection` + `DashboardLocalEventsStrip`)

- Single source for day events (legacy “events on date” text block removed).
- Section header: day label and **Create** event (calendar selection is AppBar only).
- **Horizontal strip** (~116 dp): compressed layout — adjacent event cards, compact gap markers for long idle periods (≥90 min).
- **Event card:** accent bar, **start–end time** (no decorative calendar icon), title, optional recurrence icon, linked-tasks badge.
- **Today only:** past / current / future styling; pulsing **Now** chip on current event (`events_now_chip`); live **now** vertical indicator (updates every minute); auto-scroll to current or next event.
- **Tap** card → **`EventDetailScreen`** (linked tasks, add task, AppBar edit).
- **Long-press** card → `EventFormSheet` (edit mode).
- Device events are upserted into Isar; strip reads local `calendarEvents` filtered by `RecurrenceEvaluator`.

### Tasks

- **Overdue section (today only):** collapsible **Overdue (N)** above task sections (`overdue_section`; `DashboardLoaded.overdueTasks`). Hidden on other days.
- **Tasks due (dated):** section header **Tasks due today** / **Tasks due on {date}**; root uncompleted **dated** tasks for `selectedDate` (`getUncompletedTasksForDate`; excludes `dueDate == null`).
- **Backlog:** standalone section **Backlog (N)** (`backlog_section`); always expanded; all uncompleted tasks with `dueDate == null` from `getUndatedTasks`; shown on every selected day.
- **Completed tasks (same day):** collapsible **Completed (N)** at the bottom (`completed_section`); tiles at **50% opacity**, **strikethrough** title; unchecking returns task to the active list immediately (`ToggleTaskCompletion`).
- **Empty day:** when there are no dated, backlog, or completed tasks for the day, a hint is shown at the **bottom** of the scroll (events and other content stay higher).
- **One full-width compact tile per row** (`TaskExpandableTile`).
  - **Checkbox** (48×48 dp): `ToggleTaskCompletion`; separate splash from body.
  - **Body tap** → **`TaskDetailScreen`** (`Navigator.push`).
  - **Title** + optional **description** (up to two lines, ellipsis).
  - **Badge row** (`TaskBadge`, `Wrap`): context calendar, priority, due, overdue, linked event, subtasks, checklist, attachments; tappable badges can open detail or event screen.
  - Chevron indicates navigation (no in-place expand).
- **FAB (+):** `TaskFormSheet` (create mode); no default due date — user may leave deadline empty.
- Empty state at the bottom of the scroll when active dated, backlog, and completed lists are all empty.

### Task detail (`TaskDetailScreen`)

- **AppBar:** back, title **Task** (`task_title`), **edit** (`Icons.edit_outlined`) → `TaskFormSheet`.
- **Header:** `headlineMedium` title, full description, badge row, due / overdue / created metadata.
- **Actions:** Tomorrow / Postpone (if not completed); unlink linked event.
- **Linked subtasks:** `ReorderableListView` (`TaskDetailChildTasksSection`); drag handle; persists `Task.sortOrder` via `ReorderChildTasks`; completed children listed below; link existing task; tap child → nested `TaskDetailScreen`.
- **Attachments:** full `TaskAttachmentsSection` with action sheet + edit/delete flows.
- Pull-to-refresh; listens to `DashboardBloc` for live updates.

### Event detail (`EventDetailScreen`)

- **AppBar:** back, title **Event** (`event_title`), **edit** → `EventFormSheet`.
- Calendar chip, date/time, recurrence chip when applicable.
- Linked tasks list (toggle completion, tap → `TaskDetailScreen`).
- **Add task to event** button (create + link).

### App bar

| Action | Purpose |
|--------|---------|
| Templates (`layers_outlined`) | Opens `TemplatesPage` (create/apply UI templates) |
| Calendars | Device calendar selection + **language** dropdown (system / en / ru / es) |
| Refresh | `LoadDashboardData` |

### Create / edit forms

| Sheet | Create | Edit | Delete |
|-------|--------|------|--------|
| `TaskFormSheet` | Title **New task** (`task_new`); optional `dueDate`; calendar chips | Prefilled fields; `UpdateTask` via BLoC | `DeleteTask` + confirm dialog (`delete_dialog_*`) |
| `EventFormSheet` | Title **New event** (`event_new`); default 10:00–11:00 on `initialDay` | Recurrence + times; `LoadDashboardData` after save | `DeleteCalendarEvent` + confirm dialog |
| `AddAttachmentSheet` | Pick type + form | `attachmentToEdit` prefills fields; `UpdateTaskAttachment` | — (delete via attachment action sheet) |

Legacy `CreateTaskSheet`, `EditTaskSheet`, `CreateCalendarEventSheet`, and `EditCalendarEventSheet` were removed in favor of the unified sheets. In-dashboard tile expansion was removed in favor of detail screens.

### Completed tasks on dashboard

- Standalone completed archive screen was removed; use the collapsible **Completed** section on the dashboard.
- Domain helper `TaskReopen` / `reopenFromCompleted` unchanged for reopen flows.

### Appearance

- Follows **device theme** (light / dark / system setting).

### Localization

- **Default:** app language follows the **device locale** when it matches `en`, `ru`, or `es`; otherwise **English** fallback.
- **Override:** **Calendars** screen → **Language** dropdown (System default / English / Russian / Spanish); persisted in SharedPreferences; UI updates immediately without restart.
- **Day-status notification (Android):** same settings screen → **Show status bar in notifications** (`day_status_bar_enabled`) and **Pin above other notifications** (`day_status_bar_pinned`, default on); requires notification permission on Android 13+.
- **Implementation:** all presentation strings use translation keys in `assets/translations/*.json`; helpers in `lib/core/localization/l10n.dart` for plurals, priorities, and `DateFormat`.
- **Not localized:** demo seed tasks in `task_bootstrap.dart`; calendar-name heuristics in `calendar_context_colors.dart` (matching only).

---

## 6. Out of scope (MVP)

- Google Tasks API sync
- Full Google Calendar OAuth write access
- Cloud sync / multi-device backup
- AI scheduling assistant
- In-app manual theme override (system only for now; language override is in scope)

---

## 7. Revision history

| Date | Change |
|------|--------|
| 2026-05 | Initial PRD (Russian) |
| 2026-05 | Translated to English; aligned with implemented MVP |
| 2026-05 | Dashboard date filter, completed/reopen, expandable tiles, system theme |
| 2026-05 | Manual postpone UI; dynamic overdue-day badge (`dynamicOverdueDays`) |
| 2026-05 | Embedded subtasks on tasks (checklist, dashboard + create flow) |
| 2026-05 | Link existing tasks as child subtasks via `parentTaskId` |
| 2026-05 | Local `TaskAttachment` types (contact, image, URL, location, note, checklist) |
| 2026-05 | Attachment UX: device contacts, OSM place search, map-app chooser (coords only), image preview, compact URL tile |
| 2026-05 | Checklist as attachment only (removed embedded subtasks on `Task`) |
| 2026-05 | Overdue panel, week activity dots, tile tap zones, linked vs checklist UI, location place names (Nominatim) |
| 2026-05 | Local events strip (compressed timeline, now indicator); dashboard completed section; compact `TaskExpandableTile` + interactive badges; AppBar templates stub |
| 2026-05 | Undated tasks section; `TaskFormSheet` / `EventFormSheet`; `Task.calendarId` (removed `TaskCategory`); `DeleteTask` / `DeleteCalendarEvent` |
| 2026-05 | `TaskDetailScreen` / `EventDetailScreen`; compact dashboard tiles; attachment action sheet; `Task.sortOrder` + `ReorderChildTasks`; `UpdateTaskAttachment` / `RestoreTaskAttachment` |
| 2026-05 | **easy_localization** (`en` / `ru` / `es`); language picker on Calendars settings; PRD/structure docs use English; UI via JSON keys |
| 2026-05 | Android day-status foreground notification (ongoing FGS, dashboard sync, settings toggle) |
| 2026-05 | Deep links: `daylinx://create?type=task\|event` → prefilled create sheets |
| 2026-05 | Product name **DayLinx** (Dayline unavailable); `daylinx://`; `DayLinxApp` root widget |
| 2026-05 | Dashboard **backlog** top-level section; empty tasks hint at scroll bottom |
| 2026-06 | Device calendar write-back; removed Google OAuth from scope; midnight overdue roll + settings toggle |
| 2026-06 | Android home widget MVP (medium 4×2, shared day-status payload, widget deep links) |
| 2026-06-04 | Calendar UX: selected calendars only; recurring instances + merger; now line before first event; week strip task counts aligned with dashboard |
| 2026-06-06 | Checklist `moveCompletedToEnd` setting; shared completion-list animations (`SlidingCompletionList`, `CollapsingCompletionTile`); linked tasks on event detail; dashboard tiles keyed by task id for stable BLoC reload |
| 2026-06-06 | Lock screen widget spec (variant 1 «Pulse»); removed obsolete `REFACTORING_ROADMAP.md` and `ANDROID_HOME_WIDGET_SKETCH.md` |
