import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/search/domain/search_result_item.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Case-insensitive search across local tasks and calendar events.
class GlobalSearchService {
  GlobalSearchService({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<SearchResultItem>> search(String query) async {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const <SearchResultItem>[];
    }

    final List<Task> tasks = await _db.tasks.where().findAll();
    final List<CalendarEvent> events = await _db.calendarEvents.where().findAll();
    final Map<Id, Task> tasksById = <Id, Task>{
      for (final Task task in tasks) task.id: task,
    };

    final List<SearchResultItem> results = <SearchResultItem>[];

    for (final Task task in tasks) {
      if (!task.title.toLowerCase().contains(needle) &&
          !(task.description ?? '').toLowerCase().contains(needle)) {
        continue;
      }
      String? parentTitle;
      final Id? parentId = task.parentTaskId;
      if (parentId != null) {
        parentTitle = tasksById[parentId]?.title;
      }
      results.add(
        SearchResultItem.task(
          task: task,
          parentTitle: parentTitle,
        ),
      );
    }

    for (final CalendarEvent event in events) {
      if (!event.title.toLowerCase().contains(needle)) {
        continue;
      }
      results.add(SearchResultItem.event(event: event));
    }

    results.sort(_compareResults);
    return results;
  }

  int _compareResults(SearchResultItem a, SearchResultItem b) {
    final DateTime? dateA = a.sortDate;
    final DateTime? dateB = b.sortDate;
    if (dateA == null && dateB == null) {
      return a.title.compareTo(b.title);
    }
    if (dateA == null) {
      return 1;
    }
    if (dateB == null) {
      return -1;
    }
    final int byDate = dateB.compareTo(dateA);
    if (byDate != 0) {
      return byDate;
    }
    return a.title.compareTo(b.title);
  }
}
