/// Project-wide identifier type for local entities.
///
/// Isar exposes its own `Id` typedef, but the domain and presentation layers
/// must not depend on the database package. This alias keeps those layers
/// Isar-free while remaining strictly compatible with Isar's identifier type.
typedef Id = int;