import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

@Deprecated('Only used by deprecated [CompletedTasksBloc].')
sealed class CompletedTasksState {
  const CompletedTasksState();
}

final class CompletedTasksInitial extends CompletedTasksState {
  const CompletedTasksInitial();
}

final class CompletedTasksLoading extends CompletedTasksState {
  const CompletedTasksLoading();
}

final class CompletedTasksLoaded extends CompletedTasksState {
  const CompletedTasksLoaded({
    required this.tasks,
    this.lastReopenedTaskId,
  });

  final List<Task> tasks;

  /// ID только что созданной задачи (для обновления дашборда).
  final int? lastReopenedTaskId;

  CompletedTasksLoaded copyWith({
    List<Task>? tasks,
    int? lastReopenedTaskId,
    bool clearLastReopened = false,
  }) {
    return CompletedTasksLoaded(
      tasks: tasks ?? this.tasks,
      lastReopenedTaskId: clearLastReopened
          ? null
          : (lastReopenedTaskId ?? this.lastReopenedTaskId),
    );
  }
}

final class CompletedTasksError extends CompletedTasksState {
  const CompletedTasksError(this.message);

  final String message;
}

final class CompletedTasksReopening extends CompletedTasksState {
  const CompletedTasksReopening(this.tasks);

  final List<Task> tasks;
}
