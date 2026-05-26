import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_create_action.dart';
import 'package:smart_planner/features/deep_links/domain/deep_link_parser.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

void main() {
  final DateTime reference = DateTime(2026, 5, 25, 9, 30);

  group('DeepLinkParser', () {
    test('parses create task link with title and priority', () {
      final Uri uri = Uri.parse(
        'daylinx://create?type=task&title=Купить_струны&priority=2',
      );

      final DeepLinkCreateAction? action =
          DeepLinkParser.parse(uri, referenceNow: reference);

      expect(action, isA<DeepLinkCreateTaskAction>());
      final DeepLinkCreateTaskAction task = action! as DeepLinkCreateTaskAction;
      expect(task.title, 'Купить струны');
      expect(task.priority, TaskPriority.high);
    });

    test('parses create event link with start time', () {
      final Uri uri = Uri.parse(
        'daylinx://create?type=event&title=Встреча&start=14:00',
      );

      final DeepLinkCreateAction? action =
          DeepLinkParser.parse(uri, referenceNow: reference);

      expect(action, isA<DeepLinkCreateEventAction>());
      final DeepLinkCreateEventAction event =
          action! as DeepLinkCreateEventAction;
      expect(event.title, 'Встреча');
      expect(event.start, DateTime(2026, 5, 25, 14, 0));
      expect(event.end, DateTime(2026, 5, 25, 15, 0));
    });

    test('rejects unknown scheme', () {
      final Uri uri = Uri.parse('https://example.com/create?type=task&title=x');
      expect(DeepLinkParser.parse(uri), isNull);
    });

    test('rejects missing title', () {
      final Uri uri = Uri.parse('daylinx://create?type=task');
      expect(DeepLinkParser.parse(uri), isNull);
    });

    test('truncates overly long titles', () {
      final String longTitle = 'a' * 300;
      final Uri uri = Uri.parse(
        'daylinx://create?type=task&title=$longTitle',
      );
      final DeepLinkCreateTaskAction? action =
          DeepLinkParser.parse(uri, referenceNow: reference)
              as DeepLinkCreateTaskAction?;
      expect(action!.title.length, DeepLinkParser.maxTitleLength);
    });
  });
}
