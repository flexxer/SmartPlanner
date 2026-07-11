// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCalendarEventCollection on Isar {
  IsarCollection<CalendarEvent> get calendarEvents => this.collection();
}

const CalendarEventSchema = CollectionSchema(
  name: r'CalendarEvent',
  id: 2832606634183555054,
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
    r'isLocalOnly': PropertySchema(
      id: 5,
      name: r'isLocalOnly',
      type: IsarType.bool,
    ),
    r'linkedTaskIds': PropertySchema(
      id: 6,
      name: r'linkedTaskIds',
      type: IsarType.longList,
    ),
    r'recurrenceRuleJson': PropertySchema(
      id: 7,
      name: r'recurrenceRuleJson',
      type: IsarType.string,
    ),
    r'reminderMinutesBefore': PropertySchema(
      id: 8,
      name: r'reminderMinutesBefore',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 9,
      name: r'source',
      type: IsarType.byte,
      enumMap: _CalendarEventsourceEnumValueMap,
    ),
    r'start': PropertySchema(id: 10, name: r'start', type: IsarType.dateTime),
    r'syncedDeviceEventIdsJson': PropertySchema(
      id: 11,
      name: r'syncedDeviceEventIdsJson',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 12, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _calendarEventEstimateSize,
  serialize: _calendarEventSerialize,
  deserialize: _calendarEventDeserialize,
  deserializeProp: _calendarEventDeserializeProp,
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

  getId: _calendarEventGetId,
  getLinks: _calendarEventGetLinks,
  attach: _calendarEventAttach,
  version: '3.3.2',
);

int _calendarEventEstimateSize(
  CalendarEvent object,
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

void _calendarEventSerialize(
  CalendarEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.calendarId);
  writer.writeLong(offsets[1], object.colorValue);
  writer.writeString(offsets[2], object.deviceEventId);
  writer.writeDateTime(offsets[3], object.end);
  writer.writeString(offsets[4], object.googleEventId);
  writer.writeBool(offsets[5], object.isLocalOnly);
  writer.writeLongList(offsets[6], object.linkedTaskIds);
  writer.writeString(offsets[7], object.recurrenceRuleJson);
  writer.writeLong(offsets[8], object.reminderMinutesBefore);
  writer.writeByte(offsets[9], object.source.index);
  writer.writeDateTime(offsets[10], object.start);
  writer.writeString(offsets[11], object.syncedDeviceEventIdsJson);
  writer.writeString(offsets[12], object.title);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

CalendarEvent _calendarEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CalendarEvent();
  object.calendarId = reader.readString(offsets[0]);
  object.colorValue = reader.readLong(offsets[1]);
  object.deviceEventId = reader.readString(offsets[2]);
  object.end = reader.readDateTime(offsets[3]);
  object.googleEventId = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.linkedTaskIds = reader.readLongList(offsets[6]) ?? [];
  object.recurrenceRuleJson = reader.readStringOrNull(offsets[7]);
  object.reminderMinutesBefore = reader.readLongOrNull(offsets[8]);
  object.source =
      _CalendarEventsourceValueEnumMap[reader.readByteOrNull(offsets[9])] ??
      EventSource.local;
  object.start = reader.readDateTime(offsets[10]);
  object.syncedDeviceEventIdsJson = reader.readStringOrNull(offsets[11]);
  object.title = reader.readString(offsets[12]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[13]);
  return object;
}

P _calendarEventDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLongList(offset) ?? []) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (_CalendarEventsourceValueEnumMap[reader.readByteOrNull(offset)] ??
              EventSource.local)
          as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CalendarEventsourceEnumValueMap = {
  'local': 0,
  'device': 1,
  'googleApi': 2,
};
const _CalendarEventsourceValueEnumMap = {
  0: EventSource.local,
  1: EventSource.device,
  2: EventSource.googleApi,
};

Id _calendarEventGetId(CalendarEvent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _calendarEventGetLinks(CalendarEvent object) {
  return [];
}

void _calendarEventAttach(
  IsarCollection<dynamic> col,
  Id id,
  CalendarEvent object,
) {
  object.id = id;
}

extension CalendarEventQueryWhereSort
    on QueryBuilder<CalendarEvent, CalendarEvent, QWhere> {
  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }
}

extension CalendarEventQueryWhere
    on QueryBuilder<CalendarEvent, CalendarEvent, QWhereClause> {
  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> idBetween(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleNotEqualTo(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleLessThan(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleBetween(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleStartsWith(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: ['']),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
  calendarIdEqualTo(String calendarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'calendarId', value: [calendarId]),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterWhereClause>
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

extension CalendarEventQueryFilter
    on QueryBuilder<CalendarEvent, CalendarEvent, QFilterCondition> {
  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  calendarIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'calendarId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  calendarIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'calendarId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorValue', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  deviceEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  deviceEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> endEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'end', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> endLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> endBetween(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  googleEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'googleEventId'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  googleEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'googleEventId'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  googleEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'googleEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  googleEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'googleEventId', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  isLocalOnlyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isLocalOnly', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'linkedTaskIds', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', length, true, length, true);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, true, 0, true);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', 0, true, length, include);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  linkedTaskIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'linkedTaskIds', length, include, 999999, true);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  recurrenceRuleJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'recurrenceRuleJson'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  recurrenceRuleJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'recurrenceRuleJson'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  recurrenceRuleJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recurrenceRuleJson', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  recurrenceRuleJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'recurrenceRuleJson', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  reminderMinutesBeforeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reminderMinutesBefore'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  reminderMinutesBeforeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reminderMinutesBefore'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  sourceEqualTo(EventSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  startEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'start', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'syncedDeviceEventIdsJson'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  syncedDeviceEventIdsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'syncedDeviceEventIdsJson'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
  updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterFilterCondition>
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

extension CalendarEventQueryObject
    on QueryBuilder<CalendarEvent, CalendarEvent, QFilterCondition> {}

extension CalendarEventQueryLinks
    on QueryBuilder<CalendarEvent, CalendarEvent, QFilterCondition> {}

extension CalendarEventQuerySortBy
    on QueryBuilder<CalendarEvent, CalendarEvent, QSortBy> {
  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByCalendarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByCalendarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByDeviceEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByDeviceEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByGoogleEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByGoogleEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByIsLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocalOnly', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByIsLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocalOnly', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByRecurrenceRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByRecurrenceRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByReminderMinutesBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortBySyncedDeviceEventIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortBySyncedDeviceEventIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CalendarEventQuerySortThenBy
    on QueryBuilder<CalendarEvent, CalendarEvent, QSortThenBy> {
  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByCalendarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByCalendarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calendarId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByDeviceEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByDeviceEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByGoogleEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByGoogleEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleEventId', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByIsLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocalOnly', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByIsLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocalOnly', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByRecurrenceRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByRecurrenceRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceRuleJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByReminderMinutesBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesBefore', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenBySyncedDeviceEventIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenBySyncedDeviceEventIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedDeviceEventIdsJson', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CalendarEventQueryWhereDistinct
    on QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> {
  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByCalendarId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calendarId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByDeviceEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'deviceEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'end');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByGoogleEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'googleEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByIsLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocalOnly');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByLinkedTaskIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedTaskIds');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByRecurrenceRuleJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'recurrenceRuleJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctByReminderMinutesBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderMinutesBefore');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'start');
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct>
  distinctBySyncedDeviceEventIdsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'syncedDeviceEventIdsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CalendarEvent, CalendarEvent, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CalendarEventQueryProperty
    on QueryBuilder<CalendarEvent, CalendarEvent, QQueryProperty> {
  QueryBuilder<CalendarEvent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CalendarEvent, String, QQueryOperations> calendarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calendarId');
    });
  }

  QueryBuilder<CalendarEvent, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<CalendarEvent, String, QQueryOperations>
  deviceEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceEventId');
    });
  }

  QueryBuilder<CalendarEvent, DateTime, QQueryOperations> endProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'end');
    });
  }

  QueryBuilder<CalendarEvent, String?, QQueryOperations>
  googleEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'googleEventId');
    });
  }

  QueryBuilder<CalendarEvent, bool, QQueryOperations> isLocalOnlyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocalOnly');
    });
  }

  QueryBuilder<CalendarEvent, List<int>, QQueryOperations>
  linkedTaskIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedTaskIds');
    });
  }

  QueryBuilder<CalendarEvent, String?, QQueryOperations>
  recurrenceRuleJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceRuleJson');
    });
  }

  QueryBuilder<CalendarEvent, int?, QQueryOperations>
  reminderMinutesBeforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderMinutesBefore');
    });
  }

  QueryBuilder<CalendarEvent, EventSource, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<CalendarEvent, DateTime, QQueryOperations> startProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'start');
    });
  }

  QueryBuilder<CalendarEvent, String?, QQueryOperations>
  syncedDeviceEventIdsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedDeviceEventIdsJson');
    });
  }

  QueryBuilder<CalendarEvent, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<CalendarEvent, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
