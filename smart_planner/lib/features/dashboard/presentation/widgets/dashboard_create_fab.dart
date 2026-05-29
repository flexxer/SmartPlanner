import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Primary create action on the dashboard: task or calendar event.
class DashboardCreateFab extends StatelessWidget {
  const DashboardCreateFab({
    required this.onCreateTask,
    required this.onCreateEvent,
    super.key,
  });

  final VoidCallback onCreateTask;
  final VoidCallback onCreateEvent;

  Future<void> _showCreateMenu(BuildContext context) async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'dashboard_create_menu_title'.tr(),
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.task_alt_outlined),
                title: Text('dashboard_create_task'.tr()),
                onTap: () => Navigator.of(sheetContext).pop('task'),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text('dashboard_create_event'.tr()),
                onTap: () => Navigator.of(sheetContext).pop('event'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case 'task':
        onCreateTask();
      case 'event':
        onCreateEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'dashboard_create_menu_title'.tr(),
      onPressed: () => _showCreateMenu(context),
      child: const Icon(Icons.add),
    );
  }
}
