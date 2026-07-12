import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

part 'payment.g.dart';

/// Local income/expense row; amounts stored as minor units (no float).
@collection
class Payment {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  String? note;

  int amountMinor = 0;

  String currencyCode = 'USD';

  @Enumerated(EnumType.ordinal)
  late PaymentDirection direction;

  @Enumerated(EnumType.ordinal)
  PaymentStatus status = PaymentStatus.planned;

  DateTime occurredAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  int? linkedTaskId;

  int? linkedEventId;

  Payment();

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
}
