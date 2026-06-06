# DayLinx

**DayLinx** combines **device calendars** and **local tasks** in one day view (overdue block, week activity dots, attachments, postpone, deep links). Flutter app package lives in [`smart_planner/`](smart_planner/) (legacy folder name).

**Source repository:** [github.com/flexxer/SmartPlanner](https://github.com/flexxer/SmartPlanner)

## Documentation

| Document | Description |
|----------|-------------|
| [PRD_PRODUCT_SPEC.md](PRD_PRODUCT_SPEC.md) | Product requirements and current UX |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Architecture, folder tree, key components |
| [ANDROID_LOCK_SCREEN_WIDGET.md](ANDROID_LOCK_SCREEN_WIDGET.md) | Lock screen widget spec (variant 1 «Pulse», planned) |
| [AGENT_HANDOFF_PROMPT.md](AGENT_HANDOFF_PROMPT.md) | Copy-paste prompt for a new Cursor agent session |
| [smart_planner/README.md](smart_planner/README.md) | Build, run, and test instructions |
| [smart_planner/DEVICE_CALENDAR.md](smart_planner/DEVICE_CALENDAR.md) | Device calendar read/write behavior |

## Quick start

```bash
cd smart_planner
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**Note:** Do not target Web (Isar). Use Android or iOS.

## AI / Cursor

See [.cursorrules](.cursorrules) and `PROJECT_STRUCTURE.md` for coding conventions.
