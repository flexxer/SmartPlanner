import 'package:isar/isar.dart';

@Deprecated('Only used by deprecated [CompletedTasksBloc].')
sealed class CompletedTasksEvent {
  const CompletedTasksEvent();
}

final class LoadCompletedTasks extends CompletedTasksEvent {
  const LoadCompletedTasks();
}

final class ReopenCompletedTask extends CompletedTasksEvent {
  const ReopenCompletedTask({
    required this.sourceTaskId,
    required this.newDueDate,
  });

  final Id sourceTaskId;
  final DateTime newDueDate;
}
