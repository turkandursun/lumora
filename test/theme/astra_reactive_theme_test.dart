import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/theme/app_theme.dart';
import 'package:mindful_journal/theme/astra_design_tokens.dart';
import 'package:mindful_journal/theme/astra_screen_kit.dart';
import 'package:mindful_journal/theme/luma_glass_theme.dart';

void main() {
  test('palette ThemeData maps material surfaces to the active palette', () {
    final theme = AppTheme.forPalette(astraSageVeil);
    expect(
        theme.extension<AstraThemeTokens>()?.palette.id, AstraThemeId.sageVeil);
    expect(theme.scaffoldBackgroundColor, astraSageVeil.surface);
    expect(theme.colorScheme.primary, astraSageVeil.primary);
    expect(theme.inputDecorationTheme.fillColor, astraSageVeil.inputBackground);
    expect(theme.dialogTheme.backgroundColor, astraSageVeil.surfaceElevated);
    expect(
        theme.bottomSheetTheme.backgroundColor, astraSageVeil.surfaceElevated);
  });

  testWidgets('shared Astra and Luma glass tokens react across palettes',
      (tester) async {
    Color? astraAccent;
    Color? glassAccent;

    Widget appFor(AstraPalette palette) => MaterialApp(
          theme: AppTheme.forPalette(palette),
          home: Builder(
            builder: (context) {
              astraAccent = AstraKit.primary(context, false);
              glassAccent = LumaGlass.sparkle(context);
              return const SizedBox.shrink();
            },
          ),
        );

    await tester.pumpWidget(appFor(astraSageVeil));
    expect(astraAccent, astraSageVeil.primary);
    expect(glassAccent, astraSageVeil.activeAccent);

    await tester.pumpWidget(appFor(astraApricotCloud));
    await tester.pump(const Duration(milliseconds: 350));
    expect(astraAccent, astraApricotCloud.primary);
    expect(glassAccent, astraApricotCloud.activeAccent);
    expect(astraAccent, isNot(astraSageVeil.primary));
  });

  test('all seven persisted palettes build distinct reactive themes', () {
    expect(astraPalettes, hasLength(7));
    final ids = astraPalettes
        .map((palette) => AppTheme.forPalette(palette)
            .extension<AstraThemeTokens>()!
            .palette
            .id)
        .toSet();
    expect(ids, hasLength(7));
  });

  test('dark appearance replaces neutral surfaces but keeps palette identity',
      () {
    final light = AppTheme.forPalette(astraSageVeil);
    final dark = AppTheme.forPalette(
      astraSageVeil,
      brightness: Brightness.dark,
    );
    final darkTokens = dark.extension<AstraThemeTokens>()!;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(darkTokens.palette.id, AstraThemeId.sageVeil);
    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    expect(dark.scaffoldBackgroundColor.computeLuminance(), lessThan(0.08));
    expect(dark.cardTheme.color!.computeLuminance(), lessThan(0.12));
    expect(dark.inputDecorationTheme.fillColor!.computeLuminance(),
        lessThan(0.12));
    expect(
        dark.dialogTheme.backgroundColor!.computeLuminance(), lessThan(0.12));
    expect(dark.bottomSheetTheme.backgroundColor!.computeLuminance(),
        lessThan(0.12));
    expect(darkTokens.textPrimary.computeLuminance(), greaterThan(0.75));
    expect(darkTokens.textSecondary.computeLuminance(), greaterThan(0.55));
  });

  test('light mode preserves the production palette surface values', () {
    final theme = AppTheme.forPalette(astraApricotCloud);
    final tokens = theme.extension<AstraThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, astraApricotCloud.surface);
    expect(theme.cardTheme.color, astraApricotCloud.cardBackground);
    expect(
      theme.inputDecorationTheme.fillColor,
      astraApricotCloud.inputBackground,
    );
    expect(tokens.palette.gradientTop, astraApricotCloud.gradientTop);
    expect(tokens.textPrimary, AstraText.title);
  });

  testWidgets('LumaGlass and navigation react to brightness and palette',
      (tester) async {
    Color? glassTop;
    Color? navigation;
    Color? accent;

    Widget app(AstraPalette palette, Brightness brightness) => MaterialApp(
          theme: AppTheme.forPalette(palette, brightness: brightness),
          home: Builder(builder: (context) {
            glassTop = LumaGlass.glassFillTop(context);
            navigation = Theme.of(context).navigationBarTheme.backgroundColor;
            accent = LumaGlass.sparkle(context);
            return const SizedBox.shrink();
          }),
        );

    await tester.pumpWidget(app(astraSageVeil, Brightness.dark));
    final sageDarkGlass = glassTop;
    expect(glassTop!.computeLuminance(), lessThan(0.12));
    expect(navigation!.computeLuminance(), lessThan(0.12));
    expect(accent, isNot(astraApricotCloud.activeAccent));

    await tester.pumpWidget(app(astraApricotCloud, Brightness.dark));
    await tester.pump(const Duration(milliseconds: 350));
    expect(glassTop, isNot(sageDarkGlass));
    expect(navigation!.computeLuminance(), lessThan(0.12));
    expect(
      AstraThemeId.apricotCloud,
      AppTheme.forPalette(astraApricotCloud, brightness: Brightness.dark)
          .extension<AstraThemeTokens>()!
          .palette
          .id,
    );
  });
}
