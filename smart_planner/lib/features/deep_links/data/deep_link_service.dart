import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_action.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_parser.dart';

/// Subscribes to platform deep links and exposes parsed create actions.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final StreamController<DeepLinkAction> _actionsController =
      StreamController<DeepLinkAction>.broadcast();

  StreamSubscription<Uri>? _uriSubscription;
  bool _initialized = false;

  Stream<DeepLinkAction> get actions => _actionsController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final Uri? initial = await _appLinks.getInitialLink();
      _emitParsed(initial);
      await _emitWidgetLaunchUriIfAny();
      await _emitLatestAppLink();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'DeepLinkService',
          context: ErrorDescription('while reading getInitialLink'),
        ),
      );
    }

    _uriSubscription = _appLinks.uriLinkStream.listen(
      _emitParsed,
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'DeepLinkService',
            context: ErrorDescription('while listening to uriLinkStream'),
          ),
        );
      },
    );
  }

  void _emitParsed(Uri? uri) {
    final DeepLinkAction? action = DeepLinkParser.parse(uri);
    if (action != null) {
      _actionsController.add(action);
    }
  }

  Future<void> _emitWidgetLaunchUriIfAny() async {
    try {
      final Uri? widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _emitParsed(widgetUri);
    } on Object {
      //
    }
  }

  Future<void> _emitLatestAppLink() async {
    try {
      final Uri? latest = await _appLinks.getLatestLink();
      _emitParsed(latest);
    } on Object {
      //
    }
  }

  /// Re-read platform link after [MainActivity.onNewIntent] (warm start from widget).
  Future<void> handleAppResumed() async {
    await _emitLatestAppLink();
    await _emitWidgetLaunchUriIfAny();
  }

  Future<void> dispose() async {
    await _uriSubscription?.cancel();
    await _actionsController.close();
    _initialized = false;
  }
}
