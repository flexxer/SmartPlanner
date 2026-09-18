import 'package:easy_localization/easy_localization.dart';
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
    final MarkerRequest request = MapLauncher.marker(
      LocationCoords(latitude, longitude),
    );
    final List<SupportedMap> maps = (await request.getSupportedMaps(MapApp.all))
        .where((SupportedMap map) => map.isInstalled)
        .toList(growable: false);
    if (maps.isEmpty) {
      return false;
    }

    if (maps.length == 1) {
      await maps.single.show();
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final SupportedMap? chosen = await showModalBottomSheet<SupportedMap>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'attachment_open_in'.tr(),
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              ...maps.map(
                (SupportedMap map) => ListTile(
                  leading: Image.memory(
                    map.iconBytes,
                    height: 30,
                    width: 30,
                  ),
                  title: Text(map.name),
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

    await chosen.show();
    return true;
  }
}
