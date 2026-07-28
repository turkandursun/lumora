import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

class LumoraApp extends StatelessWidget {
  const LumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Lumora',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
