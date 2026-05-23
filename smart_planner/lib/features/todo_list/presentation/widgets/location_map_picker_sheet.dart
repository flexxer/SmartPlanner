import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_planner/features/todo_list/data/services/osm_place_search_service.dart';

/// Result of picking a point on the map.
class LocationPickResult {
  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  final double latitude;
  final double longitude;

  /// Nominatim [display_name] for the picked point (search or reverse geocode).
  final String? placeName;
}

/// Tap on OpenStreetMap to choose coordinates; search places via Nominatim.
class LocationMapPickerSheet extends StatefulWidget {
  const LocationMapPickerSheet({
    this.initialLatitude,
    this.initialLongitude,
    super.key,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationMapPickerSheet> createState() => _LocationMapPickerSheetState();
}

class _LocationMapPickerSheetState extends State<LocationMapPickerSheet> {
  static const LatLng _defaultCenter = LatLng(55.7558, 37.6173);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selected;
  String? _placeName;
  bool _loading = true;
  bool _searching = false;
  bool _resolvingPlaceName = false;
  List<OsmPlaceResult> _searchResults = <OsmPlaceResult>[];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initCenter();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCenter() async {
    LatLng center = _defaultCenter;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selected = center;
    } else {
      try {
        final bool enabled = await Geolocator.isLocationServiceEnabled();
        if (enabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final Position position = await Geolocator.getCurrentPosition();
            center = LatLng(position.latitude, position.longitude);
          }
        }
      } on Object {
        // Keep default center.
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 14);
      });
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(_searchController.text);
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _searchResults = <OsmPlaceResult>[];
          _searching = false;
        });
      }
      return;
    }

    setState(() => _searching = true);
    try {
      final List<OsmPlaceResult> results =
          await OsmPlaceSearchService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _searchResults = <OsmPlaceResult>[];
          _searching = false;
        });
      }
    }
  }

  void _selectSearchResult(OsmPlaceResult place) {
    final LatLng point = LatLng(place.latitude, place.longitude);
    setState(() {
      _selected = point;
      _placeName = place.displayName;
      _resolvingPlaceName = false;
      _searchResults = <OsmPlaceResult>[];
      _searchController.text = place.displayName;
    });
    _mapController.move(point, 15);
  }

  Future<void> _onTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selected = point;
      _placeName = null;
      _resolvingPlaceName = true;
    });

    final String? name = await OsmPlaceSearchService.reverseGeocode(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (!mounted || _selected != point) {
      return;
    }

    setState(() {
      _placeName = name;
      _resolvingPlaceName = false;
      if (name != null && name.isNotEmpty) {
        _searchController.text = name;
      }
    });
  }

  void _confirm() {
    final LatLng? point = _selected;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нажмите на карту, чтобы выбрать точку')),
      );
      return;
    }
    Navigator.of(context).pop(
      LocationPickResult(
        latitude: point.latitude,
        longitude: point.longitude,
        placeName: _placeName?.trim().isNotEmpty == true ? _placeName!.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Выбор точки на карте',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск места (OpenStreetMap)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = <OsmPlaceResult>[];
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_searchResults.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      final OsmPlaceResult place = _searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          place.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(place),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Нажмите на карту, чтобы поставить метку',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selected ?? _defaultCenter,
                            initialZoom: 14,
                            onTap: _onTap,
                          ),
                          children: <Widget>[
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.aliakseipcholkin.smart_planner',
                            ),
                            if (_selected != null)
                              MarkerLayer(
                                markers: <Marker>[
                                  Marker(
                                    point: _selected!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
              if (_selected != null) ...<Widget>[
                const SizedBox(height: 8),
                if (_resolvingPlaceName)
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Определяем адрес…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  )
                else if (_placeName != null && _placeName!.isNotEmpty)
                  Text(
                    _placeName!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    '${_selected!.latitude.toStringAsFixed(6)}, '
                    '${_selected!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _confirm,
                child: const Text('Выбрать эту точку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
