// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_template.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUiTemplateCollection on Isar {
  IsarCollection<UiTemplate> get uiTemplates => this.collection();
}

const UiTemplateSchema = CollectionSchema(
  name: r'UiTemplate',
  id: -4584535413842022981,
  properties: {
    r'checklistItems': PropertySchema(
      id: 0,
      name: r'checklistItems',
      type: IsarType.stringList,
    ),
    r'embeddedAttachmentJson': PropertySchema(
      id: 1,
      name: r'embeddedAttachmentJson',
      type: IsarType.string,
    ),
    r'templateDescription': PropertySchema(
      id: 2,
      name: r'templateDescription',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 3, name: r'title', type: IsarType.string),
  },

  estimateSize: _uiTemplateEstimateSize,
  serialize: _uiTemplateSerialize,
  deserialize: _uiTemplateDeserialize,
  deserializeProp: _uiTemplateDeserializeProp,
  idName: r'id',
  indexes: {
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _uiTemplateGetId,
  getLinks: _uiTemplateGetLinks,
  attach: _uiTemplateAttach,
  version: '3.3.2',
);

int _uiTemplateEstimateSize(
  UiTemplate object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.checklistItems.length * 3;
  {
    for (var i = 0; i < object.checklistItems.length; i++) {
      final value = object.checklistItems[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.embeddedAttachmentJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.templateDescription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _uiTemplateSerialize(
  UiTemplate object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.checklistItems);
  writer.writeString(offsets[1], object.embeddedAttachmentJson);
  writer.writeString(offsets[2], object.templateDescription);
  writer.writeString(offsets[3], object.title);
}

UiTemplate _uiTemplateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UiTemplate();
  object.checklistItems = reader.readStringList(offsets[0]) ?? [];
  object.embeddedAttachmentJson = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.templateDescription = reader.readStringOrNull(offsets[2]);
  object.title = reader.readString(offsets[3]);
  return object;
}

P _uiTemplateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _uiTemplateGetId(UiTemplate object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _uiTemplateGetLinks(UiTemplate object) {
  return [];
}

void _uiTemplateAttach(IsarCollection<dynamic> col, Id id, UiTemplate object) {
  object.id = id;
}

extension UiTemplateQueryWhereSort
    on QueryBuilder<UiTemplate, UiTemplate, QWhere> {
  QueryBuilder<UiTemplate, UiTemplate, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }
}

extension UiTemplateQueryWhere
    on QueryBuilder<UiTemplate, UiTemplate, QWhereClause> {
  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> idBetween(
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

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleNotEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleGreaterThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [title],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleLessThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [],
          upper: [title],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleBetween(
    String lowerTitle,
    String upperTitle, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [lowerTitle],
          includeLower: includeLower,
          upper: [upperTitle],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleStartsWith(
    String TitlePrefix,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [TitlePrefix],
          upper: ['$TitlePrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: ['']),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterWhereClause> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            );
      }
    });
  }
}

extension UiTemplateQueryFilter
    on QueryBuilder<UiTemplate, UiTemplate, QFilterCondition> {
  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'checklistItems',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'checklistItems',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'checklistItems',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'checklistItems', value: ''),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'checklistItems', value: ''),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checklistItems', length, true, length, true);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checklistItems', 0, true, 0, true);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checklistItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checklistItems', 0, true, length, include);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checklistItems', length, include, 999999, true);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  checklistItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checklistItems',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'embeddedAttachmentJson'),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'embeddedAttachmentJson'),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'embeddedAttachmentJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'embeddedAttachmentJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'embeddedAttachmentJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'embeddedAttachmentJson', value: ''),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  embeddedAttachmentJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'embeddedAttachmentJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'templateDescription'),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'templateDescription'),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'templateDescription',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'templateDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'templateDescription',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'templateDescription', value: ''),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  templateDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'templateDescription',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }
}

extension UiTemplateQueryObject
    on QueryBuilder<UiTemplate, UiTemplate, QFilterCondition> {}

extension UiTemplateQueryLinks
    on QueryBuilder<UiTemplate, UiTemplate, QFilterCondition> {}

extension UiTemplateQuerySortBy
    on QueryBuilder<UiTemplate, UiTemplate, QSortBy> {
  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  sortByEmbeddedAttachmentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddedAttachmentJson', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  sortByEmbeddedAttachmentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddedAttachmentJson', Sort.desc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  sortByTemplateDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateDescription', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  sortByTemplateDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateDescription', Sort.desc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension UiTemplateQuerySortThenBy
    on QueryBuilder<UiTemplate, UiTemplate, QSortThenBy> {
  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  thenByEmbeddedAttachmentJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddedAttachmentJson', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  thenByEmbeddedAttachmentJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddedAttachmentJson', Sort.desc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  thenByTemplateDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateDescription', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy>
  thenByTemplateDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateDescription', Sort.desc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension UiTemplateQueryWhereDistinct
    on QueryBuilder<UiTemplate, UiTemplate, QDistinct> {
  QueryBuilder<UiTemplate, UiTemplate, QDistinct> distinctByChecklistItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checklistItems');
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QDistinct>
  distinctByEmbeddedAttachmentJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'embeddedAttachmentJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QDistinct>
  distinctByTemplateDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'templateDescription',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UiTemplate, UiTemplate, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension UiTemplateQueryProperty
    on QueryBuilder<UiTemplate, UiTemplate, QQueryProperty> {
  QueryBuilder<UiTemplate, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UiTemplate, List<String>, QQueryOperations>
  checklistItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checklistItems');
    });
  }

  QueryBuilder<UiTemplate, String?, QQueryOperations>
  embeddedAttachmentJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embeddedAttachmentJson');
    });
  }

  QueryBuilder<UiTemplate, String?, QQueryOperations>
  templateDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateDescription');
    });
  }

  QueryBuilder<UiTemplate, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
