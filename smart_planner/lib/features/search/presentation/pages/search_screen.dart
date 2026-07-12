import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/presentation/widgets/category_filter_chips.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/presentation/pages/event_detail_screen.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:smart_planner/features/search/data/global_search_service.dart';
import 'package:smart_planner/features/search/domain/search_result_item.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/pages/task_detail_screen.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_icon.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_ui.dart';

/// Global search across tasks and calendar events.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  GlobalSearchService? _searchService;
  Timer? _debounce;
  List<SearchResultItem> _results = <SearchResultItem>[];
  List<Id> _selectedCategoryIds = <Id>[];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchService ??= GlobalSearchService(
      categoryTagService: context.read<CategoryTagService>(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(_queryController.text);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    final List<SearchResultItem> results = await _searchService!.search(
      query,
      categoryIds: _selectedCategoryIds,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _onCategoryFilterChanged(List<Id> ids) {
    setState(() => _selectedCategoryIds = ids);
    _runSearch(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'search_hint'.tr(),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CategoryFilterChips(
            selectedCategoryIds: _selectedCategoryIds,
            onSelectionChanged: _onCategoryFilterChanged,
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final String query = _queryController.text.trim();
    final bool hasCategoryFilter = _selectedCategoryIds.isNotEmpty;
    if (query.isEmpty && !hasCategoryFilter) {
      return Center(
        child: Text(
          'search_prompt'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(child: Text('search_no_results'.tr()));
    }

    final Map<String, List<SearchResultItem>> grouped =
        <String, List<SearchResultItem>>{};
    for (final SearchResultItem item in _results) {
      final String key = item.kind == SearchResultKind.task
          ? 'search_section_tasks'
          : 'search_section_events';
      grouped.putIfAbsent(key, () => <SearchResultItem>[]).add(item);
    }

    return ListView(
      children: <Widget>[
        for (final MapEntry<String, List<SearchResultItem>> section
            in grouped.entries) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              section.key.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...section.value.map(
            (SearchResultItem item) => _SearchResultTile(
              item: item,
              onTap: () => _openResult(context, item),
            ),
          ),
        ],
      ],
    );
  }

  void _openResult(BuildContext context, SearchResultItem item) {
    final DashboardBloc bloc = context.read<DashboardBloc>();
    final DashboardState state = bloc.state;
    if (state is! DashboardLoaded) {
      return;
    }
    final DateTime selectedDate = state.selectedDate;
    if (item.kind == SearchResultKind.task) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: TaskDetailScreen(
              taskId: item.recordId,
              selectedDate: selectedDate,
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: EventDetailScreen(
            eventId: item.recordId,
            selectedDate: selectedDate,
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.onTap,
  });

  final SearchResultItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateFormat dateFormat = L10n.dateFormat('d MMM', context: context);
    final DateFormat timeFormat = L10n.dateFormat('Hm', context: context);

    return ListTile(
      leading: item.kind == SearchResultKind.task
          ? CircleAvatar(
              backgroundColor: TaskPriorityUi.backgroundColor(
                item.task!.priority,
                colors,
              ),
              child: TaskPriorityIcon(
                priority: item.task!.priority,
                size: 18,
              ),
            )
          : CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.event_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
      title: Text(item.title),
      subtitle: _buildSubtitle(context, dateFormat, timeFormat),
      isThreeLine: true,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle(
    BuildContext context,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final List<String> lines = <String>[];

    if (item.kind == SearchResultKind.task) {
      final Task task = item.task!;
      if (task.dueDate != null) {
        lines.add(
          'search_meta_due'.tr(
            namedArgs: <String, String>{
              'date': dateFormat.format(task.dueDate!),
            },
          ),
        );
      } else {
        lines.add('search_meta_no_due'.tr());
      }
      if (task.reminderAt != null) {
        lines.add(
          'search_meta_reminder'.tr(
            namedArgs: <String, String>{
              'time': timeFormat.format(task.reminderAt!),
            },
          ),
        );
      }
      if (item.parentTitle != null) {
        lines.add(
          'search_meta_parent'.tr(
            namedArgs: <String, String>{'title': item.parentTitle!},
          ),
        );
      }
      if (task.isCompleted) {
        lines.add('search_meta_completed'.tr());
      }
    } else {
      final CalendarEvent event = item.event!;
      lines.add(
        'search_meta_event_time'.tr(
          namedArgs: <String, String>{
            'date': dateFormat.format(event.start),
            'start': timeFormat.format(event.start),
            'end': timeFormat.format(event.end),
          },
        ),
      );
      if (event.reminderMinutesBefore != null) {
        lines.add(
          'search_meta_event_reminder'.tr(
            namedArgs: <String, String>{
              'minutes': '${event.reminderMinutesBefore}',
            },
          ),
        );
      }
      if (event.linkedTaskIds.isNotEmpty) {
        lines.add(
          'search_meta_linked_tasks'.tr(
            namedArgs: <String, String>{
              'count': '${event.linkedTaskIds.length}',
            },
          ),
        );
      }
    }

    if (lines.isEmpty) {
      return null;
    }

    return Text(lines.join('\n'));
  }
}
