import '../../../l10n/generated/app_localizations.dart';
import '../domain/goal_template.dart';

String localizedGoalTemplateTitle(
  AppLocalizations l10n,
  GoalTemplate template,
) {
  switch (template.titleKey) {
    case 'goalsTemplateWater':
      return l10n.goalsTemplateWater;
    case 'goalsTemplateJournal':
      return l10n.goalsTemplateJournal;
    case 'goalsTemplateMeditation':
      return l10n.goalsTemplateMeditation;
    case 'goalsTemplateBreathing':
      return l10n.goalsTemplateBreathing;
    case 'goalsTemplateReading':
      return l10n.goalsTemplateReading;
    case 'goalsTemplateWalking':
      return l10n.goalsTemplateWalking;
    case 'goalsTemplateStretching':
      return l10n.goalsTemplateStretching;
    case 'goalsTemplateSleepEarly':
      return l10n.goalsTemplateSleepEarly;
    case 'goalsTemplateScreenFree':
      return l10n.goalsTemplateScreenFree;
  }
  throw StateError('Unknown goal template title key: ${template.titleKey}');
}

String? localizedGoalTemplateCustomUnit(
  AppLocalizations l10n,
  GoalTemplate template,
) {
  switch (template.customUnitLabelKey) {
    case null:
      return null;
    case 'goalsCustomUnitEntry':
      return l10n.goalsCustomUnitEntry;
    case 'goalsCustomUnitNight':
      return l10n.goalsCustomUnitNight;
  }
  throw StateError(
    'Unknown goal custom unit key: ${template.customUnitLabelKey}',
  );
}
