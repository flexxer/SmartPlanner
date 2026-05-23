# Product Requirements Document (PRD) — Smart Time & Task Linker

> **Documentation language:** All project documentation (PRD, architecture, README, inline specs, and AI context files) must be written and maintained in **English**. User-facing app strings may be localized separately (e.g. Russian UI).

---

## 1. Product overview

A mobile app that aggregates multiple calendars and provides flexible task lists, with a focus on informative home-screen widgets and smart reminders.

**Working name:** Smart Planner / Smart Time & Task Linker  
**Repository layout:** Flutter app in `smart_planner/`

---

## 2. Target audience

Professionals, freelancers, and people with high cognitive load who juggle multiple life contexts (work, side projects, home, hobbies).

---

## 3. Functional requirements (MVP)

### 3.1 Multi-calendar aggregation

| Requirement | Status | Notes |
|-------------|--------|-------|
| Read device calendars (Google accounts synced to Android Calendar) | **Implemented** | `device_calendar` + calendar picker |
| Google Calendar via OAuth 2.0 | **Planned** | Stub: `GoogleCalendarApiClient` |
| Show events from multiple accounts (Personal, Work, Projects) | **Partial** | User selects calendars in settings |
| Color-code events by calendar source | **Implemented** | `CalendarEvent.colorValue` on dashboard |
| Events for a user-selected day | **Implemented** | `DeviceCalendarService.getEventsForDay` |

### 3.2 To-Do engine

| Requirement | Status | Notes |
|-------------|--------|-------|
| Tasks without strict time binding | **Implemented** | Optional `dueDate`; undated tasks appear only on “today” |
| Roll unfinished tasks with overdue indicator | **Partial** | Manual **postpone** in UI; `overdueCount` via `TaskOverdueRules`; automatic midnight roll not yet wired (`background_service` TODO) |
| Tasks filtered by selected calendar day | **Implemented** | Dashboard date bar; default = today |
| Postpone task (tomorrow or pick date) | **Implemented** | Expanded tile + `PostponeTaskSheet`; `PostponeTask` / `PostponeTaskToNextDay` |
| Categories: Work, Home, Hobby, Rest, Finance | **Partial** | `TaskCategory` model; demo seed uses Work/Home |
| Recurring tasks (bills, stand-ups) | **Planned** | Not in schema yet |
| Local CRUD + priority sorting | **Implemented** | Isar + `TodoRepository` |
| Completed tasks archive | **Implemented** | `CompletedTasksPage` |
| Reopen completed task (new copy, new due date) | **Implemented** | `TaskReopen` + `reopenFromCompleted`; original stays completed |
| Expandable task tiles with badges | **Implemented** | `TaskExpandableTile`: priority, due date, overdue |
| Linked subtasks (existing task under a parent task) | **Implemented** | `Task.parentTaskId`; child hidden from root list; link via picker; detach; progress badge on parent |
| Task attachments (local) | **Implemented** | `TaskAttachment`: contact, image, URL, location, note, checklist; multiple per task (see §3.2.1) |

**Important distinction:** **Calendar events** (meetings) come from the device calendar. **Tasks** are stored locally in Isar—they are not Google Calendar tasks unless a future sync feature is added.

**Subtasks vs checklist:** **Linked subtasks** are separate `Task` rows (`parentTaskId`). A **checklist** is a `TaskAttachment` of type `checklist` (plain items inside the attachment payload, not separate tasks).

#### Overdue badge (“Dragging for N days”)

Shown on a task tile when **all** of the following hold:

1. `Task.overdueCount > 0` (increments when the user **postpones** the due date forward via `TaskOverdueRules.recordPostpone`).
2. `Task.dueDate` is set.
3. The task’s due date is **not** the same calendar day as the **dashboard selected day**.

`N` is `overdueCount`, not “days since deadline.” The counter does **not** increase automatically each night without a postpone action.

#### 3.2.1 Task attachments (local)

Stored as `TaskAttachment` in Isar (`taskId`, `type`, `payloadJson`, optional `label`, `sortOrder`). Multiple attachments per task. Images are copied into app documents (`AttachmentFileStore`).

| Type | Add flow | View / interact |
|------|----------|-----------------|
| **Contact** | Choosing type opens the **device contact picker** immediately; full contact re-fetched after pick (`flutter_contacts`) | Name in header; tap phone (call), SMS, or email |
| **Image** | Gallery pick; **preview** in add sheet | Tap thumbnail → full-screen viewer |
| **URL** | Title + URL fields | **Clickable title** in tile header (opens browser); compact single-row layout |
| **Location** | Optional place name; **OSM map picker** with **Nominatim search** and reverse geocode on map tap; lat/lng fields; current location | **Place title** from Nominatim `display_name` (`placeName` in payload); coords in small text; **«Open in maps»** button (`map_launcher`, coords only) |
| **Note** | Title + body | Title in header; body in tile |
| **Checklist** | Title; items with **+** next to input; pending line saved on Save without pressing + | Checkboxes in tile; progress badge on parent when applicable |

**Location note:** External map apps (Google Maps, Yandex, etc.) cannot return a picked point to third-party apps without Google Places SDK and an API key. Coordinates are saved via the in-app OpenStreetMap picker.

### 3.3 Notifications and widgets

| Requirement | Status | Notes |
|-------------|--------|-------|
| Push: meeting reminders (15/30 min before) | **Planned** | Channels defined; scheduling TBD |
| Push: morning/evening task digest | **Planned** | |
| Android home widget: day schedule + focus tasks + complete from widget | **Planned** | Stubs: `android_widget_provider.dart` |
| Background check for overdue tasks | **Partial** | `workmanager` registered; postpone/notify logic TODO |

---

## 4. Non-functional requirements

| Area | Choice |
|------|--------|
| Cross-platform | Flutter (primary target: Android; iOS structure prepared) |
| Local storage | **Isar** (offline-first tasks and categories) |
| State management | **flutter_bloc** |
| Architecture | Feature-driven Clean Architecture (`data` / `domain` / `presentation`) |
| Calendar on device | `device_calendar` |
| Local notifications | `flutter_local_notifications` + `timezone` |
| Theming | **System light/dark** — `ThemeMode.system`, Material 3 light + dark (`AppTheme`) |
| Future AI modules | Keep domain layer free of UI/framework deps where possible |

**Platform note:** Isar does **not** support Web. Run on Android/iOS/desktop, not Chrome.

---

## 5. Dashboard (current UX)

### Date navigation

- **Date bar:** previous / next day, tap to open date picker, “Today” shortcut; horizontal week strip with activity dots (calendar = primary/calendar color, local tasks = secondary).
- **Default day:** today.
- **Calendar events** and **tasks** both respect the selected day.

### Calendar events

- Horizontal scroll cards for the selected day.
- Section title reflects the day (e.g. “Events today” vs dated label).
- Banner when permissions or calendar selection is missing.

### Tasks

- **`DashboardLoaded.overdueTasks`:** when the selected day is today, the dashboard state includes root uncompleted tasks whose `dueDate` is strictly before today (for a dedicated overdue section in UI); empty on any other selected day.
- **One full-width tile per row** (`TaskExpandableTile`).
- **Collapsed:** bold title, description preview (up to 2 lines, ellipsis), badges (priority, due date, overdue if applicable), checkbox to complete.
- **Expanded (tap tile):** smooth vertical animation; **linked subtasks**; **attachments** (see §3.2.1); full description; detail lines; **actions:**
  - **“Tomorrow”** — `PostponeTaskToNextDay` relative to the selected dashboard day.
  - **“Postpone”** — `PostponeTaskSheet`: quick tomorrow or pick another date.
- **Collapsed:** optional subtask progress badge (e.g. `2/5`) when the task has subtasks.
- **Reopen completed task:** subtask titles are copied; all subtasks start unchecked.
- **FAB (+):** create task sheet; default due date = selected dashboard day.
- After postpone: snackbar with the new due date; task may leave the list if the new due date is outside the selected day.
- Empty state copy depends on selected day.

### App bar

| Action | Purpose |
|--------|---------|
| Completed tasks (✓) | Archive of completed tasks; reopen as new task |
| Calendars | Select device calendars |
| Refresh | Reload dashboard data |

### Completed tasks screen

- List of completed tasks (newest first by `createDate`).
- **Reopen:** creates a **new** uncompleted task (same title, description, priority, category) with a user-chosen due date; completed record unchanged.
- Returning to dashboard refreshes the task list if any task was reopened.

### Appearance

- Follows **device theme** (light / dark / system setting).

---

## 6. Out of scope (MVP)

- Google Tasks API sync
- Full Google Calendar OAuth write access
- Cloud sync / multi-device backup
- AI scheduling assistant
- In-app manual theme override (system only for now)
- Automatic nightly task rollover without user action (planned via background job)

---

## 7. Revision history

| Date | Change |
|------|--------|
| 2026-05 | Initial PRD (Russian) |
| 2026-05 | Translated to English; aligned with implemented MVP |
| 2026-05 | Dashboard date filter, completed/reopen, expandable tiles, system theme |
| 2026-05 | Manual postpone UI; overdue badge rules documented |
| 2026-05 | Embedded subtasks on tasks (checklist, dashboard + create flow) |
| 2026-05 | Link existing tasks as child subtasks via `parentTaskId` |
| 2026-05 | Local `TaskAttachment` types (contact, image, URL, location, note, checklist) |
| 2026-05 | Attachment UX: device contacts, OSM place search, map-app chooser (coords only), image preview, compact URL tile |
| 2026-05 | Checklist as attachment only (removed embedded subtasks on `Task`) |
