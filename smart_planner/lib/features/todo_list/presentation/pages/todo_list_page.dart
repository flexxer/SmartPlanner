import 'package:flutter/material.dart';

/// Заглушка экрана списка задач.
class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')),
      body: const Center(
        child: Text('Список задач — в разработке'),
      ),
    );
  }
}
