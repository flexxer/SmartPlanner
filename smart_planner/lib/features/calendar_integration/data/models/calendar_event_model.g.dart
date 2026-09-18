// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCalendarEventModelCollection on Isar {
  IsarCollection<CalendarEventModel> get calendarEventModels =>
      this.collection();
}

const CalendarEventModelSchema = CollectionSchema(
  name: r'CalendarEventModel',
  id: 15124112474898114,
  properties: {
    r'calendarId': PropertySchema(
      id: 0,
      name: r'calendarId',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 1,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'deviceEventId': PropertySchema(
      id: 2,
      name: r'deviceEventId',
      type: IsarType.string,
    ),
    r'end': PropertySchema(id: 3, name: r'end', type: IsarType.dateTime),
    r'googleEventId': PropertySchema(
      id: 4,
      name: r'googleEventId',
      type: IsarType.string,
    ),
    r'linkedTaskIds': PropertySchema(
      id: 5,
      name: r'linkedTaskIds',
      type: IsarType.longList,
    ),
    r'recurrenceRuleJson': PropertySchema(
      id: 6,
      name: r'recurrenceRuleJson',
      type: IsarType.string,
    ),
    r'reminderMinutesBefore': PropertySchema(
      id: 7,
      name: r'reminderMinutesBefore',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 8,
      name: r'source',
      type: IsarType.byte,
      enumMap: _CalendarEventModelsourceEnumValueMap,
    ),
    r'start': PropertySchema(id: 9, name: r'start', type: IsarType.dateTime),
    r'syncedDeviceEventIdsJson': PropertySchema(
      id: 10,
      name: r'syncedDeviceEventIdsJson',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 11, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _calendarEventModelEstimateSize,
  serialize: _calendarEventModelSerialize,
  deserialize: _calendarEventModelDeserialize,
  deserializeProp: _calendarEventModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'deviceEventId': IndexSchema(
      id: -9169851619673310280,
      name: r'deviceEventId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deviceEventId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
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
    r'calendarId': IndexSchema(
      id: -7248395326174044983,
      name: r'calendarId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'calendarId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _calendarEventModelGetId,
  getLinks: _calendarEventModelGetLinks,
  attach: _calendarEventModelAttach,
  version: '3.3.2',
);

int _calendarEventModelEstimateSize(
  CalendarEventModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.calendarId.length * 3;
  bytesCount += 3 + object.deviceEventId.length * 3;
  {
    final value = object.googleEventId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.linkedTaskIds.length * 8;
  {
    final value = object.recurrenceRuleJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.syncedDeviceEventIdsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _calendarEventModelSerialize(
  CalendarEventModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.calendarId);
  writer.writeLong(offsets[1], object.colorValue);
  writer.writeString(offsets[2], object.deviceEventId);
  writer.writeDateTime(offsets[3], object.end);
  writer.writeString(offsets[4], object.googleEventId);
  writer.writeLongList(offsets[5], object.linkedTaskIds);
  writer.writeString(offsets[6], object.recurrenceRuleJson);
  writer.writeLong(offsets[7], object.reminderMinutesBefore);
  writer.writeByte(offsets[8], object.source.index);
  writer.writeDateTime(offsets[9], object.start);
  writer.writeString(offsets[10], object.syncedDeviceEventIdsJson);
  writer.writeString(offsets[11], object.title);
  writer.writeDateTime(offsets[12], object.updatedAt);
}

CalendarEventModel _calendarEventModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CalendarEventModel();
  object.calendarId = reader.readString(offsets[0]);
  object.colorValue = reader.readLong(offsets[1]);
  object.deviceEventId = reader.readString(offsets[2]);
  object.end = reader.readDateTime(offsets[3]);
  object.googleEventId = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.linkedTaskIds = reader.readLongList(offsets[5]) ?? [];
  object.recurrenceRuleJson = reader.readStringOrNull(offsets[6]);
  object.reminderMinutesBefore = reader.readLongOrNull(offsets[7]);
  object.source =
      _CalendarEventModelsourceValueEnumMap[reader.readByteOrNull(
        offsets[8],
      )] ??
      EventSource.local;
  object.start = reader.readDateTime(offsets[9]);
  object.syncedDeviceEventIdsJson = reader.readStringOrNull(offsets[10]);
  object.title = reader.readString(offsets[11]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[12]);
  return object;
}

P _calendarEventModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongList(offset) ?? []) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (_CalendarEventModelsourceValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              EventSource.local)
          as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CalendarEventModelsourceEnumValueMap = {
  'local': 0,
  'device': 1,
  'googleApi': 2,
};
const _CalendarEventModelsourceValueEnumMap = {
  0: EventSource.local,
  1: EventSource.device,
  2: EventSource.googleApi,
};

Id _calendarEventModelGetId(CalendarEventModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _calendarEventModelGetLinks(
  CalendarEventModel object,
) {
  return [];
}

void _calendarEventModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  CalendarEventModel object,
) {
  object.id = id;
}

extension CalendarEventModelQueryWhereSort
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QWhere> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }
}

extension CalendarEventModelQueryWhere
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QWhereClause> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  deviceEventIdEqualTo(String deviceEventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'deviceEventId',
          value: [deviceEventId],
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  deviceEventIdNotEqualTo(String deviceEventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceEventId',
                lower: [],
                upper: [deviceEventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceEventId',
                lower: [deviceEventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceEventId',
                lower: [deviceEventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceEventId',
                lower: [],
                upper: [deviceEventId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleEqualTo(String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleNotEqualTo(String title) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleGreaterThan(String title, {bool include = false}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleLessThan(String title, {bool include = false}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleBetween(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleStartsWith(String TitlePrefix) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: ['']),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  titleIsNotEmpty() {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  calendarIdEqualTo(String calendarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'calendarId', value: [calendarId]),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterWhereClause>
  calendarIdNotEqualTo(String calendarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'calendarId',
                lower: [],
                upper: [calendarId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'calendarId',
                lower: [calendarId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'calendarId',
                lower: [calendarId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'calendarId',
                lower: [],
                upper: [calendarId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CalendarEventModelQueryFilter
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'calendarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'calendarId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'calendarId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'calendarId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  calendarIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'calendarId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorValue', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  colorValueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  colorValueLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deviceEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deviceEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  deviceEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  endEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'end', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  endGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'end',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  endLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'end',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  endBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'end',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'googleEventId'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'googleEventId'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'googleEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'googleEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'googleEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'googleEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  googleEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'googleEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'linkedTaskIds', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'linkedTaskIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'linkedTaskIds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'linkedTaskIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', length, true, length, true);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, true, 0, true);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, true, length, include);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', length, include, 999999, true);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  linkedTaskIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'linkedTaskIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'recurrenceRuleJson'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'recurrenceRuleJson'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recurrenceRuleJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'recurrenceRuleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'recurrenceRuleJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recurrenceRuleJson', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  recurrenceRuleJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'recurrenceRuleJson', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reminderMinutesBefore'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reminderMinutesBefore'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reminderMinutesBefore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reminderMinutesBefore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reminderMinutesBefore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  reminderMinutesBeforeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reminderMinutesBefore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  sourceEqualTo(EventSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  sourceGreaterThan(EventSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  sourceLessThan(EventSource value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  sourceBetween(
    EventSource lower,
    EventSource upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  startEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'start', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  startGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'start',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  startLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'start',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  startBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'start',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'syncedDeviceEventIdsJson'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'syncedDeviceEventIdsJson'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncedDeviceEventIdsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'syncedDeviceEventIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'syncedDeviceEventIdsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'syncedDeviceEventIdsJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'syncedDeviceEventIdsJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleGreaterThan(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleLessThan(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleBetween(
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterFilterCondition>
  updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CalendarEventModelQueryObject
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {}

extension CalendarEventModelQueryLinks
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QFilterCondition> {}

extension CalendarEventModelQuerySortBy
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QSortBy> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByCalendarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByCalendarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByDeviceEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByDeviceEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByGoogleEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByGoogleEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByRecurrenceRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByRecurrenceRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByReminderMinutesBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortBySyncedDeviceEventIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortBySyncedDeviceEventIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CalendarEventModelQuerySortThenBy
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QSortThenBy> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByCalendarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByCalendarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByDeviceEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByDeviceEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByGoogleEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByGoogleEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByRecurrenceRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByRecurrenceRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByReminderMinutesBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenBySyncedDeviceEventIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenBySyncedDeviceEventIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CalendarEventModelQueryWhereDistinct
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct> {
  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByCalendarId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calendarId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByDeviceEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'deviceEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'end');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByGoogleEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'googleEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByLinkedTaskIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedTaskIds');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByRecurrenceRuleJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'recurrenceRuleJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderMinutesBefore');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'start');
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctBySyncedDeviceEventIdsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'syncedDeviceEventIdsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEventModel, CalendarEventModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CalendarEventModelQueryProperty
    on QueryBuilder<CalendarEventModel, CalendarEventModel, QQueryProperty> {
  QueryBuilder<CalendarEventModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CalendarEventModel, String, QQueryOperations>
  calendarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calendarId');
    });
  }

  QueryBuilder<CalendarEventModel, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<CalendarEventModel, String, QQueryOperations>
  deviceEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceEventId');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations> endProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'end');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
  googleEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'googleEventId');
    });
  }

  QueryBuilder<CalendarEventModel, List<int>, QQueryOperations>
  linkedTaskIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedTaskIds');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
  recurrenceRuleJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceRuleJson');
    });
  }

  QueryBuilder<CalendarEventModel, int?, QQueryOperations>
  reminderMinutesBeforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderMinutesBefore');
    });
  }

  QueryBuilder<CalendarEventModel, EventSource, QQueryOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime, QQueryOperations> startProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'start');
    });
  }

  QueryBuilder<CalendarEventModel, String?, QQueryOperations>
  syncedDeviceEventIdsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedDeviceEventIdsJson');
    });
  }

  QueryBuilder<CalendarEventModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<CalendarEventModel, DateTime?, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
