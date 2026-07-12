import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/categories/data/category_repository_impl.dart';
import 'package:smart_planner/features/categories/domain/category_filter_utils.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';
import 'package:smart_planner/features/search/domain/search_result_item.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Case-insensitive search across local tasks and calendar events.
class GlobalSearchService {
  GlobalSearchService({
    Isar? isar,
    CategoryTagService? categoryTagService,
  })  : _isar = isar,
        _categoryTagService = categoryTagService ?? CategoryTagService(isar: isar);

  final Isar? _isar;
  final CategoryTagService _categoryTagService;

  Isar get _db => _isar ?? IsarDatabase.instance;

  Future<List<SearchResultItem>> search(
    String query, {
    List<Id> categoryIds = const <Id>[],
  }) async {
    final String needle = query.trim().toLowerCase();
    final bool hasText = needle.isNotEmpty;
    final bool hasCategory = categoryIds.isNotEmpty;
    if (!hasText && !hasCategory) {
      return const <SearchResultItem>[];
    }

    final List<Task> tasks = await _db.tasks.where().findAll();
    final List<CalendarEvent> events = await _db.calendarEvents.where().findAll();
    final Map<Id, Task> tasksById = <Id, Task>{
      for (final Task task in tasks) task.id: task,
    };

    Map<int, List<Id>> taskTagIdsByEntity = const <int, List<Id>>{};
    Map<int, List<Id>> eventTagIdsByEntity = const <int, List<Id>>{};
    if (hasCategory) {
      taskTagIdsByEntity = await _categoryTagService.getTagIdsForEntities(
        entityType: TaggedEntityType.task,
        entityIds: tasks.map((Task task) => task.id),
      );
      eventTagIdsByEntity = await _categoryTagService.getTagIdsForEntities(
        entityType: TaggedEntityType.calendarEvent,
        entityIds: events.map((CalendarEvent event) => event.id),
      );
    }

    final List<SearchResultItem> results = <SearchResultItem>[];

    for (final Task task in tasks) {
      if (hasText &&
          !task.title.toLowerCase().contains(needle) &&
          !(task.description ?? '').toLowerCase().contains(needle)) {
        continue;
      }
      if (hasCategory &&
          !CategoryFilterUtils.matchesAnySelectedCategory(
            entityId: task.id,
            selectedCategoryIds: categoryIds,
            tagIdsByEntityId: taskTagIdsByEntity,
          )) {
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
      if (hasText && !event.title.toLowerCase().contains(needle)) {
        continue;
      }
      if (hasCategory &&
          !CategoryFilterUtils.matchesAnySelectedCategory(
            entityId: event.id,
            selectedCategoryIds: categoryIds,
            tagIdsByEntityId: eventTagIdsByEntity,
          )) {
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
