import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_de.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_en.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_es.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_fr.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_tr.dart';

void main() {
  test('first LUMA welcome is distinct and names the current product', () {
    final localizations = [
      AppLocalizationsTr(),
      AppLocalizationsEn(),
      AppLocalizationsDe(),
      AppLocalizationsEs(),
      AppLocalizationsFr(),
    ];

    for (final l10n in localizations) {
      expect(l10n.greetingFirstWelcome, contains('ASTRA'));
      expect(l10n.greetingFirstWelcome, contains('LUMA'));
      expect(l10n.greetingFirstWelcome, isNot(l10n.greetingWelcomeBack));
    }
  });
}
