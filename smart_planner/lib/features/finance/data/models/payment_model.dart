import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_direction.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

part 'payment_model.g.dart';

/// Isar persistence model for [Payment].
@collection
class PaymentModel {
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

  Payment toDomain() => Payment(id: id)
    ..title = title
    ..note = note
    ..amountMinor = amountMinor
    ..currencyCode = currencyCode
    ..direction = direction
    ..status = status
    ..occurredAt = occurredAt
    ..updatedAt = updatedAt
    ..linkedTaskId = linkedTaskId
    ..linkedEventId = linkedEventId;

  static PaymentModel fromDomain(Payment payment) {
    final PaymentModel model = PaymentModel()
      ..title = payment.title
      ..note = payment.note
      ..amountMinor = payment.amountMinor
      ..currencyCode = payment.currencyCode
      ..direction = payment.direction
      ..status = payment.status
      ..occurredAt = payment.occurredAt
      ..updatedAt = payment.updatedAt
      ..linkedTaskId = payment.linkedTaskId
      ..linkedEventId = payment.linkedEventId;
    if (payment.id > 0) {
      model.id = payment.id;
    }
    return model;
  }
}
