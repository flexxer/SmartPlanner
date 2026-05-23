import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/calendar_settings_page.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/pages/completed_tasks_page.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/create_task_sheet.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/add_attachment_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/link_task_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/postpone_task_sheet.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_expandable_tile.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_week_date_strip.dart';

/// Главный экран: события календаря на сегодня и список задач.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final DateFormat _timeFormat = DateFormat.Hm();
  static final DateFormat _dayTitleFormat = DateFormat('d MMMM', 'ru');
  static final DateFormat _dayShortFormat = DateFormat('d MMM', 'ru');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Planner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.task_alt),
            tooltip: 'Выполненные задачи',
            onPressed: () => _openCompletedTasks(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Выбор календарей',
            onPressed: () => _openCalendarSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () =>
                context.read<DashboardBloc>().add(const LoadDashboardData()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTask(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (BuildContext context, DashboardState state) {
          return switch (state) {
            DashboardInitial() || DashboardLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DashboardError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context
                    .read<DashboardBloc>()
                    .add(const LoadDashboardData()),
              ),
            DashboardLoaded(
              :final tasks,
              :final overdueTasks,
              :final events,
              :final selectedDate,
              :final calendarMessage,
              :final childTasksByParentId,
              :final attachmentsByTaskId,
              :final dayMarkers,
            ) =>
              RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _DateSelectorBar(
                        selectedDate: selectedDate,
                        dayShortFormat: _dayShortFormat,
                        dayMarkers: dayMarkers,
                      ),
                    ),
                    if (calendarMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: MaterialBanner(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            content: Text(calendarMessage),
                            leading: const Icon(Icons.info_outline),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => _openCalendarSettings(context),
                                child: const Text('Календари'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _DayEventsSection(
                        selectedDate: selectedDate,
                        events: events,
                        timeFormat: _timeFormat,
                        dayTitleFormat: _dayTitleFormat,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    if (overdueTasks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _OverdueTasksPanel(
                          overdueTasks: overdueTasks,
                          selectedDate: selectedDate,
                          childTasksByParentId: childTasksByParentId,
                          attachmentsByTaskId: attachmentsByTaskId,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          _tasksSectionTitle(selectedDate),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    _TasksSliver(
                      tasks: tasks,
                      selectedDate: selectedDate,
                      childTasksByParentId: childTasksByParentId,
                      attachmentsByTaskId: attachmentsByTaskId,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  static String _tasksSectionTitle(DateTime selectedDate) {
    if (AppDateUtils.isToday(selectedDate)) {
      return 'Мои задачи на сегодня';
    }
    return 'Мои задачи на ${_dayTitleFormat.format(selectedDate)}';
  }

  static Future<void> _openCreateTask(BuildContext context) async {
    final DashboardState blocState = context.read<DashboardBloc>().state;
    final DateTime initialDueDate = blocState is DashboardLoaded
        ? blocState.selectedDate
        : AppDateUtils.startOfDay(DateTime.now());

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => CreateTaskSheet(
        repository: sheetContext.read<TodoRepository>(),
        initialDueDate: initialDueDate,
      ),
    );
    if (created == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
    }
  }

  static Future<void> _openCompletedTasks(BuildContext context) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CompletedTasksPage(),
      ),
    );
    if (changed == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
    }
  }

  static Future<void> _openCalendarSettings(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardBloc>(),
          child: const CalendarSettingsPage(),
        ),
      ),
    );
  }

  static Future<void> _onRefresh(BuildContext context) async {
    context.read<DashboardBloc>().add(const LoadDashboardData());
    await context.read<DashboardBloc>().stream.firstWhere(
          (DashboardState s) => s is! DashboardLoading,
        );
  }

  static final DateFormat _postponeSnackFormat = DateFormat('d MMM yyyy', 'ru');

  static void postponeTaskToTomorrow(
    BuildContext context,
    Task task,
    DateTime selectedDate,
  ) {
    final DateTime tomorrow = AppDateUtils.startOfDay(selectedDate).add(
      const Duration(days: 1),
    );
    context.read<DashboardBloc>().add(PostponeTaskToNextDay(task.id));
    _showPostponeSnackBar(context, tomorrow);
  }

  static Future<void> openAddAttachmentSheet(
    BuildContext context, {
    required Task task,
  }) async {
    final TaskAttachmentRepository repository =
        context.read<TaskAttachmentRepository>();
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => AddAttachmentSheet(
        repository: repository,
        taskId: task.id,
      ),
    );
    if (added == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вложение добавлено')),
      );
    }
  }

  static Future<void> openLinkTaskSheet(
    BuildContext context, {
    required Task parentTask,
  }) async {
    final TodoRepository repository = context.read<TodoRepository>();
    final bool? linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => LinkTaskSheet(
        repository: repository,
        parentTaskId: parentTask.id,
        parentTitle: parentTask.title,
      ),
    );
    if (linked == true && context.mounted) {
      context.read<DashboardBloc>().add(const LoadDashboardData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача привязана как подзадача')),
      );
    }
  }

  static Future<void> openPostponeTask(
    BuildContext context,
    Task task,
    DateTime selectedDate,
  ) async {
    final DateTime? newDueDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => PostponeTaskSheet(
        task: task,
        referenceDate: selectedDate,
      ),
    );
    if (newDueDate == null || !context.mounted) {
      return;
    }

    context.read<DashboardBloc>().add(
          PostponeTask(taskId: task.id, newDueDate: newDueDate),
        );
    _showPostponeSnackBar(context, newDueDate);
  }

  static void _showPostponeSnackBar(BuildContext context, DateTime newDueDate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Срок перенесён на ${_postponeSnackFormat.format(newDueDate)}',
        ),
      ),
    );
  }
}

class _DateSelectorBar extends StatelessWidget {
  const _DateSelectorBar({
    required this.selectedDate,
    required this.dayShortFormat,
    required this.dayMarkers,
  });

  final DateTime selectedDate;
  final DateFormat dayShortFormat;
  final Map<int, DayActivityMarker> dayMarkers;

  @override
  Widget build(BuildContext context) {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final bool isToday = AppDateUtils.isToday(selectedDate);
    final String label = isToday
        ? 'Сегодня'
        : dayShortFormat.format(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Предыдущий день',
                onPressed: () => bloc.add(
                  SelectDashboardDate(
                    selectedDate.subtract(const Duration(days: 1)),
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickDate(context, bloc, selectedDate),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Следующий день',
                onPressed: () => bloc.add(
                  SelectDashboardDate(
                    selectedDate.add(const Duration(days: 1)),
                  ),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
              if (!isToday)
                TextButton(
                  onPressed: () => bloc.add(
                    SelectDashboardDate(DateTime.now()),
                  ),
                  child: const Text('Сегодня'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          DashboardWeekDateStrip(
            selectedDate: selectedDate,
            dayMarkers: dayMarkers,
            onDateSelected: (DateTime date) =>
                bloc.add(SelectDashboardDate(date)),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    DashboardBloc bloc,
    DateTime current,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('ru'),
    );
    if (picked != null && context.mounted) {
      bloc.add(SelectDashboardDate(picked));
    }
  }
}

class _DayEventsSection extends StatelessWidget {
  const _DayEventsSection({
    required this.selectedDate,
    required this.events,
    required this.timeFormat,
    required this.dayTitleFormat,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final DateFormat timeFormat;
  final DateFormat dayTitleFormat;

  @override
  Widget build(BuildContext context) {
    final String title = AppDateUtils.isToday(selectedDate)
        ? 'События на сегодня'
        : 'События на ${dayTitleFormat.format(selectedDate)}';
    final String emptyText = AppDateUtils.isToday(selectedDate)
        ? 'На сегодня встреч нет'
        : 'На этот день встреч нет';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(emptyText),
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                return _EventCard(
                  event: events[index],
                  timeFormat: timeFormat,
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.timeFormat,
  });

  final CalendarEvent event;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final Color calendarColor = Color(_normalizeColor(event.colorValue));
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 6, color: calendarColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${timeFormat.format(event.start)} – '
                        '${timeFormat.format(event.end)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _normalizeColor(int value) {
    if (value > 0xFFFFFF) {
      return value;
    }
    return 0xFF000000 | value;
  }
}

class _OverdueTasksPanel extends StatelessWidget {
  const _OverdueTasksPanel({
    required this.overdueTasks,
    required this.selectedDate,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
  });

  final List<Task> overdueTasks;
  final DateTime selectedDate;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int count = overdueTasks.length;
    final TextStyle? titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.error,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            dividerColor: colors.surfaceContainerHighest,
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text('Просрочено ($count)', style: titleStyle),
            iconColor: colors.error,
            collapsedIconColor: colors.error,
            children: <Widget>[
              for (final Task task in overdueTasks)
                _DashboardTaskTile(
                  task: task,
                  selectedDate: selectedDate,
                  childTasksByParentId: childTasksByParentId,
                  attachmentsByTaskId: attachmentsByTaskId,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({
    required this.task,
    required this.selectedDate,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
  });

  final Task task;
  final DateTime selectedDate;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;

  @override
  Widget build(BuildContext context) {
    final ChildTasksBundle childBundle =
        childTasksByParentId[task.id] ??
        const ChildTasksBundle(
          activeChildren: <Task>[],
          completedCount: 0,
          totalCount: 0,
        );
    final List<TaskAttachment> attachments =
        attachmentsByTaskId[task.id] ?? const <TaskAttachment>[];
    final TaskAttachmentRepository attachmentRepository =
        context.read<TaskAttachmentRepository>();

    return TaskExpandableTile(
      task: task,
      selectedDate: selectedDate,
      childTasksBundle: childBundle,
      attachments: attachments,
      attachmentRepository: attachmentRepository,
      onToggleComplete: () => context.read<DashboardBloc>().add(
            ToggleTaskCompletion(task.id),
          ),
      onPostponeToTomorrow: () => DashboardScreen.postponeTaskToTomorrow(
        context,
        task,
        selectedDate,
      ),
      onPostpone: () => DashboardScreen.openPostponeTask(
        context,
        task,
        selectedDate,
      ),
      onToggleChildComplete: (Id childId) => context
          .read<DashboardBloc>()
          .add(ToggleTaskCompletion(childId)),
      onDetachChild: (Id childId) => context.read<DashboardBloc>().add(
            DetachTaskFromParent(childId),
          ),
      onLinkExistingTask: () => DashboardScreen.openLinkTaskSheet(
        context,
        parentTask: task,
      ),
      onDeleteAttachment: (Id id) => context.read<DashboardBloc>().add(
            DeleteTaskAttachment(id),
          ),
      onToggleChecklistItem: (Id attachmentId, int localId) =>
          context.read<DashboardBloc>().add(
            ToggleAttachmentChecklistItem(
              attachmentId: attachmentId,
              itemLocalId: localId,
            ),
          ),
      onAddAttachment: () => DashboardScreen.openAddAttachmentSheet(
        context,
        task: task,
      ),
    );
  }
}

class _TasksSliver extends StatelessWidget {
  const _TasksSliver({
    required this.tasks,
    required this.selectedDate,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
  });

  final List<Task> tasks;
  final DateTime selectedDate;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      final String hint = AppDateUtils.isToday(selectedDate)
          ? 'На сегодня задач нет. Нажмите «+», чтобы добавить.'
          : 'На этот день задач нет. Нажмите «+», чтобы добавить.';

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$hint\n'
            '(Это локальные задачи приложения, не Google Calendar.)',
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final Task task = tasks[index];
          return _DashboardTaskTile(
            task: task,
            selectedDate: selectedDate,
            childTasksByParentId: childTasksByParentId,
            attachmentsByTaskId: attachmentsByTaskId,
          );
        },
        childCount: tasks.length,
      ),
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
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

