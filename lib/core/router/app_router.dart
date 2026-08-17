import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/letters/presentation/screens/letters_screen.dart';
import '../../features/meditation/presentation/screens/meditation_screen.dart';

import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/ai_questions/presentation/screens/ai_questions_screen.dart';
import '../../features/auth/domain/auth_flow_routes.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/name_entry_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/breathing/presentation/screens/breathing_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/dreams/presentation/screens/dream_journal_screen.dart';
import '../../features/dreams/presentation/screens/dream_reflection_screen.dart';
import '../../features/dreams/presentation/screens/new_dream_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/hobbies/presentation/screens/hobbies_screen.dart';
import '../../features/journal/presentation/screens/favorites_screen.dart';
import '../../features/journal/presentation/screens/daily_reflection_screen.dart';
import '../../features/journal/presentation/screens/journal_entry_screen.dart';
import '../../features/journal/presentation/screens/quote_gallery_screen.dart';
import '../../features/journal/presentation/screens/sealed_journals_screen.dart';
import '../../features/posts/presentation/screens/feed_screen.dart';
import '../../features/onboarding/presentation/screens/ai_rating_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_complete_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_theme_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/shell/presentation/widgets/feature_coming_soon_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/theme_choice/presentation/screens/astra_landing_screen.dart';

import '../../features/wellbeing/presentation/screens/focus_timer_screen.dart';
import '../../features/wellbeing/presentation/screens/sos_calm_screen.dart';

import '../../features/export/presentation/screens/export_screen.dart';
import '../../features/auth/presentation/screens/greeting_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const astraLanding = '/astra-landing';
  static const onboarding = AuthFlowRoutes.onboarding;
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const nameEntry = AuthFlowRoutes.nameEntry;
  static const themeSelect = AuthFlowRoutes.themeSelect;
  static const welcome = AuthFlowRoutes.mood;
  static const greeting = AuthFlowRoutes.greeting;
  static const aiRating = AuthFlowRoutes.aiRating;
  static const onboardingComplete = AuthFlowRoutes.onboardingComplete;
  static const dailyReflection = AuthFlowRoutes.dailyReflection;
  static const home = AuthFlowRoutes.home;
  static const reminders = '/reminders';
  static const goals = '/goals';
  static const breathing = '/breathing';
  static const dreams = '/dreams';
  static const newDream = '/dreams/new';
  static const dreamReflection = '/dreams/reflection';
  static const featureComingSoon = '/feature-coming-soon';
  static const community = '/community';
  static const journalEntry = '/journal-entry';
  static const sealedJournals = '/sealed-journals';
  static const calendar = '/calendar';
  static const rewards = '/rewards';
  static const letters = '/letters';
  static const stats = '/stats';
  static const aiQuestions = '/ai-questions';
  static const meditation = '/meditation';
  static const hobbies = '/hobbies';
  static const hobbiesOnboarding = AuthFlowRoutes.hobbiesOnboarding;
  static const activities = '/activities';
  static const feed = '/feed';
  static const calm = '/calm';
  static const focusTimer = '/focus';
  static const favorites = '/favorites';
  static const quotes = '/quotes';
  static const exportData = '/export';
}

/// Bridges Supabase's auth-state stream to a [Listenable] so [GoRouter] can
/// re-run its `redirect` the moment a session is created or cleared —
/// otherwise `redirect` only fires on navigation, and a sign-out (say) would
/// leave a stale authenticated screen on-stack until the next manual nav.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Routes that require an authenticated Supabase session. Everything else
/// (splash/onboarding/login/signup) is reachable while logged out.
const _protectedRoutes = {
  AppRoutes.welcome,
  AppRoutes.home,
  AppRoutes.reminders,
  AppRoutes.goals,
  AppRoutes.breathing,
  AppRoutes.dreams,
  AppRoutes.newDream,
  AppRoutes.dreamReflection,
  AppRoutes.featureComingSoon,
  AppRoutes.community,
  AppRoutes.journalEntry,
  AppRoutes.dailyReflection,
  AppRoutes.sealedJournals,
  AppRoutes.calendar,
  AppRoutes.rewards,
  AppRoutes.letters,
  AppRoutes.stats,
  AppRoutes.aiQuestions,
  AppRoutes.meditation,
  AppRoutes.hobbies,
  AppRoutes.hobbiesOnboarding,
  AppRoutes.activities,
  AppRoutes.feed,
  AppRoutes.calm,
  AppRoutes.focusTimer,
  AppRoutes.favorites,
  AppRoutes.quotes,
  AppRoutes.exportData,
};

/// Lets screens (e.g. [AppShell]) become [RouteAware] so they can replay their
/// entrance animation when a pushed screen is popped and they reappear.
final RouteObserver<ModalRoute<void>> astraRouteObserver = RouteObserver<ModalRoute<void>>();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  observers: [astraRouteObserver],
  refreshListenable: _AuthRefreshNotifier(),
  redirect: (context, state) {
    final isAuthenticated = Supabase.instance.client.auth.currentSession != null;
    final targetRequiresFreshSignupIntent =
        state.matchedLocation == AppRoutes.nameEntry ||
            state.matchedLocation == AppRoutes.onboarding ||
            state.matchedLocation == AppRoutes.hobbiesOnboarding;
    if (targetRequiresFreshSignupIntent &&
        !AuthFlowRoutes.hasFreshSignupIntent(state.extra)) {
      return isAuthenticated ? AppRoutes.welcome : AppRoutes.login;
    }
    final targetIsProtected = _protectedRoutes.contains(state.matchedLocation);
    if (targetIsProtected && !isAuthenticated) {
      return AppRoutes.login;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _smoothPage(state, const SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.astraLanding,
      pageBuilder: (context, state) => _smoothPage(state, const AstraLandingScreen()),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _smoothPage(state, const OnboardingScreen(isNewSignup: true)),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _smoothPage(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.signup,
      pageBuilder: (context, state) => _smoothPage(state, const SignupScreen()),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      pageBuilder: (context, state) => _smoothPage(
        state,
        ResetPasswordScreen(email: state.extra is String ? state.extra as String : ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.nameEntry,
      pageBuilder: (context, state) => _smoothPage(state, const NameEntryScreen()),
    ),
    GoRoute(
      path: AppRoutes.themeSelect,
      pageBuilder: (context, state) => _smoothPage(state, const OnboardingThemeScreen()),
    ),
    GoRoute(
      path: AppRoutes.dailyReflection,
      pageBuilder: (context, state) =>
          _smoothPage(state, const DailyReflectionScreen()),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final isNewSignup = extra is bool
            ? extra
            : (extra is Map && extra['isNewSignup'] == true);
        return _smoothPage(state, WelcomeScreen(isNewSignup: isNewSignup));
      },
    ),
    GoRoute(
      path: AppRoutes.greeting,
      pageBuilder: (context, state) {
        final extra = state.extra;
        var isFirstWelcome = false;
        var nextRoute = AppRoutes.home;
        if (extra is bool) {
          // Legacy: end of sign-up flow passes `true` → first welcome → Home.
          isFirstWelcome = extra;
        } else if (extra is Map) {
          isFirstWelcome = extra['first'] == true;
          final next = extra['next'];
          if (next is String) nextRoute = next;
        }
        return _smoothPage(
          state,
          GreetingScreen(
            isFirstWelcome: isFirstWelcome,
            nextRoute: nextRoute,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.aiRating,
      pageBuilder: (context, state) => _smoothPage(
        state,
        AiRatingScreen(
          onBack: null,
          onSubmit: (rating) {
            unawaited(_persistAiRating(rating));
            context.go(AppRoutes.onboardingComplete);
          },
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingComplete,
      pageBuilder: (context, state) {
        final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
        final full = (meta?['full_name'] as String?)?.trim();
        final name = (full != null && full.isNotEmpty)
            ? full.split(RegExp(r'\s+')).first
            : null;
        return _smoothPage(
          state,
          OnboardingCompleteScreen(
            userName: name,
            onStart: () => context.go(AppRoutes.home),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _smoothPage(state, const AppShell()),
    ),
    GoRoute(
      path: AppRoutes.reminders,
      pageBuilder: (context, state) => _smoothPage(state, const RemindersScreen()),
    ),
    GoRoute(
      path: AppRoutes.goals,
      pageBuilder: (context, state) => _smoothPage(state, const GoalsScreen()),
    ),
    GoRoute(
      path: AppRoutes.breathing,
      pageBuilder: (context, state) => _smoothPage(state, const BreathingScreen()),
    ),
    GoRoute(
      path: AppRoutes.dreams,
      pageBuilder: (context, state) => _smoothPage(state, const DreamJournalScreen()),
    ),
    GoRoute(
      path: AppRoutes.newDream,
      pageBuilder: (context, state) => _smoothPage(state, const NewDreamScreen()),
    ),
    GoRoute(
      path: AppRoutes.dreamReflection,
      pageBuilder: (context, state) => _smoothPage(state, DreamReflectionScreen(dreamId: state.extra! as int)),
    ),
    GoRoute(
      path: AppRoutes.featureComingSoon,
      pageBuilder: (context, state) =>
          _smoothPage(state, FeatureComingSoonScreen(args: state.extra! as FeatureComingSoonArgs)),
    ),
    GoRoute(
      path: AppRoutes.exportData,
      pageBuilder: (context, state) => _smoothPage(state, const ExportScreen()),
    ),
    GoRoute(
      path: AppRoutes.community,
      pageBuilder: (context, state) => _smoothPage(state, const CommunityScreen()),
    ),
    GoRoute(
      path: AppRoutes.journalEntry,
      pageBuilder: (context, state) => _smoothPage(state, const JournalEntryScreen()),
    ),
    GoRoute(
      path: AppRoutes.sealedJournals,
      pageBuilder: (context, state) => _smoothPage(state, const SealedJournalsScreen()),
    ),
    GoRoute(
      path: AppRoutes.calendar,
      pageBuilder: (context, state) => _smoothPage(state, const CalendarScreen()),
    ),
    GoRoute(
      path: AppRoutes.rewards,
      pageBuilder: (context, state) => _smoothPage(state, const RewardsScreen()),
    ),
    GoRoute(
      path: AppRoutes.letters,
      pageBuilder: (context, state) => _smoothPage(state, const LettersScreen()),
    ),
    GoRoute(
      path: AppRoutes.stats,
      pageBuilder: (context, state) => _smoothPage(state, const StatsScreen()),
    ),
    GoRoute(
      path: AppRoutes.aiQuestions,
      pageBuilder: (context, state) => _smoothPage(state, const AiQuestionsScreen()),
    ),
    GoRoute(
      path: AppRoutes.meditation,
      pageBuilder: (context, state) => _smoothPage(state, const MeditationScreen()),
    ),
    GoRoute(
      path: AppRoutes.hobbies,
      pageBuilder: (context, state) => _smoothPage(state, const HobbiesScreen()),
    ),
    GoRoute(
      path: AppRoutes.hobbiesOnboarding,
      pageBuilder: (context, state) => _smoothPage(state, const HobbiesScreen(onboarding: true)),
    ),
    GoRoute(
      path: AppRoutes.activities,
      pageBuilder: (context, state) => _smoothPage(state, const ActivitiesScreen()),
    ),
    GoRoute(
      path: AppRoutes.feed,
      pageBuilder: (context, state) => _smoothPage(state, const FeedScreen()),
    ),
    GoRoute(
      path: AppRoutes.calm,
      pageBuilder: (context, state) => _smoothPage(state, const SosCalmScreen()),
    ),
    GoRoute(
      path: AppRoutes.focusTimer,
      pageBuilder: (context, state) => _smoothPage(state, const FocusTimerScreen()),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      pageBuilder: (context, state) => _smoothPage(state, const FavoritesScreen()),
    ),
    GoRoute(
      path: AppRoutes.quotes,
      pageBuilder: (context, state) => _smoothPage(state, QuoteGalleryScreen(initialIndex: (state.extra as int?) ?? 0)),
    ),
  ],
);

/// A soft, Reflectly-style page transition used app-wide: the incoming screen
/// fades in while gently rising, the outgoing one fades out — smooth on every
/// platform (the default web transition is an instant, "dead" cut). Keeping one
/// helper means every route shares the exact same feel.
CustomTransitionPage<void> _smoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Shared-axis (Z) feel that animates BOTH directions:
      // • Entering (animation 0→1): fade in + scale 0.96→1.0 + slight rise.
      // • Being covered (secondaryAnimation 0→1): fade out + recede to 0.95.
      // • Revealed on pop (secondaryAnimation 1→0): the old screen grows
      //   0.95→1.0 and fades back in — no more static cut on back.
      final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final outCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

      // Bold, unmistakable horizontal push: the new screen slides in from the
      // right while fading; the old one recedes to the left.
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.30, 0), end: Offset.zero)
            .animate(inCurve),
        child: FadeTransition(
          opacity: inCurve,
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.14, 0))
                .animate(outCurve),
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

/// Stores the user's first AI-experience rating (1–5) locally. Best-effort;
/// a sync problem must never block the onboarding hand-off.
Future<void> _persistAiRating(int rating) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_first_rating_v1', rating);
  } catch (_) {
    // Ignore — the rating is a nice-to-have signal, not critical state.
  }
}
