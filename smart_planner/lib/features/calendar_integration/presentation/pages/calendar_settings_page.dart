import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smart_planner/core/finance/currency_picker_section.dart';
import 'package:smart_planner/core/localization/language_picker_section.dart';
import 'package:smart_planner/core/theme/theme_picker_section.dart';

import 'package:smart_planner/core/presentation/widgets/settings_expandable_section.dart';

import 'package:smart_planner/features/notifications/presentation/widgets/day_status_bar_settings_section.dart';

import 'package:smart_planner/features/notifications/presentation/widgets/auto_roll_overdue_settings_section.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/task_digest_settings_section.dart';
import 'package:smart_planner/features/notifications/presentation/widgets/default_reminder_settings_section.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';

import 'package:smart_planner/features/calendar_integration/data/services/calendar_system_settings_launcher.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/calendar_integration/domain/linked_calendar_ids_resolver.dart';

import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'package:smart_planner/features/dashboard/presentation/bloc/dashboard_event.dart';



/// App settings: language, reminders, notifications, device calendars.

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

      final bool wasAwaitingPermission = _error != null;
      final bool granted = await _calendarService.requestPermissions();

      if (!granted) {

        setState(() {

          _loading = false;

          _error = 'calendar_settings_permission_needed'.tr();

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

      if (wasAwaitingPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('calendar_onboarding_permission_granted'.tr()),
          ),
        );
      }

    } on CalendarPermissionDeniedException {

      setState(() {

        _loading = false;

        _error = 'calendar_settings_permission_denied'.tr();

      });

    } catch (e) {

      setState(() {

        _loading = false;

        _error = e.toString();

      });

    }

  }



  Future<void> _openSystemCalendarSettings() async {
    final bool opened = await CalendarSystemSettingsLauncher.open();
    if (!mounted) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('calendar_settings_open_failed'.tr())),
      );
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

        title: Text('settings_page_title'.tr()),

        actions: <Widget>[

          TextButton(

            onPressed: _selectedIds.isEmpty ? null : _save,

            child: Text('common_done'.tr()),

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



    return ListView(

      padding: const EdgeInsets.only(bottom: 24),

      children: <Widget>[

        SettingsExpandableSection(

          title: 'settings_section_language'.tr(),

          initiallyExpanded: true,

          children: const <Widget>[

            LanguagePickerSection(),

          ],

        ),

        SettingsExpandableSection(

          title: 'settings_section_theme'.tr(),

          initiallyExpanded: true,

          children: const <Widget>[

            ThemePickerSection(),

          ],

        ),

        SettingsExpandableSection(

          title: 'settings_section_finance'.tr(),

          initiallyExpanded: true,

          children: const <Widget>[

            CurrencyPickerSection(),

          ],

        ),

        SettingsExpandableSection(

          title: 'settings_section_reminders'.tr(),

          initiallyExpanded: true,

          children: const <Widget>[

            DefaultReminderSettingsSection(),

            AutoRollOverdueSettingsSection(),

            TaskDigestSettingsSection(),

          ],

        ),

        if (DayStatusBarSettingsSection.isSupported)

          SettingsExpandableSection(

            title: 'settings_section_notifications'.tr(),

            children: const <Widget>[

              DayStatusBarSettingsSection(),

            ],

          ),

        SettingsExpandableSection(

          title: 'settings_section_calendars'.tr(),

          initiallyExpanded: true,

          children: _buildCalendarSectionChildren(),

        ),

      ],

    );

  }



  Widget _buildOpenSystemCalendarButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: OutlinedButton.icon(
        onPressed: _openSystemCalendarSettings,
        icon: const Icon(Icons.open_in_new),
        label: Text('calendar_settings_open_system'.tr()),
      ),
    );
  }

  List<Widget> _buildCalendarSectionChildren() {
    final List<Widget> children = <Widget>[
      _buildOpenSystemCalendarButton(),
    ];

    if (_error != null) {
      children.addAll(<Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text('calendar_settings_request_access'.tr()),
              ),
            ],
          ),
        ),
      ]);
      return children;
    }

    if (_calendars.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'calendar_settings_empty'.tr(),
            textAlign: TextAlign.center,
          ),
        ),
      );
      return children;
    }

    children.addAll(<Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'calendar_settings_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
      for (final DeviceCalendarInfo calendar in _calendars)

        CheckboxListTile(

          value: _selectedIds.contains(calendar.id),

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

        ),
    ]);
    return children;
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
      final Set<String> validIds = calendars
          .map(
            (DeviceCalendarInfo c) =>
                LinkedCalendarIdsResolver.normalizeId(c.id),
          )
          .toSet();
      final Set<String> filtered = saved
          .map(LinkedCalendarIdsResolver.normalizeId)
          .where(validIds.contains)
          .toSet();
      if (filtered.isNotEmpty) {
        return filtered;
      }
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

