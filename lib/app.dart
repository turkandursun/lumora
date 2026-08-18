import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/auth_listener.dart';
import 'core/providers/astra_palette_provider.dart';
import 'core/providers/astra_theme_provider.dart';
import 'core/router/app_router.dart';
<<<<<<< Updated upstream
import 'features/auth/domain/registration_flow_state.dart';
=======
import 'core/services/smart_reminders_service.dart';
>>>>>>> Stashed changes
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

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
    // (Re)schedule the smart daily nudges on every launch so they stay active
    // even if the user never opens the reminders screen.
    final isTr =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr';
    unawaited(SmartRemindersService.instance.sync(isTr: isTr));
    _lastAuthenticatedUserId = Supabase.instance.client.auth.currentUser?.id;
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        debugPrint(
            '[AuthListener] User signed out -> clearing local DB & invalidating user providers');
        // Palette is visible app-wide, so reset it before slower local cleanup.
        ref.invalidate(astraPaletteProvider);
        ref.invalidate(astraThemeProvider);
        await registrationFlowStore.clearForUser(_lastAuthenticatedUserId);
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
    final palette = ref.watch(activePaletteProvider);
    final appearance = ref.watch(astraThemeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ASTRA',
      theme: AppTheme.forPalette(
        palette,
        brightness: appearance == AstraThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
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
