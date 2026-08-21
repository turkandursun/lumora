import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/reminders/presentation/widgets/new_reminder_sheet.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:mindful_journal/theme/app_theme.dart';
import 'package:mindful_journal/theme/astra_design_tokens.dart';
import 'package:mindful_journal/theme/premium_button.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required AstraPalette palette,
    required Brightness brightness,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.forPalette(palette, brightness: brightness),
          home: const Scaffold(body: NewReminderSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color surfaceColor(WidgetTester tester) {
    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('new-reminder-sheet-surface')),
    );
    return (surface.decoration! as BoxDecoration).color!;
  }

  InputDecoration fieldDecoration(WidgetTester tester) {
    final field = find.byKey(const ValueKey('new-reminder-title-field'));
    return tester
        .widget<InputDecorator>(
          find.descendant(of: field, matching: find.byType(InputDecorator)),
        )
        .decoration;
  }

  Color inputFill(WidgetTester tester) {
    return fieldDecoration(tester).fillColor!;
  }

  Color focusBorder(WidgetTester tester) {
    final decoration = fieldDecoration(tester);
    return (decoration.focusedBorder! as OutlineInputBorder).borderSide.color;
  }

  testWidgets('light reminder sheet follows selected palette tokens',
      (tester) async {
    await pumpSheet(
      tester,
      palette: astraSoftLilacMist,
      brightness: Brightness.light,
    );
    final lilacTokens = AstraThemeTokens.fromPalette(astraSoftLilacMist);
    expect(surfaceColor(tester), lilacTokens.palette.surfaceElevated);
    expect(inputFill(tester), lilacTokens.palette.inputBackground);
    expect(focusBorder(tester), lilacTokens.palette.activeAccent);

    await pumpSheet(
      tester,
      palette: astraDustyRoseHaze,
      brightness: Brightness.light,
    );
    final roseTokens = AstraThemeTokens.fromPalette(astraDustyRoseHaze);
    expect(surfaceColor(tester), roseTokens.palette.surfaceElevated);
    expect(inputFill(tester), roseTokens.palette.inputBackground);
    expect(focusBorder(tester), roseTokens.palette.activeAccent);
    expect(roseTokens.palette.activeAccent,
        isNot(lilacTokens.palette.activeAccent));
  });

  testWidgets('dark reminder sheet uses dark surfaces and palette CTA',
      (tester) async {
    await pumpSheet(
      tester,
      palette: astraSoftLilacMist,
      brightness: Brightness.dark,
    );
    final tokens = AstraThemeTokens.fromPalette(
      astraSoftLilacMist,
      brightness: Brightness.dark,
    );

    expect(surfaceColor(tester), tokens.palette.surfaceElevated);
    expect(inputFill(tester), tokens.palette.inputBackground);
    final field = find.byKey(const ValueKey('new-reminder-title-field'));
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.style.color, tokens.textPrimary);

    final button = tester.widget<PremiumButton>(
      find.byKey(const ValueKey('new-reminder-submit-button')),
    );
    expect(
      button.gradient,
      [tokens.palette.buttonPrimary, tokens.palette.secondary],
    );
  });
}
