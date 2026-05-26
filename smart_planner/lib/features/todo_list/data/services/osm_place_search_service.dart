import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place from OpenStreetMap Nominatim search.
class OsmPlaceResult {
  const OsmPlaceResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;

  factory OsmPlaceResult.fromJson(Map<String, dynamic> json) {
    return OsmPlaceResult(
      displayName: json['display_name'] as String? ?? '',
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
    );
  }
}

/// Forward geocoding via Nominatim (OpenStreetMap).
class OsmPlaceSearchService {
  OsmPlaceSearchService._();

  static const String _userAgent =
      'DayLinx/1.0 (com.aliakseipcholkin.smart_planner)';

  static Future<List<OsmPlaceResult>> search(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) {
      return <OsmPlaceResult>[];
    }

    final Uri uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      <String, String>{
        'q': trimmed,
        'format': 'json',
        'limit': '8',
        'addressdetails': '0',
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: <String, String>{'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      return <OsmPlaceResult>[];
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (dynamic item) =>
              OsmPlaceResult.fromJson(item as Map<String, dynamic>),
        )
        .where((OsmPlaceResult place) => place.displayName.isNotEmpty)
        .toList(growable: false);
  }

  /// Reverse geocoding: coordinates → Nominatim [display_name].
  static Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: <String, String>{'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String displayName = data['display_name'] as String? ?? '';
    final String trimmed = displayName.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
