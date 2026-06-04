# Android home screen widget — design sketch (DayLinx)

> **Status:** **Implemented (MVP)** — medium 4×2 widget via `DayLinxWidgetProvider` + `DayStatusHomeWidgetService`. Large widget and checkbox toggle = phase 2.  
> **Goal:** Same mental model as the **day-status notification**, but richer: scannable layout, short lists, tap targets, optional complete-from-widget (PRD §3.3).

---

## 1. Relationship to the notification

| Notification (compact) | Widget (expanded) |
|------------------------|-----------------|
| Title: task progress or plain “Today's plan” | Header + **progress bar** + `✓ done / total` |
| Body line 1: current or next **one** event | **Now** card + **next 2–3** events with times |
| Body line 2: backlog count (if > 0) | **Backlog** section: count + **top 2–3** task titles |
| — | **Due today**: up to **5** tasks with **checkbox** |
| — | **Overdue** chip + count (today only) |
| Open action | Tap zones: app, event, task toggle, “+ task” |

Data should reuse the same loaders as `DayStatusNotificationController` / `DayStatusNotificationBuilder`, plus small list slices from `TodoRepository` and `TaskOverdueSelection`.

---

## 2. Widget sizes (Android)

Recommend **two** providers (user picks on home screen):

| Size | Grid (dp guideline) | Role |
|------|---------------------|------|
| **Medium** | 4×2 (~250×110 dp) | Default; fits notification++ content |
| **Large** | 4×3 or 4×4 (~250×180–250 dp) | Full day snapshot + more tasks/events |

Optional later: **Small** 2×2 — only header + progress + one “next event” line (notification parity).

---

## 3. Wireframes

### 3.1 Medium — 4×2 (primary)

```text
┌─────────────────────────────────────────────────────────────┐
│ DayLinx · Ср, 26 мая                              ↻  [+]  │  ← tap app / refresh / add task
├─────────────────────────────────────────────────────────────┤
│ Планы на сегодня          ✓ 2 / 5                          │
│ ████████░░░░░░░░░░  40%                                     │  ← progress bar (hide if total=0)
├─────────────────────────────────────────────────────────────┤
│ ● СЕЙЧАС  11:00–19:00                                       │  ← accent bar (calendar color)
│   Репетиция                                                 │
├─────────────────────────────────────────────────────────────┤
│   15:00  Stand-up                                           │  ← next event (max 1 on medium)
│   20:00  Ужин с командой                                    │
├─────────────────────────────────────────────────────────────┤
│ Задачи на сегодня                                           │
│ ☐ Подготовить слайды                              [high]    │  ← checkbox → toggle complete
│ ☑ Отправить отчёт                                 (done)    │
│ ☐ Созвон с клиентом                                         │
├─────────────────────────────────────────────────────────────┤
│ Без срока: 3  ·  Просрочено: 1                    Открыть → │  ← backlog + overdue summary
└─────────────────────────────────────────────────────────────┘
```

**Rules (medium):**

- Hide `✓ 0 / 0` and progress bar when `total == 0` (same as notification title rule).
- **Now** block: same logic as `DayStatusNotificationBuilder._eventLine` (current event).
- **Next** lines: following events today (cap at 1–2 on medium).
- **Due today**: uncompleted dated tasks for today, root only, priority sort, max 3 rows.
- **Footer**: backlog count + overdue count (if today); tap “Открыть” → dashboard today.

### 3.2 Large — 4×3 / 4×4

```text
┌─────────────────────────────────────────────────────────────┐
│ DayLinx · Сегодня, 26 мая                         ↻  [+]  │
├─────────────────────────────────────────────────────────────┤
│ ✓ 2 / 5 задач    ████████░░░░░░░░░░                          │
├──────────────────────────┬──────────────────────────────────┤
│ СОБЫТИЯ                 │ ЗАДАЧИ НА СЕГОДНЯ                 │
│ ● 11:00–19:00 Репетиция │ ☐ Подготовить слайды      [high]  │
│   15:00 Stand-up        │ ☐ Созвон с клиентом               │
│   20:00 Ужин            │ ☑ Отправить отчёт                 │
│   —                     │ ☐ Купить подарок                  │
│                         │ ☐ … ещё 2                         │
├──────────────────────────┴──────────────────────────────────┤
│ ПРОСРОЧЕНО (1)                                              │
│ ☐ Оплатить счёт · просрочено 2 дн.                          │
├─────────────────────────────────────────────────────────────┤
│ БЕЗ СРОКА (3)                                               │
│   Идея для блога · Настроить бэкап · Позвонить маме         │
└─────────────────────────────────────────────────────────────┘
```

**Large extras:**

- Two-column layout on wide resizes; single column on narrow.
- Up to **5** due-today tasks + “+N more”.
- **Overdue** block (today only), 1–2 rows with overdue badge text.
- **Backlog**: count + up to **3** titles (no checkbox in v1 — tap opens app on backlog section).

### 3.3 Small — 2×2 (optional, phase 2)

```text
┌──────────────────────┐
│ DayLinx · Сегодня    │
│ ✓ 2/5  ████░░░░      │
│ Сейчас: Репетиция    │
│ до 19:00             │
│ Без срока: 3    →    │
└──────────────────────┘
```

---

## 4. Visual language

Align with **dashboard** and **notification**, not a new design system.

| Element | Treatment |
|---------|-----------|
| Header | App name + short date (`d MMM` / “Сегодня”) |
| Progress | `LinearProgressIndicator` style; `done/total` text; hidden when `total == 0` |
| Now event | Left **4 dp** accent bar = `CalendarContextColors` / event calendar color |
| Next events | Muted `bodySmall`, time + title |
| Task row | Leading **checkbox** (48 dp touch on large; 40 dp medium) |
| Priority | Small chip: reuse `TaskPriorityUi` colors (dot or label) |
| Overdue | `error` container chip in footer or section |
| Empty states | “Нет событий”, “Нет задач на сегодня” — same keys as notification/dashboard |

**Dark/light:** follow system; RemoteViews/Glance use theme-aware colors from `AppTheme` palette (no hardcoded hex in spec).

---

## 5. Data model (widget payload)

Single JSON/blob updated when dashboard loads or on periodic refresh:

```json
{
  "updatedAt": "2026-05-26T14:30:00",
  "dateLabel": "Сегодня, 26 мая",
  "tasksDone": 2,
  "tasksTotal": 5,
  "events": [
    { "id": 1, "title": "Репетиция", "start": "11:00", "end": "19:00", "status": "current", "colorArgb": 4280391411 },
    { "id": 2, "title": "Stand-up", "start": "15:00", "end": "15:30", "status": "future", "colorArgb": 4280391411 }
  ],
  "dueTodayTasks": [
    { "id": 10, "title": "Подготовить слайды", "completed": false, "priority": 2, "overdueDays": 0 }
  ],
  "overdueTasks": [
    { "id": 99, "title": "Оплатить счёт", "overdueDays": 2 }
  ],
  "backlogCount": 3,
  "backlogPreview": ["Идея для блога", "Настроить бэкап", "Позвонить маме"]
}
```

**Builder (Dart):** extend or mirror `DayStatusNotificationBuilder` → `DayStatusWidgetPayloadBuilder` in `features/notifications/domain/` or `features/dashboard/domain/`.

| Field | Source |
|-------|--------|
| `tasksDone` / `tasksTotal` | `getCompletedTasksForDate(today)` + `getUncompletedTasksForDate(today)` |
| `events` | Same as notification: device upsert + `RecurrenceEvaluator` + `EventTimeStatusResolver` |
| `dueTodayTasks` | `getUncompletedTasksForDate(today)`, root, sorted by priority, `take(5)` |
| `overdueTasks` | `getOverdueUncompletedTasks()` if today |
| `backlogCount` / `backlogPreview` | `getUndatedTasks()`, `take(3)` titles |

---

## 6. Interactions

| Tap target | Action |
|------------|--------|
| Widget background (header) | `daylinx://` or `MainActivity` → dashboard **today** |
| Refresh icon | `Workmanager` / immediate reload payload |
| `[+]` | `daylinx://create?type=task` |
| Event row | Deep link or `EventDetailScreen` via `eventId` extra |
| Task checkbox | `ToggleTaskCompletion` via background `Isar` + widget update (PRD) |
| “Без срока: N” / backlog rows | Dashboard scroll to backlog section (intent extra) |
| “Просрочено” | Dashboard with overdue expanded |

**Checkbox:** requires `PendingIntent` + `BroadcastReceiver` or `home_widget` callback; sync widget after write.

---

## 7. Refresh strategy

| Trigger | Interval |
|---------|----------|
| `DashboardBloc` after `DashboardLoaded` | Immediate (same as notification sync) |
| Periodic | Every **15–30 min** while today (battery) |
| Midnight | Reschedule + clear stale payload |
| User refresh icon | On demand |

Use `Workmanager` (already stubbed) or `AlarmManager` for periodic updates when app not in foreground.

---

## 8. Implementation path (suggested)

1. **`DayStatusWidgetPayloadBuilder`** + unit tests (mirror notification tests).
2. **`AndroidWidgetProvider.updateWidgetData`** → `home_widget` or platform channel writing SharedPreferences / `Glance`.
3. **Android:** Jetpack **Glance** (Compose) *or* classic **RemoteViews** XML (`res/layout/widget_day_medium.xml`).
4. Wire **`DashboardBloc`** + **`DayStatusNotificationController.syncTodayStatus()`** to also call `updateWidgetData`.
5. Phase 2: checkbox `BroadcastReceiver`, large widget, resize layouts.

**Glance vs RemoteViews:** Glance easier for progress + lists; RemoteViews better understood for checkbox lists. PRD mentions complete-from-widget — plan **RemoteViews + `CheckBox`** or Glance `Checkbox` with `ActionCallback`.

---

## 9. Localization

Reuse existing keys where possible:

| UI | Key |
|----|-----|
| Plain header | `day_status_notification_title_plain` |
| Progress title | `day_status_notification_title` |
| Now / next event | `day_status_notification_now`, `_next` |
| No events | `day_status_notification_no_events` |
| Backlog footer | `day_status_notification_backlog`, `backlog_section` |
| Section “Due today” | `dashboard_due_section_today` |
| Overdue | `overdue_section` |

Add widget-only keys if needed: `widget_refresh`, `widget_add_task`, `widget_more_tasks` (`+{count} more`).

---

## 10. Open questions

1. **Medium vs large default** — ship medium first?
2. **Complete from widget in v1** — or read-only v1, checkboxes in v2?
3. **Backlog checkboxes** — omit in v1 (notification only shows count).
4. **Widget pin** — separate from notification pin; N/A on home screen.
5. **iOS** — `ios_widget_bridge.dart` later; same payload builder.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-05 | Initial sketch aligned with day-status notification and dashboard sections |
