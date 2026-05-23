import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/bloc/completed_tasks_event.dart';
import 'package:smart_planner/features/todo_list/presentation/bloc/completed_tasks_state.dart';

class CompletedTasksBloc
    extends Bloc<CompletedTasksEvent, CompletedTasksState> {
  CompletedTasksBloc({required TodoRepository repository})
      : _repository = repository,
        super(const CompletedTasksInitial()) {
    on<LoadCompletedTasks>(_onLoad);
    on<ReopenCompletedTask>(_onReopen);
  }

  final TodoRepository _repository;

  Future<void> _onLoad(
    LoadCompletedTasks event,
    Emitter<CompletedTasksState> emit,
  ) async {
    emit(const CompletedTasksLoading());
    try {
      final List<Task> tasks = await _repository.getCompletedTasks();
      emit(CompletedTasksLoaded(tasks: tasks));
    } catch (error) {
      emit(CompletedTasksError(error.toString()));
    }
  }

  Future<void> _onReopen(
    ReopenCompletedTask event,
    Emitter<CompletedTasksState> emit,
  ) async {
    final CompletedTasksState current = state;
    if (current is! CompletedTasksLoaded) {
      return;
    }

    emit(CompletedTasksReopening(current.tasks));

    try {
      final Task? source = await _repository.getTaskById(event.sourceTaskId);
      if (source == null || !source.isCompleted) {
        emit(const CompletedTasksError('Задача не найдена'));
        add(const LoadCompletedTasks());
        return;
      }

      final Task created = await _repository.reopenFromCompleted(
        source,
        event.newDueDate,
      );

      final List<Task> tasks = await _repository.getCompletedTasks();
      emit(
        CompletedTasksLoaded(
          tasks: tasks,
          lastReopenedTaskId: created.id,
        ),
      );
    } catch (error) {
      emit(CompletedTasksError(error.toString()));
      add(const LoadCompletedTasks());
    }
  }
}
