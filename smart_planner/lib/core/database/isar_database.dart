import 'package:isar/isar.dart';

import 'package:path_provider/path_provider.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';

import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';



/// Синглтон локальной БД Isar.

class IsarDatabase {

  IsarDatabase._();



  static const String _dbName = 'smart_planner';



  static Isar? _instance;



  static Isar get instance {

    final Isar? db = _instance;

    if (db == null || !db.isOpen) {

      throw StateError(

        'Isar не инициализирован. Вызовите IsarDatabase.init() в main.',

      );

    }

    return db;

  }



  static Future<void> init() async {

    if (_instance?.isOpen ?? false) {

      return;

    }

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(

      <CollectionSchema<dynamic>>[

        TaskSchema,

        TaskAttachmentSchema,

        CalendarEventSchema,

        EventAttachmentSchema,

        UiTemplateSchema,

      ],

      directory: dir.path,

      name: _dbName,

    );

  }



  static Future<void> close() async {

    await _instance?.close();

    _instance = null;

  }

}

