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
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, iconKey, frequency, weekday, hour, minute, enabled];
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
  const ReminderRow(
      {required this.id,
      required this.title,
      required this.iconKey,
      required this.frequency,
      this.weekday,
      required this.hour,
      required this.minute,
      required this.enabled});
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
          bool? enabled}) =>
      ReminderRow(
        id: id ?? this.id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        frequency: frequency ?? this.frequency,
        weekday: weekday.present ? weekday.value : this.weekday,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
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
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, iconKey, frequency, weekday, hour, minute, enabled);
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
          other.enabled == this.enabled);
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
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.frequency = const Value.absent(),
    this.weekday = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.enabled = const Value.absent(),
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
      Value<bool>? enabled}) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
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
          ..write('enabled: $enabled')
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
        aiInterpretation
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
  const DreamRow(
      {required this.id,
      required this.date,
      required this.content,
      required this.symbolTags,
      this.feelingTag,
      this.familiarPerson,
      this.firstThought,
      this.lifeConnection,
      this.aiInterpretation});
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
          Value<String?> aiInterpretation = const Value.absent()}) =>
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
          ..write('aiInterpretation: $aiInterpretation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, content, symbolTags, feelingTag,
      familiarPerson, firstThought, lifeConnection, aiInterpretation);
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
          other.aiInterpretation == this.aiInterpretation);
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
      Value<String?>? aiInterpretation}) {
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
          ..write('aiInterpretation: $aiInterpretation')
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
      [id, createdAt, content, title, audioPath, userId, supabaseId];
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

  /// Optional short heading the user typed for this entry. Local-only for
  /// now (not synced to Supabase, which has no matching column yet).
  final String? title;

  /// Absolute path to an attached voice-note recording, if the entry has
  /// one. Null for text-only entries (the common case).
  final String? audioPath;

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
          Value<String?> userId = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      JournalEntryRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        content: content ?? this.content,
        title: title.present ? title.value : this.title,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
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
          ..write('userId: $userId, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, content, title, audioPath, userId, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.content == this.content &&
          other.title == this.title &&
          other.audioPath == this.audioPath &&
          other.userId == this.userId &&
          other.supabaseId == this.supabaseId);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> content;
  final Value<String?> title;
  final Value<String?> audioPath;
  final Value<String?> userId;
  final Value<String?> supabaseId;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.content = const Value.absent(),
    this.title = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.userId = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String content,
    this.title = const Value.absent(),
    this.audioPath = const Value.absent(),
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
    Expression<String>? userId,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (content != null) 'content': content,
      if (title != null) 'title': title,
      if (audioPath != null) 'audio_path': audioPath,
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
      Value<String?>? userId,
      Value<String?>? supabaseId}) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $DreamsTable dreams = $DreamsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $DailyQuestionAnswersTable dailyQuestionAnswers =
      $DailyQuestionAnswersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [reminders, goals, dreams, journalEntries, dailyQuestionAnswers];
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
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              JournalEntriesCompanion(
            id: id,
            createdAt: createdAt,
            content: content,
            title: title,
            audioPath: audioPath,
            userId: userId,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime createdAt,
            required String content,
            Value<String?> title = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              JournalEntriesCompanion.insert(
            id: id,
            createdAt: createdAt,
            content: content,
            title: title,
            audioPath: audioPath,
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
}
