/// Where a task row appears — drives which metadata badges are shown.
enum TaskTileListContext {
  /// Due-date section for the selected dashboard day.
  dashboardDueOnSelectedDay,

  /// Backlog (no due date) section.
  dashboardBacklog,

  /// Overdue expansion panel.
  dashboardOverdue,

  /// Task detail screen (full metadata, fewer duplicates).
  detail,
}
