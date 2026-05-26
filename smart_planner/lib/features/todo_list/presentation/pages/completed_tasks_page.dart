import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/bloc/completed_tasks_bloc.dart';
import 'package:smart_planner/features/todo_list/presentation/bloc/completed_tasks_event.dart';
import 'package:smart_planner/features/todo_list/presentation/bloc/completed_tasks_state.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/reopen_task_sheet.dart';

/// Archive of completed tasks with reopen flow.
///
/// No longer linked from the dashboard AppBar; completed tasks for the
/// selected day appear in the dashboard list. Kept for a possible dedicated
/// archive or reopen entry point later.
@Deprecated(
  'Not routed from the dashboard. Use the dashboard completed section or '
  'reopen via TodoRepository.reopenFromCompleted when a new entry is added.',
)
class CompletedTasksPage extends StatelessWidget {
  const CompletedTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompletedTasksBloc>(
      create: (BuildContext context) => CompletedTasksBloc(
        repository: context.read<TodoRepository>(),
      )..add(const LoadCompletedTasks()),
      child: const _CompletedTasksView(),
    );
  }
}

class _CompletedTasksView extends StatefulWidget {
  const _CompletedTasksView();

  @override
  State<_CompletedTasksView> createState() => _CompletedTasksViewState();
}

class _CompletedTasksViewState extends State<_CompletedTasksView> {
  bool _reopenedDuringVisit = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_reopenedDuringVisit);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('completed_page_title'.tr()),
        ),
        body: BlocConsumer<CompletedTasksBloc, CompletedTasksState>(
        listenWhen: (CompletedTasksState prev, CompletedTasksState next) =>
            next is CompletedTasksLoaded &&
            next.lastReopenedTaskId != null &&
            (prev is! CompletedTasksLoaded ||
                prev.lastReopenedTaskId != next.lastReopenedTaskId),
        listener: (BuildContext context, CompletedTasksState state) {
          if (state is CompletedTasksLoaded &&
              state.lastReopenedTaskId != null) {
            setState(() => _reopenedDuringVisit = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('completed_task_created'.tr())),
            );
          }
        },
        builder: (BuildContext context, CompletedTasksState state) {
          return switch (state) {
            CompletedTasksInitial() ||
            CompletedTasksLoading() =>
              const Center(child: CircularProgressIndicator()),
            CompletedTasksError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context
                    .read<CompletedTasksBloc>()
                    .add(const LoadCompletedTasks()),
              ),
            CompletedTasksReopening(:final tasks) ||
            CompletedTasksLoaded(:final tasks) =>
              _CompletedTasksList(
                tasks: tasks,
                busy: state is CompletedTasksReopening,
              ),
          };
        },
      ),
      ),
    );
  }
}

class _CompletedTasksList extends StatelessWidget {
  const _CompletedTasksList({
    required this.tasks,
    required this.busy,
  });

  final List<Task> tasks;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'completed_empty_body'.tr(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        RefreshIndicator(
          onRefresh: () async {
            context.read<CompletedTasksBloc>().add(const LoadCompletedTasks());
            await context.read<CompletedTasksBloc>().stream.firstWhere(
                  (CompletedTasksState s) => s is! CompletedTasksLoading,
                );
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1, indent: 16),
            itemBuilder: (BuildContext context, int index) {
              final Task task = tasks[index];
              return _CompletedTaskTile(
                task: task,
                onReopen: busy ? null : () => _reopen(context, task),
              );
            },
          ),
        ),
        if (busy)
          const ColoredBox(
            color: Color(0x33000000),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  static Future<void> _reopen(BuildContext context, Task task) async {
    final DateTime? newDueDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          ReopenTaskSheet(sourceTask: task),
    );
    if (newDueDate == null || !context.mounted) {
      return;
    }

    context.read<CompletedTasksBloc>().add(
          ReopenCompletedTask(
            sourceTaskId: task.id,
            newDueDate: newDueDate,
          ),
        );
  }
}

class _CompletedTaskTile extends StatelessWidget {
  const _CompletedTaskTile({
    required this.task,
    required this.onReopen,
  });

  final Task task;
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? dueLabel = task.dueDate != null
        ? L10n.dateFormat('d MMM yyyy', context: context).format(task.dueDate!)
        : null;

    return ListTile(
      leading: Icon(
        Icons.check_circle,
        color: colors.primary.withValues(alpha: 0.6),
      ),
      title: Text(
        task.title,
        style: theme.textTheme.titleMedium?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: colors.onSurfaceVariant,
        ),
      ),
      subtitle: dueLabel != null
          ? Text(
              'due_was_label'.tr(
                namedArgs: <String, String>{'date': dueLabel},
              ),
            )
          : Text('no_due_date'.tr()),
      trailing: IconButton(
        icon: const Icon(Icons.replay),
        tooltip: 'completed_reopen_tooltip'.tr(),
        onPressed: onReopen,
      ),
      onTap: onReopen,
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text('common_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
