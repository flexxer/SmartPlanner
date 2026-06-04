import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_action.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Parses and sanitizes `daylinx://` URIs.
abstract final class DeepLinkParser {
  DeepLinkParser._();

  static const String scheme = 'daylinx';
  static const String createHost = 'create';
  static const int maxTitleLength = 200;

  /// Returns a [DeepLinkAction] or `null` if the URI is invalid or unsupported.
  static DeepLinkAction? parse(Uri? uri, {DateTime? referenceNow}) {
    if (uri == null || uri.scheme.toLowerCase() != scheme) {
      return null;
    }

    final DeepLinkRefreshWidgetAction? refresh = _parseWidgetRefresh(uri);
    if (refresh != null) {
      return refresh;
    }

    if (!_isCreateTarget(uri)) {
      return null;
    }

    final String? type = _queryValue(uri, 'type')?.toLowerCase();
    if (type == null) {
      return null;
    }

    final DateTime now = referenceNow ?? DateTime.now();
    final DateTime day = AppDateUtils.startOfDay(now);

    switch (type) {
      case 'task':
        final String? rawTitle = _queryValue(uri, 'title');
        final String title =
            rawTitle != null ? _sanitizeTitle(rawTitle) : '';
        return DeepLinkCreateTaskAction(
          title: title,
          priority: _parsePriority(_queryValue(uri, 'priority')),
        );
      case 'event':
        final String? rawTitle = _queryValue(uri, 'title');
        if (rawTitle == null) {
          return null;
        }
        final String title = _sanitizeTitle(rawTitle);
        if (title.isEmpty) {
          return null;
        }
        final DateTime? start = _parseClockOnDay(
          _queryValue(uri, 'start'),
          day,
        );
        DateTime? end = _parseClockOnDay(_queryValue(uri, 'end'), day);
        if (start != null && end == null) {
          end = start.add(const Duration(hours: 1));
        }
        if (start != null && end != null && !end.isAfter(start)) {
          end = start.add(const Duration(hours: 1));
        }
        return DeepLinkCreateEventAction(
          title: title,
          start: start,
          end: end,
        );
      case 'template':
        final String? idRaw =
            _queryValue(uri, 'templateId') ?? _queryValue(uri, 'id');
        final int? templateId = int.tryParse(idRaw ?? '');
        if (templateId == null || templateId <= 0) {
          return null;
        }
        return DeepLinkCreateTaskFromTemplateAction(templateId: templateId);
      default:
        return null;
    }
  }

  static DeepLinkRefreshWidgetAction? _parseWidgetRefresh(Uri uri) {
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    final bool isWidget = host == 'widget' || path == '/widget' || path == 'widget';
    if (!isWidget) {
      return null;
    }
    if (_queryValue(uri, 'action')?.toLowerCase() == 'refresh') {
      return const DeepLinkRefreshWidgetAction();
    }
    return null;
  }

  static bool _isCreateTarget(Uri uri) {
    final String host = uri.host.toLowerCase();
    if (host == createHost) {
      return true;
    }
    final String path = uri.path.toLowerCase();
    return path == '/create' || path == 'create';
  }

  static String? _queryValue(Uri uri, String key) {
    if (!uri.queryParameters.containsKey(key)) {
      return null;
    }
    return uri.queryParameters[key];
  }

  static String _sanitizeTitle(String raw) {
    final String decoded = _decodeQueryFragment(raw);
    final String normalized = decoded.replaceAll('_', ' ').trim();
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in normalized.codeUnits) {
      final String char = String.fromCharCode(codeUnit);
      if (char == '\n' || char == '\r' || char == '\t') {
        buffer.write(' ');
        continue;
      }
      if (codeUnit < 0x20) {
        continue;
      }
      buffer.write(char);
    }
    final String collapsed =
        buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= maxTitleLength) {
      return collapsed;
    }
    return collapsed.substring(0, maxTitleLength);
  }

  /// [Uri.queryParameters] values are usually already decoded; this handles `+` and `%` safely.
  static String _decodeQueryFragment(String raw) {
    final String plusAsSpace = raw.replaceAll('+', ' ');
    if (!plusAsSpace.contains('%')) {
      return plusAsSpace;
    }
    try {
      return Uri.decodeComponent(plusAsSpace);
    } on ArgumentError {
      return plusAsSpace;
    }
  }

  static TaskPriority? _parsePriority(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final int? index = int.tryParse(raw);
    if (index == null || index < 0 || index >= TaskPriority.values.length) {
      return null;
    }
    return TaskPriority.values[index];
  }

  /// Parses `HH:mm` (24h) on [day]. Returns `null` when invalid.
  static DateTime? _parseClockOnDay(String? raw, DateTime day) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final List<String> parts = raw.split(':');
    if (parts.length != 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}
