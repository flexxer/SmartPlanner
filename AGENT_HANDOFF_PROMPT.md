# Prompt for new Cursor agent window

Copy everything below the line into a new chat.

---

## Prompt (copy from here)

You are continuing work on **DayLinx** (Flutter app in `smart_planner/`, repo root `SmartPlanner/`).

### Read first
1. `REFACTORING_ROADMAP.md` — sprints A–E done  
2. `PROJECT_STRUCTURE.md` — architecture  
3. `PRD_PRODUCT_SPEC.md` — product status  
4. `smart_planner/DEVICE_CALENDAR.md` — device calendar only (no OAuth)

### What is already done
- Phases 0–5 + **Sprints A–E** (write-back, widget, templates, product polish)  
- Device calendar read/write, `VisibleCalendarEventsMerger` (selected calendars + recurring expansion), recurring task rules, morning/evening digest WM  
- Dashboard UX fixes (2026-06-04): disabled calendars hidden, week strip counts, now line before first event — see `DEVICE_CALENDAR.md`  
- ~90 tests pass (`flutter test`)

### Your task (default)
Only if the user asks — **Sprint F** cloud sync is deferred. Otherwise fix bugs or small features they specify.

### Rules
- Minimize scope; match existing code style  
- Do **not** re-add Google Calendar API unless explicitly asked  
- Do **not** commit unless asked  
- Run `flutter test` before finishing  

## End of prompt
