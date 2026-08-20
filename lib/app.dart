import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/auth_listener.dart';
import 'core/providers/astra_palette_provider.dart';
import 'core/providers/astra_theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/smart_reminders_service.dart';
import 'features/auth/domain/registration_flow_state.dart';
import 'features/wellbeing/presentation/providers/focus_providers.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

class LumoraApp extends ConsumerStatefulWidget {
  const LumoraApp({super.key});

  @override
  ConsumerState<LumoraApp> createState() => _LumoraAppState();
}

class _LumoraAppState extends ConsumerState<LumoraApp>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastAuthenticatedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // (Re)schedule the smart daily nudges on every launch so they stay active
    // even if the user never opens the reminders screen.
    final isTr =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr';
    unawaited(SmartRemindersService.instance.sync(isTr: isTr));
    _lastAuthenticatedUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_lastAuthenticatedUserId != null) {
      unawaited(_bootstrapFocus());
    }
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
        final nextUserId = data.session?.user.id ??
            Supabase.instance.client.auth.currentUser?.id;
        final previousUserId = _lastAuthenticatedUserId;
        if (previousUserId != null &&
            nextUserId != null &&
            previousUserId != nextUserId) {
          await registrationFlowStore.clearForUser(previousUserId);
          await clearLocalUserData(ref, userId: previousUserId);
        }
        _lastAuthenticatedUserId = nextUserId;
        debugPrint(
            '[AuthListener] Auth state change ($event) -> invalidating user providers for fresh load');
        invalidateUserProviders(ref);
        unawaited(_bootstrapFocus());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapFocus() async {
    try {
      ref.read(focusRepositoryProvider).initialize();
      await ref.read(activeFocusSessionProvider.notifier).initialize();
      await ref.read(focusStatsProvider.notifier).refresh();
    } catch (error) {
      debugPrint('[Focus] bootstrap deferred error=${error.runtimeType}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(ref.read(activeFocusSessionProvider.notifier).onAppResumed());
    unawaited(ref.read(focusStatsProvider.notifier).refresh());
    // Re-arm the evening "pişt, neredesin?" poke for the next day so an active
    // user is never nudged; a full day away still triggers it.
    final isTr =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr';
    unawaited(SmartRemindersService.instance.markAppOpened(isTr: isTr));
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
