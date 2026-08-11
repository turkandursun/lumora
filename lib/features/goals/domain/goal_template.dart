import '../../../core/database/tables/goals_table.dart';

/// Uygulama paketinde yayımlanan, kimliği kararlı hedef önerisi.
///
/// Başlık ve özel birim metinleri [titleKey] / [customUnitLabelKey] üzerinden
/// ARB yerelleştirmelerinden çözülür. Bir template ancak kullanıcı seçtiğinde
/// gerçek bir Goal satırına dönüşür.
class GoalTemplate {
  const GoalTemplate({
    required this.key,
    required this.titleKey,
    required this.iconKey,
    required this.defaultTarget,
    required this.unit,
    required this.frequency,
    required this.sortOrder,
    this.customUnitLabelKey,
    this.autoProgressSource,
  });

  final String key;
  final String titleKey;
  final String iconKey;
  final int defaultTarget;
  final GoalUnit unit;
  final String? customUnitLabelKey;
  final GoalFrequency frequency;
  final int sortOrder;
  final GoalAutoProgressSource? autoProgressSource;
}

enum GoalAutoProgressSource { journal, meditation, breathing }

abstract final class GoalTemplateKeys {
  static const water = 'water';
  static const journal = 'journal';
  static const meditation = 'meditation';
  static const breathing = 'breathing';
  static const reading = 'reading';
  static const walking = 'walking';
  static const stretching = 'stretching';
  static const sleepEarly = 'sleep_early';
  static const screenFree = 'screen_free';
}

/// Supabase'te ayrı template tablosu yoktur; katalog uygulama bundle'ındadır.
const goalTemplates = <GoalTemplate>[
  GoalTemplate(
    key: GoalTemplateKeys.water,
    titleKey: 'goalsTemplateWater',
    iconKey: GoalTemplateKeys.water,
    defaultTarget: 8,
    unit: GoalUnit.glasses,
    frequency: GoalFrequency.daily,
    sortOrder: 0,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.journal,
    titleKey: 'goalsTemplateJournal',
    iconKey: GoalTemplateKeys.journal,
    defaultTarget: 1,
    unit: GoalUnit.custom,
    customUnitLabelKey: 'goalsCustomUnitEntry',
    frequency: GoalFrequency.daily,
    sortOrder: 1,
    autoProgressSource: GoalAutoProgressSource.journal,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.meditation,
    titleKey: 'goalsTemplateMeditation',
    iconKey: GoalTemplateKeys.meditation,
    defaultTarget: 15,
    unit: GoalUnit.minutes,
    frequency: GoalFrequency.daily,
    sortOrder: 2,
    autoProgressSource: GoalAutoProgressSource.meditation,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.breathing,
    titleKey: 'goalsTemplateBreathing',
    iconKey: GoalTemplateKeys.breathing,
    defaultTarget: 10,
    unit: GoalUnit.minutes,
    frequency: GoalFrequency.daily,
    sortOrder: 3,
    autoProgressSource: GoalAutoProgressSource.breathing,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.reading,
    titleKey: 'goalsTemplateReading',
    iconKey: GoalTemplateKeys.reading,
    defaultTarget: 4,
    unit: GoalUnit.books,
    frequency: GoalFrequency.monthly,
    sortOrder: 4,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.walking,
    titleKey: 'goalsTemplateWalking',
    iconKey: GoalTemplateKeys.walking,
    defaultTarget: 30,
    unit: GoalUnit.minutes,
    frequency: GoalFrequency.daily,
    sortOrder: 5,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.stretching,
    titleKey: 'goalsTemplateStretching',
    iconKey: GoalTemplateKeys.stretching,
    defaultTarget: 15,
    unit: GoalUnit.minutes,
    frequency: GoalFrequency.daily,
    sortOrder: 6,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.sleepEarly,
    titleKey: 'goalsTemplateSleepEarly',
    iconKey: GoalTemplateKeys.sleepEarly,
    defaultTarget: 1,
    unit: GoalUnit.custom,
    customUnitLabelKey: 'goalsCustomUnitNight',
    frequency: GoalFrequency.daily,
    sortOrder: 7,
  ),
  GoalTemplate(
    key: GoalTemplateKeys.screenFree,
    titleKey: 'goalsTemplateScreenFree',
    iconKey: GoalTemplateKeys.screenFree,
    defaultTarget: 20,
    unit: GoalUnit.minutes,
    frequency: GoalFrequency.daily,
    sortOrder: 8,
  ),
];

GoalTemplate? goalTemplateByKey(String? key) {
  if (key == null) return null;
  for (final template in goalTemplates) {
    if (template.key == key) return template;
  }
  return null;
}
