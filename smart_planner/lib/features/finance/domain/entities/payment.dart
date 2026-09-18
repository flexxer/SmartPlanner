import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

/// Local income/expense row; amounts stored as minor units (no float).
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `PaymentModel` in the data layer.
class Payment {
  Payment({this.id = 0});

  factory Payment.create({
    required String title,
    required int amountMinor,
    required String currencyCode,
    required PaymentDirection direction,
    PaymentStatus status = PaymentStatus.planned,
    DateTime? occurredAt,
    String? note,
    int? linkedTaskId,
    int? linkedEventId,
  }) {
    final DateTime now = DateTime.now();
    return Payment()
      ..title = title
      ..amountMinor = amountMinor
      ..currencyCode = currencyCode
      ..direction = direction
      ..status = status
      ..occurredAt = occurredAt ?? now
      ..updatedAt = now
      ..note = note
      ..linkedTaskId = linkedTaskId
      ..linkedEventId = linkedEventId;
  }

  /// Database id; `0` until persisted.
  int id;

  String title = '';

  String? note;

  int amountMinor = 0;

  String currencyCode = 'USD';

  PaymentDirection direction = PaymentDirection.expense;

  PaymentStatus status = PaymentStatus.planned;

  DateTime occurredAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int? linkedTaskId;

  int? linkedEventId;
}
