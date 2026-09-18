import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';

/// Result of a system contact pick attempt.
enum DeviceContactPickOutcome {
  cancelled,
  picked,
  failed,
}

/// Result wrapper for [DeviceContactPicker.pickSystem].
class DeviceContactPickResult {
  const DeviceContactPickResult({
    required this.outcome,
    this.payload,
  });

  final DeviceContactPickOutcome outcome;
  final ContactAttachmentPayload? payload;
}

/// Picks a contact from the device address book.
class DeviceContactPicker {
  DeviceContactPicker._();

  /// Opens the native contact picker (Android/iOS).
  static Future<DeviceContactPickResult> pickSystem() async {
    final PermissionStatus status =
        await FlutterContacts.permissions.request(PermissionType.read);
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      return const DeviceContactPickResult(
        outcome: DeviceContactPickOutcome.failed,
      );
    }

    final Contact? picked = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone, ContactProperty.email},
    );
    if (picked == null) {
      return const DeviceContactPickResult(
        outcome: DeviceContactPickOutcome.cancelled,
      );
    }

    final ContactAttachmentPayload? payload = _toPayload(picked);
    if (payload == null) {
      return const DeviceContactPickResult(
        outcome: DeviceContactPickOutcome.failed,
      );
    }
    return DeviceContactPickResult(
      outcome: DeviceContactPickOutcome.picked,
      payload: payload,
    );
  }

  static ContactAttachmentPayload? _toPayload(Contact contact) {
    final String displayName = (contact.displayName ?? '').trim();
    final List<String> phones = contact.phones
        .map((Phone phone) => phone.number.trim())
        .where((String number) => number.isNotEmpty)
        .toList(growable: false);
    final List<String> emails = contact.emails
        .map((Email email) => email.address.trim())
        .where((String address) => address.isNotEmpty)
        .toList(growable: false);

    if (displayName.isEmpty && phones.isEmpty && emails.isEmpty) {
      return null;
    }

    return ContactAttachmentPayload(
      displayName: displayName.isEmpty
          ? (phones.isNotEmpty ? phones.first : emails.first)
          : displayName,
      phones: phones,
      emails: emails,
    );
  }
}
