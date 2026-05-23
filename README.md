# Smart Planner (Smart Time & Task Linker)

Mobile planner: **device calendars** + **local tasks** (day view, overdue block, week activity dots, attachments, postpone, completed archive). Flutter app lives in [`smart_planner/`](smart_planner/).

**Source repository:** [github.com/flexxer/SmartPlanner](https://github.com/flexxer/SmartPlanner)

## Documentation

| Document | Description |
|----------|-------------|
| [PRD_PRODUCT_SPEC.md](PRD_PRODUCT_SPEC.md) | Product requirements and current UX |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Architecture, folder tree, key components |
| [smart_planner/README.md](smart_planner/README.md) | Build, run, and test instructions |

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
