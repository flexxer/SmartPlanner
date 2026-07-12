import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/categories/domain/category_filter_utils.dart';

void main() {
  group('CategoryFilterUtils', () {
    test('matchesAnySelectedCategory uses OR semantics', () {
      const Map<int, List<int>> tagIds = <int, List<int>>{
        1: <int>[10, 20],
        2: <int>[30],
      };

      expect(
        CategoryFilterUtils.matchesAnySelectedCategory(
          entityId: 1,
          selectedCategoryIds: <int>[20],
          tagIdsByEntityId: tagIds,
        ),
        isTrue,
      );
      expect(
        CategoryFilterUtils.matchesAnySelectedCategory(
          entityId: 2,
          selectedCategoryIds: <int>[10, 20],
          tagIdsByEntityId: tagIds,
        ),
        isFalse,
      );
      expect(
        CategoryFilterUtils.matchesAnySelectedCategory(
          entityId: 1,
          selectedCategoryIds: const <int>[],
          tagIdsByEntityId: tagIds,
        ),
        isTrue,
      );
    });

    test('filterEntities keeps items with any matching tag', () {
      final List<_Item> items = <_Item>[
        const _Item(1, 'a'),
        const _Item(2, 'b'),
        const _Item(3, 'c'),
      ];
      const Map<int, List<int>> tagIds = <int, List<int>>{
        1: <int>[5],
        3: <int>[6],
      };

      final List<_Item> filtered = CategoryFilterUtils.filterEntities<_Item>(
        items: items,
        idFor: (_Item item) => item.id,
        selectedCategoryIds: <int>[5, 9],
        tagIdsByEntityId: tagIds,
      );

      expect(filtered.map((_Item i) => i.id).toList(), <int>[1]);
    });
  });
}

class _Item {
  const _Item(this.id, this.label);

  final int id;
  final String label;
}
