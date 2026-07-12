import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';

/// Persistence contract for local [Payment] rows.
abstract class PaymentRepository {
  Future<List<Payment>> getAll();

  Future<Payment?> getById(Id id);

  Future<List<Payment>> getForMonth({
    required int year,
    required int month,
  });

  Future<List<Payment>> getByTaskId(int taskId);

  Future<List<Payment>> getByEventId(int eventId);

  Future<Id> save(Payment payment);

  Future<void> delete(Id id);

  Future<Payment?> togglePlannedCompleted(Id id);
}
