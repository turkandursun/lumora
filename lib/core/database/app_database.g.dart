// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderFrequency, String>
      frequency = GeneratedColumn<String>('frequency', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ReminderFrequency>(
              $RemindersTable.$converterfrequency);
  static const VerificationMeta _weekdayMeta =
      const VerificationMeta('weekday');
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
      'weekday', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
      'minute', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        iconKey,
        frequency,
        weekday,
        hour,
        minute,
        enabled,
        userId,
        supabaseId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(_weekdayMeta,
          weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta));
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(_minuteMeta,
          minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta));
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      frequency: $RemindersTable.$converterfrequency.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!),
      weekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekday']),
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      minute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderFrequency, String, String>
      $converterfrequency =
      const EnumNameConverter<ReminderFrequency>(ReminderFrequency.values);
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final int id;
  final String title;
  final String iconKey;
  final ReminderFrequency frequency;

  /// Day of week (1 = Monday .. 7 = Sunday, matching [DateTime.weekday]).
  /// Only meaningful when [frequency] is [ReminderFrequency.weekly].
  final int? weekday;
  final int hour;
  final int minute;
  final bool enabled;
  final String? userId;
  final String? supabaseId;
  const ReminderRow(
      {required this.id,
      required this.title,
      required this.iconKey,
      required this.frequency,
      this.weekday,
      required this.hour,
      required this.minute,
      required this.enabled,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['icon_key'] = Variable<String>(iconKey);
    {
      map['frequency'] = Variable<String>(
          $RemindersTable.$converterfrequency.toSql(frequency));
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      iconKey: Value(iconKey),
      frequency: Value(frequency),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      hour: Value(hour),
      minute: Value(minute),
      enabled: Value(enabled),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      frequency: $RemindersTable.$converterfrequency
          .fromJson(serializer.fromJson<String>(json['frequency'])),
      weekday: serializer.fromJson<int?>(json['weekday']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'iconKey': serializer.toJson<String>(iconKey),
      'frequency': serializer.toJson<String>(
          $RemindersTable.$converterfrequency.toJson(frequency)),
      'weekday': serializer.toJson<int?>(weekday),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'enabled': serializer.toJson<bool>(enabled),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  ReminderRow copyWith(
          {int? id,
          String? title,
          String? iconKey,
          ReminderFrequency? frequency,
          Value<int?> weekday = const Value.absent(),
          int? hour,
          int? minute,
          bool? enabled,
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      ReminderRow(
        id: id ?? this.id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        frequency: frequency ?? this.frequency,
        weekday: weekday.present ? weekday.value : this.weekday,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('frequency: $frequency, ')
          ..write('weekday: $weekday, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, iconKey, frequency, weekday, hour,
      minute, enabled, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.iconKey == this.iconKey &&
          other.frequency == this.frequency &&
          other.weekday == this.weekday &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.enabled == this.enabled &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> iconKey;
  final Value<ReminderFrequency> frequency;
  final Value<int?> weekday;
  final Value<int> hour;
  final Value<int> minute;
  final Value<bool> enabled;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.frequency = const Value.absent(),
    this.weekday = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.enabled = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String iconKey,
    required ReminderFrequency frequency,
    this.weekday = const Value.absent(),
    required int hour,
    required int minute,
    this.enabled = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : title = Value(title),
        iconKey = Value(iconKey),
        frequency = Value(frequency),
        hour = Value(hour),
        minute = Value(minute);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? iconKey,
    Expression<String>? frequency,
    Expression<int>? weekday,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<bool>? enabled,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (iconKey != null) 'icon_key': iconKey,
      if (frequency != null) 'frequency': frequency,
      if (weekday != null) 'weekday': weekday,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (enabled != null) 'enabled': enabled,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  RemindersCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? iconKey,
      Value<ReminderFrequency>? frequency,
      Value<int?>? weekday,
      Value<int>? hour,
      Value<int>? minute,
      Value<bool>? enabled,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(
          $RemindersTable.$converterfrequency.toSql(frequency.value));
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('frequency: $frequency, ')
          ..write('weekday: $weekday, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<GoalUnit, String> unit =
      GeneratedColumn<String>('unit', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<GoalUnit>($GoalsTable.$converterunit);
  static const VerificationMeta _customUnitLabelMeta =
      const VerificationMeta('customUnitLabel');
  @override
  late final GeneratedColumn<String> customUnitLabel = GeneratedColumn<String>(
      'custom_unit_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
      'target', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<GoalFrequency, String> frequency =
      GeneratedColumn<String>('frequency', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<GoalFrequency>($GoalsTable.$converterfrequency);
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
      'period_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        iconKey,
        unit,
        customUnitLabel,
        target,
        progress,
        frequency,
        periodStart,
        userId,
        supabaseId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<GoalRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('custom_unit_label')) {
      context.handle(
          _customUnitLabelMeta,
          customUnitLabel.isAcceptableOrUnknown(
              data['custom_unit_label']!, _customUnitLabelMeta));
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      unit: $GoalsTable.$converterunit.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!),
      customUnitLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_unit_label']),
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      frequency: $GoalsTable.$converterfrequency.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!),
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}period_start'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalUnit, String, String> $converterunit =
      const EnumNameConverter<GoalUnit>(GoalUnit.values);
  static JsonTypeConverter2<GoalFrequency, String, String> $converterfrequency =
      const EnumNameConverter<GoalFrequency>(GoalFrequency.values);
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final int id;
  final String title;
  final String iconKey;
  final GoalUnit unit;

  /// User-provided unit label, only set when [unit] is [GoalUnit.custom].
  final String? customUnitLabel;
  final int target;
  final int progress;
  final GoalFrequency frequency;

  /// Start of the period [progress] is currently counting toward — midnight
  /// of today, this week's Monday, or this month's 1st, depending on
  /// [frequency].
  final DateTime periodStart;

  /// Supabase auth ID of the user who owns this goal.
  final String? userId;

  /// Remote primary key in Supabase `goals` table.
  final String? supabaseId;
  const GoalRow(
      {required this.id,
      required this.title,
      required this.iconKey,
      required this.unit,
      this.customUnitLabel,
      required this.target,
      required this.progress,
      required this.frequency,
      required this.periodStart,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['icon_key'] = Variable<String>(iconKey);
    {
      map['unit'] = Variable<String>($GoalsTable.$converterunit.toSql(unit));
    }
    if (!nullToAbsent || customUnitLabel != null) {
      map['custom_unit_label'] = Variable<String>(customUnitLabel);
    }
    map['target'] = Variable<int>(target);
    map['progress'] = Variable<int>(progress);
    {
      map['frequency'] =
          Variable<String>($GoalsTable.$converterfrequency.toSql(frequency));
    }
    map['period_start'] = Variable<DateTime>(periodStart);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      iconKey: Value(iconKey),
      unit: Value(unit),
      customUnitLabel: customUnitLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customUnitLabel),
      target: Value(target),
      progress: Value(progress),
      frequency: Value(frequency),
      periodStart: Value(periodStart),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory GoalRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      unit: $GoalsTable.$converterunit
          .fromJson(serializer.fromJson<String>(json['unit'])),
      customUnitLabel: serializer.fromJson<String?>(json['customUnitLabel']),
      target: serializer.fromJson<int>(json['target']),
      progress: serializer.fromJson<int>(json['progress']),
      frequency: $GoalsTable.$converterfrequency
          .fromJson(serializer.fromJson<String>(json['frequency'])),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'iconKey': serializer.toJson<String>(iconKey),
      'unit':
          serializer.toJson<String>($GoalsTable.$converterunit.toJson(unit)),
      'customUnitLabel': serializer.toJson<String?>(customUnitLabel),
      'target': serializer.toJson<int>(target),
      'progress': serializer.toJson<int>(progress),
      'frequency': serializer
          .toJson<String>($GoalsTable.$converterfrequency.toJson(frequency)),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  GoalRow copyWith(
          {int? id,
          String? title,
          String? iconKey,
          GoalUnit? unit,
          Value<String?> customUnitLabel = const Value.absent(),
          int? target,
          int? progress,
          GoalFrequency? frequency,
          DateTime? periodStart,
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      GoalRow(
        id: id ?? this.id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        unit: unit ?? this.unit,
        customUnitLabel: customUnitLabel.present
            ? customUnitLabel.value
            : this.customUnitLabel,
        target: target ?? this.target,
        progress: progress ?? this.progress,
        frequency: frequency ?? this.frequency,
        periodStart: periodStart ?? this.periodStart,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      unit: data.unit.present ? data.unit.value : this.unit,
      customUnitLabel: data.customUnitLabel.present
          ? data.customUnitLabel.value
          : this.customUnitLabel,
      target: data.target.present ? data.target.value : this.target,
      progress: data.progress.present ? data.progress.value : this.progress,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('unit: $unit, ')
          ..write('customUnitLabel: $customUnitLabel, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('frequency: $frequency, ')
          ..write('periodStart: $periodStart, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, iconKey, unit, customUnitLabel,
      target, progress, frequency, periodStart, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.iconKey == this.iconKey &&
          other.unit == this.unit &&
          other.customUnitLabel == this.customUnitLabel &&
          other.target == this.target &&
          other.progress == this.progress &&
          other.frequency == this.frequency &&
          other.periodStart == this.periodStart &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> iconKey;
  final Value<GoalUnit> unit;
  final Value<String?> customUnitLabel;
  final Value<int> target;
  final Value<int> progress;
  final Value<GoalFrequency> frequency;
  final Value<DateTime> periodStart;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.unit = const Value.absent(),
    this.customUnitLabel = const Value.absent(),
    this.target = const Value.absent(),
    this.progress = const Value.absent(),
    this.frequency = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String iconKey,
    required GoalUnit unit,
    this.customUnitLabel = const Value.absent(),
    required int target,
    this.progress = const Value.absent(),
    required GoalFrequency frequency,
    required DateTime periodStart,
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : title = Value(title),
        iconKey = Value(iconKey),
        unit = Value(unit),
        target = Value(target),
        frequency = Value(frequency),
        periodStart = Value(periodStart);
  static Insertable<GoalRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? iconKey,
    Expression<String>? unit,
    Expression<String>? customUnitLabel,
    Expression<int>? target,
    Expression<int>? progress,
    Expression<String>? frequency,
    Expression<DateTime>? periodStart,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (iconKey != null) 'icon_key': iconKey,
      if (unit != null) 'unit': unit,
      if (customUnitLabel != null) 'custom_unit_label': customUnitLabel,
      if (target != null) 'target': target,
      if (progress != null) 'progress': progress,
      if (frequency != null) 'frequency': frequency,
      if (periodStart != null) 'period_start': periodStart,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? iconKey,
      Value<GoalUnit>? unit,
      Value<String?>? customUnitLabel,
      Value<int>? target,
      Value<int>? progress,
      Value<GoalFrequency>? frequency,
      Value<DateTime>? periodStart,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      unit: unit ?? this.unit,
      customUnitLabel: customUnitLabel ?? this.customUnitLabel,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      frequency: frequency ?? this.frequency,
      periodStart: periodStart ?? this.periodStart,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (unit.present) {
      map['unit'] =
          Variable<String>($GoalsTable.$converterunit.toSql(unit.value));
    }
    if (customUnitLabel.present) {
      map['custom_unit_label'] = Variable<String>(customUnitLabel.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(
          $GoalsTable.$converterfrequency.toSql(frequency.value));
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconKey: $iconKey, ')
          ..write('unit: $unit, ')
          ..write('customUnitLabel: $customUnitLabel, ')
          ..write('target: $target, ')
          ..write('progress: $progress, ')
          ..write('frequency: $frequency, ')
          ..write('periodStart: $periodStart, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $DreamsTable extends Dreams with TableInfo<$DreamsTable, DreamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolTagsMeta =
      const VerificationMeta('symbolTags');
  @override
  late final GeneratedColumn<String> symbolTags = GeneratedColumn<String>(
      'symbol_tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _feelingTagMeta =
      const VerificationMeta('feelingTag');
  @override
  late final GeneratedColumn<String> feelingTag = GeneratedColumn<String>(
      'feeling_tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _familiarPersonMeta =
      const VerificationMeta('familiarPerson');
  @override
  late final GeneratedColumn<String> familiarPerson = GeneratedColumn<String>(
      'familiar_person', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firstThoughtMeta =
      const VerificationMeta('firstThought');
  @override
  late final GeneratedColumn<String> firstThought = GeneratedColumn<String>(
      'first_thought', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lifeConnectionMeta =
      const VerificationMeta('lifeConnection');
  @override
  late final GeneratedColumn<String> lifeConnection = GeneratedColumn<String>(
      'life_connection', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiInterpretationMeta =
      const VerificationMeta('aiInterpretation');
  @override
  late final GeneratedColumn<String> aiInterpretation = GeneratedColumn<String>(
      'ai_interpretation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        content,
        symbolTags,
        feelingTag,
        familiarPerson,
        firstThought,
        lifeConnection,
        aiInterpretation,
        userId,
        supabaseId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dreams';
  @override
  VerificationContext validateIntegrity(Insertable<DreamRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('symbol_tags')) {
      context.handle(
          _symbolTagsMeta,
          symbolTags.isAcceptableOrUnknown(
              data['symbol_tags']!, _symbolTagsMeta));
    }
    if (data.containsKey('feeling_tag')) {
      context.handle(
          _feelingTagMeta,
          feelingTag.isAcceptableOrUnknown(
              data['feeling_tag']!, _feelingTagMeta));
    }
    if (data.containsKey('familiar_person')) {
      context.handle(
          _familiarPersonMeta,
          familiarPerson.isAcceptableOrUnknown(
              data['familiar_person']!, _familiarPersonMeta));
    }
    if (data.containsKey('first_thought')) {
      context.handle(
          _firstThoughtMeta,
          firstThought.isAcceptableOrUnknown(
              data['first_thought']!, _firstThoughtMeta));
    }
    if (data.containsKey('life_connection')) {
      context.handle(
          _lifeConnectionMeta,
          lifeConnection.isAcceptableOrUnknown(
              data['life_connection']!, _lifeConnectionMeta));
    }
    if (data.containsKey('ai_interpretation')) {
      context.handle(
          _aiInterpretationMeta,
          aiInterpretation.isAcceptableOrUnknown(
              data['ai_interpretation']!, _aiInterpretationMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DreamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DreamRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      symbolTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol_tags'])!,
      feelingTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feeling_tag']),
      familiarPerson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}familiar_person']),
      firstThought: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_thought']),
      lifeConnection: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}life_connection']),
      aiInterpretation: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ai_interpretation']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $DreamsTable createAlias(String alias) {
    return $DreamsTable(attachedDatabase, alias);
  }
}

class DreamRow extends DataClass implements Insertable<DreamRow> {
  final int id;
  final DateTime date;
  final String content;

  /// Comma-separated canonical symbol keys detected in [content] at save
  /// time (e.g. `"water,flying"`). Kept denormalized rather than a join
  /// table — dream entries are immutable once saved, so there's nothing to
  /// keep in sync, and the tag set is always a subset of the small fixed
  /// symbol dictionary.
  final String symbolTags;

  /// Answers to the optional post-save reflection flow (see
  /// `DreamReflectionScreen`) — every field stays null when its question
  /// was skipped; there's no forced completion.
  final String? feelingTag;
  final String? familiarPerson;
  final String? firstThought;
  final String? lifeConnection;

  /// Cached AI-generated reflection from the `dream-interpret` Edge
  /// Function, kept alongside the locally-detected [symbolTags] rather than
  /// replacing them. Null until the user explicitly requests an
  /// interpretation; re-requesting overwrites it rather than appending.
  final String? aiInterpretation;

  /// The Supabase auth user ID owning this entry.
  final String? userId;

  /// The primary key ID in Supabase's `dreams` cloud table.
  final String? supabaseId;
  const DreamRow(
      {required this.id,
      required this.date,
      required this.content,
      required this.symbolTags,
      this.feelingTag,
      this.familiarPerson,
      this.firstThought,
      this.lifeConnection,
      this.aiInterpretation,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['content'] = Variable<String>(content);
    map['symbol_tags'] = Variable<String>(symbolTags);
    if (!nullToAbsent || feelingTag != null) {
      map['feeling_tag'] = Variable<String>(feelingTag);
    }
    if (!nullToAbsent || familiarPerson != null) {
      map['familiar_person'] = Variable<String>(familiarPerson);
    }
    if (!nullToAbsent || firstThought != null) {
      map['first_thought'] = Variable<String>(firstThought);
    }
    if (!nullToAbsent || lifeConnection != null) {
      map['life_connection'] = Variable<String>(lifeConnection);
    }
    if (!nullToAbsent || aiInterpretation != null) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  DreamsCompanion toCompanion(bool nullToAbsent) {
    return DreamsCompanion(
      id: Value(id),
      date: Value(date),
      content: Value(content),
      symbolTags: Value(symbolTags),
      feelingTag: feelingTag == null && nullToAbsent
          ? const Value.absent()
          : Value(feelingTag),
      familiarPerson: familiarPerson == null && nullToAbsent
          ? const Value.absent()
          : Value(familiarPerson),
      firstThought: firstThought == null && nullToAbsent
          ? const Value.absent()
          : Value(firstThought),
      lifeConnection: lifeConnection == null && nullToAbsent
          ? const Value.absent()
          : Value(lifeConnection),
      aiInterpretation: aiInterpretation == null && nullToAbsent
          ? const Value.absent()
          : Value(aiInterpretation),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory DreamRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DreamRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      content: serializer.fromJson<String>(json['content']),
      symbolTags: serializer.fromJson<String>(json['symbolTags']),
      feelingTag: serializer.fromJson<String?>(json['feelingTag']),
      familiarPerson: serializer.fromJson<String?>(json['familiarPerson']),
      firstThought: serializer.fromJson<String?>(json['firstThought']),
      lifeConnection: serializer.fromJson<String?>(json['lifeConnection']),
      aiInterpretation: serializer.fromJson<String?>(json['aiInterpretation']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'content': serializer.toJson<String>(content),
      'symbolTags': serializer.toJson<String>(symbolTags),
      'feelingTag': serializer.toJson<String?>(feelingTag),
      'familiarPerson': serializer.toJson<String?>(familiarPerson),
      'firstThought': serializer.toJson<String?>(firstThought),
      'lifeConnection': serializer.toJson<String?>(lifeConnection),
      'aiInterpretation': serializer.toJson<String?>(aiInterpretation),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  DreamRow copyWith(
          {int? id,
          DateTime? date,
          String? content,
          String? symbolTags,
          Value<String?> feelingTag = const Value.absent(),
          Value<String?> familiarPerson = const Value.absent(),
          Value<String?> firstThought = const Value.absent(),
          Value<String?> lifeConnection = const Value.absent(),
          Value<String?> aiInterpretation = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      DreamRow(
        id: id ?? this.id,
        date: date ?? this.date,
        content: content ?? this.content,
        symbolTags: symbolTags ?? this.symbolTags,
        feelingTag: feelingTag.present ? feelingTag.value : this.feelingTag,
        familiarPerson:
            familiarPerson.present ? familiarPerson.value : this.familiarPerson,
        firstThought:
            firstThought.present ? firstThought.value : this.firstThought,
        lifeConnection:
            lifeConnection.present ? lifeConnection.value : this.lifeConnection,
        aiInterpretation: aiInterpretation.present
            ? aiInterpretation.value
            : this.aiInterpretation,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  DreamRow copyWithCompanion(DreamsCompanion data) {
    return DreamRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      content: data.content.present ? data.content.value : this.content,
      symbolTags:
          data.symbolTags.present ? data.symbolTags.value : this.symbolTags,
      feelingTag:
          data.feelingTag.present ? data.feelingTag.value : this.feelingTag,
      familiarPerson: data.familiarPerson.present
          ? data.familiarPerson.value
          : this.familiarPerson,
      firstThought: data.firstThought.present
          ? data.firstThought.value
          : this.firstThought,
      lifeConnection: data.lifeConnection.present
          ? data.lifeConnection.value
          : this.lifeConnection,
      aiInterpretation: data.aiInterpretation.present
          ? data.aiInterpretation.value
          : this.aiInterpretation,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DreamRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('symbolTags: $symbolTags, ')
          ..write('feelingTag: $feelingTag, ')
          ..write('familiarPerson: $familiarPerson, ')
          ..write('firstThought: $firstThought, ')
          ..write('lifeConnection: $lifeConnection, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      date,
      content,
      symbolTags,
      feelingTag,
      familiarPerson,
      firstThought,
      lifeConnection,
      aiInterpretation,
      userId,
      supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DreamRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.content == this.content &&
          other.symbolTags == this.symbolTags &&
          other.feelingTag == this.feelingTag &&
          other.familiarPerson == this.familiarPerson &&
          other.firstThought == this.firstThought &&
          other.lifeConnection == this.lifeConnection &&
          other.aiInterpretation == this.aiInterpretation &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class DreamsCompanion extends UpdateCompanion<DreamRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> content;
  final Value<String> symbolTags;
  final Value<String?> feelingTag;
  final Value<String?> familiarPerson;
  final Value<String?> firstThought;
  final Value<String?> lifeConnection;
  final Value<String?> aiInterpretation;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const DreamsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.content = const Value.absent(),
    this.symbolTags = const Value.absent(),
    this.feelingTag = const Value.absent(),
    this.familiarPerson = const Value.absent(),
    this.firstThought = const Value.absent(),
    this.lifeConnection = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  DreamsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String content,
    this.symbolTags = const Value.absent(),
    this.feelingTag = const Value.absent(),
    this.familiarPerson = const Value.absent(),
    this.firstThought = const Value.absent(),
    this.lifeConnection = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : date = Value(date),
        content = Value(content);
  static Insertable<DreamRow> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? content,
    Expression<String>? symbolTags,
    Expression<String>? feelingTag,
    Expression<String>? familiarPerson,
    Expression<String>? firstThought,
    Expression<String>? lifeConnection,
    Expression<String>? aiInterpretation,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (content != null) 'content': content,
      if (symbolTags != null) 'symbol_tags': symbolTags,
      if (feelingTag != null) 'feeling_tag': feelingTag,
      if (familiarPerson != null) 'familiar_person': familiarPerson,
      if (firstThought != null) 'first_thought': firstThought,
      if (lifeConnection != null) 'life_connection': lifeConnection,
      if (aiInterpretation != null) 'ai_interpretation': aiInterpretation,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  DreamsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? content,
      Value<String>? symbolTags,
      Value<String?>? feelingTag,
      Value<String?>? familiarPerson,
      Value<String?>? firstThought,
      Value<String?>? lifeConnection,
      Value<String?>? aiInterpretation,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return DreamsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      symbolTags: symbolTags ?? this.symbolTags,
      feelingTag: feelingTag ?? this.feelingTag,
      familiarPerson: familiarPerson ?? this.familiarPerson,
      firstThought: firstThought ?? this.firstThought,
      lifeConnection: lifeConnection ?? this.lifeConnection,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (symbolTags.present) {
      map['symbol_tags'] = Variable<String>(symbolTags.value);
    }
    if (feelingTag.present) {
      map['feeling_tag'] = Variable<String>(feelingTag.value);
    }
    if (familiarPerson.present) {
      map['familiar_person'] = Variable<String>(familiarPerson.value);
    }
    if (firstThought.present) {
      map['first_thought'] = Variable<String>(firstThought.value);
    }
    if (lifeConnection.present) {
      map['life_connection'] = Variable<String>(lifeConnection.value);
    }
    if (aiInterpretation.present) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('symbolTags: $symbolTags, ')
          ..write('feelingTag: $feelingTag, ')
          ..write('familiarPerson: $familiarPerson, ')
          ..write('firstThought: $firstThought, ')
          ..write('lifeConnection: $lifeConnection, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, content, title, audioPath, photoUrl, userId, supabaseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(Insertable<JournalEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntryRow extends DataClass implements Insertable<JournalEntryRow> {
  final int id;
  final DateTime createdAt;
  final String content;

  /// Optional short heading the user typed for this entry.
  final String? title;

  /// Absolute path to an attached voice-note recording, if the entry has
  /// one. Null for text-only entries (the common case).
  final String? audioPath;

  /// Remote signed URL or local path to an attached photo.
  final String? photoUrl;

  /// ID of the Supabase user who owns this entry.
  final String? userId;

  /// Remote primary key ID in Supabase's `journal_entries` table.
  final String? supabaseId;
  const JournalEntryRow(
      {required this.id,
      required this.createdAt,
      required this.content,
      this.title,
      this.audioPath,
      this.photoUrl,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      content: Value(content),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory JournalEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      content: serializer.fromJson<String>(json['content']),
      title: serializer.fromJson<String?>(json['title']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'content': serializer.toJson<String>(content),
      'title': serializer.toJson<String?>(title),
      'audioPath': serializer.toJson<String?>(audioPath),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  JournalEntryRow copyWith(
          {int? id,
          DateTime? createdAt,
          String? content,
          Value<String?> title = const Value.absent(),
          Value<String?> audioPath = const Value.absent(),
          Value<String?> photoUrl = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      JournalEntryRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        content: content ?? this.content,
        title: title.present ? title.value : this.title,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  JournalEntryRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      content: data.content.present ? data.content.value : this.content,
      title: data.title.present ? data.title.value : this.title,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('title: $title, ')
          ..write('audioPath: $audioPath, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, createdAt, content, title, audioPath, photoUrl, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.content == this.content &&
          other.title == this.title &&
          other.audioPath == this.audioPath &&
          other.photoUrl == this.photoUrl &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> content;
  final Value<String?> title;
  final Value<String?> audioPath;
  final Value<String?> photoUrl;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.content = const Value.absent(),
    this.title = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String content,
    this.title = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : createdAt = Value(createdAt),
        content = Value(content);
  static Insertable<JournalEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? content,
    Expression<String>? title,
    Expression<String>? audioPath,
    Expression<String>? photoUrl,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (content != null) 'content': content,
      if (title != null) 'title': title,
      if (audioPath != null) 'audio_path': audioPath,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  JournalEntriesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? createdAt,
      Value<String>? content,
      Value<String?>? title,
      Value<String?>? audioPath,
      Value<String?>? photoUrl,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('content: $content, ')
          ..write('title: $title, ')
          ..write('audioPath: $audioPath, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $DailyQuestionAnswersTable extends DailyQuestionAnswers
    with TableInfo<$DailyQuestionAnswersTable, DailyQuestionAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyQuestionAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _questionIndexMeta =
      const VerificationMeta('questionIndex');
  @override
  late final GeneratedColumn<int> questionIndex = GeneratedColumn<int>(
      'question_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _answerTextMeta =
      const VerificationMeta('answerText');
  @override
  late final GeneratedColumn<String> answerText = GeneratedColumn<String>(
      'answer_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSharedToCommunityMeta =
      const VerificationMeta('isSharedToCommunity');
  @override
  late final GeneratedColumn<bool> isSharedToCommunity = GeneratedColumn<bool>(
      'is_shared_to_community', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_shared_to_community" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _communityShareIdMeta =
      const VerificationMeta('communityShareId');
  @override
  late final GeneratedColumn<String> communityShareId = GeneratedColumn<String>(
      'community_share_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        questionIndex,
        answerText,
        isSharedToCommunity,
        communityShareId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_question_answers';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyQuestionAnswerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('question_index')) {
      context.handle(
          _questionIndexMeta,
          questionIndex.isAcceptableOrUnknown(
              data['question_index']!, _questionIndexMeta));
    } else if (isInserting) {
      context.missing(_questionIndexMeta);
    }
    if (data.containsKey('answer_text')) {
      context.handle(
          _answerTextMeta,
          answerText.isAcceptableOrUnknown(
              data['answer_text']!, _answerTextMeta));
    } else if (isInserting) {
      context.missing(_answerTextMeta);
    }
    if (data.containsKey('is_shared_to_community')) {
      context.handle(
          _isSharedToCommunityMeta,
          isSharedToCommunity.isAcceptableOrUnknown(
              data['is_shared_to_community']!, _isSharedToCommunityMeta));
    }
    if (data.containsKey('community_share_id')) {
      context.handle(
          _communityShareIdMeta,
          communityShareId.isAcceptableOrUnknown(
              data['community_share_id']!, _communityShareIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyQuestionAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyQuestionAnswerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      questionIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_index'])!,
      answerText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer_text'])!,
      isSharedToCommunity: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_shared_to_community'])!,
      communityShareId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}community_share_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyQuestionAnswersTable createAlias(String alias) {
    return $DailyQuestionAnswersTable(attachedDatabase, alias);
  }
}

class DailyQuestionAnswerRow extends DataClass
    implements Insertable<DailyQuestionAnswerRow> {
  final int id;

  /// Midnight of the calendar day this question/answer belongs to.
  final DateTime date;

  /// Index into `dailyQuestionBank`, so the question text stays localized
  /// and re-orderable rather than frozen as whatever string was shown when
  /// it was answered.
  final int questionIndex;
  final String answerText;
  final bool isSharedToCommunity;

  /// The matching row's id in Supabase's `daily_question_shares` table, or
  /// null when [isSharedToCommunity] is false.
  final String? communityShareId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyQuestionAnswerRow(
      {required this.id,
      required this.date,
      required this.questionIndex,
      required this.answerText,
      required this.isSharedToCommunity,
      this.communityShareId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['question_index'] = Variable<int>(questionIndex);
    map['answer_text'] = Variable<String>(answerText);
    map['is_shared_to_community'] = Variable<bool>(isSharedToCommunity);
    if (!nullToAbsent || communityShareId != null) {
      map['community_share_id'] = Variable<String>(communityShareId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyQuestionAnswersCompanion toCompanion(bool nullToAbsent) {
    return DailyQuestionAnswersCompanion(
      id: Value(id),
      date: Value(date),
      questionIndex: Value(questionIndex),
      answerText: Value(answerText),
      isSharedToCommunity: Value(isSharedToCommunity),
      communityShareId: communityShareId == null && nullToAbsent
          ? const Value.absent()
          : Value(communityShareId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyQuestionAnswerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyQuestionAnswerRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      questionIndex: serializer.fromJson<int>(json['questionIndex']),
      answerText: serializer.fromJson<String>(json['answerText']),
      isSharedToCommunity:
          serializer.fromJson<bool>(json['isSharedToCommunity']),
      communityShareId: serializer.fromJson<String?>(json['communityShareId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'questionIndex': serializer.toJson<int>(questionIndex),
      'answerText': serializer.toJson<String>(answerText),
      'isSharedToCommunity': serializer.toJson<bool>(isSharedToCommunity),
      'communityShareId': serializer.toJson<String?>(communityShareId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyQuestionAnswerRow copyWith(
          {int? id,
          DateTime? date,
          int? questionIndex,
          String? answerText,
          bool? isSharedToCommunity,
          Value<String?> communityShareId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DailyQuestionAnswerRow(
        id: id ?? this.id,
        date: date ?? this.date,
        questionIndex: questionIndex ?? this.questionIndex,
        answerText: answerText ?? this.answerText,
        isSharedToCommunity: isSharedToCommunity ?? this.isSharedToCommunity,
        communityShareId: communityShareId.present
            ? communityShareId.value
            : this.communityShareId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyQuestionAnswerRow copyWithCompanion(DailyQuestionAnswersCompanion data) {
    return DailyQuestionAnswerRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      questionIndex: data.questionIndex.present
          ? data.questionIndex.value
          : this.questionIndex,
      answerText:
          data.answerText.present ? data.answerText.value : this.answerText,
      isSharedToCommunity: data.isSharedToCommunity.present
          ? data.isSharedToCommunity.value
          : this.isSharedToCommunity,
      communityShareId: data.communityShareId.present
          ? data.communityShareId.value
          : this.communityShareId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyQuestionAnswerRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('answerText: $answerText, ')
          ..write('isSharedToCommunity: $isSharedToCommunity, ')
          ..write('communityShareId: $communityShareId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, questionIndex, answerText,
      isSharedToCommunity, communityShareId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyQuestionAnswerRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.questionIndex == this.questionIndex &&
          other.answerText == this.answerText &&
          other.isSharedToCommunity == this.isSharedToCommunity &&
          other.communityShareId == this.communityShareId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyQuestionAnswersCompanion
    extends UpdateCompanion<DailyQuestionAnswerRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> questionIndex;
  final Value<String> answerText;
  final Value<bool> isSharedToCommunity;
  final Value<String?> communityShareId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DailyQuestionAnswersCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.questionIndex = const Value.absent(),
    this.answerText = const Value.absent(),
    this.isSharedToCommunity = const Value.absent(),
    this.communityShareId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyQuestionAnswersCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int questionIndex,
    required String answerText,
    this.isSharedToCommunity = const Value.absent(),
    this.communityShareId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : date = Value(date),
        questionIndex = Value(questionIndex),
        answerText = Value(answerText),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DailyQuestionAnswerRow> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? questionIndex,
    Expression<String>? answerText,
    Expression<bool>? isSharedToCommunity,
    Expression<String>? communityShareId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (questionIndex != null) 'question_index': questionIndex,
      if (answerText != null) 'answer_text': answerText,
      if (isSharedToCommunity != null)
        'is_shared_to_community': isSharedToCommunity,
      if (communityShareId != null) 'community_share_id': communityShareId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyQuestionAnswersCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int>? questionIndex,
      Value<String>? answerText,
      Value<bool>? isSharedToCommunity,
      Value<String?>? communityShareId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return DailyQuestionAnswersCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      questionIndex: questionIndex ?? this.questionIndex,
      answerText: answerText ?? this.answerText,
      isSharedToCommunity: isSharedToCommunity ?? this.isSharedToCommunity,
      communityShareId: communityShareId ?? this.communityShareId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (questionIndex.present) {
      map['question_index'] = Variable<int>(questionIndex.value);
    }
    if (answerText.present) {
      map['answer_text'] = Variable<String>(answerText.value);
    }
    if (isSharedToCommunity.present) {
      map['is_shared_to_community'] = Variable<bool>(isSharedToCommunity.value);
    }
    if (communityShareId.present) {
      map['community_share_id'] = Variable<String>(communityShareId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyQuestionAnswersCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('answerText: $answerText, ')
          ..write('isSharedToCommunity: $isSharedToCommunity, ')
          ..write('communityShareId: $communityShareId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _activityIdsJsonMeta =
      const VerificationMeta('activityIdsJson');
  @override
  late final GeneratedColumn<String> activityIdsJson = GeneratedColumn<String>(
      'activity_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityTextMeta =
      const VerificationMeta('activityText');
  @override
  late final GeneratedColumn<String> activityText = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        activityIdsJson,
        activityText,
        photoPath,
        photoUrl,
        userId,
        supabaseId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('activity_ids_json')) {
      context.handle(
          _activityIdsJsonMeta,
          activityIdsJson.isAcceptableOrUnknown(
              data['activity_ids_json']!, _activityIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_activityIdsJsonMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_activityTextMeta,
          activityText.isAcceptableOrUnknown(data['text']!, _activityTextMeta));
    } else if (isInserting) {
      context.missing(_activityTextMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      activityIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}activity_ids_json'])!,
      activityText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final int id;
  final DateTime createdAt;
  final String activityIdsJson;
  final String activityText;
  final String? photoPath;
  final String? photoUrl;
  final String? userId;
  final String? supabaseId;
  const ActivityRow(
      {required this.id,
      required this.createdAt,
      required this.activityIdsJson,
      required this.activityText,
      this.photoPath,
      this.photoUrl,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['activity_ids_json'] = Variable<String>(activityIdsJson);
    map['text'] = Variable<String>(activityText);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      activityIdsJson: Value(activityIdsJson),
      activityText: Value(activityText),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory ActivityRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      activityIdsJson: serializer.fromJson<String>(json['activityIdsJson']),
      activityText: serializer.fromJson<String>(json['activityText']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'activityIdsJson': serializer.toJson<String>(activityIdsJson),
      'activityText': serializer.toJson<String>(activityText),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  ActivityRow copyWith(
          {int? id,
          DateTime? createdAt,
          String? activityIdsJson,
          String? activityText,
          Value<String?> photoPath = const Value.absent(),
          Value<String?> photoUrl = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      ActivityRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        activityIdsJson: activityIdsJson ?? this.activityIdsJson,
        activityText: activityText ?? this.activityText,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  ActivityRow copyWithCompanion(ActivitiesCompanion data) {
    return ActivityRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      activityIdsJson: data.activityIdsJson.present
          ? data.activityIdsJson.value
          : this.activityIdsJson,
      activityText: data.activityText.present
          ? data.activityText.value
          : this.activityText,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('activityIdsJson: $activityIdsJson, ')
          ..write('activityText: $activityText, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, activityIdsJson, activityText,
      photoPath, photoUrl, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.activityIdsJson == this.activityIdsJson &&
          other.activityText == this.activityText &&
          other.photoPath == this.photoPath &&
          other.photoUrl == this.photoUrl &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> activityIdsJson;
  final Value<String> activityText;
  final Value<String?> photoPath;
  final Value<String?> photoUrl;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.activityIdsJson = const Value.absent(),
    this.activityText = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String activityIdsJson,
    required String activityText,
    this.photoPath = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : createdAt = Value(createdAt),
        activityIdsJson = Value(activityIdsJson),
        activityText = Value(activityText);
  static Insertable<ActivityRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? activityIdsJson,
    Expression<String>? activityText,
    Expression<String>? photoPath,
    Expression<String>? photoUrl,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (activityIdsJson != null) 'activity_ids_json': activityIdsJson,
      if (activityText != null) 'text': activityText,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  ActivitiesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? createdAt,
      Value<String>? activityIdsJson,
      Value<String>? activityText,
      Value<String?>? photoPath,
      Value<String?>? photoUrl,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      activityIdsJson: activityIdsJson ?? this.activityIdsJson,
      activityText: activityText ?? this.activityText,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (activityIdsJson.present) {
      map['activity_ids_json'] = Variable<String>(activityIdsJson.value);
    }
    if (activityText.present) {
      map['text'] = Variable<String>(activityText.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('activityIdsJson: $activityIdsJson, ')
          ..write('activityText: $activityText, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $LettersTable extends Letters with TableInfo<$LettersTable, LetterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LettersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _openAtMeta = const VerificationMeta('openAt');
  @override
  late final GeneratedColumn<DateTime> openAt = GeneratedColumn<DateTime>(
      'open_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, openAt, title, body, userId, supabaseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letters';
  @override
  VerificationContext validateIntegrity(Insertable<LetterRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('open_at')) {
      context.handle(_openAtMeta,
          openAt.isAcceptableOrUnknown(data['open_at']!, _openAtMeta));
    } else if (isInserting) {
      context.missing(_openAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LetterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      openAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}open_at'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $LettersTable createAlias(String alias) {
    return $LettersTable(attachedDatabase, alias);
  }
}

class LetterRow extends DataClass implements Insertable<LetterRow> {
  final int id;
  final DateTime createdAt;
  final DateTime openAt;
  final String title;
  final String body;
  final String? userId;
  final String? supabaseId;
  const LetterRow(
      {required this.id,
      required this.createdAt,
      required this.openAt,
      required this.title,
      required this.body,
      this.userId,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['open_at'] = Variable<DateTime>(openAt);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  LettersCompanion toCompanion(bool nullToAbsent) {
    return LettersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      openAt: Value(openAt),
      title: Value(title),
      body: Value(body),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory LetterRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      openAt: serializer.fromJson<DateTime>(json['openAt']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      userId: serializer.fromJson<String?>(json['userId']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'openAt': serializer.toJson<DateTime>(openAt),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'userId': serializer.toJson<String?>(userId),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  LetterRow copyWith(
          {int? id,
          DateTime? createdAt,
          DateTime? openAt,
          String? title,
          String? body,
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      LetterRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        openAt: openAt ?? this.openAt,
        title: title ?? this.title,
        body: body ?? this.body,
        userId: userId.present ? userId.value : this.userId,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  LetterRow copyWithCompanion(LettersCompanion data) {
    return LetterRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      openAt: data.openAt.present ? data.openAt.value : this.openAt,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      userId: data.userId.present ? data.userId.value : this.userId,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('openAt: $openAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, openAt, title, body, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.openAt == this.openAt &&
          other.title == this.title &&
          other.body == this.body &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class LettersCompanion extends UpdateCompanion<LetterRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> openAt;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const LettersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.openAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  LettersCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required DateTime openAt,
    required String title,
    required String body,
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : createdAt = Value(createdAt),
        openAt = Value(openAt),
        title = Value(title),
        body = Value(body);
  static Insertable<LetterRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? openAt,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (openAt != null) 'open_at': openAt,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (userId != null) 'user_id': userId,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  LettersCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? openAt,
      Value<String>? title,
      Value<String>? body,
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return LettersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      openAt: openAt ?? this.openAt,
      title: title ?? this.title,
      body: body ?? this.body,
      userId: userId ?? this.userId,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (openAt.present) {
      map['open_at'] = Variable<DateTime>(openAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LettersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('openAt: $openAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $QuotesTable extends Quotes with TableInfo<$QuotesTable, QuoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textTrMeta = const VerificationMeta('textTr');
  @override
  late final GeneratedColumn<String> textTr = GeneratedColumn<String>(
      'text_tr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
      'text_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rotationOrderMeta =
      const VerificationMeta('rotationOrder');
  @override
  late final GeneratedColumn<int> rotationOrder = GeneratedColumn<int>(
      'rotation_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, textTr, textEn, author, rotationOrder, isActive, source, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotes';
  @override
  VerificationContext validateIntegrity(Insertable<QuoteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_tr')) {
      context.handle(_textTrMeta,
          textTr.isAcceptableOrUnknown(data['text_tr']!, _textTrMeta));
    } else if (isInserting) {
      context.missing(_textTrMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(_textEnMeta,
          textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta));
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('rotation_order')) {
      context.handle(
          _rotationOrderMeta,
          rotationOrder.isAcceptableOrUnknown(
              data['rotation_order']!, _rotationOrderMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      textTr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_tr'])!,
      textEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_en'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      rotationOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rotation_order']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }
}

class QuoteRow extends DataClass implements Insertable<QuoteRow> {
  final String id;
  final String textTr;
  final String textEn;
  final String? author;
  final int? rotationOrder;
  final bool isActive;
  final String source;
  final DateTime updatedAt;
  const QuoteRow(
      {required this.id,
      required this.textTr,
      required this.textEn,
      this.author,
      this.rotationOrder,
      required this.isActive,
      required this.source,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_tr'] = Variable<String>(textTr);
    map['text_en'] = Variable<String>(textEn);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || rotationOrder != null) {
      map['rotation_order'] = Variable<int>(rotationOrder);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['source'] = Variable<String>(source);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      textTr: Value(textTr),
      textEn: Value(textEn),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      rotationOrder: rotationOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationOrder),
      isActive: Value(isActive),
      source: Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteRow(
      id: serializer.fromJson<String>(json['id']),
      textTr: serializer.fromJson<String>(json['textTr']),
      textEn: serializer.fromJson<String>(json['textEn']),
      author: serializer.fromJson<String?>(json['author']),
      rotationOrder: serializer.fromJson<int?>(json['rotationOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      source: serializer.fromJson<String>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textTr': serializer.toJson<String>(textTr),
      'textEn': serializer.toJson<String>(textEn),
      'author': serializer.toJson<String?>(author),
      'rotationOrder': serializer.toJson<int?>(rotationOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'source': serializer.toJson<String>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuoteRow copyWith(
          {String? id,
          String? textTr,
          String? textEn,
          Value<String?> author = const Value.absent(),
          Value<int?> rotationOrder = const Value.absent(),
          bool? isActive,
          String? source,
          DateTime? updatedAt}) =>
      QuoteRow(
        id: id ?? this.id,
        textTr: textTr ?? this.textTr,
        textEn: textEn ?? this.textEn,
        author: author.present ? author.value : this.author,
        rotationOrder:
            rotationOrder.present ? rotationOrder.value : this.rotationOrder,
        isActive: isActive ?? this.isActive,
        source: source ?? this.source,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  QuoteRow copyWithCompanion(QuotesCompanion data) {
    return QuoteRow(
      id: data.id.present ? data.id.value : this.id,
      textTr: data.textTr.present ? data.textTr.value : this.textTr,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      author: data.author.present ? data.author.value : this.author,
      rotationOrder: data.rotationOrder.present
          ? data.rotationOrder.value
          : this.rotationOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRow(')
          ..write('id: $id, ')
          ..write('textTr: $textTr, ')
          ..write('textEn: $textEn, ')
          ..write('author: $author, ')
          ..write('rotationOrder: $rotationOrder, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, textTr, textEn, author, rotationOrder, isActive, source, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteRow &&
          other.id == this.id &&
          other.textTr == this.textTr &&
          other.textEn == this.textEn &&
          other.author == this.author &&
          other.rotationOrder == this.rotationOrder &&
          other.isActive == this.isActive &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class QuotesCompanion extends UpdateCompanion<QuoteRow> {
  final Value<String> id;
  final Value<String> textTr;
  final Value<String> textEn;
  final Value<String?> author;
  final Value<int?> rotationOrder;
  final Value<bool> isActive;
  final Value<String> source;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.textTr = const Value.absent(),
    this.textEn = const Value.absent(),
    this.author = const Value.absent(),
    this.rotationOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuotesCompanion.insert({
    required String id,
    required String textTr,
    required String textEn,
    this.author = const Value.absent(),
    this.rotationOrder = const Value.absent(),
    required bool isActive,
    required String source,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        textTr = Value(textTr),
        textEn = Value(textEn),
        isActive = Value(isActive),
        source = Value(source),
        updatedAt = Value(updatedAt);
  static Insertable<QuoteRow> custom({
    Expression<String>? id,
    Expression<String>? textTr,
    Expression<String>? textEn,
    Expression<String>? author,
    Expression<int>? rotationOrder,
    Expression<bool>? isActive,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textTr != null) 'text_tr': textTr,
      if (textEn != null) 'text_en': textEn,
      if (author != null) 'author': author,
      if (rotationOrder != null) 'rotation_order': rotationOrder,
      if (isActive != null) 'is_active': isActive,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? textTr,
      Value<String>? textEn,
      Value<String?>? author,
      Value<int?>? rotationOrder,
      Value<bool>? isActive,
      Value<String>? source,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return QuotesCompanion(
      id: id ?? this.id,
      textTr: textTr ?? this.textTr,
      textEn: textEn ?? this.textEn,
      author: author ?? this.author,
      rotationOrder: rotationOrder ?? this.rotationOrder,
      isActive: isActive ?? this.isActive,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textTr.present) {
      map['text_tr'] = Variable<String>(textTr.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (rotationOrder.present) {
      map['rotation_order'] = Variable<int>(rotationOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('textTr: $textTr, ')
          ..write('textEn: $textEn, ')
          ..write('author: $author, ')
          ..write('rotationOrder: $rotationOrder, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuoteFavoritesTable extends QuoteFavorites
    with TableInfo<$QuoteFavoritesTable, QuoteFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuoteFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quoteIdMeta =
      const VerificationMeta('quoteId');
  @override
  late final GeneratedColumn<String> quoteId = GeneratedColumn<String>(
      'quote_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_favorite" IN (0, 1))'));
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _changedAtMeta =
      const VerificationMeta('changedAt');
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
      'changed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, quoteId, isFavorite, syncState, changedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote_favorites';
  @override
  VerificationContext validateIntegrity(Insertable<QuoteFavoriteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('quote_id')) {
      context.handle(_quoteIdMeta,
          quoteId.isAcceptableOrUnknown(data['quote_id']!, _quoteIdMeta));
    } else if (isInserting) {
      context.missing(_quoteIdMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(_changedAtMeta,
          changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta));
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, quoteId};
  @override
  QuoteFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteFavoriteRow(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      quoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quote_id'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      changedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}changed_at'])!,
    );
  }

  @override
  $QuoteFavoritesTable createAlias(String alias) {
    return $QuoteFavoritesTable(attachedDatabase, alias);
  }
}

class QuoteFavoriteRow extends DataClass
    implements Insertable<QuoteFavoriteRow> {
  final String userId;
  final String quoteId;
  final bool isFavorite;
  final String syncState;
  final DateTime changedAt;
  const QuoteFavoriteRow(
      {required this.userId,
      required this.quoteId,
      required this.isFavorite,
      required this.syncState,
      required this.changedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['quote_id'] = Variable<String>(quoteId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['sync_state'] = Variable<String>(syncState);
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  QuoteFavoritesCompanion toCompanion(bool nullToAbsent) {
    return QuoteFavoritesCompanion(
      userId: Value(userId),
      quoteId: Value(quoteId),
      isFavorite: Value(isFavorite),
      syncState: Value(syncState),
      changedAt: Value(changedAt),
    );
  }

  factory QuoteFavoriteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteFavoriteRow(
      userId: serializer.fromJson<String>(json['userId']),
      quoteId: serializer.fromJson<String>(json['quoteId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      syncState: serializer.fromJson<String>(json['syncState']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'quoteId': serializer.toJson<String>(quoteId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'syncState': serializer.toJson<String>(syncState),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  QuoteFavoriteRow copyWith(
          {String? userId,
          String? quoteId,
          bool? isFavorite,
          String? syncState,
          DateTime? changedAt}) =>
      QuoteFavoriteRow(
        userId: userId ?? this.userId,
        quoteId: quoteId ?? this.quoteId,
        isFavorite: isFavorite ?? this.isFavorite,
        syncState: syncState ?? this.syncState,
        changedAt: changedAt ?? this.changedAt,
      );
  QuoteFavoriteRow copyWithCompanion(QuoteFavoritesCompanion data) {
    return QuoteFavoriteRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      quoteId: data.quoteId.present ? data.quoteId.value : this.quoteId,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteFavoriteRow(')
          ..write('userId: $userId, ')
          ..write('quoteId: $quoteId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('syncState: $syncState, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, quoteId, isFavorite, syncState, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteFavoriteRow &&
          other.userId == this.userId &&
          other.quoteId == this.quoteId &&
          other.isFavorite == this.isFavorite &&
          other.syncState == this.syncState &&
          other.changedAt == this.changedAt);
}

class QuoteFavoritesCompanion extends UpdateCompanion<QuoteFavoriteRow> {
  final Value<String> userId;
  final Value<String> quoteId;
  final Value<bool> isFavorite;
  final Value<String> syncState;
  final Value<DateTime> changedAt;
  final Value<int> rowid;
  const QuoteFavoritesCompanion({
    this.userId = const Value.absent(),
    this.quoteId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.syncState = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuoteFavoritesCompanion.insert({
    required String userId,
    required String quoteId,
    required bool isFavorite,
    required String syncState,
    required DateTime changedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        quoteId = Value(quoteId),
        isFavorite = Value(isFavorite),
        syncState = Value(syncState),
        changedAt = Value(changedAt);
  static Insertable<QuoteFavoriteRow> custom({
    Expression<String>? userId,
    Expression<String>? quoteId,
    Expression<bool>? isFavorite,
    Expression<String>? syncState,
    Expression<DateTime>? changedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (quoteId != null) 'quote_id': quoteId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (syncState != null) 'sync_state': syncState,
      if (changedAt != null) 'changed_at': changedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuoteFavoritesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? quoteId,
      Value<bool>? isFavorite,
      Value<String>? syncState,
      Value<DateTime>? changedAt,
      Value<int>? rowid}) {
    return QuoteFavoritesCompanion(
      userId: userId ?? this.userId,
      quoteId: quoteId ?? this.quoteId,
      isFavorite: isFavorite ?? this.isFavorite,
      syncState: syncState ?? this.syncState,
      changedAt: changedAt ?? this.changedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (quoteId.present) {
      map['quote_id'] = Variable<String>(quoteId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuoteFavoritesCompanion(')
          ..write('userId: $userId, ')
          ..write('quoteId: $quoteId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('syncState: $syncState, ')
          ..write('changedAt: $changedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $DreamsTable dreams = $DreamsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $DailyQuestionAnswersTable dailyQuestionAnswers =
      $DailyQuestionAnswersTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $LettersTable letters = $LettersTable(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  late final $QuoteFavoritesTable quoteFavorites = $QuoteFavoritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        reminders,
        goals,
        dreams,
        journalEntries,
        dailyQuestionAnswers,
        activities,
        letters,
        quotes,
        quoteFavorites
      ];
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required String title,
  required String iconKey,
  required ReminderFrequency frequency,
  Value<int?> weekday,
  required int hour,
  required int minute,
  Value<bool> enabled,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> iconKey,
  Value<ReminderFrequency> frequency,
  Value<int?> weekday,
  Value<int> hour,
  Value<int> minute,
  Value<bool> enabled,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ReminderFrequency, ReminderFrequency, String>
      get frequency => $composableBuilder(
          column: $table.frequency,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderFrequency, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<ReminderFrequency> frequency = const Value.absent(),
            Value<int?> weekday = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<int> minute = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            title: title,
            iconKey: iconKey,
            frequency: frequency,
            weekday: weekday,
            hour: hour,
            minute: minute,
            enabled: enabled,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String iconKey,
            required ReminderFrequency frequency,
            Value<int?> weekday = const Value.absent(),
            required int hour,
            required int minute,
            Value<bool> enabled = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            title: title,
            iconKey: iconKey,
            frequency: frequency,
            weekday: weekday,
            hour: hour,
            minute: minute,
            enabled: enabled,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String title,
  required String iconKey,
  required GoalUnit unit,
  Value<String?> customUnitLabel,
  required int target,
  Value<int> progress,
  required GoalFrequency frequency,
  required DateTime periodStart,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> iconKey,
  Value<GoalUnit> unit,
  Value<String?> customUnitLabel,
  Value<int> target,
  Value<int> progress,
  Value<GoalFrequency> frequency,
  Value<DateTime> periodStart,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GoalUnit, GoalUnit, String> get unit =>
      $composableBuilder(
          column: $table.unit,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get customUnitLabel => $composableBuilder(
      column: $table.customUnitLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GoalFrequency, GoalFrequency, String>
      get frequency => $composableBuilder(
          column: $table.frequency,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customUnitLabel => $composableBuilder(
      column: $table.customUnitLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get customUnitLabel => $composableBuilder(
      column: $table.customUnitLabel, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalFrequency, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    GoalRow,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
    GoalRow,
    PrefetchHooks Function()> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<GoalUnit> unit = const Value.absent(),
            Value<String?> customUnitLabel = const Value.absent(),
            Value<int> target = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<GoalFrequency> frequency = const Value.absent(),
            Value<DateTime> periodStart = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            title: title,
            iconKey: iconKey,
            unit: unit,
            customUnitLabel: customUnitLabel,
            target: target,
            progress: progress,
            frequency: frequency,
            periodStart: periodStart,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String iconKey,
            required GoalUnit unit,
            Value<String?> customUnitLabel = const Value.absent(),
            required int target,
            Value<int> progress = const Value.absent(),
            required GoalFrequency frequency,
            required DateTime periodStart,
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            title: title,
            iconKey: iconKey,
            unit: unit,
            customUnitLabel: customUnitLabel,
            target: target,
            progress: progress,
            frequency: frequency,
            periodStart: periodStart,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    GoalRow,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
    GoalRow,
    PrefetchHooks Function()>;
typedef $$DreamsTableCreateCompanionBuilder = DreamsCompanion Function({
  Value<int> id,
  required DateTime date,
  required String content,
  Value<String> symbolTags,
  Value<String?> feelingTag,
  Value<String?> familiarPerson,
  Value<String?> firstThought,
  Value<String?> lifeConnection,
  Value<String?> aiInterpretation,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$DreamsTableUpdateCompanionBuilder = DreamsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> content,
  Value<String> symbolTags,
  Value<String?> feelingTag,
  Value<String?> familiarPerson,
  Value<String?> firstThought,
  Value<String?> lifeConnection,
  Value<String?> aiInterpretation,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$DreamsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbolTags => $composableBuilder(
      column: $table.symbolTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feelingTag => $composableBuilder(
      column: $table.feelingTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get familiarPerson => $composableBuilder(
      column: $table.familiarPerson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstThought => $composableBuilder(
      column: $table.firstThought, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lifeConnection => $composableBuilder(
      column: $table.lifeConnection,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiInterpretation => $composableBuilder(
      column: $table.aiInterpretation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$DreamsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbolTags => $composableBuilder(
      column: $table.symbolTags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feelingTag => $composableBuilder(
      column: $table.feelingTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get familiarPerson => $composableBuilder(
      column: $table.familiarPerson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstThought => $composableBuilder(
      column: $table.firstThought,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lifeConnection => $composableBuilder(
      column: $table.lifeConnection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiInterpretation => $composableBuilder(
      column: $table.aiInterpretation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$DreamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get symbolTags => $composableBuilder(
      column: $table.symbolTags, builder: (column) => column);

  GeneratedColumn<String> get feelingTag => $composableBuilder(
      column: $table.feelingTag, builder: (column) => column);

  GeneratedColumn<String> get familiarPerson => $composableBuilder(
      column: $table.familiarPerson, builder: (column) => column);

  GeneratedColumn<String> get firstThought => $composableBuilder(
      column: $table.firstThought, builder: (column) => column);

  GeneratedColumn<String> get lifeConnection => $composableBuilder(
      column: $table.lifeConnection, builder: (column) => column);

  GeneratedColumn<String> get aiInterpretation => $composableBuilder(
      column: $table.aiInterpretation, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$DreamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DreamsTable,
    DreamRow,
    $$DreamsTableFilterComposer,
    $$DreamsTableOrderingComposer,
    $$DreamsTableAnnotationComposer,
    $$DreamsTableCreateCompanionBuilder,
    $$DreamsTableUpdateCompanionBuilder,
    (DreamRow, BaseReferences<_$AppDatabase, $DreamsTable, DreamRow>),
    DreamRow,
    PrefetchHooks Function()> {
  $$DreamsTableTableManager(_$AppDatabase db, $DreamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> symbolTags = const Value.absent(),
            Value<String?> feelingTag = const Value.absent(),
            Value<String?> familiarPerson = const Value.absent(),
            Value<String?> firstThought = const Value.absent(),
            Value<String?> lifeConnection = const Value.absent(),
            Value<String?> aiInterpretation = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              DreamsCompanion(
            id: id,
            date: date,
            content: content,
            symbolTags: symbolTags,
            feelingTag: feelingTag,
            familiarPerson: familiarPerson,
            firstThought: firstThought,
            lifeConnection: lifeConnection,
            aiInterpretation: aiInterpretation,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String content,
            Value<String> symbolTags = const Value.absent(),
            Value<String?> feelingTag = const Value.absent(),
            Value<String?> familiarPerson = const Value.absent(),
            Value<String?> firstThought = const Value.absent(),
            Value<String?> lifeConnection = const Value.absent(),
            Value<String?> aiInterpretation = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              DreamsCompanion.insert(
            id: id,
            date: date,
            content: content,
            symbolTags: symbolTags,
            feelingTag: feelingTag,
            familiarPerson: familiarPerson,
            firstThought: firstThought,
            lifeConnection: lifeConnection,
            aiInterpretation: aiInterpretation,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DreamsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DreamsTable,
    DreamRow,
    $$DreamsTableFilterComposer,
    $$DreamsTableOrderingComposer,
    $$DreamsTableAnnotationComposer,
    $$DreamsTableCreateCompanionBuilder,
    $$DreamsTableUpdateCompanionBuilder,
    (DreamRow, BaseReferences<_$AppDatabase, $DreamsTable, DreamRow>),
    DreamRow,
    PrefetchHooks Function()>;
typedef $$JournalEntriesTableCreateCompanionBuilder = JournalEntriesCompanion
    Function({
  Value<int> id,
  required DateTime createdAt,
  required String content,
  Value<String?> title,
  Value<String?> audioPath,
  Value<String?> photoUrl,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$JournalEntriesTableUpdateCompanionBuilder = JournalEntriesCompanion
    Function({
  Value<int> id,
  Value<DateTime> createdAt,
  Value<String> content,
  Value<String?> title,
  Value<String?> audioPath,
  Value<String?> photoUrl,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$JournalEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalEntriesTable,
    JournalEntryRow,
    $$JournalEntriesTableFilterComposer,
    $$JournalEntriesTableOrderingComposer,
    $$JournalEntriesTableAnnotationComposer,
    $$JournalEntriesTableCreateCompanionBuilder,
    $$JournalEntriesTableUpdateCompanionBuilder,
    (
      JournalEntryRow,
      BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntryRow>
    ),
    JournalEntryRow,
    PrefetchHooks Function()> {
  $$JournalEntriesTableTableManager(
      _$AppDatabase db, $JournalEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              JournalEntriesCompanion(
            id: id,
            createdAt: createdAt,
            content: content,
            title: title,
            audioPath: audioPath,
            photoUrl: photoUrl,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime createdAt,
            required String content,
            Value<String?> title = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              JournalEntriesCompanion.insert(
            id: id,
            createdAt: createdAt,
            content: content,
            title: title,
            audioPath: audioPath,
            photoUrl: photoUrl,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JournalEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalEntriesTable,
    JournalEntryRow,
    $$JournalEntriesTableFilterComposer,
    $$JournalEntriesTableOrderingComposer,
    $$JournalEntriesTableAnnotationComposer,
    $$JournalEntriesTableCreateCompanionBuilder,
    $$JournalEntriesTableUpdateCompanionBuilder,
    (
      JournalEntryRow,
      BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntryRow>
    ),
    JournalEntryRow,
    PrefetchHooks Function()>;
typedef $$DailyQuestionAnswersTableCreateCompanionBuilder
    = DailyQuestionAnswersCompanion Function({
  Value<int> id,
  required DateTime date,
  required int questionIndex,
  required String answerText,
  Value<bool> isSharedToCommunity,
  Value<String?> communityShareId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$DailyQuestionAnswersTableUpdateCompanionBuilder
    = DailyQuestionAnswersCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int> questionIndex,
  Value<String> answerText,
  Value<bool> isSharedToCommunity,
  Value<String?> communityShareId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$DailyQuestionAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $DailyQuestionAnswersTable> {
  $$DailyQuestionAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get questionIndex => $composableBuilder(
      column: $table.questionIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerText => $composableBuilder(
      column: $table.answerText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSharedToCommunity => $composableBuilder(
      column: $table.isSharedToCommunity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get communityShareId => $composableBuilder(
      column: $table.communityShareId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyQuestionAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyQuestionAnswersTable> {
  $$DailyQuestionAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get questionIndex => $composableBuilder(
      column: $table.questionIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerText => $composableBuilder(
      column: $table.answerText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSharedToCommunity => $composableBuilder(
      column: $table.isSharedToCommunity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get communityShareId => $composableBuilder(
      column: $table.communityShareId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyQuestionAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyQuestionAnswersTable> {
  $$DailyQuestionAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get questionIndex => $composableBuilder(
      column: $table.questionIndex, builder: (column) => column);

  GeneratedColumn<String> get answerText => $composableBuilder(
      column: $table.answerText, builder: (column) => column);

  GeneratedColumn<bool> get isSharedToCommunity => $composableBuilder(
      column: $table.isSharedToCommunity, builder: (column) => column);

  GeneratedColumn<String> get communityShareId => $composableBuilder(
      column: $table.communityShareId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyQuestionAnswersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyQuestionAnswersTable,
    DailyQuestionAnswerRow,
    $$DailyQuestionAnswersTableFilterComposer,
    $$DailyQuestionAnswersTableOrderingComposer,
    $$DailyQuestionAnswersTableAnnotationComposer,
    $$DailyQuestionAnswersTableCreateCompanionBuilder,
    $$DailyQuestionAnswersTableUpdateCompanionBuilder,
    (
      DailyQuestionAnswerRow,
      BaseReferences<_$AppDatabase, $DailyQuestionAnswersTable,
          DailyQuestionAnswerRow>
    ),
    DailyQuestionAnswerRow,
    PrefetchHooks Function()> {
  $$DailyQuestionAnswersTableTableManager(
      _$AppDatabase db, $DailyQuestionAnswersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyQuestionAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyQuestionAnswersTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyQuestionAnswersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> questionIndex = const Value.absent(),
            Value<String> answerText = const Value.absent(),
            Value<bool> isSharedToCommunity = const Value.absent(),
            Value<String?> communityShareId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DailyQuestionAnswersCompanion(
            id: id,
            date: date,
            questionIndex: questionIndex,
            answerText: answerText,
            isSharedToCommunity: isSharedToCommunity,
            communityShareId: communityShareId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required int questionIndex,
            required String answerText,
            Value<bool> isSharedToCommunity = const Value.absent(),
            Value<String?> communityShareId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              DailyQuestionAnswersCompanion.insert(
            id: id,
            date: date,
            questionIndex: questionIndex,
            answerText: answerText,
            isSharedToCommunity: isSharedToCommunity,
            communityShareId: communityShareId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyQuestionAnswersTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DailyQuestionAnswersTable,
        DailyQuestionAnswerRow,
        $$DailyQuestionAnswersTableFilterComposer,
        $$DailyQuestionAnswersTableOrderingComposer,
        $$DailyQuestionAnswersTableAnnotationComposer,
        $$DailyQuestionAnswersTableCreateCompanionBuilder,
        $$DailyQuestionAnswersTableUpdateCompanionBuilder,
        (
          DailyQuestionAnswerRow,
          BaseReferences<_$AppDatabase, $DailyQuestionAnswersTable,
              DailyQuestionAnswerRow>
        ),
        DailyQuestionAnswerRow,
        PrefetchHooks Function()>;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  required DateTime createdAt,
  required String activityIdsJson,
  required String activityText,
  Value<String?> photoPath,
  Value<String?> photoUrl,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<DateTime> createdAt,
  Value<String> activityIdsJson,
  Value<String> activityText,
  Value<String?> photoPath,
  Value<String?> photoUrl,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityIdsJson => $composableBuilder(
      column: $table.activityIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityText => $composableBuilder(
      column: $table.activityText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityIdsJson => $composableBuilder(
      column: $table.activityIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityText => $composableBuilder(
      column: $table.activityText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get activityIdsJson => $composableBuilder(
      column: $table.activityIdsJson, builder: (column) => column);

  GeneratedColumn<String> get activityText => $composableBuilder(
      column: $table.activityText, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$ActivitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    ActivityRow,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (ActivityRow, BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>),
    ActivityRow,
    PrefetchHooks Function()> {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> activityIdsJson = const Value.absent(),
            Value<String> activityText = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              ActivitiesCompanion(
            id: id,
            createdAt: createdAt,
            activityIdsJson: activityIdsJson,
            activityText: activityText,
            photoPath: photoPath,
            photoUrl: photoUrl,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime createdAt,
            required String activityIdsJson,
            required String activityText,
            Value<String?> photoPath = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              ActivitiesCompanion.insert(
            id: id,
            createdAt: createdAt,
            activityIdsJson: activityIdsJson,
            activityText: activityText,
            photoPath: photoPath,
            photoUrl: photoUrl,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    ActivityRow,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (ActivityRow, BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>),
    ActivityRow,
    PrefetchHooks Function()>;
typedef $$LettersTableCreateCompanionBuilder = LettersCompanion Function({
  Value<int> id,
  required DateTime createdAt,
  required DateTime openAt,
  required String title,
  required String body,
  Value<String?> userId,
  Value<String?> supabaseId,
});
typedef $$LettersTableUpdateCompanionBuilder = LettersCompanion Function({
  Value<int> id,
  Value<DateTime> createdAt,
  Value<DateTime> openAt,
  Value<String> title,
  Value<String> body,
  Value<String?> userId,
  Value<String?> supabaseId,
});

class $$LettersTableFilterComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openAt => $composableBuilder(
      column: $table.openAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));
}

class $$LettersTableOrderingComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openAt => $composableBuilder(
      column: $table.openAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$LettersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get openAt =>
      $composableBuilder(column: $table.openAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);
}

class $$LettersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LettersTable,
    LetterRow,
    $$LettersTableFilterComposer,
    $$LettersTableOrderingComposer,
    $$LettersTableAnnotationComposer,
    $$LettersTableCreateCompanionBuilder,
    $$LettersTableUpdateCompanionBuilder,
    (LetterRow, BaseReferences<_$AppDatabase, $LettersTable, LetterRow>),
    LetterRow,
    PrefetchHooks Function()> {
  $$LettersTableTableManager(_$AppDatabase db, $LettersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LettersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LettersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LettersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> openAt = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              LettersCompanion(
            id: id,
            createdAt: createdAt,
            openAt: openAt,
            title: title,
            body: body,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime createdAt,
            required DateTime openAt,
            required String title,
            required String body,
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              LettersCompanion.insert(
            id: id,
            createdAt: createdAt,
            openAt: openAt,
            title: title,
            body: body,
            userId: userId,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LettersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LettersTable,
    LetterRow,
    $$LettersTableFilterComposer,
    $$LettersTableOrderingComposer,
    $$LettersTableAnnotationComposer,
    $$LettersTableCreateCompanionBuilder,
    $$LettersTableUpdateCompanionBuilder,
    (LetterRow, BaseReferences<_$AppDatabase, $LettersTable, LetterRow>),
    LetterRow,
    PrefetchHooks Function()>;
typedef $$QuotesTableCreateCompanionBuilder = QuotesCompanion Function({
  required String id,
  required String textTr,
  required String textEn,
  Value<String?> author,
  Value<int?> rotationOrder,
  required bool isActive,
  required String source,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$QuotesTableUpdateCompanionBuilder = QuotesCompanion Function({
  Value<String> id,
  Value<String> textTr,
  Value<String> textEn,
  Value<String?> author,
  Value<int?> rotationOrder,
  Value<bool> isActive,
  Value<String> source,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$QuotesTableFilterComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textTr => $composableBuilder(
      column: $table.textTr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textEn => $composableBuilder(
      column: $table.textEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rotationOrder => $composableBuilder(
      column: $table.rotationOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$QuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textTr => $composableBuilder(
      column: $table.textTr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textEn => $composableBuilder(
      column: $table.textEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rotationOrder => $composableBuilder(
      column: $table.rotationOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textTr =>
      $composableBuilder(column: $table.textTr, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<int> get rotationOrder => $composableBuilder(
      column: $table.rotationOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuotesTable,
    QuoteRow,
    $$QuotesTableFilterComposer,
    $$QuotesTableOrderingComposer,
    $$QuotesTableAnnotationComposer,
    $$QuotesTableCreateCompanionBuilder,
    $$QuotesTableUpdateCompanionBuilder,
    (QuoteRow, BaseReferences<_$AppDatabase, $QuotesTable, QuoteRow>),
    QuoteRow,
    PrefetchHooks Function()> {
  $$QuotesTableTableManager(_$AppDatabase db, $QuotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> textTr = const Value.absent(),
            Value<String> textEn = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<int?> rotationOrder = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCompanion(
            id: id,
            textTr: textTr,
            textEn: textEn,
            author: author,
            rotationOrder: rotationOrder,
            isActive: isActive,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String textTr,
            required String textEn,
            Value<String?> author = const Value.absent(),
            Value<int?> rotationOrder = const Value.absent(),
            required bool isActive,
            required String source,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCompanion.insert(
            id: id,
            textTr: textTr,
            textEn: textEn,
            author: author,
            rotationOrder: rotationOrder,
            isActive: isActive,
            source: source,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuotesTable,
    QuoteRow,
    $$QuotesTableFilterComposer,
    $$QuotesTableOrderingComposer,
    $$QuotesTableAnnotationComposer,
    $$QuotesTableCreateCompanionBuilder,
    $$QuotesTableUpdateCompanionBuilder,
    (QuoteRow, BaseReferences<_$AppDatabase, $QuotesTable, QuoteRow>),
    QuoteRow,
    PrefetchHooks Function()>;
typedef $$QuoteFavoritesTableCreateCompanionBuilder = QuoteFavoritesCompanion
    Function({
  required String userId,
  required String quoteId,
  required bool isFavorite,
  required String syncState,
  required DateTime changedAt,
  Value<int> rowid,
});
typedef $$QuoteFavoritesTableUpdateCompanionBuilder = QuoteFavoritesCompanion
    Function({
  Value<String> userId,
  Value<String> quoteId,
  Value<bool> isFavorite,
  Value<String> syncState,
  Value<DateTime> changedAt,
  Value<int> rowid,
});

class $$QuoteFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $QuoteFavoritesTable> {
  $$QuoteFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quoteId => $composableBuilder(
      column: $table.quoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
      column: $table.changedAt, builder: (column) => ColumnFilters(column));
}

class $$QuoteFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuoteFavoritesTable> {
  $$QuoteFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quoteId => $composableBuilder(
      column: $table.quoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
      column: $table.changedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuoteFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuoteFavoritesTable> {
  $$QuoteFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get quoteId =>
      $composableBuilder(column: $table.quoteId, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);
}

class $$QuoteFavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuoteFavoritesTable,
    QuoteFavoriteRow,
    $$QuoteFavoritesTableFilterComposer,
    $$QuoteFavoritesTableOrderingComposer,
    $$QuoteFavoritesTableAnnotationComposer,
    $$QuoteFavoritesTableCreateCompanionBuilder,
    $$QuoteFavoritesTableUpdateCompanionBuilder,
    (
      QuoteFavoriteRow,
      BaseReferences<_$AppDatabase, $QuoteFavoritesTable, QuoteFavoriteRow>
    ),
    QuoteFavoriteRow,
    PrefetchHooks Function()> {
  $$QuoteFavoritesTableTableManager(
      _$AppDatabase db, $QuoteFavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuoteFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuoteFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuoteFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> quoteId = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime> changedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuoteFavoritesCompanion(
            userId: userId,
            quoteId: quoteId,
            isFavorite: isFavorite,
            syncState: syncState,
            changedAt: changedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String quoteId,
            required bool isFavorite,
            required String syncState,
            required DateTime changedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuoteFavoritesCompanion.insert(
            userId: userId,
            quoteId: quoteId,
            isFavorite: isFavorite,
            syncState: syncState,
            changedAt: changedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuoteFavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuoteFavoritesTable,
    QuoteFavoriteRow,
    $$QuoteFavoritesTableFilterComposer,
    $$QuoteFavoritesTableOrderingComposer,
    $$QuoteFavoritesTableAnnotationComposer,
    $$QuoteFavoritesTableCreateCompanionBuilder,
    $$QuoteFavoritesTableUpdateCompanionBuilder,
    (
      QuoteFavoriteRow,
      BaseReferences<_$AppDatabase, $QuoteFavoritesTable, QuoteFavoriteRow>
    ),
    QuoteFavoriteRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$DreamsTableTableManager get dreams =>
      $$DreamsTableTableManager(_db, _db.dreams);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$DailyQuestionAnswersTableTableManager get dailyQuestionAnswers =>
      $$DailyQuestionAnswersTableTableManager(_db, _db.dailyQuestionAnswers);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$LettersTableTableManager get letters =>
      $$LettersTableTableManager(_db, _db.letters);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db, _db.quotes);
  $$QuoteFavoritesTableTableManager get quoteFavorites =>
      $$QuoteFavoritesTableTableManager(_db, _db.quoteFavorites);
}
