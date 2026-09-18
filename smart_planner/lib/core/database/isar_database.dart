import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/attachment_templates/data/models/attachment_template_model.dart';
import 'package:smart_planner/features/calendar_integration/data/models/calendar_event_model.dart';
import 'package:smart_planner/features/calendar_integration/data/models/event_attachment_model.dart';
import 'package:smart_planner/features/categories/data/models/category_model.dart';
import 'package:smart_planner/features/categories/data/models/category_link_model.dart';
import 'package:smart_planner/features/finance/data/models/payment_model.dart';
import 'package:smart_planner/features/templates/data/models/ui_template_model.dart';
import 'package:smart_planner/features/todo_list/data/models/task_model.dart';
import 'package:smart_planner/features/todo_list/data/models/task_attachment_model.dart';

/// Singleton for the local Isar database.
class IsarDatabase {
  IsarDatabase._();

  static const String _dbName = 'smart_planner';

  static Isar? _instance;

  /// The open database. Throws when [init] has not completed yet.
  static Isar get instance {
    final Isar? db = _instance;
    if (db == null || !db.isOpen) {
      throw StateError('Isar is not initialized. Call IsarDatabase.init() first.');
    }
    return db;
  }

  /// Opens the database once. Returns a [Result] so startup failures are
  /// surfaced as a typed [AppFailure] instead of a raw exception.
  static Future<Result<Isar>> init() async {
    final Isar? existing = _instance;
    if (existing != null && existing.isOpen) {
      return Success(existing);
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final Isar isar = await Isar.open(
        <CollectionSchema<dynamic>>[
          TaskModelSchema,
          TaskAttachmentModelSchema,
          CalendarEventModelSchema,
          EventAttachmentModelSchema,
          UiTemplateModelSchema,
          AttachmentTemplateModelSchema,
          CategoryModelSchema,
          CategoryLinkModelSchema,
          PaymentModelSchema,
        ],
        directory: dir.path,
        name: _dbName,
      );
      _instance = isar;
      return Success(isar);
    } on Object catch (error, stackTrace) {
      return Failure(
        DatabaseFailure('Failed to open Isar database: $error', stackTrace),
      );
    }
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
