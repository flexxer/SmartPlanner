import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';

/// Выбор календарей устройства (в т.ч. Google, синхронизированных в Android).
class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  final DeviceCalendarService _calendarService = DeviceCalendarService();
  final CalendarPreferencesRepository _preferences =
      CalendarPreferencesRepository();

  bool _loading = true;
  String? _error;
  List<DeviceCalendarInfo> _calendars = <DeviceCalendarInfo>[];
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bool granted = await _calendarService.requestPermissions();
      if (!granted) {
        setState(() {
          _loading = false;
          _error = 'Нужен доступ к календарю устройства';
        });
        return;
      }

      final List<DeviceCalendarInfo> calendars =
          await _calendarService.getCalendars();
      final List<String>? saved = await _preferences.getSelectedCalendarIds();

      final Set<String> initialSelection = _initialSelection(
        calendars: calendars,
        saved: saved,
      );

      setState(() {
        _calendars = calendars;
        _selectedIds
          ..clear()
          ..addAll(initialSelection);
        _loading = false;
      });
    } on CalendarPermissionDeniedException {
      setState(() {
        _loading = false;
        _error = 'Доступ к календарю не предоставлен';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    await _preferences.saveSelectedCalendarIds(_selectedIds.toList());
    if (!mounted) {
      return;
    }
    context.read<DashboardBloc>().add(
          LoadDashboardData(selectedCalendarIds: _selectedIds.toList()),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календари'),
        actions: <Widget>[
          TextButton(
            onPressed: _selectedIds.isEmpty ? null : _save,
            child: const Text('Готово'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Запросить доступ'),
              ),
            ],
          ),
        ),
      );
    }

    if (_calendars.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Календари не найдены. Добавьте аккаунт Google в приложении '
            '«Календарь» на телефоне и включите синхронизацию.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'События читаются из календарей Android (включая Google, '
            'если они синхронизированы на устройстве). OAuth Google API — позже.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _calendars.length,
            itemBuilder: (BuildContext context, int index) {
              final DeviceCalendarInfo calendar = _calendars[index];
              final bool selected = _selectedIds.contains(calendar.id);

              return CheckboxListTile(
                value: selected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedIds.add(calendar.id);
                    } else {
                      _selectedIds.remove(calendar.id);
                    }
                  });
                },
                secondary: CircleAvatar(
                  backgroundColor: Color(_colorArgb(calendar.colorValue)),
                  radius: 10,
                ),
                title: Text(calendar.name),
                subtitle: Text(
                  _subtitle(calendar),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _subtitle(DeviceCalendarInfo calendar) {
    final String account = calendar.accountName ?? '—';
    final String googleLabel = calendar.isGoogleAccount ? ' · Google' : '';
    return '$account$googleLabel';
  }

  static int _colorArgb(int value) {
    if (value > 0xFFFFFF) {
      return value;
    }
    return 0xFF000000 | value;
  }

  static Set<String> _initialSelection({
    required List<DeviceCalendarInfo> calendars,
    required List<String>? saved,
  }) {
    if (saved != null && saved.isNotEmpty) {
      return saved.toSet();
    }

    final Set<String> googleIds = calendars
        .where((DeviceCalendarInfo c) => c.isGoogleAccount)
        .map((DeviceCalendarInfo c) => c.id)
        .toSet();

    if (googleIds.isNotEmpty) {
      return googleIds;
    }

    return calendars.map((DeviceCalendarInfo c) => c.id).toSet();
  }
}
