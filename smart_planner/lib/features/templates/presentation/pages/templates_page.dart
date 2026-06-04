import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/attachment_templates/presentation/widgets/attachment_templates_tab.dart';
import 'package:smart_planner/features/templates/presentation/widgets/task_templates_tab.dart';

/// Hub for task and attachment template management (AppBar → Templates).
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({
    this.initialTabIndex = 0,
    super.key,
  });

  /// `0` = task templates, `1` = attachment templates.
  final int initialTabIndex;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<TaskTemplatesTabState> _taskTabKey =
      GlobalKey<TaskTemplatesTabState>();
  final GlobalKey<AttachmentTemplatesTabState> _attachmentTabKey =
      GlobalKey<AttachmentTemplatesTabState>();

  @override
  void initState() {
    super.initState();
    final int initialIndex = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      initialIndex: initialIndex,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    if (_tabController.index == 0) {
      _taskTabKey.currentState?.createNew();
    } else {
      _attachmentTabKey.currentState?.createNew();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool attachmentTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('templates_hub_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: const Icon(Icons.task_alt_outlined),
              text: 'templates_tab_tasks'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.attach_file_outlined),
              text: 'templates_tab_attachments'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          TaskTemplatesTab(key: _taskTabKey),
          AttachmentTemplatesTab(key: _attachmentTabKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        icon: const Icon(Icons.add),
        label: Text(
          attachmentTab
              ? 'attachment_template_new'.tr()
              : 'templates_new_tooltip'.tr(),
        ),
      ),
    );
  }
}
