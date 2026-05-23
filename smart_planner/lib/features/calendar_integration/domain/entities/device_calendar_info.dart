/// Календарь устройства (локальный / Google / Exchange и т.д.).
class DeviceCalendarInfo {
  const DeviceCalendarInfo({
    required this.id,
    required this.name,
    required this.colorValue,
    this.accountName,
    this.accountType,
    this.isReadOnly = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int colorValue;
  final String? accountName;
  final String? accountType;
  final bool isReadOnly;
  final bool isDefault;

  /// Календарь аккаунта Google, синхронизированный в приложение «Календарь» Android.
  bool get isGoogleAccount {
    final String type = (accountType ?? '').toLowerCase();
    final String account = (accountName ?? '').toLowerCase();
    return type.contains('google') ||
        type.contains('gmail') ||
        account.contains('gmail') ||
        account.contains('google');
  }
}
