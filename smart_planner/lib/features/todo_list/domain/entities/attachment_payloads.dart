/// JSON payloads for [TaskAttachment.payloadJson] (typed per [TaskAttachmentType]).
library;

class ContactAttachmentPayload {
  const ContactAttachmentPayload({
    required this.displayName,
    required this.phones,
    this.emails = const <String>[],
  });

  final String displayName;
  final List<String> phones;
  final List<String> emails;

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'displayName': displayName,
        'phones': phones,
        'emails': emails,
      };

  factory ContactAttachmentPayload.fromJson(Map<String, dynamic> json) {
    return ContactAttachmentPayload(
      displayName: json['displayName'] as String? ?? '',
      phones: (json['phones'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          <String>[],
      emails: (json['emails'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          <String>[],
    );
  }
}

class ImageAttachmentPayload {
  const ImageAttachmentPayload({
    required this.relativePath,
    this.mimeType,
  });

  final String relativePath;
  final String? mimeType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'relativePath': relativePath,
        'mimeType': mimeType,
      };

  factory ImageAttachmentPayload.fromJson(Map<String, dynamic> json) {
    return ImageAttachmentPayload(
      relativePath: json['relativePath'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
    );
  }
}

class UrlAttachmentPayload {
  const UrlAttachmentPayload({
    required this.url,
    this.label,
  });

  final String url;
  final String? label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'label': label,
      };

  factory UrlAttachmentPayload.fromJson(Map<String, dynamic> json) {
    return UrlAttachmentPayload(
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
    );
  }
}

class LocationAttachmentPayload {
  const LocationAttachmentPayload({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.label,
  });

  final double latitude;
  final double longitude;

  /// Human-readable name from Nominatim [display_name] (map pick / reverse geocode).
  final String? placeName;

  /// Optional user override shown instead of [placeName].
  final String? label;

  /// Title for UI: custom [label], then [placeName], then legacy payload `label` only.
  String? get resolvedPlaceTitle {
    final String? custom = label?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final String? place = placeName?.trim();
    if (place != null && place.isNotEmpty) {
      return place;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (placeName != null) 'placeName': placeName,
        if (label != null) 'label': label,
      };

  factory LocationAttachmentPayload.fromJson(Map<String, dynamic> json) {
    final String? placeNameJson = json['placeName'] as String?;
    final String? labelJson = json['label'] as String?;
    if (placeNameJson != null && placeNameJson.trim().isNotEmpty) {
      return LocationAttachmentPayload(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        placeName: placeNameJson.trim(),
        label: labelJson?.trim().isEmpty == true ? null : labelJson?.trim(),
      );
    }
    return LocationAttachmentPayload(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      placeName: labelJson?.trim().isEmpty == true ? null : labelJson?.trim(),
    );
  }
}

class ChecklistItemPayload {
  const ChecklistItemPayload({
    required this.localId,
    required this.text,
    this.isCompleted = false,
  });

  final int localId;
  final String text;
  final bool isCompleted;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'localId': localId,
        'text': text,
        'isCompleted': isCompleted,
      };

  factory ChecklistItemPayload.fromJson(Map<String, dynamic> json) {
    return ChecklistItemPayload(
      localId: json['localId'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// Plain text note (no checklist — use [ChecklistAttachmentPayload]).
class NoteAttachmentPayload {
  const NoteAttachmentPayload({
    this.title,
    required this.body,
  });

  final String? title;
  final String body;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
      };

  factory NoteAttachmentPayload.fromJson(Map<String, dynamic> json) {
    return NoteAttachmentPayload(
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
    );
  }
}

class ChecklistAttachmentPayload {
  const ChecklistAttachmentPayload({
    this.title,
    required this.items,
  });

  final String? title;
  final List<ChecklistItemPayload> items;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'items': items.map((ChecklistItemPayload i) => i.toJson()).toList(),
      };

  factory ChecklistAttachmentPayload.fromJson(Map<String, dynamic> json) {
    return ChecklistAttachmentPayload(
      title: json['title'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                (dynamic e) => ChecklistItemPayload.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          <ChecklistItemPayload>[],
    );
  }
}
