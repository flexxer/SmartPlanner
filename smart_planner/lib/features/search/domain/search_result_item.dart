import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

enum SearchResultKind { task, event }

/// One row in global search results.
class SearchResultItem {
  const SearchResultItem._({
    required this.kind,
    this.task,
    this.event,
    this.parentTitle,
  });

  factory SearchResultItem.task({
    required Task task,
    String? parentTitle,
  }) {
    return SearchResultItem._(
      kind: SearchResultKind.task,
      task: task,
      parentTitle: parentTitle,
    );
  }

  factory SearchResultItem.event({required CalendarEvent event}) {
    return SearchResultItem._(
      kind: SearchResultKind.event,
      event: event,
    );
  }

  final SearchResultKind kind;
  final Task? task;
  final CalendarEvent? event;
  final String? parentTitle;

  Id get recordId => kind == SearchResultKind.task ? task!.id : event!.id;

  String get title =>
      kind == SearchResultKind.task ? task!.title : event!.title;

  DateTime? get sortDate => switch (kind) {
        SearchResultKind.task => task?.dueDate ?? task?.createDate,
        SearchResultKind.event => event?.start,
      };
}
