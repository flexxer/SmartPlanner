import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Placeholder task list screen.
class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('todo_list_page_title'.tr())),
      body: Center(
        child: Text('todo_list_placeholder'.tr()),
      ),
    );
  }
}
