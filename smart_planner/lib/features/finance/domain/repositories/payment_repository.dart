import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';

/// Persistence contract for local [Payment] rows.
abstract class PaymentRepository {
  Future<Result<List<Payment>>> getAll();

  Future<Result<Payment?>> getById(int id);

  Future<Result<List<Payment>>> getForMonth({
    required int year,
    required int month,
  });

  Future<Result<List<Payment>>> getByTaskId(int taskId);

  Future<Result<List<Payment>>> getByEventId(int eventId);

  Future<Result<Payment>> save(Payment payment);

  Future<Result<bool>> delete(int id);

  Future<Result<Payment?>> togglePlannedCompleted(int id);
}
