/// Приоритет задачи для сортировки списка (выше — важнее).
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

extension TaskPrioritySort on TaskPriority {
  /// Чем больше значение, тем выше приоритет в списке.
  int get sortWeight => index;
}
