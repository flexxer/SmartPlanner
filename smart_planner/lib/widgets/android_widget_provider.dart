/// Точка интеграции Android home screen widget (PRD §3.3).
///
/// Реализация через platform channel / home_widget — отдельным этапом.
abstract class AndroidWidgetProvider {
  static Future<void> updateWidgetData({
    required String scheduleSummary,
    required List<String> focusTaskTitles,
  }) async {
    // TODO: platform channel
  }
}
