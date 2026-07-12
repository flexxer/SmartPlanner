import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/features/attachment_templates/presentation/widgets/attachment_templates_tab.dart';
import 'package:smart_planner/features/categories/presentation/tabs/categories_tab.dart';
import 'package:smart_planner/features/templates/presentation/widgets/task_templates_tab.dart';

/// Hub for task templates, attachment presets, and user categories.
class LibraryPage extends StatefulWidget {
  const LibraryPage({
    this.initialTabIndex = 0,
    super.key,
  });

  /// `0` = tasks, `1` = attachments, `2` = categories.
  final int initialTabIndex;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<TaskTemplatesTabState> _taskTabKey =
      GlobalKey<TaskTemplatesTabState>();
  final GlobalKey<AttachmentTemplatesTabState> _attachmentTabKey =
      GlobalKey<AttachmentTemplatesTabState>();
  final GlobalKey<CategoriesTabState> _categoriesTabKey =
      GlobalKey<CategoriesTabState>();

  @override
  void initState() {
    super.initState();
    final int initialIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3,
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
    switch (_tabController.index) {
      case 0:
        _taskTabKey.currentState?.createNew();
      case 1:
        _attachmentTabKey.currentState?.createNew();
      case 2:
        _categoriesTabKey.currentState?.createNew();
    }
  }

  String _fabLabel() {
    switch (_tabController.index) {
      case 1:
        return 'attachment_template_new'.tr();
      case 2:
        return 'category_new'.tr();
      default:
        return 'templates_new_tooltip'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('library_hub_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: const Icon(Icons.task_alt_outlined),
              text: 'library_tab_tasks'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.attach_file_outlined),
              text: 'library_tab_attachments'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.label_outline),
              text: 'library_tab_categories'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          TaskTemplatesTab(key: _taskTabKey),
          AttachmentTemplatesTab(key: _attachmentTabKey),
          CategoriesTab(key: _categoriesTabKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        icon: const Icon(Icons.add),
        label: Text(_fabLabel()),
      ),
    );
  }
}
