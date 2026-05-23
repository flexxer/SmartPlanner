import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

/// Opens installed map apps (Google Maps, Yandex, etc.) at coordinates only.
class MapAppLauncherService {
  MapAppLauncherService._();

  static Future<bool> showAtCoordinate({
    required BuildContext context,
    required double latitude,
    required double longitude,
  }) async {
    final List<AvailableMap> maps = await MapLauncher.installedMaps;
    if (maps.isEmpty) {
      return false;
    }

    final Coords coords = Coords(latitude, longitude);

    if (maps.length == 1) {
      await maps.first.showMarker(
        coords: coords,
        title: '',
      );
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final AvailableMap? chosen = await showModalBottomSheet<AvailableMap>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Открыть в',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              ...maps.map(
                (AvailableMap map) => ListTile(
                  leading: Image.asset(
                    map.icon,
                    height: 30,
                    width: 30,
                    package: 'map_launcher',
                  ),
                  title: Text(map.mapName),
                  onTap: () => Navigator.of(sheetContext).pop(map),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == null) {
      return false;
    }

    await chosen.showMarker(
      coords: coords,
      title: '',
    );
    return true;
  }
}
