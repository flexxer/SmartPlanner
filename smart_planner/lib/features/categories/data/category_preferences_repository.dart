import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted dashboard category filter selection.
class CategoryPreferencesRepository {
  CategoryPreferencesRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _dashboardFilterKey = 'dashboard_category_filter_ids';

  final Future<SharedPreferences> _preferencesFuture;

  Future<List<Id>> getDashboardFilterCategoryIds() async {
    final SharedPreferences prefs = await _preferencesFuture;
    final List<String>? stored = prefs.getStringList(_dashboardFilterKey);
    if (stored == null || stored.isEmpty) {
      return const <Id>[];
    }
    return stored.map(int.parse).toList(growable: false);
  }

  Future<void> saveDashboardFilterCategoryIds(List<Id> ids) async {
    final SharedPreferences prefs = await _preferencesFuture;
    if (ids.isEmpty) {
      await prefs.remove(_dashboardFilterKey);
      return;
    }
    await prefs.setStringList(
      _dashboardFilterKey,
      ids.map((Id id) => id.toString()).toList(growable: false),
    );
  }
}
