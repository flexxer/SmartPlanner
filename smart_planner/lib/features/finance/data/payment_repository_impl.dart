import 'package:isar_community/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/result/result.dart';
import 'package:smart_planner/features/finance/data/models/payment_model.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/finance/domain/payment_status.dart';
import 'package:smart_planner/features/finance/domain/repositories/payment_repository.dart';

/// Isar-backed [PaymentRepository]. Maps between the pure domain entity and the
/// [PaymentModel] persistence row, and reports failures as [Result].
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({this.isar});

  final Isar? isar;

  Isar get _db => isar ?? IsarDatabase.instance;

  @override
  Future<Result<List<Payment>>> getAll() async {
    try {
      final List<PaymentModel> list = await _db.paymentModels.where().findAll();
      list.sort(
        (PaymentModel a, PaymentModel b) =>
            b.occurredAt.compareTo(a.occurredAt),
      );
      return Success(
        list.map((PaymentModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load payments: $error', stackTrace));
    }
  }

  @override
  Future<Result<Payment?>> getById(int id) async {
    try {
      final PaymentModel? model = await _db.paymentModels.get(id);
      return Success(model?.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load payment $id: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Payment>>> getForMonth({
    required int year,
    required int month,
  }) async {
    final Result<List<Payment>> result = await getAll();
    return result.map(
      (List<Payment> all) => all
          .where(
            (Payment payment) =>
                payment.occurredAt.year == year &&
                payment.occurredAt.month == month,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Payment>>> getByTaskId(int taskId) async {
    try {
      final List<PaymentModel> list = await _db.paymentModels
          .filter()
          .linkedTaskIdEqualTo(taskId)
          .findAll();
      return Success(
        list.map((PaymentModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load payments: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<Payment>>> getByEventId(int eventId) async {
    try {
      final List<PaymentModel> list = await _db.paymentModels
          .filter()
          .linkedEventIdEqualTo(eventId)
          .findAll();
      return Success(
        list.map((PaymentModel m) => m.toDomain()).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to load payments: $error', stackTrace));
    }
  }

  @override
  Future<Result<Payment>> save(Payment payment) async {
    try {
      payment.updatedAt = DateTime.now();
      final PaymentModel model = PaymentModel.fromDomain(payment);
      await _db.writeTxn(() => _db.paymentModels.put(model));
      return Success(model.toDomain());
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to save payment: $error', stackTrace));
    }
  }

  @override
  Future<Result<bool>> delete(int id) async {
    try {
      final bool deleted = await _db.writeTxn(() => _db.paymentModels.delete(id));
      return Success(deleted);
    } on Object catch (error, stackTrace) {
      return Failure(DatabaseFailure('Failed to delete payment $id: $error', stackTrace));
    }
  }

  @override
  Future<Result<Payment?>> togglePlannedCompleted(int id) async {
    final Payment? payment = (await getById(id)).getOrElse((_) => null);
    if (payment == null) {
      return const Success(null);
    }
    if (payment.status == PaymentStatus.planned) {
      payment.status = PaymentStatus.completed;
    } else if (payment.status == PaymentStatus.completed) {
      payment.status = PaymentStatus.planned;
    } else {
      return Success(payment);
    }
    final Result<Payment> saved = await save(payment);
    return saved.map<Payment?>((Payment p) => p);
  }
}
