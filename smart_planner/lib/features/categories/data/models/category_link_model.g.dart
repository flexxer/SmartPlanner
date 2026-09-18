// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_link_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCategoryLinkModelCollection on Isar {
  IsarCollection<CategoryLinkModel> get categoryLinkModels => this.collection();
}

const CategoryLinkModelSchema = CollectionSchema(
  name: r'CategoryLink',
  id: -3577824777422675610,
  properties: {
    r'categoryId': PropertySchema(
      id: 0,
      name: r'categoryId',
      type: IsarType.long,
    ),
    r'entityId': PropertySchema(id: 1, name: r'entityId', type: IsarType.long),
    r'entityType': PropertySchema(
      id: 2,
      name: r'entityType',
      type: IsarType.byte,
      enumMap: _CategoryLinkModelentityTypeEnumValueMap,
    ),
  },

  estimateSize: _categoryLinkModelEstimateSize,
  serialize: _categoryLinkModelSerialize,
  deserialize: _categoryLinkModelDeserialize,
  deserializeProp: _categoryLinkModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'entityId': IndexSchema(
      id: 745355021660786263,
      name: r'entityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'categoryId': IndexSchema(
      id: -8798048739239305339,
      name: r'categoryId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'categoryId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _categoryLinkModelGetId,
  getLinks: _categoryLinkModelGetLinks,
  attach: _categoryLinkModelAttach,
  version: '3.3.2',
);

int _categoryLinkModelEstimateSize(
  CategoryLinkModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _categoryLinkModelSerialize(
  CategoryLinkModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.categoryId);
  writer.writeLong(offsets[1], object.entityId);
  writer.writeByte(offsets[2], object.entityType.index);
}

CategoryLinkModel _categoryLinkModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CategoryLinkModel();
  object.categoryId = reader.readLong(offsets[0]);
  object.entityId = reader.readLong(offsets[1]);
  object.entityType =
      _CategoryLinkModelentityTypeValueEnumMap[reader.readByteOrNull(
        offsets[2],
      )] ??
      TaggedEntityType.task;
  object.id = id;
  return object;
}

P _categoryLinkModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (_CategoryLinkModelentityTypeValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              TaggedEntityType.task)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CategoryLinkModelentityTypeEnumValueMap = {
  'task': 0,
  'calendarEvent': 1,
  'payment': 2,
};
const _CategoryLinkModelentityTypeValueEnumMap = {
  0: TaggedEntityType.task,
  1: TaggedEntityType.calendarEvent,
  2: TaggedEntityType.payment,
};

Id _categoryLinkModelGetId(CategoryLinkModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _categoryLinkModelGetLinks(
  CategoryLinkModel object,
) {
  return [];
}

void _categoryLinkModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  CategoryLinkModel object,
) {
  object.id = id;
}

extension CategoryLinkModelQueryWhereSort
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QWhere> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhere>
  anyEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'entityId'),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhere>
  anyCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'categoryId'),
      );
    });
  }
}

extension CategoryLinkModelQueryWhere
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QWhereClause> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  entityIdEqualTo(int entityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityId', value: [entityId]),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  entityIdNotEqualTo(int entityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  entityIdGreaterThan(int entityId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'entityId',
          lower: [entityId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  entityIdLessThan(int entityId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'entityId',
          lower: [],
          upper: [entityId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  entityIdBetween(
    int lowerEntityId,
    int upperEntityId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'entityId',
          lower: [lowerEntityId],
          includeLower: includeLower,
          upper: [upperEntityId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  categoryIdEqualTo(int categoryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'categoryId', value: [categoryId]),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  categoryIdNotEqualTo(int categoryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryId',
                lower: [],
                upper: [categoryId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryId',
                lower: [categoryId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryId',
                lower: [categoryId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'categoryId',
                lower: [],
                upper: [categoryId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  categoryIdGreaterThan(int categoryId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'categoryId',
          lower: [categoryId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  categoryIdLessThan(int categoryId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'categoryId',
          lower: [],
          upper: [categoryId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterWhereClause>
  categoryIdBetween(
    int lowerCategoryId,
    int upperCategoryId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'categoryId',
          lower: [lowerCategoryId],
          includeLower: includeLower,
          upper: [upperCategoryId],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CategoryLinkModelQueryFilter
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QFilterCondition> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  categoryIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categoryId', value: value),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  categoryIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categoryId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  categoryIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categoryId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  categoryIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categoryId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityId', value: value),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityTypeEqualTo(TaggedEntityType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityType', value: value),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityTypeGreaterThan(TaggedEntityType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityTypeLessThan(TaggedEntityType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  entityTypeBetween(
    TaggedEntityType lower,
    TaggedEntityType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CategoryLinkModelQueryObject
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QFilterCondition> {}

extension CategoryLinkModelQueryLinks
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QFilterCondition> {}

extension CategoryLinkModelQuerySortBy
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QSortBy> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }
}

extension CategoryLinkModelQuerySortThenBy
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QSortThenBy> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension CategoryLinkModelQueryWhereDistinct
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QDistinct> {
  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QDistinct>
  distinctByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId');
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QDistinct>
  distinctByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId');
    });
  }

  QueryBuilder<CategoryLinkModel, CategoryLinkModel, QDistinct>
  distinctByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType');
    });
  }
}

extension CategoryLinkModelQueryProperty
    on QueryBuilder<CategoryLinkModel, CategoryLinkModel, QQueryProperty> {
  QueryBuilder<CategoryLinkModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CategoryLinkModel, int, QQueryOperations> categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<CategoryLinkModel, int, QQueryOperations> entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<CategoryLinkModel, TaggedEntityType, QQueryOperations>
  entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }
}
