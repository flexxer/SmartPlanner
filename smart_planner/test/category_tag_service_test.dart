import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/categories/data/category_repository_impl.dart';
import 'package:smart_planner/features/categories/domain/category_tag_service.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/categories/domain/entities/category_link.dart';
import 'package:smart_planner/features/categories/domain/tagged_entity_type.dart';
import 'package:smart_planner/features/finance/domain/entities/payment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Allows Isar to download its native core once in unit tests.
class _IsarTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  late Directory tempDir;
  late Isar isar;
  late CategoryTagService tagService;
  late CategoryRepositoryImpl categoryRepository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _IsarTestHttpOverrides();
    await Isar.initializeIsarCore(download: true);
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('daylinx_isar_test');
    isar = await Isar.open(
      <CollectionSchema<dynamic>>[
        TaskSchema,
        CategorySchema,
        CategoryLinkSchema,
        PaymentSchema,
      ],
      directory: tempDir.path,
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    categoryRepository = CategoryRepositoryImpl(isar: isar);
    tagService = CategoryTagService(
      categoryRepository: categoryRepository,
      isar: isar,
    );
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Category> saveCategory(String name) async {
    final Id id = await categoryRepository.save(Category.create(name: name));
    final Category? category = await categoryRepository.getById(id);
    return category!;
  }

  test('setTags replaces links for an entity', () async {
    final Category work = await saveCategory('Work');
    final Category home = await saveCategory('Home');
    final Category hobby = await saveCategory('Hobby');

    await tagService.setTags(
      entityType: TaggedEntityType.task,
      entityId: 42,
      categoryIds: <Id>[work.id, home.id],
    );

    var tags = await tagService.getTags(
      entityType: TaggedEntityType.task,
      entityId: 42,
    );
    expect(tags.map((Category c) => c.name).toList(), <String>['Work', 'Home']);

    await tagService.setTags(
      entityType: TaggedEntityType.task,
      entityId: 42,
      categoryIds: <Id>[hobby.id],
    );

    tags = await tagService.getTags(
      entityType: TaggedEntityType.task,
      entityId: 42,
    );
    expect(tags.map((Category c) => c.name).toList(), <String>['Hobby']);
  });

  test('copyFromEntity duplicates tag ids', () async {
    final Category finance = await saveCategory('Finance');

    await tagService.setTags(
      entityType: TaggedEntityType.payment,
      entityId: 7,
      categoryIds: <Id>[finance.id],
    );

    await tagService.copyFromEntity(
      fromType: TaggedEntityType.payment,
      fromId: 7,
      toType: TaggedEntityType.calendarEvent,
      toId: 99,
    );

    final List<Category> eventTags = await tagService.getTags(
      entityType: TaggedEntityType.calendarEvent,
      entityId: 99,
    );
    expect(eventTags.single.name, 'Finance');
  });

  test('deleteLinksForEntity removes all junction rows', () async {
    final Category tag = await saveCategory('Tag');

    await tagService.setTags(
      entityType: TaggedEntityType.task,
      entityId: 1,
      categoryIds: <Id>[tag.id],
    );

    await tagService.deleteLinksForEntity(
      entityType: TaggedEntityType.task,
      entityId: 1,
    );

    final List<Category> tags = await tagService.getTags(
      entityType: TaggedEntityType.task,
      entityId: 1,
    );
    expect(tags, isEmpty);

    final int linkCount = await categoryRepository.countLinks(tag.id);
    expect(linkCount, 0);
  });

  test('getTagsForEntities batch-loads tags for multiple entities', () async {
    final Category work = await saveCategory('Work');
    final Category home = await saveCategory('Home');

    await tagService.setTags(
      entityType: TaggedEntityType.task,
      entityId: 10,
      categoryIds: <Id>[work.id],
    );
    await tagService.setTags(
      entityType: TaggedEntityType.task,
      entityId: 20,
      categoryIds: <Id>[home.id, work.id],
    );

    final Map<int, List<Category>> tags = await tagService.getTagsForEntities(
      entityType: TaggedEntityType.task,
      entityIds: <int>[10, 20, 99],
    );

    expect(tags[10]!.map((Category c) => c.name).toList(), <String>['Work']);
    expect(
      tags[20]!.map((Category c) => c.name).toSet(),
      <String>{'Work', 'Home'},
    );
    expect(tags.containsKey(99), isFalse);

    final Map<int, List<Id>> tagIds = await tagService.getTagIdsForEntities(
      entityType: TaggedEntityType.task,
      entityIds: <int>[10, 20],
    );
    expect(tagIds[10], <Id>[work.id]);
    expect(tagIds[20]!.toSet(), <Id>{work.id, home.id});
  });
}
