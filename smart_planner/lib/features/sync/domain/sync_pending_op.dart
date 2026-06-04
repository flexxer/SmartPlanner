/// Outbox operation waiting to be pushed to a remote provider.
enum SyncPendingOp {
  none,
  create,
  update,
  delete,
}
