import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';

/// Isar-backed [PaymentRepository].
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Isar get _db => _isar ?? IsarDatabase.instance;

  @override
  Future<List<Payment>> getAll() async {
    final List<Payment> list = await _db.payments.where().findAll();
    list.sort(
      (Payment a, Payment b) => b.occurredAt.compareTo(a.occurredAt),
    );
    return list;
  }

  @override
  Future<Payment?> getById(Id id) => _db.payments.get(id);

  @override
  Future<List<Payment>> getForMonth({
    required int year,
    required int month,
  }) async {
    final List<Payment> all = await getAll();
    return all
        .where(
          (Payment payment) =>
              payment.occurredAt.year == year &&
              payment.occurredAt.month == month,
        )
        .toList(growable: false);
  }

  @override
  Future<List<Payment>> getByTaskId(int taskId) async {
    return _db.payments.filter().linkedTaskIdEqualTo(taskId).findAll();
  }

  @override
  Future<List<Payment>> getByEventId(int eventId) async {
    return _db.payments.filter().linkedEventIdEqualTo(eventId).findAll();
  }

  @override
  Future<Id> save(Payment payment) async {
    payment.updatedAt = DateTime.now();
    return _db.writeTxn(() => _db.payments.put(payment));
  }

  @override
  Future<void> delete(Id id) =>
      _db.writeTxn(() => _db.payments.delete(id));

  @override
  Future<Payment?> togglePlannedCompleted(Id id) async {
    final Payment? payment = await getById(id);
    if (payment == null) {
      return null;
    }
    if (payment.status == PaymentStatus.planned) {
      payment.status = PaymentStatus.completed;
    } else if (payment.status == PaymentStatus.completed) {
      payment.status = PaymentStatus.planned;
    } else {
      return payment;
    }
    await save(payment);
    return payment;
  }
}
