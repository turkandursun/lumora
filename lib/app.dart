import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/astra_palette_provider.dart';
import 'core/providers/auth_listener.dart';
import 'core/router/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';
import 'theme/astra_screen_kit.dart';

class LumoraApp extends ConsumerStatefulWidget {
  const LumoraApp({super.key});

  @override
  ConsumerState<LumoraApp> createState() => _LumoraAppState();
}

class _LumoraAppState extends ConsumerState<LumoraApp> {
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastAuthenticatedUserId;

  @override
  void initState() {
    super.initState();
    _lastAuthenticatedUserId = Supabase.instance.client.auth.currentUser?.id;
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        debugPrint(
            '[AuthListener] User signed out -> clearing local DB & invalidating user providers');
        await clearLocalUserData(
          ref,
          userId: _lastAuthenticatedUserId,
        );
        _lastAuthenticatedUserId = null;
        invalidateUserProviders(ref);
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _lastAuthenticatedUserId = data.session?.user.id ??
            Supabase.instance.client.auth.currentUser?.id;
        debugPrint(
            '[AuthListener] Auth state change ($event) -> invalidating user providers for fresh load');
        invalidateUserProviders(ref);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the shared design-kit palette in sync app-wide: every surface that
    // reads AstraKit.active / LumaGlass statically (Home, AI chat, journal,
    // the nav bar) paints the currently-selected theme, and changing the theme
    // in Profile rebuilds from here so the whole app recolours at once.
    AstraKit.active = ref.watch(activePaletteProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ASTRA',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Follow the phone's language automatically: use the device locale when
      // we have a translation for it, otherwise fall back to English.
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale != null) {
          for (final locale in supported) {
            if (locale.languageCode == deviceLocale.languageCode) {
              return locale;
            }
          }
        }
        return const Locale('en');
      },
    );
  }
}
