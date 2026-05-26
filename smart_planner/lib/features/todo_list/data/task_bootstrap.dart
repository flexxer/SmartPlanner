import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Первичное наполнение БД демо-задачами (один раз после установки).
class TaskBootstrap {
  TaskBootstrap._();

  static const String _seededKey = 'tasks_demo_seeded';

  static Future<void> seedIfNeeded(TodoRepository repository) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) {
      return;
    }

    final List<Task> existing = await repository.getAllTasks();
    if (existing.isNotEmpty) {
      await prefs.setBool(_seededKey, true);
      return;
    }

    final TaskAttachmentRepository attachments = TaskAttachmentRepository();

    final DateTime today = AppDateUtils.startOfDay(DateTime.now());

    final Task urgent = Task.create(
      title: 'Подготовить отчёт',
      dueDate: today,
      priority: TaskPriority.high,
    );
    final Id urgentId = await repository.saveTask(urgent);
    await attachments.save(
      TaskAttachment.create(
        taskId: urgentId,
        type: TaskAttachmentType.checklist,
        payloadJson: TaskAttachmentCodec.encodeMap(
          ChecklistAttachmentPayload(
            items: <ChecklistItemPayload>[
              ChecklistItemPayload(localId: 1, text: 'Собрать цифры'),
              ChecklistItemPayload(localId: 2, text: 'Сверстать слайды'),
              ChecklistItemPayload(
                localId: 3,
                text: 'Отправить руководителю',
                isCompleted: true,
              ),
            ],
          ).toJson(),
        ),
      ),
    );

    final Task overdue = Task.create(
      title: 'Оплатить подписку',
      dueDate: today.subtract(const Duration(days: 2)),
      priority: TaskPriority.medium,
    );
    await repository.saveTask(overdue);

    final Task birthday = Task.create(
      title: 'Поздравить маму с днём рождения',
      dueDate: today,
      priority: TaskPriority.high,
    );
    final Id birthdayId = await repository.saveTask(birthday);

    final Task buyCake = Task.create(
      title: 'Купить торт',
      dueDate: today,
      priority: TaskPriority.medium,
    );
    final Id buyCakeId = await repository.saveTask(buyCake);
    await repository.attachTaskToParent(
      childTaskId: buyCakeId,
      parentTaskId: birthdayId,
    );

    final Task later = Task.create(
      title: 'Купить продукты',
      dueDate: today.add(const Duration(days: 1)),
      priority: TaskPriority.low,
    );
    await repository.saveTask(later);

    await prefs.setBool(_seededKey, true);
  }
}
